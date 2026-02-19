import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Serviço para WebSocket de atualizações de saldo em tempo real
class BalanceWebSocketService {
  StompClient? _stompClient;
  final String baseUrl;
  final String userId;
  final String? authToken;
  final Function(BalanceUpdate) onBalanceUpdate;
  bool _isConnected = false;

  BalanceWebSocketService({
    required this.baseUrl,
    required this.userId,
    this.authToken,
    required this.onBalanceUpdate,
  });

  bool get isConnected => _isConnected;

  /// Conecta ao WebSocket do backend
  void connect() {
    if (_stompClient != null && _isConnected) {
      debugPrint('⚠️ WebSocket já está conectado');
      return;
    }

    // Converter HTTP/HTTPS para WS/WSS
    var wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    // Remove trailing slash se houver
    if (wsUrl.endsWith('/')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 1);
    }

    // SockJS do Spring Boot requer /websocket no final
    final fullUrl = '$wsUrl/ws/balance/websocket';
    debugPrint('🔌 Conectando WebSocket: $fullUrl');

    _stompClient = StompClient(
      config: StompConfig(
        url: fullUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          debugPrint('❌ WS Error: $error');
          _isConnected = false;
        },
        onStompError: (StompFrame frame) {
          debugPrint('❌ STOMP Error: ${frame.body}');
          _isConnected = false;
        },
        onDisconnect: (_) {
          debugPrint('🔌 WebSocket desconectado');
          _isConnected = false;
        },
        beforeConnect: () async {
          debugPrint('🔄 Iniciando conexão WebSocket...');
        },
        onWebSocketDone: () {
          debugPrint('✅ WebSocket done');
        },
        // Headers com autenticação JWT
        webSocketConnectHeaders: {
          'ngrok-skip-browser-warning': 'true',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        // Reconectar automaticamente se cair
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
  }

  /// Callback quando conectado ao WebSocket
  void _onConnect(StompFrame frame) {
    _isConnected = true;
    debugPrint('✅ WebSocket conectado com sucesso!');
    debugPrint('📡 Frame: ${frame.headers}');
    debugPrint('📡 Inscrevendo-se em: /topic/balance/$userId');

    _stompClient?.subscribe(
      destination: '/topic/balance/$userId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            debugPrint('📨 RAW MESSAGE: ${frame.body}');
            final json = jsonDecode(frame.body!);
            final update = BalanceUpdate.fromJson(json);

            debugPrint(
              '💰 Balance update recebido: ${update.walletName} = ${update.newBalance} BTC',
            );
            onBalanceUpdate(update);
          } catch (e, stackTrace) {
            debugPrint('❌ Erro ao processar mensagem WS: $e');
            debugPrint('Stack: $stackTrace');
          }
        }
      },
    );

    debugPrint('✅ Subscrição concluída!');
  }

  /// Desconecta do WebSocket
  void disconnect() {
    if (_stompClient != null) {
      debugPrint('🔌 Desconectando WebSocket...');
      _stompClient?.deactivate();
      _stompClient = null;
      _isConnected = false;
    }
  }
}

/// Modelo de atualização de saldo recebida via WebSocket
class BalanceUpdate {
  final int walletId;
  final String walletName;
  final int userId;
  final double newBalance;
  final double amount;
  final String context;
  final String timestamp;

  BalanceUpdate({
    required this.walletId,
    required this.walletName,
    required this.userId,
    required this.newBalance,
    required this.amount,
    required this.context,
    required this.timestamp,
  });

  factory BalanceUpdate.fromJson(Map<String, dynamic> json) {
    return BalanceUpdate(
      walletId: json['walletId'] as int,
      walletName: json['walletName'] as String,
      userId: json['userId'] as int,
      newBalance: (json['newBalance'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      context: json['context'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletId': walletId,
      'walletName': walletName,
      'userId': userId,
      'newBalance': newBalance,
      'amount': amount,
      'context': context,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'BalanceUpdate(wallet: $walletName, newBalance: $newBalance BTC, amount: $amount, context: $context)';
  }
}
