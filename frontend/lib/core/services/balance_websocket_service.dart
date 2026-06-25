import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

typedef BalanceStompClientFactory = StompClient Function(StompConfig config);

class BalanceWebSocketReconnectPolicy {
  BalanceWebSocketReconnectPolicy({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 1),
  })  : assert(maxAttempts >= 0),
        assert(baseDelay >= Duration.zero),
        assert(maxDelay >= Duration.zero);

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  int _attemptCount = 0;

  int get attemptCount => _attemptCount;

  Duration? nextDelay() {
    if (_attemptCount >= maxAttempts) {
      return null;
    }

    final multiplier = 1 << _attemptCount;
    final delay = Duration(
      milliseconds: baseDelay.inMilliseconds * multiplier,
    );
    _attemptCount += 1;

    return delay > maxDelay ? maxDelay : delay;
  }

  void reset() {
    _attemptCount = 0;
  }
}

/// Serviço para WebSocket de atualizações de saldo em tempo real
class BalanceWebSocketService {
  StompClient? _stompClient;
  final String baseUrl;
  final String userId;
  final String? authToken;
  final String? deviceHash;
  final Function(BalanceUpdate) onBalanceUpdate;
  final Function(RealtimeNotificationEvent)? onNotification;
  final VoidCallback? onSessionInvalidated;
  final BalanceWebSocketReconnectPolicy _reconnectPolicy;
  final BalanceStompClientFactory _stompClientFactory;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _manualDisconnect = false;
  bool _sessionInvalidated = false;
  bool _reconnectExhausted = false;

  BalanceWebSocketService({
    required this.baseUrl,
    required this.userId,
    this.authToken,
    this.deviceHash,
    required this.onBalanceUpdate,
    this.onNotification,
    this.onSessionInvalidated,
    BalanceWebSocketReconnectPolicy? reconnectPolicy,
    BalanceStompClientFactory? stompClientFactory,
  })  : _reconnectPolicy = reconnectPolicy ?? BalanceWebSocketReconnectPolicy(),
        _stompClientFactory =
            stompClientFactory ?? ((config) => StompClient(config: config));

  bool get isConnected => _isConnected;
  bool get stoppedReconnecting => _sessionInvalidated || _reconnectExhausted;

  /// Conecta ao WebSocket do backend via ponte local SOCKS5 (Tor)
  Future<void> connect() async {
    if (_sessionInvalidated) {
      debugPrint('BalanceWebSocketService: session already invalidated.');
      return;
    }

    if (_stompClient != null && (_isConnected || _stompClient!.isActive)) {
      debugPrint('BalanceWebSocketService: already connected.');
      return;
    }

    _manualDisconnect = false;
    _reconnectExhausted = false;
    _reconnectPolicy.reset();
    await _connectOnce();
  }

  Future<void> _connectOnce() async {
    if (_manualDisconnect || _sessionInvalidated) {
      return;
    }

    final token = _normalizedAuthToken;
    if (token == null) {
      _stopForInvalidSession('session credential missing');
      return;
    }

    final fullUrl = '$baseUrl/ws/balance';

    debugPrint('BalanceWebSocketService: connecting.');

    _stompClient = _stompClientFactory(
      StompConfig.sockJS(
          url: fullUrl,
          onConnect: _onConnect,
          onWebSocketError: _handleWebSocketError,
          onStompError: _handleStompError,
          onDisconnect: (_) {
            debugPrint('BalanceWebSocketService: disconnected.');
            _handleConnectionClosed('stomp disconnect');
          },
          beforeConnect: () async {
            debugPrint('BalanceWebSocketService: starting handshake.');
            debugPrint(
              'BalanceWebSocketService: session credential available.',
            );
          },
          onWebSocketDone: () {
            debugPrint('BalanceWebSocketService: socket closed.');
            _handleConnectionClosed('socket closed');
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
            if (deviceHash != null) 'X-Device-Hash': deviceHash!,
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          reconnectDelay: Duration.zero,
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10)),
    );

    _stompClient?.activate();
  }

  /// Callback quando conectado ao WebSocket
  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectPolicy.reset();
    debugPrint('BalanceWebSocketService: connected.');
    debugPrint('BalanceWebSocketService: subscribing to balance feed.');

    _stompClient?.subscribe(
      destination: '/user/queue/balance',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!);
            final update = BalanceUpdate.fromJson(json);

