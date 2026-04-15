import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/network/api_client.dart';

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
}
