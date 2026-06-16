import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:kerosene/core/logging/app_log.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/network/api_response_interceptor.dart';
import 'package:kerosene/core/network/api_client_route_policy.dart';
import 'package:kerosene/core/network/api_client_platform.dart' as platform;
import 'package:kerosene/core/utils/snackbar_helper.dart';

/// Cliente HTTP configurado com Dio
class ApiClient {
  static const int _paranoidMaxPayloadBytes = 2048;
  static const int _psbtMaxPayloadBytes = 64 * 1024;
  late final Dio _dio;
  Dio get dio => _dio; // Added for TokenInterceptor retry logic
  final Ref ref; // Add Ref to access providers

  final ApiClientRoutePolicy routePolicy;

  ApiClient({
    required String baseUrl,
    required this.ref,
    this.routePolicy = ApiClientRoutePolicy.auto,
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

    _configureProxyRouting();

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
          appLog('[Retry] $firstLine');
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

    // Cache Interceptor for Network Caching (Phase 5)
    _dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          policy: CachePolicy.request,
          hitCacheOnErrorExcept: [401, 403],
          maxStale: const Duration(minutes: 5),
          priority: CachePriority.normal,
          cipher: null,
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: false,
        ),
      ),
    );

    _initCookieManager();
  }

  Future<void> _initCookieManager() async {
    await platform.initializeCookieSupport(_dio);
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
      await _prepareRequestRoute();
      final mergedOptions = _mergeOptions(options, headers);
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
      ref.read(networkStatusProvider.notifier).markOnline();
      return response;
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
      _validatePayloadSize(path, data);
      await _prepareRequestRoute();
      final mergedOptions = _mergeOptions(options, headers);
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
      ref.read(networkStatusProvider.notifier).markOnline();
      return response;
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
      _validatePayloadSize(path, data);
      await _prepareRequestRoute();
      final mergedOptions = _mergeOptions(options, headers);
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
      ref.read(networkStatusProvider.notifier).markOnline();
      return response;
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
      _validatePayloadSize(path, data);
      await _prepareRequestRoute();
      final mergedOptions = _mergeOptions(options, headers);
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: mergedOptions,
      );
      ref.read(networkStatusProvider.notifier).markOnline();
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> _prepareRequestRoute() async {
    await platform.ensureNetworkReady(
      ref: ref,
      routePolicy: routePolicy,
      baseUrl: _dio.options.baseUrl,
    );
    _configureProxyRouting();
  }

  /// Mesclar options com headers customizados
  Options _mergeOptions(Options? options, Map<String, String>? headers) {
    if (headers == null) return options ?? Options();

    final currentHeaders = Map<String, dynamic>.from(options?.headers ?? {});
    currentHeaders.addAll(headers);

    return (options ?? Options()).copyWith(headers: currentHeaders);
  }

  void _validatePayloadSize(String path, dynamic data) {
    if (data == null) {
      return;
    }

    List<int>? payloadBytes;

    if (data is String) {
      payloadBytes = utf8.encode(data);
    } else if (data is List<int>) {
      payloadBytes = data;
    } else if (data is Map || data is List) {
      payloadBytes = utf8.encode(jsonEncode(data));
    }

    if (payloadBytes == null ||
        payloadBytes.length <= _maxPayloadBytesForPath(path)) {
      return;
    }

    const message =
        'O conteúdo é grande demais para enviar com segurança. Reduza as informações e tente novamente.';
    SnackbarHelper.showWarning(message, title: 'Conteúdo muito grande');
    throw const ValidationException(
      message: message,
      errorCode: 'ERR_PAYLOAD_TOO_LARGE',
    );
  }

  int _maxPayloadBytesForPath(String path) {
    if (path.startsWith('/bitcoin/psbt/') ||
        (path.contains('/cold-wallets/') && path.endsWith('/psbt'))) {
      return _psbtMaxPayloadBytes;
    }
    return _paranoidMaxPayloadBytes;
  }

  @visibleForTesting
  static bool shouldUseSocksProxy({
    required String baseUrl,
    required ApiClientRoutePolicy routePolicy,
    required bool torRunning,
  }) {
    final normalizedBaseUrl = baseUrl.toLowerCase();
    final isLocalRelay = normalizedBaseUrl.contains('127.0.0.1') ||
        normalizedBaseUrl.contains('localhost');

    if (isLocalRelay || !torRunning) {
      return false;
    }

    switch (routePolicy) {
      case ApiClientRoutePolicy.tor:
        return true;
      case ApiClientRoutePolicy.clearnet:
        return false;
      case ApiClientRoutePolicy.auto:
        return normalizedBaseUrl.contains('.onion');
    }
  }

  // Headers are now managed exclusively by TokenInterceptor

  /// Tratamento de erros
  AppException _handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      if (error.response != null) {
        ref.read(networkStatusProvider.notifier).markOnline();
      }

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
          var message = 'Não conseguimos concluir a solicitação agora.';
          String? errorCode;
          Object? errorData;

          final data = error.response?.data;
          if (data is Map) {
            if (data.containsKey('message')) message = data['message'];
            if (data.containsKey('errorCode')) errorCode = data['errorCode'];
            if (data.containsKey('data')) errorData = data['data'];
          } else if (data is String) {
            try {
              final json = jsonDecode(data);
              if (json is Map) {
                if (json.containsKey('message')) message = json['message'];
                if (json.containsKey('errorCode')) {
                  errorCode = json['errorCode'];
                }
                if (json.containsKey('data')) {
                  errorData = json['data'];
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
              if (errMap.containsKey('data')) {
                errorData = errMap['data'];
              }
            }
          }

          if (statusCode == 401 || statusCode == 403) {
            return AuthException(
              message: message,
              statusCode: statusCode,
              errorCode: errorCode,
              data: errorData,
            );
          }

          if (statusCode != null && statusCode >= 500) {
            return ServerException(
              message: message,
              statusCode: statusCode,
              errorCode: errorCode,
              data: errorData,
            );
          }

          return ValidationException(
            message: message,
            statusCode: statusCode,
            errorCode: errorCode,
            data: errorData,
          );

        default:
          final statusCode = error.response?.statusCode;
          final errorStr = error.error?.toString();
          return AppException(
            message: error.message ??
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
    appLog('[${options.method}] ${options.baseUrl}${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLog('[${response.statusCode}] ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode ?? '?';
    final path = err.requestOptions.path;
    final errCode = err.response?.data is Map
        ? (err.response!.data['errorCode'] ?? '')
        : '';
    appLog('[$code] $path${errCode.isNotEmpty ? ' ($errCode)' : ''}');
    super.onError(err, handler);
  }
}

extension ApiClientProxy on ApiClient {
  void _configureProxyRouting() {
    platform.configureProxyRouting(
      dio: _dio,
      ref: ref,
      routePolicy: routePolicy,
      baseUrl: _dio.options.baseUrl,
      shouldUseSocksProxy: ApiClient.shouldUseSocksProxy,
    );
  }
}
