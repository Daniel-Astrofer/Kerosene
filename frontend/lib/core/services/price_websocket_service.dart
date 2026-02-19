import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for real-time BTC price updates via WebSocket
/// Primary: Binance, Backup: Coinbase
class PriceWebSocketService {
  WebSocketChannel? _primaryChannel;
  WebSocketChannel? _backupChannel;
  final _priceController = StreamController<double>.broadcast();
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _usingBackup = false;

  // Binance WebSocket URL
  static const String _binanceUrl =
      'wss://stream.binance.com:9443/ws/btcusdt@ticker';

  // Coinbase WebSocket URL
  static const String _coinbaseUrl = 'wss://ws-feed.exchange.coinbase.com';

  Stream<double> get priceStream => _priceController.stream;

  void connect() {
    if (_isDisposed) return;
    _connectPrimary();
  }

  void _connectPrimary() {
    try {
      debugPrint('>>> PriceWebSocket: Connecting to Binance...');
      _primaryChannel = WebSocketChannel.connect(Uri.parse(_binanceUrl));

      _primaryChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            final price = double.parse(json['c']); // Current price
            _priceController.add(price);
            _usingBackup = false;
            debugPrint(
              '>>> PriceWebSocket: Binance price: \$${price.toStringAsFixed(2)}',
            );
          } catch (e) {
            debugPrint('>>> PriceWebSocket: Error parsing Binance data: $e');
          }
        },
        onError: (error) {
          debugPrint('>>> PriceWebSocket: Binance error: $error');
          _connectBackup();
        },
        onDone: () {
          debugPrint('>>> PriceWebSocket: Binance connection closed');
          if (!_isDisposed && !_usingBackup) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      debugPrint('>>> PriceWebSocket: Failed to connect to Binance: $e');
      _connectBackup();
    }
  }

  void _connectBackup() {
    if (_usingBackup || _isDisposed) return;

    try {
      debugPrint('>>> PriceWebSocket: Switching to Coinbase backup...');
      _usingBackup = true;

      _backupChannel = WebSocketChannel.connect(Uri.parse(_coinbaseUrl));

      // Subscribe to BTC-USD ticker
      final subscribeMessage = jsonEncode({
        'type': 'subscribe',
        'product_ids': ['BTC-USD'],
        'channels': ['ticker'],
      });
      _backupChannel!.sink.add(subscribeMessage);

      _backupChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            if (json['type'] == 'ticker' && json['price'] != null) {
              final price = double.parse(json['price']);
              _priceController.add(price);
              debugPrint(
                '>>> PriceWebSocket: Coinbase price: \$${price.toStringAsFixed(2)}',
              );
            }
          } catch (e) {
            debugPrint('>>> PriceWebSocket: Error parsing Coinbase data: $e');
          }
        },
        onError: (error) {
          debugPrint('>>> PriceWebSocket: Coinbase error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('>>> PriceWebSocket: Coinbase connection closed');
          if (!_isDisposed) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      debugPrint('>>> PriceWebSocket: Failed to connect to Coinbase: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        debugPrint('>>> PriceWebSocket: Attempting reconnect...');
        _usingBackup = false;
        _connectPrimary();
      }
    });
  }

  void dispose() {
    debugPrint('>>> PriceWebSocket: Disposing...');
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _primaryChannel?.sink.close();
    _backupChannel?.sink.close();
    _priceController.close();
  }
}
