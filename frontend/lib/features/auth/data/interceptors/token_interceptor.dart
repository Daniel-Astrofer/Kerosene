import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../datasources/auth_local_datasource.dart';

class TokenInterceptor extends QueuedInterceptor {
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  /// Guard para evitar múltiplos redirects simultâneos (caso várias requests
  /// falhem com 500/401 ao mesmo tempo)
  bool _redirecting = false;

  TokenInterceptor({required this.localDataSource, required this.apiClient});

  @override
  Future<void> onRequest(
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

      // 2. Mask the Host header para o Spring Boot aceitar o request via relay TCP
      options.headers['Host'] = Uri.parse(AppConfig.onionBaseUrl).host;
    } catch (e) {
      debugPrint('⚠️ TokenInterceptor error: $e');
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final newToken = response.headers.value(AppConfig.newTokenHeader);

    if (newToken != null && newToken.isNotEmpty) {
      debugPrint('🔄 JWT Renewal: novo token recebido');
      var cleanToken = newToken.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }
      await localDataSource.saveToken(cleanToken);
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final errorCode = err.response?.data is Map
        ? (err.response!.data['errorCode'] as String? ?? '')
        : '';

    // Detecta sessão inválida:
    // • 401 — token expirado, ausente ou rejeitado pelo servidor.
    // • 403 com ERR_AUTH_* — ex: token revogado explicitamente.
    //
    // NÃO limpamos sessão em 500: esses erros são falhas do servidor
    // (bugs, DB indisponível, etc.) e não indicam que o JWT é inválido.
    // Tratar 500 como sessão inválida derrubava o usuário por erros temporários.
    final isInvalidSession =
        statusCode == 401 ||
        (statusCode == 403 &&
            (errorCode.startsWith('ERR_AUTH_') ||
                errorCode == 'ERR_AUTH_UNRECOGNIZED_DEVICE'));

    if (isInvalidSession && !_redirecting) {
      _redirecting = true;
      debugPrint(
        '🔑 Sessão inválida [$statusCode/$errorCode] — limpando sessão e redirecionando para /welcome',
      );

      // 1. Limpar toda a sessão local
      try {
        await localDataSource.clearAll();
      } catch (_) {}

      // 2. Agendar navegação no próximo frame UI via SchedulerBinding.
      //    É a única forma segura de navegar a partir de um interceptor assíncrono:
      //    garante que o widget tree acabou de renderizar antes de chamar o navigator.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _redirecting = false; // reset para próxima sessão
        final navigator = SnackbarHelper.navigatorKey.currentState;
        if (navigator == null) {
          debugPrint(
            '⚠️ navigatorKey.currentState é null — tentando de novo no próximo frame.',
          );
          // Tentar novamente no próximo frame (pode acontecer durante splash)
          SchedulerBinding.instance.addPostFrameCallback((_) {
            SnackbarHelper.navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/welcome',
              (route) => false,
            );
          });
          return;
        }

        // Remove toda a stack e vai para /welcome
        navigator.pushNamedAndRemoveUntil('/welcome', (route) => false);

        // Snackbar informativo após a navegação
        SchedulerBinding.instance.addPostFrameCallback((_) {
          SnackbarHelper.scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text(
                'Sua sessão expirou. Por favor, faça login novamente.',
              ),
              backgroundColor: Color(0xFFD32F2F),
              duration: Duration(seconds: 4),
            ),
          );
        });
      });

      return; // Não propagar o erro — a navegação foi agendada
    }

    handler.next(err);
  }
}
