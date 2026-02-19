import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class BinanceSocketService {
  WebSocketChannel? _channel;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dataStream => _streamController.stream;

  void connect() {
    // Connect to combined streams for real-time klines and ticker info
    // streams: btcusdt@ticker (for 24h stats), btcusdt@kline_1m (for real-time chart tip)
    final url = Uri.parse(
      'wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/btcusdt@kline_1m',
    );

    _channel = WebSocketChannel.connect(url);

    _channel!.stream.listen(
      (message) {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          _streamController.add(decoded);
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
    Future.delayed(const Duration(seconds: 3), () => connect());
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<List<dynamic>>();
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