            debugPrint('BalanceWebSocketService: balance event decoded.');
            onBalanceUpdate(update);
          } catch (_) {
            debugPrint('BalanceWebSocketService: balance event rejected.');
          }
        }
      },
    );

    _stompClient?.subscribe(
      destination: '/user/queue/notifications',
      callback: (StompFrame frame) {
        if (frame.body == null) {
          return;
        }

        try {
          final json = jsonDecode(frame.body!);
          if (json is Map<String, dynamic>) {
            onNotification?.call(RealtimeNotificationEvent.fromJson(json));
          } else if (json is Map) {
            onNotification?.call(
              RealtimeNotificationEvent.fromJson(
                Map<String, dynamic>.from(json),
              ),
            );
          }
        } catch (_) {
          debugPrint('BalanceWebSocketService: notification event rejected.');
        }
      },
    );

    debugPrint('BalanceWebSocketService: subscriptions ready.');
  }

  /// Desconecta do WebSocket
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectPolicy.reset();

    if (_stompClient == null) {
      _isConnected = false;
      return;
    }

    debugPrint('BalanceWebSocketService: disconnecting.');
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
  }

  void _handleWebSocketError(dynamic error) {
    debugPrint('BalanceWebSocketService: socket error.');
    _isConnected = false;

    if (isSessionFailureSignal(error)) {
      _stopForInvalidSession('socket rejected session');
      return;
    }

    _scheduleReconnect('socket error');
  }

  void _handleStompError(StompFrame frame) {
    debugPrint('BalanceWebSocketService: protocol error.');
    _isConnected = false;

    if (isSessionFailureSignal(frame.body) ||
        isSessionFailureSignal(frame.command) ||
        frame.headers.values.any(isSessionFailureSignal)) {
      _stopForInvalidSession('protocol rejected session');
      return;
    }

    _scheduleReconnect('protocol error');
  }

  void _handleConnectionClosed(String reason) {
    _isConnected = false;
    _scheduleReconnect(reason);
  }

  void _scheduleReconnect(String reason) {
    if (_manualDisconnect || _sessionInvalidated || _reconnectExhausted) {
      return;
    }
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    final token = _normalizedAuthToken;
    if (token == null) {
      _stopForInvalidSession('session credential missing');
      return;
    }

    final delay = _reconnectPolicy.nextDelay();
    if (delay == null) {
      _reconnectExhausted = true;
      _closeCurrentClient();
      debugPrint(
        'BalanceWebSocketService: max reconnect attempts reached after '
        '$reason. Stopping.',
      );
      return;
    }

    debugPrint(
      'BalanceWebSocketService: reconnecting in ${delay.inSeconds}s '
      'after $reason (attempt ${_reconnectPolicy.attemptCount}/'
      '${_reconnectPolicy.maxAttempts}).',
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_manualDisconnect && !_sessionInvalidated && !_reconnectExhausted) {
        unawaited(_connectOnce());
      }
    });
    _closeCurrentClient();
  }

  void _stopForInvalidSession(String reason) {
    if (_sessionInvalidated) {
      return;
    }

    _sessionInvalidated = true;
    _manualDisconnect = true;
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeCurrentClient();
    debugPrint('BalanceWebSocketService: $reason. Stopping reconnects.');
    onSessionInvalidated?.call();
  }

  void _closeCurrentClient() {
    final client = _stompClient;
    _stompClient = null;
    client?.deactivate();
  }

  String? get _normalizedAuthToken {
    final token = authToken?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  @visibleForTesting
  static bool isSessionFailureSignal(Object? value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.isEmpty) {
      return false;
    }

    return text.contains('401') ||
        text.contains('403') ||
        text.contains('unauthor') ||
        text.contains('forbidden') ||
        text.contains('authentication') ||
        text.contains('invalid session') ||
        text.contains('session invalid') ||
        text.contains('session expired') ||
        text.contains('invalid token') ||
        text.contains('token expired') ||
        text.contains('jwt expired') ||
        text.contains('jwt invalid');
  }
}

class RealtimeNotificationEvent {
  final String id;
  final String kind;
  final String severity;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? deeplink;
  final String? entityType;
  final String? entityId;
  final Map<String, String> metadata;

  RealtimeNotificationEvent({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.body,
    required this.timestamp,
    this.deeplink,
    this.entityType,
    this.entityId,
    this.metadata = const {},
  });

