import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/auth/data/interceptors/token_interceptor.dart';

void main() {
  group('TokenInterceptor.shouldOverrideHostForOnionRelay', () {
    test('does not override Host in Flutter Web', () {
      expect(
        TokenInterceptor.shouldOverrideHostForOnionRelay(
          isWeb: true,
          baseUrl: 'http://127.0.0.1:43123',
          onionBaseUrl: 'http://abc123.onion',
        ),
        isFalse,
      );
    });

    test('overrides Host only for local relay to onion on non-web clients', () {
      expect(
        TokenInterceptor.shouldOverrideHostForOnionRelay(
          isWeb: false,
          baseUrl: 'http://127.0.0.1:43123',
          onionBaseUrl: 'http://abc123.onion',
        ),
        isTrue,
      );
    });

    test('keeps direct non-local API requests untouched', () {
      expect(
        TokenInterceptor.shouldOverrideHostForOnionRelay(
          isWeb: false,
          baseUrl: 'https://api.kerosene.example',
          onionBaseUrl: 'http://abc123.onion',
        ),
        isFalse,
      );
    });
  });

  group('TokenInterceptor.isKfeTransactionStepUpPath', () {
    test('matches active KFE transaction paths', () {
      expect(
        TokenInterceptor.isKfeTransactionStepUpPath('/kfe/transactions'),
        isTrue,
      );
      expect(
        TokenInterceptor.isKfeTransactionStepUpPath(
          '/api/admin/kfe/transactions/review',
        ),
        isTrue,
      );
    });

    test('does not match legacy generic transaction paths', () {
      expect(
        TokenInterceptor.isKfeTransactionStepUpPath('/transactions/123'),
        isFalse,
      );
      expect(
        TokenInterceptor.isKfeTransactionStepUpPath(
          '/transactions/visualization/blockchain',
        ),
        isFalse,
      );
    });
  });
}
