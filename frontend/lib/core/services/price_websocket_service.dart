import 'dart:async';
import 'dart:convert';
import 'package:kerosene/core/logging/app_log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PriceTickerSnapshot {
  final double priceUsd;
  final double? dailyChangePercent;

  const PriceTickerSnapshot({
    required this.priceUsd,
    required this.dailyChangePercent,
  });
}

/// Service for real-time BTC price updates via WebSocket
/// Primary: Binance, Backup: Coinbase.
/// External market feeds stay on clearnet; only the sovereign backend uses Tor.
class PriceWebSocketService {
  static final Uri _binanceTickerUri = Uri.parse(
    'wss://stream.binance.com:9443/ws/btcusdt@ticker',
  );
  static final Uri _coinbaseFeedUri = Uri.parse(
    'wss://ws-feed.exchange.coinbase.com',
  );
  static const String _coinbaseProductId = 'BTC-USD';
  static final String _coinbaseSubscriptionMessage = jsonEncode({
    'type': 'subscribe',
    'product_ids': [_coinbaseProductId],
    'channels': ['ticker'],
  });

  WebSocketChannel? _primaryChannel;
  WebSocketChannel? _backupChannel;
  StreamSubscription<dynamic>? _primarySubscription;
  StreamSubscription<dynamic>? _backupSubscription;
  final _priceController = StreamController<double>.broadcast();
  final _tickerController = StreamController<PriceTickerSnapshot>.broadcast();
  Timer? _reconnectTimer;
  PriceTickerSnapshot? _lastEmittedTicker;
  DateTime? _lastTickerEmittedAt;
  bool _isDisposed = false;
  bool _isUsingBackup = false;
  bool _isConnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _tickerEmitInterval = Duration(seconds: 2);
  static const double _minPriceDeltaUsd = 1;
  static const double _minChangeDeltaPercent = 0.01;

  Stream<double> get priceStream => _priceController.stream;
  Stream<PriceTickerSnapshot> get tickerStream => _tickerController.stream;

  void connect() {
    if (_isDisposed) return;
    _retryCount = 0;
    _connectPrimary();
  }

