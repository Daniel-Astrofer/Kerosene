import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/tor_service.dart';

class BinanceSocketService {
  WebSocketChannel? _channel;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _streamController.stream;

  String _currentInterval = '1m';

  void connect({String interval = '1m'}) {
    _currentInterval = interval;
    _internalConnect();
  }

  void _internalConnect() async {
    _channel?.sink.close();

    // Valid Binance stream intervals: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M
    debugPrint('Connecting to Binance Socket via Tor...');

    final relayPort = await TorService.instance.startRelay(
      'stream.binance.com',
      9443,
    );
    final url = Uri.parse(
      'wss://127.0.0.1:$relayPort/stream?streams=btcusdt@ticker/btcusdt@kline_$_currentInterval',
    );

    _channel = WebSocketChannel.connect(url);

    _channel!.stream.listen(
      (message) async {
        try {
          final decoded = await compute(jsonDecode, message as String);
          if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
            _streamController.add(decoded);
          }
        } catch (e) {
          debugPrint('Binance Socket Parse Error: $e');
        }
      },
      onError: (error) {
        debugPrint('Binance Socket Error: $error');
        _reconnect();
      },
      onDone: () {
        debugPrint('Binance Socket Closed');
        _reconnect();
      },
    );
  }

  void _reconnect() {
    disconnect();
    Future.delayed(const Duration(seconds: 3), () => _internalConnect());
  }

  // Fetch historical klines (candles) via REST API
  // Intervals: 1m, 15m, 1h, 4h, 1d, 1w
  Future<List<List<dynamic>>> fetchHistoricalCandles(
    String symbol,
    String interval, {
    int limit = 500,
  }) async {
    final uri = Uri.parse(
      'https://api.binance.com/api/v3/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = await compute(jsonDecode, response.body);
        return (data as List<dynamic>).cast<List<dynamic>>();
      } else {
        debugPrint('Binance REST Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching historical candles: $e');
      return [];
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
