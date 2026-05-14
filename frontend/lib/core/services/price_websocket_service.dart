import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'tor_service.dart';

/// Service for real-time BTC price updates via WebSocket
/// Primary: Binance, Backup: Coinbase
class PriceWebSocketService {
  IOWebSocketChannel? _primaryChannel;
  IOWebSocketChannel? _backupChannel;
  final _priceController = StreamController<double>.broadcast();
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _usingBackup = false;
  bool _isConnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  Stream<double> get priceStream => _priceController.stream;

  void connect() {
    if (_isDisposed) return;
    _retryCount = 0;
    _connectPrimary();
  }

  /// Creates an HttpClient that accepts certs for the local Tor relay
  HttpClient _createRelayHttpClient() {
    return HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host == '127.0.0.1' || host == 'localhost';
      };
  }

  Future<void> _connectPrimary() async {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;

    try {
      debugPrint('>>> PriceWebSocket: Connecting to Binance via Tor...');
      final relayPort = await TorService.instance.startRelay(
        'stream.binance.com',
        9443,
      );

      _primaryChannel = IOWebSocketChannel.connect(
        Uri.parse('wss://127.0.0.1:$relayPort/ws/btcusdt@ticker'),
        customClient: _createRelayHttpClient(),
      );

      await _primaryChannel!.ready;
      debugPrint('>>> PriceWebSocket: Binance connected.');
      _retryCount = 0;

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
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _connectBackup() async {
    if (_usingBackup || _isDisposed) return;

    try {
      debugPrint('>>> PriceWebSocket: Switching to Coinbase backup via Tor...');
      _usingBackup = true;

      final relayPort = await TorService.instance.startRelay(
        'ws-feed.exchange.coinbase.com',
        443,
      );

      _backupChannel = IOWebSocketChannel.connect(
        Uri.parse('wss://127.0.0.1:$relayPort'),
        customClient: _createRelayHttpClient(),
      );

      await _backupChannel!.ready;
      debugPrint('>>> PriceWebSocket: Coinbase connected.');

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
    if (_isDisposed) return;
    _reconnectTimer?.cancel();

    if (_retryCount >= _maxRetries) {
      debugPrint(
        '>>> PriceWebSocket: Max retries ($_maxRetries) reached. Stopping.',
      );
      return;
    }

    final delay = Duration(seconds: 5 * (1 << _retryCount));
    _retryCount++;
    debugPrint(
      '>>> PriceWebSocket: Reconnecting in ${delay.inSeconds}s (attempt $_retryCount/$_maxRetries)...',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        _usingBackup = false;
        _isConnecting = false;
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
