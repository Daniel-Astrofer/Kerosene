import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/network/api_client.dart';
import 'package:kerosene/core/network/api_response_interceptor.dart';

void main() {
  group('ApiResponseInterceptor correlation IDs', () {
    test('generates X-Correlation-Id when request does not provide one', () {
      final headers = <String, dynamic>{};

      ApiResponseInterceptor.ensureCorrelationId(headers);

      expect(headers[ApiResponseInterceptor.correlationIdHeader], isNotEmpty);
    });

    test('preserves caller-provided X-Correlation-Id', () {
      final headers = <String, dynamic>{
        ApiResponseInterceptor.correlationIdHeader: 'caller-correlation-123',
      };

      ApiResponseInterceptor.ensureCorrelationId(headers);

      expect(
        headers[ApiResponseInterceptor.correlationIdHeader],
        'caller-correlation-123',
      );
    });
  });

  group('ApiClient trace IDs', () {
    test('stores backend traceId from error body in ServerException', () {
      final request = RequestOptions(path: '/kfe/wallets');
      final response = Response(
        requestOptions: request,
        statusCode: 500,
        data: const {
          'success': false,
          'message': 'Internal Server Error',
          'errorCode': 'SYS_INTERNAL_ERROR',
          'traceId': 'trace-body-123',
        },
      );

      final exception = ApiClient.exceptionFromBadResponse(
        DioException(
          requestOptions: request,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );

      expect(exception, isA<ServerException>());
      expect(exception.traceId, 'trace-body-123');
      expect(exception.toString(), contains('"traceId":"trace-body-123"'));
    });

    test(
      'falls back to X-Correlation-Id header when body traceId is absent',
      () {
        final request = RequestOptions(path: '/auth/login');
        final response = Response(
          requestOptions: request,
          statusCode: 403,
          headers: Headers.fromMap({
            ApiResponseInterceptor.correlationIdHeader: ['corr-header-456'],
          }),
          data: const {
            'success': false,
            'message': 'Forbidden',
            'errorCode': 'ERR_AUTH_FORBIDDEN',
          },
        );

        final exception = ApiClient.exceptionFromBadResponse(
          DioException(
            requestOptions: request,
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );

        expect(exception, isA<AuthException>());
        expect(exception.traceId, 'corr-header-456');
      },
    );

    test(
      'stores traceId from explicit API failure maps in ValidationException',
      () {
        final request = RequestOptions(path: '/kfe/transactions');
        final response = Response(
          requestOptions: request,
          statusCode: 409,
          data: const {
            'success': false,
            'message': 'Conflict',
            'errorCode': 'ERR_CONFLICT',
            'traceId': 'trace-validation-789',
          },
        );

        final exception = ApiClient.exceptionFromBadResponse(
          DioException(
            requestOptions: request,
            response: response,
            type: DioExceptionType.badResponse,
            error: const {
              'message': 'Conflict',
              'errorCode': 'ERR_CONFLICT',
              'traceId': 'trace-validation-789',
            },
          ),
        );

        expect(exception, isA<ValidationException>());
        expect(exception.traceId, 'trace-validation-789');
      },
    );
  });
}
