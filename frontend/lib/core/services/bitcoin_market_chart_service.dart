import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:kerosene/core/logging/app_log.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BitcoinMarketChartPoint {
  final DateTime time;
  final double price;

  const BitcoinMarketChartPoint({
    required this.time,
    required this.price,
  });

  int get timeMillis => time.millisecondsSinceEpoch;
}

enum BitcoinMarketChartRange {
  oneDay('1D', '15m', 96),
  oneWeek('1W', '1h', 168),
  oneMonth('1M', '4h', 180),
  oneYear('1Y', '1d', 366),
  all('ALL', '1M', 1000);

  const BitcoinMarketChartRange(this.label, this.binanceInterval, this.limit);

  final String label;
  final String binanceInterval;
  final int limit;

  DateTime? startDate(DateTime now) {
    switch (this) {
      case BitcoinMarketChartRange.oneDay:
        return now.subtract(const Duration(days: 1));
      case BitcoinMarketChartRange.oneWeek:
        return now.subtract(const Duration(days: 7));
      case BitcoinMarketChartRange.oneMonth:
        return now.subtract(const Duration(days: 31));
      case BitcoinMarketChartRange.oneYear:
        return now.subtract(const Duration(days: 366));
      case BitcoinMarketChartRange.all:
        return null;
    }
  }
}

class BitcoinMarketChartRequest {
  final String symbol;
  final Currency quoteCurrency;
  final BitcoinMarketChartRange range;

  const BitcoinMarketChartRequest({
    required this.symbol,
    required this.quoteCurrency,
    required this.range,
  });

  static const fallback = BitcoinMarketChartRequest(
    symbol: 'BTCUSDT',
    quoteCurrency: Currency.usd,
    range: BitcoinMarketChartRange.oneDay,
  );

  String get streamName => '${symbol.toLowerCase()}@kline_${range.binanceInterval}';
  String get tickerStreamName => '${symbol.toLowerCase()}@ticker';
  String get combinedStreamNames => '$streamName/$tickerStreamName';
  String get pairLabel => 'BTC/${quoteCurrency.code}';

