import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/services/balance_websocket_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

void main() {
  group('BalanceWebSocketReconnectPolicy', () {
    test('caps reconnect attempts and clamps delay', () {
      final policy = BalanceWebSocketReconnectPolicy(
        maxAttempts: 3,
        baseDelay: const Duration(seconds: 5),
        maxDelay: const Duration(seconds: 12),
      );

      expect(policy.nextDelay(), const Duration(seconds: 5));
      expect(policy.nextDelay(), const Duration(seconds: 10));
      expect(policy.nextDelay(), const Duration(seconds: 12));
      expect(policy.nextDelay(), isNull);
      expect(policy.attemptCount, 3);

      policy.reset();

      expect(policy.attemptCount, 0);
      expect(policy.nextDelay(), const Duration(seconds: 5));
    });
  });

  group('BalanceWebSocketService', () {
    test('does not open socket when session credential is missing', () async {
      var invalidated = false;
      var createdClients = 0;
      final service = BalanceWebSocketService(
        baseUrl: 'http://127.0.0.1:30080',
        userId: '1',
        authToken: null,
        onBalanceUpdate: (_) {},
        onSessionInvalidated: () => invalidated = true,
        stompClientFactory: (config) {
          createdClients += 1;
          return _FakeStompClient(config);
        },
      );

      await service.connect();

      expect(createdClients, 0);
      expect(invalidated, isTrue);
      expect(service.stoppedReconnecting, isTrue);
    });

    test('disables STOMP automatic reconnect for app-owned retry policy',
        () async {
      StompConfig? capturedConfig;
      _FakeStompClient? client;
      final service = BalanceWebSocketService(
        baseUrl: 'http://127.0.0.1:30080',
        userId: '1',
        authToken: 'jwt-token',
        deviceHash: 'device-hash',
        onBalanceUpdate: (_) {},
        stompClientFactory: (config) {
          capturedConfig = config;
          client = _FakeStompClient(config);
          return client!;
        },
      );

      await service.connect();

      expect(client?.activated, isTrue);
      expect(capturedConfig?.reconnectDelay, Duration.zero);
      expect(
        capturedConfig?.webSocketConnectHeaders?['Authorization'],
        'Bearer jwt-token',
      );
      expect(
        capturedConfig?.webSocketConnectHeaders?['X-Device-Hash'],
        'device-hash',
      );
      expect(
        capturedConfig?.stompConnectHeaders?['Authorization'],
        'Bearer jwt-token',
      );
    });

    test('recognizes explicit session failure signals', () {
      expect(
        BalanceWebSocketService.isSessionFailureSignal(
          'HTTP 401 Unauthorized',
        ),
        isTrue,
      );
      expect(
        BalanceWebSocketService.isSessionFailureSignal('token expired'),
        isTrue,
      );
      expect(
        BalanceWebSocketService.isSessionFailureSignal('connection refused'),
        isFalse,
      );
    });
  });
}

class _FakeStompClient extends StompClient {
  _FakeStompClient(StompConfig config) : super(config: config);

  bool activated = false;
  bool deactivated = false;

  @override
  bool get isActive => activated && !deactivated;

  @override
  void activate() {
    activated = true;
  }

  @override
  void deactivate() {
    deactivated = true;
  }
}