  Future<void> _connectPrimary() async {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;
    _closePrimary();

    try {
      appLog('PriceWebSocket: connecting to Binance via clearnet.');
      _primaryChannel = WebSocketChannel.connect(_binanceTickerUri);

      await _primaryChannel!.ready;
      appLog('PriceWebSocket: Binance connected.');
      _retryCount = 0;

      _primarySubscription = _primaryChannel!.stream.listen(
        (data) {
          try {
            _emitTicker(_parseBinanceTicker(data));
            _isUsingBackup = false;
          } catch (e) {
            appLog('PriceWebSocket: Binance payload rejected: $e');
          }
        },
        onError: (error) {
          appLog('PriceWebSocket: Binance socket error: $error');
          _closePrimary();
          _connectBackup();
        },
        onDone: () {
          appLog('PriceWebSocket: Binance connection closed.');
          _primarySubscription = null;
          _primaryChannel = null;
          if (!_isDisposed && !_isUsingBackup) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      appLog('PriceWebSocket: Binance connection failed: $e');
      _connectBackup();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _connectBackup() async {
    if (_isUsingBackup || _isDisposed) return;
    _closeBackup();

    try {
      appLog('PriceWebSocket: switching to Coinbase backup via clearnet.');
      _isUsingBackup = true;

      _backupChannel = WebSocketChannel.connect(_coinbaseFeedUri);

      await _backupChannel!.ready;
      appLog('PriceWebSocket: Coinbase connected.');

      _backupChannel!.sink.add(_coinbaseSubscriptionMessage);

      _backupSubscription = _backupChannel!.stream.listen(
        (data) {
          try {
            final ticker = _parseCoinbaseTicker(data);
            if (ticker != null) {
              _emitTicker(ticker);
            }
          } catch (e) {
            appLog('PriceWebSocket: Coinbase payload rejected: $e');
          }
        },
        onError: (error) {
          appLog('PriceWebSocket: Coinbase socket error: $error');
          _closeBackup();
          _scheduleReconnect();
        },
        onDone: () {
          appLog('PriceWebSocket: Coinbase connection closed.');
          _backupSubscription = null;
          _backupChannel = null;
          if (!_isDisposed) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      appLog('PriceWebSocket: Coinbase connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();

    if (_retryCount >= _maxRetries) {
      appLog('PriceWebSocket: max retries reached. Stopping.');
      return;
    }

    final delay = Duration(seconds: 5 * (1 << _retryCount));
    _retryCount++;
    appLog(
      'PriceWebSocket: reconnecting in ${delay.inSeconds}s '
      '(attempt $_retryCount/$_maxRetries).',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        _isUsingBackup = false;
        _isConnecting = false;
        _connectPrimary();
      }
    });
  }

  void _emitTicker(PriceTickerSnapshot ticker) {
    if (_isDisposed ||
        _priceController.isClosed ||
        _tickerController.isClosed) {
      return;
    }
    if (!_shouldEmitTicker(ticker)) {
      return;
    }
    _lastEmittedTicker = ticker;
    _lastTickerEmittedAt = DateTime.now();
    _priceController.add(ticker.priceUsd);
    _tickerController.add(ticker);
  }

  bool _shouldEmitTicker(PriceTickerSnapshot ticker) {
    final lastTicker = _lastEmittedTicker;
    final lastEmittedAt = _lastTickerEmittedAt;
    if (lastTicker == null || lastEmittedAt == null) {
      return true;
    }

    if (DateTime.now().difference(lastEmittedAt) >= _tickerEmitInterval) {
      return true;
    }

    final priceMoved =
        (ticker.priceUsd - lastTicker.priceUsd).abs() >= _minPriceDeltaUsd;
    final previousChange = lastTicker.dailyChangePercent;
    final nextChange = ticker.dailyChangePercent;
    final changeMoved = previousChange == null || nextChange == null
        ? previousChange != nextChange
        : (nextChange - previousChange).abs() >= _minChangeDeltaPercent;

    return priceMoved || changeMoved;
  }

  PriceTickerSnapshot _parseBinanceTicker(dynamic data) {
    final payload = _decodePayload(data);
    return PriceTickerSnapshot(
      priceUsd: double.parse('${payload['c']}'),
      dailyChangePercent: double.tryParse('${payload['P']}'),
    );
  }

  PriceTickerSnapshot? _parseCoinbaseTicker(dynamic data) {
    final payload = _decodePayload(data);
    if (payload['type'] != 'ticker' || payload['price'] == null) {
      return null;
    }

    final price = double.parse('${payload['price']}');
    final open24h = double.tryParse('${payload['open_24h']}');
    return PriceTickerSnapshot(
      priceUsd: price,
      dailyChangePercent: open24h != null && open24h > 0
          ? ((price - open24h) / open24h) * 100
          : null,
    );
  }

  Map<String, dynamic> _decodePayload(dynamic data) {
    final decoded = data is String ? jsonDecode(data) : data;
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('Expected JSON object payload.');
  }

  void _closePrimary() {
    final subscription = _primarySubscription;
    _primarySubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    final channel = _primaryChannel;
    _primaryChannel = null;
    if (channel != null) {
      unawaited(channel.sink.close());
    }
  }

  void _closeBackup() {
    final subscription = _backupSubscription;
    _backupSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    final channel = _backupChannel;
    _backupChannel = null;
    if (channel != null) {
      unawaited(channel.sink.close());
    }
  }

  void dispose() {
    appLog('PriceWebSocket: disposing.');
    _isDisposed = true;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closePrimary();
    _closeBackup();
    _priceController.close();
    _tickerController.close();
  }
}