  BitcoinMarketChartRequest fallbackForSameRange() {
    return BitcoinMarketChartRequest(
      symbol: 'BTCUSDT',
      quoteCurrency: Currency.usd,
      range: range,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BitcoinMarketChartRequest &&
        other.symbol == symbol &&
        other.quoteCurrency == quoteCurrency &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(symbol, quoteCurrency, range);
}

class BitcoinMarketChartSnapshot {
  final BitcoinMarketChartRequest request;
  final List<BitcoinMarketChartPoint> points;
  final DateTime lastUpdatedAt;
  final bool isLive;

  const BitcoinMarketChartSnapshot({
    required this.request,
    required this.points,
    required this.lastUpdatedAt,
    required this.isLive,
  });

  double get firstPrice => points.isEmpty ? 0 : points.first.price;
  double get lastPrice => points.isEmpty ? 0 : points.last.price;
  double get highPrice => points.fold<double>(
        0,
        (previous, point) => previous == 0 ? point.price : math.max(previous, point.price),
      );
  double get lowPrice => points.fold<double>(
        0,
        (previous, point) => previous == 0 ? point.price : math.min(previous, point.price),
      );

  double? get changePercent {
    if (points.length < 2 || firstPrice <= 0) {
      return null;
    }
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }
}

class BitcoinMarketChartService {
  BitcoinMarketChartService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static final Uri _binanceRestBaseUri = Uri.parse(
    'https://api.binance.com/api/v3/klines',
  );
  static final Uri _binanceStreamBaseUri = Uri.parse(
    'wss://data-stream.binance.vision/stream',
  );
  static const Duration _httpTimeout = Duration(seconds: 8);
  static const int _maxReconnectAttempts = 6;

  final http.Client _httpClient;
  final _snapshotController =
      StreamController<BitcoinMarketChartSnapshot>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  BitcoinMarketChartRequest? _activeRequest;
  BitcoinMarketChartSnapshot? _latestSnapshot;
  List<BitcoinMarketChartPoint> _points = const [];
  bool _isDisposed = false;
  bool _isConnecting = false;
  int _generation = 0;
  int _reconnectAttempts = 0;

  Stream<BitcoinMarketChartSnapshot> get snapshots async* {
    final snapshot = _latestSnapshot;
    if (snapshot != null) {
      yield snapshot;
    }
    yield* _snapshotController.stream;
  }

  Future<void> setRequest(BitcoinMarketChartRequest request) async {
    if (_isDisposed) {
      return;
    }

    final latest = _latestSnapshot;
    if (_activeRequest == request && latest != null) {
      _safeAdd(latest);
      return;
    }

    final generation = ++_generation;
    _activeRequest = request;
    _reconnectAttempts = 0;
    await _closeChannel();
    await _loadAndConnect(request, generation, allowFallback: true);
  }

  Future<void> _loadAndConnect(
    BitcoinMarketChartRequest request,
    int generation, {
    required bool allowFallback,
  }) async {
    try {
      final points = await _fetchHistory(request);
      if (_isStale(generation)) {
        return;
      }

      _points = List.unmodifiable(points);
      _emitSnapshot(request, isLive: false);
      _connectKlineStream(request, generation);
    } catch (error) {
      appLog(
        'BitcoinMarketChart: history load failed for ${request.symbol}: $error',
      );

      if (allowFallback && request.symbol != 'BTCUSDT') {
        final fallback = request.fallbackForSameRange();
        _activeRequest = fallback;
        await _loadAndConnect(fallback, generation, allowFallback: false);
        return;
      }

      if (!_snapshotController.isClosed && !_isDisposed) {
        _snapshotController.addError(error);
      }
    }
  }

  Future<List<BitcoinMarketChartPoint>> _fetchHistory(
    BitcoinMarketChartRequest request,
  ) async {
    final now = DateTime.now();
    final start = request.range.startDate(now);
    final query = <String, String>{
      'symbol': request.symbol,
      'interval': request.range.binanceInterval,
      'limit': '${request.range.limit}',
    };
    if (start != null) {
      query['startTime'] = '${start.millisecondsSinceEpoch}';
    }

    final uri = _binanceRestBaseUri.replace(queryParameters: query);
    final response = await _httpClient.get(uri).timeout(_httpTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode} from Binance klines.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Expected Binance kline list.');
    }

    final points = decoded
        .whereType<List<dynamic>>()
        .map(_parseRestKline)
        .where((point) => point.price > 0)
        .toList()
      ..sort((a, b) => a.timeMillis.compareTo(b.timeMillis));

    final unique = <BitcoinMarketChartPoint>[];
    for (final point in points) {
      if (unique.isNotEmpty && unique.last.timeMillis == point.timeMillis) {
        unique[unique.length - 1] = point;
      } else {
        unique.add(point);
      }
    }

    if (unique.length > request.range.limit) {
      return unique.sublist(unique.length - request.range.limit);
    }
    if (unique.isEmpty) {
      throw StateError('Binance returned no kline points.');
    }
    return unique;
  }

  BitcoinMarketChartPoint _parseRestKline(List<dynamic> raw) {
    if (raw.length < 5) {
      throw const FormatException('Invalid kline payload.');
    }
    return BitcoinMarketChartPoint(
      time: DateTime.fromMillisecondsSinceEpoch(_toInt(raw[0])),
      price: _toDouble(raw[4]),
    );
  }

  void _connectKlineStream(BitcoinMarketChartRequest request, int generation) {
    if (_isDisposed || _isStale(generation) || _isConnecting) {
      return;
    }

    _isConnecting = true;
    final streamUri = _binanceStreamBaseUri.replace(
      queryParameters: {'streams': request.combinedStreamNames},
    );

    try {
      appLog('BitcoinMarketChart: connecting ${request.streamName}.');
      final channel = WebSocketChannel.connect(streamUri);
      _channel = channel;

      unawaited(
        channel.ready.then((_) {
          if (_isStale(generation) || _isDisposed) {
            return;
          }
          _reconnectAttempts = 0;
          _isConnecting = false;
          final latest = _latestSnapshot;
          if (latest != null && latest.request == request) {
            _emitSnapshot(request, isLive: true);
          }
          appLog('BitcoinMarketChart: ${request.streamName} connected.');
        }).catchError((Object error) {
          _isConnecting = false;
          appLog('BitcoinMarketChart: websocket ready failed: $error');
          unawaited(
            _closeChannel().whenComplete(
              () => _scheduleReconnect(request, generation),
            ),
          );
        }),
      );

      _subscription = channel.stream.listen(
        (data) {
          try {
            _applyKlineUpdate(data, request, generation);
          } catch (error) {
            appLog('BitcoinMarketChart: websocket payload rejected: $error');
          }
        },
        onError: (Object error) {
          appLog('BitcoinMarketChart: websocket error: $error');
          _isConnecting = false;
          unawaited(
            _closeChannel().whenComplete(
              () => _scheduleReconnect(request, generation),
            ),
          );
        },
        onDone: () {
          appLog('BitcoinMarketChart: websocket closed.');
          _isConnecting = false;
          _subscription = null;
          _channel = null;
          _scheduleReconnect(request, generation);
        },
        cancelOnError: false,
      );
    } catch (error) {
      _isConnecting = false;
      appLog('BitcoinMarketChart: websocket connection failed: $error');
      _scheduleReconnect(request, generation);
    }
  }

  void _applyKlineUpdate(
    dynamic data,
    BitcoinMarketChartRequest request,
    int generation,
  ) {
    if (_isDisposed || _isStale(generation)) {
      return;
    }

    final envelope = _decodeMap(data);
    final payloadRaw = envelope['data'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : envelope;
    final eventType = payload['e'];
    if (eventType == 'serverShutdown') {
      unawaited(
        _closeChannel().whenComplete(
          () => _scheduleReconnect(request, generation),
        ),
      );
      return;
    }
    if (eventType == '24hrTicker') {
      _applyTickerUpdate(payload, request);
      return;
    }

    final klineRaw = payload['k'];
    if (eventType != 'kline' || klineRaw is! Map) {
      return;
    }

    final kline = Map<String, dynamic>.from(klineRaw);
    final point = BitcoinMarketChartPoint(
      time: DateTime.fromMillisecondsSinceEpoch(_toInt(kline['t'])),
      price: _toDouble(kline['c']),
    );
    if (point.price <= 0) {
      return;
    }

    final next = List<BitcoinMarketChartPoint>.of(_points);
    if (next.isEmpty) {
      next.add(point);
    } else {
      final lastIndex = next.length - 1;
      final last = next[lastIndex];
      if (last.timeMillis == point.timeMillis) {
        next[lastIndex] = point;
      } else if (point.timeMillis > last.timeMillis) {
        next.add(point);
      } else {
        final index = next.indexWhere((item) => item.timeMillis == point.timeMillis);
        if (index >= 0) {
          next[index] = point;
        }
      }
    }

    if (next.length > request.range.limit) {
      next.removeRange(0, next.length - request.range.limit);
    }

    _points = List.unmodifiable(next);
    _emitSnapshot(request, isLive: true);
  }

  void _applyTickerUpdate(
    Map<String, dynamic> payload,
    BitcoinMarketChartRequest request,
  ) {
    if (_points.isEmpty) {
      return;
    }
    final price = _toDouble(payload['c']);
    if (price <= 0) {
      return;
    }

    final next = List<BitcoinMarketChartPoint>.of(_points);
    final lastIndex = next.length - 1;
    final last = next[lastIndex];
    if ((last.price - price).abs() < 0.01) {
      return;
    }

    next[lastIndex] = BitcoinMarketChartPoint(
      time: last.time,
      price: price,
    );
    _points = List.unmodifiable(next);
    _emitSnapshot(request, isLive: true);
  }

  void _scheduleReconnect(BitcoinMarketChartRequest request, int generation) {
    if (_isDisposed || _isStale(generation)) {
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      appLog('BitcoinMarketChart: reconnect limit reached.');
      final latest = _latestSnapshot;
      if (latest != null && latest.request == request) {
        _emitSnapshot(request, isLive: false);
      }
      return;
    }

    _reconnectTimer?.cancel();
    final attempt = _reconnectAttempts++;
    final seconds = math.min(30, 2 * (1 << attempt));
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (_isDisposed || _isStale(generation)) {
        return;
      }
      _connectKlineStream(request, generation);
    });
  }

  void _emitSnapshot(BitcoinMarketChartRequest request, {required bool isLive}) {
    if (_isDisposed || _points.isEmpty) {
      return;
    }

    final snapshot = BitcoinMarketChartSnapshot(
      request: request,
      points: List.unmodifiable(_points),
      lastUpdatedAt: DateTime.now(),
      isLive: isLive,
    );
    _latestSnapshot = snapshot;
    _safeAdd(snapshot);
  }

  void _safeAdd(BitcoinMarketChartSnapshot snapshot) {
    if (!_isDisposed && !_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }

  bool _isStale(int generation) => generation != _generation;

  Map<String, dynamic> _decodeMap(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Expected JSON object payload.');
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse('$value');
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.parse('$value');
  }

  Future<void> _closeChannel() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }

    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await channel.sink.close();
    }
    _isConnecting = false;
  }

  Future<void> dispose() async {
    _isDisposed = true;
    ++_generation;
    await _closeChannel();
    await _snapshotController.close();
    _httpClient.close();
  }
}