  factory RealtimeNotificationEvent.fromJson(Map<String, dynamic> json) {
    final rawTimestamp =
        json['createdAt']?.toString() ?? json['timestamp']?.toString();
    final parsedTimestamp = DateTime.tryParse(rawTimestamp ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(rawTimestamp ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
        );
    final normalizedTitle = _normalizeText(
      json['title']?.toString(),
      fallback: 'Atualização',
    );
    final normalizedBody = _normalizeText(json['body']?.toString());
    final inferredKind = _normalizeKind(
      json['kind']?.toString(),
      title: normalizedTitle,
      body: normalizedBody,
    );
    final inferredSeverity = _normalizeSeverity(
      json['severity']?.toString(),
      kind: inferredKind,
      title: normalizedTitle,
      body: normalizedBody,
    );
    final metadata = _normalizeMetadata(json['metadata']);
    final id = _normalizeNullableText(json['id']?.toString()) ??
        '${parsedTimestamp.millisecondsSinceEpoch}|$inferredKind|$normalizedTitle|$normalizedBody';

    return RealtimeNotificationEvent(
      id: id,
      kind: inferredKind,
      severity: inferredSeverity,
      title: normalizedTitle,
      body: normalizedBody,
      timestamp: parsedTimestamp.toLocal(),
      deeplink: _normalizeNullableText(json['deeplink']?.toString()),
      entityType: _normalizeNullableText(json['entityType']?.toString()),
      entityId: _normalizeNullableText(json['entityId']?.toString()),
      metadata: metadata,
    );
  }

  int get systemNotificationId => id.hashCode & 0x7fffffff;

  static String _normalizeKind(
    String? rawValue, {
    required String title,
    required String body,
  }) {
    final normalized = _normalizeNullableText(rawValue)?.toLowerCase();
    if (normalized != null) {
      return normalized;
    }

    final combined = '$title $body'.toLowerCase();
    if (combined.contains('acesso detectado') ||
        combined.contains('login') ||
        combined.contains('sess')) {
      return 'security_login_detected';
    }
    if (combined.contains('recovery')) {
      return 'security_recovery_completed';
    }
    if (combined.contains('conta criada') ||
        combined.contains('account created')) {
      return 'account_created';
    }
    if (combined.contains('solicitação de pagamento') ||
        combined.contains('solicitacao de pagamento')) {
      return combined.contains('liquidada')
          ? 'payment_request_paid'
          : 'payment_request_created';
    }
    if (combined.contains('depósito identificado') ||
        combined.contains('deposito identificado')) {
      return 'deposit_detected';
    }
    if (combined.contains('depósito confirmado') ||
        combined.contains('deposito confirmado')) {
      return 'deposit_confirmed';
    }
    if (combined.contains('transferência recebida') ||
        combined.contains('transferencia recebida')) {
      return 'transfer_received';
    }
    if (combined.contains('transferência enviada') ||
        combined.contains('transferencia enviada')) {
      return 'transfer_sent';
    }
    if (combined.contains('transação transmitida') ||
        combined.contains('transacao transmitida') ||
        combined.contains('pagamento')) {
      return 'payment_sent';
    }
    return 'system_info';
  }

  static String _normalizeSeverity(
    String? rawValue, {
    required String kind,
    required String title,
    required String body,
  }) {
    final normalized = _normalizeNullableText(rawValue)?.toLowerCase();
    if (normalized == 'success' ||
        normalized == 'warning' ||
        normalized == 'error' ||
        normalized == 'info') {
      return normalized!;
    }

    switch (kind) {
      case 'security_login_detected':
      case 'security_recovery_completed':
        return 'warning';
      case 'account_created':
      case 'transfer_received':
      case 'payment_request_paid':
      case 'deposit_confirmed':
        return 'success';
      case 'payment_request_created':
      case 'deposit_detected':
      case 'transfer_sent':
      case 'payment_sent':
        return 'info';
      default:
        final combined = '$title $body'.toLowerCase();
        if (combined.contains('erro') ||
            combined.contains('error') ||
            combined.contains('failed')) {
          return 'error';
        }
        if (combined.contains('confirmad') ||
            combined.contains('criada') ||
            combined.contains('created') ||
            combined.contains('sucesso')) {
          return 'success';
        }
        return 'info';
    }
  }

  static Map<String, String> _normalizeMetadata(Object? rawMetadata) {
    if (rawMetadata is! Map) {
      return const {};
    }

    final normalized = <String, String>{};
    rawMetadata.forEach((key, value) {
      final normalizedKey = _normalizeNullableText(key?.toString());
      final normalizedValue = _normalizeNullableText(value?.toString());
      if (normalizedKey != null && normalizedValue != null) {
        normalized[normalizedKey] = normalizedValue;
      }
    });
    return normalized;
  }

  static String _normalizeText(String? rawValue, {String fallback = ''}) {
    if (rawValue == null) {
      return fallback;
    }

    final collapsed = rawValue.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) {
      return fallback;
    }
    return collapsed;
  }

  static String? _normalizeNullableText(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final collapsed = rawValue.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.isEmpty ? null : collapsed;
  }
}

/// Modelo de atualização de saldo recebida via WebSocket
class BalanceUpdate {
  final String walletId;
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
      walletId: (json['walletId'] ?? '').toString(),
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
