import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Cliente HTTP configurado com Dio
class ApiClient {
  late final Dio _dio;

  ApiClient({
    required String baseUrl,
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Adicionar interceptors
    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// Adicionar um interceptor customizado
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.insert(
      0,
      interceptor,
    ); // Insert at beginning to run before others
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, headers);
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, headers);
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, headers);
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
  }) async {
    try {
      final mergedOptions = _mergeOptions(options, headers);
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mesclar options com headers customizados
  Options _mergeOptions(Options? options, Map<String, String>? headers) {
    if (headers == null) return options ?? Options();

    final currentHeaders = Map<String, dynamic>.from(options?.headers ?? {});
    currentHeaders.addAll(headers);

    return (options ?? Options()).copyWith(headers: currentHeaders);
  }

  /// Adicionar token de autenticação
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remover token de autenticação
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Tratamento de erros
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException(message: 'Tempo de conexão esgotado');

        case DioExceptionType.connectionError:
          return const NetworkException();

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          var message = 'Erro no servidor';

          final data = error.response?.data;
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          } else if (data is String) {
            try {
              // Tenta parsear caso seja um JSON válido em string
              // import 'dart:convert'; (precisamos garantir esse import)
              // Mas como não temos import fácil aqui, vamos assumir que se for string, é a mensagem
              // ou tentar parsear de forma simples se possível.
              // Melhor: se for string, usa ela (truncada se necessário)
              message = data.length > 100 ? data.substring(0, 100) : data;
            } catch (_) {}
          }

          if (statusCode == 401 || statusCode == 403) {
            return AuthException(message: message, statusCode: statusCode);
          }

          if (statusCode != null && statusCode >= 500) {
            return ServerException(message: message, statusCode: statusCode);
          }

          return ValidationException(message: message, statusCode: statusCode);

        default:
          return AppException(message: error.message ?? 'Erro desconhecido');
      }
    }

    return AppException(message: error.toString());
  }
}

/// Interceptor para logging
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    print('📨 HEADERS: ${options.headers}');
    print('📦 BODY: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    print('📝 MESSAGE: ${err.message}');
    print('📌 TYPE: ${err.type}');
    if (err.response?.data != null) {
      print('📦 DATA: ${err.response?.data}');
    }
    if (err.error != null) {
      print('⚠️ ERR: ${err.error}');
    }
    super.onError(err, handler);
  }
}

/// Interceptor para tratamento de erros
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Aqui você pode adicionar lógica customizada de tratamento de erros
    // Por exemplo: refresh token, retry logic, etc.
    super.onError(err, handler);
  }
}
