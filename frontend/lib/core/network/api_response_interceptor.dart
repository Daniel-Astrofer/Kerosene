import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';

class ApiResponseInterceptor extends Interceptor {
  static const String correlationIdHeader = 'X-Correlation-Id';
  static final Random _random = Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    ensureCorrelationId(options.headers);
    super.onRequest(options, handler);
  }

  static void ensureCorrelationId(Map<String, dynamic> headers) {
    final existingHeader = headers.keys.any(
      (key) => key.toLowerCase() == correlationIdHeader.toLowerCase(),
    );
    if (existingHeader) {
      return;
    }
    headers[correlationIdHeader] = generateCorrelationId();
  }

  static String? extractTraceId(Response? response, [Object? error]) {
    final bodyTraceId =
        _traceIdFromBody(response?.data) ?? _traceIdFromBody(error);
    if (bodyTraceId != null) {
      return bodyTraceId;
    }
    return response?.headers.value(correlationIdHeader);
  }

  static String generateCorrelationId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(
      12,
      (_) => _random.nextInt(36).toRadixString(36),
    ).join();
    return 'app-$timestamp-$suffix';
  }

  static String? _traceIdFromBody(Object? data) {
    final parsed = _parseJsonObject(data);
    final value = parsed?['traceId'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static Map<dynamic, dynamic>? _parseJsonObject(Object? data) {
    if (data is Map) {
      return data;
    }
    if (data is String) {
      final trimmed = data.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return null;
      }
      try {
        final decoded = jsonDecode(trimmed);
        return decoded is Map ? decoded : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dynamic data = response.data;

    // Parse stringified JSON if needed
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          data = jsonDecode(trimmed);
        } catch (_) {}
      }
    }

    if (data is Map<String, dynamic>) {
      // Check for standardized ApiResponse payload
      if (data.containsKey('success')) {
        final success = data['success'] == true;

        if (success) {
          // Successfully obtained wrapper. Unwrap 'data' unconditionally avoiding defensive nulls checking.
          response.data = data.containsKey('data') ? data['data'] : null;
        } else {
          // Explicit API failure payload (e.g., success: false)
          final String errMsg =
              data['message'] ?? 'Não conseguimos concluir agora.';
          final String errCode = data['errorCode'] ?? 'UNKNOWN_ERROR';

          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: {
              'message': errMsg,
              'errorCode': errCode,
              'traceId': extractTraceId(response, data),
              'data': data['data'],
            }, // Pass as Map so ApiClient catches it cleanly
          );
        }
      }
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.data is Map<String, dynamic>) {
      final String code = err.response?.data['errorCode'] ?? 'UNKNOWN_ERROR';

      // Handle specific codes if necessary
      if (code == 'ERR_AUTH_UNRECOGNIZED_DEVICE') {
        // O Navigator seria chamado aqui. Nós idealmente faremos isso através do NavigationService
        // Ou deixaremos as views que chamam lidarem com a exceção se capturarem Exception específica.
      }
    }
    super.onError(err, handler);
  }
}
