import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/core/network/api_client_route_policy.dart';

void main() {
  group('ApiClient.shouldUseSocksProxy', () {
    test('uses Tor automatically for onion endpoints when Tor is running', () {
      final shouldProxy = ApiClient.shouldUseSocksProxy(
        baseUrl: 'http://examplehiddenservice.onion',
        routePolicy: ApiClientRoutePolicy.auto,
        torRunning: true,
      );

      expect(shouldProxy, isTrue);
    });

    test('keeps external https endpoints on clearnet in auto mode', () {
      final shouldProxy = ApiClient.shouldUseSocksProxy(
        baseUrl: 'https://mempool.space/api',
        routePolicy: ApiClientRoutePolicy.auto,
        torRunning: true,
      );

      expect(shouldProxy, isFalse);
    });

    test('honors explicit clearnet routing for external market endpoints', () {
      final shouldProxy = ApiClient.shouldUseSocksProxy(
        baseUrl: 'https://api.binance.com',
        routePolicy: ApiClientRoutePolicy.clearnet,
        torRunning: true,
      );

      expect(shouldProxy, isFalse);
    });

    test('does not wrap the local relay in an extra SOCKS proxy', () {
      final shouldProxy = ApiClient.shouldUseSocksProxy(
        baseUrl: 'http://127.0.0.1:43123',
        routePolicy: ApiClientRoutePolicy.tor,
        torRunning: true,
      );

      expect(shouldProxy, isFalse);
    });
  });

  group('ApiClient route sync', () {
    test('updates Dio baseUrl when Tor bootstrap resolves a local relay', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final clientProvider = Provider<ApiClient>(
        (ref) => ApiClient(
          baseUrl: 'http://examplehiddenservice.onion',
          ref: ref,
          routePolicy: ApiClientRoutePolicy.tor,
        ),
      );
      final client = container.read(clientProvider);

      client.syncBaseUrlForResolvedRoute('http://127.0.0.1:43123');

      expect(client.dio.options.baseUrl, 'http://127.0.0.1:43123');
    });
  });

  group('ApiClient retry policy', () {
    test('does not retry passkey onboarding finish', () {
      final shouldRetry = ApiClient.shouldRetryRequest(
        method: 'POST',
        path: '/auth/passkey/onboarding/finish',
        data: const {
          'signature': 'sig',
          'authData': 'auth',
          'clientDataJSON': 'client',
        },
      );

      expect(shouldRetry, isFalse);
    });

    test('allows retry for passkey onboarding start', () {
      final shouldRetry = ApiClient.shouldRetryRequest(
        method: 'POST',
        path: '/auth/passkey/onboarding/start',
      );

      expect(shouldRetry, isTrue);
    });

    test('does not retry absolute passkey verify URLs', () {
      final shouldRetry = ApiClient.shouldRetryRequest(
        method: 'POST',
        path: 'http://127.0.0.1:43123/auth/passkey/verify?username=ana',
        data: const {
          'signature': 'sig',
          'authData': 'auth',
          'clientDataJSON': 'client',
        },
      );

      expect(shouldRetry, isFalse);
    });

    test('does not retry transaction requests carrying passkey assertions', () {
      final shouldRetry = ApiClient.shouldRetryRequest(
        method: 'POST',
        path: '/kfe/transactions',
        data: const {
          'amountSats': 10,
          'passkeyAssertionJson': '{"signature":"sig"}',
        },
      );

      expect(shouldRetry, isFalse);
    });

    test('allows retry for ordinary transient POST requests', () {
      final shouldRetry = ApiClient.shouldRetryRequest(
        method: 'POST',
        path: '/kfe/wallets',
        data: const {'name': 'ACCOUNT 02'},
      );

      expect(shouldRetry, isTrue);
    });
  });
}
