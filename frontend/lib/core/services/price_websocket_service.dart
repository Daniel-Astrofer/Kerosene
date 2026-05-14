import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

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
  IOWebSocketChannel? _primaryChannel;
  IOWebSocketChannel? _backupChannel;
  final _priceController = StreamController<double>.broadcast();
  final _tickerController = StreamController<PriceTickerSnapshot>.broadcast();
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _usingBackup = false;
  bool _isConnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

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

    try {
      debugPrint('>>> PriceWebSocket: Connecting to Binance via clearnet...');
      _primaryChannel = IOWebSocketChannel.connect(
        Uri.parse('wss://stream.binance.com:9443/ws/btcusdt@ticker'),
      );

      await _primaryChannel!.ready;
      debugPrint('>>> PriceWebSocket: Binance connected.');
      _retryCount = 0;

      _primaryChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            final price = double.parse(json['c']); // Current price
            final dailyChangePercent = double.tryParse('${json['P']}');
            if (!_isDisposed) {
              _priceController.add(price);
              _tickerController.add(
                PriceTickerSnapshot(
                  priceUsd: price,
                  dailyChangePercent: dailyChangePercent,
                ),
              );
            }
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
      debugPrint(
        '>>> PriceWebSocket: Switching to Coinbase backup via clearnet...',
      );
      _usingBackup = true;

      _backupChannel = IOWebSocketChannel.connect(
        Uri.parse('wss://ws-feed.exchange.coinbase.com'),
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
              final open24h = double.tryParse('${json['open_24h']}');
              final dailyChangePercent = open24h != null && open24h > 0
                  ? ((price - open24h) / open24h) * 100
                  : null;
              if (!_isDisposed) {
                _priceController.add(price);
                _tickerController.add(
                  PriceTickerSnapshot(
                    priceUsd: price,
                    dailyChangePercent: dailyChangePercent,
                  ),
                );
              }
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
    _tickerController.close();
  }
}
