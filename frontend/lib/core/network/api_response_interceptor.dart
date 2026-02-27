import 'dart:convert';
import 'package:dio/dio.dart';

class ApiResponseInterceptor extends Interceptor {
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
          final String errMsg = data['message'] ?? 'API Error';
          final String errCode = data['errorCode'] ?? 'UNKNOWN_ERROR';

          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: {
              'message': errMsg,
              'errorCode': errCode,
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
