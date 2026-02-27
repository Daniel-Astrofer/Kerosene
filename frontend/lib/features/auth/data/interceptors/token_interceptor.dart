import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../datasources/auth_local_datasource.dart';

class TokenInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  TokenInterceptor({required this.localDataSource, required this.apiClient});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final path = options.path;
      final isAuthRoute =
          path.contains('/auth/login') || path.contains('/auth/signup');

      // 1. Injetar Token se não for rota de Auth e se não estiver presente
      if (!isAuthRoute && options.headers['Authorization'] == null) {
        final token = await localDataSource.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }

      // 2. Injetar X-Device-Hash - OBRIGATÓRIO EM TODAS
      final deviceHash = await DeviceHelper.getDeviceHash();
      options.headers[AppConfig.deviceHashHeader] = deviceHash;

      // 3. Mask the Host header to trick Spring Boot into accepting the relayed TCP HTTP request
      options.headers['Host'] = Uri.parse(AppConfig.onionBaseUrl).host;

      // 4. Log Crítico para Depuração do 403
      final authHeader = options.headers['Authorization'];
      debugPrint('🌐 [API REQ] ${options.method} => ${options.path}');
      debugPrint(
        '🔑 Auth: ${authHeader != null ? 'Bearer ...${authHeader.toString().split('.').last.substring(0, 5)}' : 'NONE'}',
      );
      debugPrint('📱 Hash: $deviceHash');
    } catch (e) {
      debugPrint('⚠️ Error in Interceptor: $e');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final newToken = response.headers.value(AppConfig.newTokenHeader);

    if (newToken != null && newToken.isNotEmpty) {
      debugPrint('🔄 JWT Renewal: Novo token recebido no header');

      var cleanToken = newToken.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }

      // Salvar localmente
      await localDataSource.saveToken(cleanToken);
      // O ApiClient buscará o novo token via interceptor na próxima chamada
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 = invalid/expired token. Wipe it so it's never sent again.
    if (err.response?.statusCode == 401) {
      debugPrint('🔑 TokenInterceptor: 401 received — clearing invalid token.');
      try {
        await localDataSource.removeToken();
        await localDataSource.removeUser();
      } catch (_) {}
    }
    return handler.next(err);
  }
}
