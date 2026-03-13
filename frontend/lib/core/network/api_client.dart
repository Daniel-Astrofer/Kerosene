import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/network_status_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import '../errors/exceptions.dart';
import 'api_response_interceptor.dart';

/// Cliente HTTP configurado com Dio
class ApiClient {
  late final Dio _dio;
  final Ref ref; // Add Ref to access providers

  ApiClient({
    required String baseUrl,
    required this.ref,
    int connectTimeout = 60000,
    int receiveTimeout = 60000,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Adicionar interceptors
    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(ApiResponseInterceptor());

    // Retry Interceptor for Network Resilience (Phase 5)
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (msg) {
          // Print only the first line of retry messages to avoid multi-line noise
          final firstLine = msg.split('\n').first;
          debugPrint('[Retry] $firstLine');
        },
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: DefaultRetryEvaluator({
          408, // RequestTimeout
          // 500 removido — server 500 não se recupera com retry
          502, // BadGateway
          503, // ServiceUnavailable
          504, // GatewayTimeout
          440, // LoginTimeout
          522, // ConnectionTimedOut
          524, // ATimeoutOccurred
          598, // NetworkReadTimeoutError
          599, // NetworkConnectTimeoutError
        }).evaluate,
      ),
    );

    _initCookieManager();
  }

  Future<void> _initCookieManager() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage("${appDocDir.path}/.cookies/"),
    );
    _dio.interceptors.add(CookieManager(cookieJar));
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

  // Headers are now managed exclusively by TokenInterceptor

  /// Tratamento de erros
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          ref.read(networkStatusProvider.notifier).reportError(error);
          return const NetworkException(message: 'Tempo de conexão esgotado');

        case DioExceptionType.connectionError:
          ref.read(networkStatusProvider.notifier).reportError(error);
          return const NetworkException();

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          var message = 'Erro no servidor';
          String? errorCode;

          final data = error.response?.data;
          if (data is Map) {
            if (data.containsKey('message')) message = data['message'];
            if (data.containsKey('errorCode')) errorCode = data['errorCode'];
          } else if (data is String) {
            try {
              final json = jsonDecode(data);
              if (json is Map) {
                if (json.containsKey('message')) message = json['message'];
                if (json.containsKey('errorCode')) {
                  errorCode = json['errorCode'];
                }
              } else {
                message = data.length > 100 ? data.substring(0, 100) : data;
              }
            } catch (_) {
              message = data.length > 100 ? data.substring(0, 100) : data;
            }
          } else if (error.error != null) {
            if (error.error is String) {
              message = error.error as String;
            } else if (error.error is Map) {
              final errMap = error.error as Map;
              if (errMap.containsKey('message')) {
                message = errMap['message'];
              }
              if (errMap.containsKey('errorCode')) {
                errorCode = errMap['errorCode'];
              }
            }
          }

          if (statusCode == 401 || statusCode == 403) {
            return AuthException(
              message: message,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          }

          if (statusCode != null && statusCode >= 500) {
            return ServerException(
              message: message,
              statusCode: statusCode,
              errorCode: errorCode,
            );
          }

          return ValidationException(
            message: message,
            statusCode: statusCode,
            errorCode: errorCode,
          );

        default:
          final statusCode = error.response?.statusCode;
          final errorStr = error.error?.toString();
          return AppException(
            message:
                error.message ??
                errorStr ??
                'Erro desconhecido (HTTP $statusCode)',
            statusCode: statusCode,
          );
      }
    }

    return AppException(message: error.toString());
  }
}

/// Interceptor para logging — conciso e sem dados sensíveis
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 [${options.method}] ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ [${response.statusCode}] ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode ?? '?';
    final path = err.requestOptions.path;
    final errCode = err.response?.data is Map
        ? (err.response!.data['errorCode'] ?? '')
        : '';
    debugPrint('❌ [$code] $path${errCode.isNotEmpty ? ' ($errCode)' : ''}');
    super.onError(err, handler);
  }
}
