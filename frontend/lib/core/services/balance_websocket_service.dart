import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Serviço para WebSocket de atualizações de saldo em tempo real
class BalanceWebSocketService {
  StompClient? _stompClient;
  final String baseUrl;
  final String userId;
  final String? authToken;
  final String? deviceHash;
  final Function(BalanceUpdate) onBalanceUpdate;
  bool _isConnected = false;

  BalanceWebSocketService({
    required this.baseUrl,
    required this.userId,
    this.authToken,
    this.deviceHash,
    required this.onBalanceUpdate,
  });

  bool get isConnected => _isConnected;

  /// Conecta ao WebSocket do backend via ponte local SOCKS5 (Tor)
  Future<void> connect() async {
    if (_stompClient != null && _isConnected) {
      debugPrint('⚠️ WebSocket já está conectado');
      return;
    }

    // baseUrl already points to the local Tor relay (e.g. http://127.0.0.1:55432),
    // set by main.dart / background_service.dart after the relay is started.
    final wsUrl = baseUrl.replaceFirst('http', 'ws');

    // Use the raw WebSocket endpoint (no SockJS negotiation needed by stomp_dart_client).
    var fullUrl = '$wsUrl/ws/raw-balance';

    // Pass auth credentials as query params — more reliable across the relay tunnel.
    final queryParams = <String>[];
    if (authToken != null && authToken!.isNotEmpty) {
      queryParams.add('token=${Uri.encodeComponent(authToken!)}');
    }
    if (deviceHash != null && deviceHash!.isNotEmpty) {
      queryParams.add('X-Device-Hash=${Uri.encodeComponent(deviceHash!)}');
    }

    if (queryParams.isNotEmpty) {
      fullUrl += '?${queryParams.join('&')}';
    }

    debugPrint('🔌 Conectando STOMP via Tor Relay: $fullUrl');

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
          if (authToken == null) {
            debugPrint(
              '⚠️ AuthToken is null. Authorization header will not be sent.',
            );
          } else {
            debugPrint(
              '✅ AuthToken is present. Authorization header will be sent.',
            );
          }
        },
        onWebSocketDone: () {
          debugPrint('✅ WebSocket done');
        },
        // Native WS headers — do NOT override Host, let the HTTP stack set
        // it automatically from the URL (overriding it causes ngrok rejection).
        webSocketConnectHeaders: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',
          if (deviceHash != null) 'X-Device-Hash': deviceHash!,
        },
        // Headers especificos do frame STOMP CONNECT
        stompConnectHeaders: {
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
    debugPrint('📡 Inscrevendo-se em: /user/queue/balance');

    _stompClient?.subscribe(
      destination: '/user/queue/balance',
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

  final String? sender;
  final String? receiver;

  BalanceUpdate({
    required this.walletId,
    required this.walletName,
    required this.userId,
    required this.newBalance,
    required this.amount,
    required this.context,
    required this.timestamp,
    this.sender,
    this.receiver,
  });

  factory BalanceUpdate.fromJson(Map<String, dynamic> json) {
    final senderField = [json['sender'], json['from'], json['fromAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    final receiverField = [json['receiver'], json['to'], json['toAddress']]
        .map((e) => e?.toString())
        .firstWhere((e) => e != null && e.isNotEmpty, orElse: () => null);

    return BalanceUpdate(
      walletId: (json['walletId'] as num?)?.toInt() ?? 0,
      walletName: json['walletName']?.toString() ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      newBalance: (json['newBalance'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      context:
          json['context']?.toString() ?? json['description']?.toString() ?? '',
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      sender: senderField,
      receiver: receiverField,
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
