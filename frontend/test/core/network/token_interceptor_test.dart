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

  group('TokenInterceptor.shouldInvalidateSessionForError', () {
    test('keeps session for KFE transaction authorization failures', () {
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 401,
          path: '/kfe/transactions',
          errorCode: 'AUTH_023',
          responseDataText: 'PIN do aplicativo obrigatorio',
          requestHadAuthorizationHeader: true,
        ),
        isFalse,
      );
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 403,
          path: '/kfe/transactions/review',
          errorCode: 'AUTH_019',
          responseDataText: 'PIN invalido',
          requestHadAuthorizationHeader: true,
        ),
        isFalse,
      );
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 428,
          path: '/kfe/transactions/authorize',
          errorCode: 'AUTH_012',
          responseDataText: 'PASSKEY_CHALLENGE_REQUIRED:abc123',
          requestHadAuthorizationHeader: true,
        ),
        isFalse,
      );
    });

    test('does not invalidate the session when the request had no token', () {
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 401,
          path: '/kfe/dashboard',
          errorCode: 'AUTH_013',
          responseDataText: 'Authentication is required',
          requestHadAuthorizationHeader: false,
        ),
        isFalse,
      );
    });

    test('invalidates confirmed session failures outside transaction step-up',
        () {
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 401,
          path: '/me',
          errorCode: 'AUTH_013',
          responseDataText: 'Session expired',
          requestHadAuthorizationHeader: true,
        ),
        isTrue,
      );
      expect(
        TokenInterceptor.shouldInvalidateSessionForError(
          statusCode: 403,
          path: '/kfe/dashboard',
          errorCode: 'ERR_AUTH_REVOKED',
          responseDataText: 'JWT rejected',
          requestHadAuthorizationHeader: true,
        ),
        isTrue,
      );
    });
  });
}
