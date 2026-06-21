import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/session_invalidation_provider.dart';
import '../../../../core/utils/device_helper.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../datasources/auth_local_datasource.dart';

class TokenInterceptor extends QueuedInterceptor {
  final AuthLocalDataSource localDataSource;
  final ApiClient apiClient;

  /// Guard para evitar múltiplos redirects simultâneos (caso várias requests
  /// falhem com 500/401 ao mesmo tempo)
  bool _redirecting = false;

  TokenInterceptor({required this.localDataSource, required this.apiClient});

  @visibleForTesting
  static bool shouldOverrideHostForOnionRelay({
    required bool isWeb,
    required String baseUrl,
    required String onionBaseUrl,
  }) {
    if (isWeb) {
      return false;
    }

    final apiHost = Uri.tryParse(baseUrl)?.host.toLowerCase();
    final onionHost = Uri.tryParse(onionBaseUrl)?.host.toLowerCase();
    if (apiHost == null || onionHost == null || onionHost.isEmpty) {
      return false;
    }

    final isLocalRelay =
        apiHost == '127.0.0.1' || apiHost == 'localhost' || apiHost == '::1';
    final onionHostIsLocal = onionHost == '127.0.0.1' ||
        onionHost == 'localhost' ||
        onionHost == '::1';

    return isLocalRelay && !onionHostIsLocal;
  }

  @visibleForTesting
  static bool isKfeTransactionStepUpPath(String path) {
    final requestPath = Uri.tryParse(path)?.path ?? path;
    return _matchesPathPrefix(requestPath, '/kfe/transactions') ||
        _matchesPathPrefix(requestPath, '/api/admin/kfe/transactions');
  }

  static bool _matchesPathPrefix(String path, String prefix) {
    return path == prefix || path.startsWith('$prefix/');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final path = options.path;
      // Public auth routes must not receive an Authorization header.
      // Some flows use sessionId or username/challenge only, and injecting a
      // stale token can force an unnecessary JWT failure before auth starts.
      final isOnboardingOrAuth = path.contains('/auth/login') ||
          path.contains('/auth/signup') ||
          path.contains('/auth/recovery/emergency/') ||
          path.contains('/auth/passkey/challenge') ||
          path.contains('/auth/passkey/verify') ||
          path.contains('/auth/passkey/onboarding/') ||
          path.contains('/auth/passkey/login/') ||
          path.contains('/auth/passkey/register/onboarding') ||
          path.contains('/auth/hardware/challenge') ||
          path.contains('/auth/hardware/verify') ||
          path.contains('/auth/hardware/register/onboarding');

      // 1. Injetar Token se não for rota de Auth/Onboarding e se não estiver presente
      if (!isOnboardingOrAuth && options.headers['Authorization'] == null) {
        final token = await localDataSource.getToken();
        if (token != null && token.isNotEmpty) {
          // Double check it looks like a JWT (contains periods) to avoid "compact JWT string" errors
          if (token.contains('.')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
      }

      // 2. Mobile/desktop Tor relay only: preserve the onion Host when the app
      // sends traffic through a local 127.0.0.1 relay. Browsers forbid setting
      // Host manually, so web admin deployments must use a real .onion origin
      // or an explicit gateway origin instead.
      if (shouldOverrideHostForOnionRelay(
        isWeb: kIsWeb,
        baseUrl: apiClient.dio.options.baseUrl,
        onionBaseUrl: AppConfig.onionBaseUrl,
      )) {
        options.headers['Host'] = Uri.parse(AppConfig.onionBaseUrl).host;
      }

      if (!kIsWeb && options.headers['X-Device-Hash'] == null) {
        final deviceHash = await DeviceHelper.getDeviceHash();
        if (deviceHash.isNotEmpty) {
          options.headers['X-Device-Hash'] = deviceHash;
        }
      }
    } catch (_) {
      debugPrint(
          'TokenInterceptor: request credentials could not be prepared.');
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
      debugPrint('TokenInterceptor: session credential refreshed.');
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
    final path = err.requestOptions.path;
    final responseDataText = err.response?.data?.toString() ?? '';
    final errorCode = err.response?.data is Map
        ? (err.response!.data['errorCode'] as String? ?? '')
        : '';
    final isAuthRoute = path.contains('/auth/login') ||
        path.contains('/auth/signup') ||
        path.contains('/auth/passkey/');
    final isTransactionRoute = isKfeTransactionStepUpPath(path);
    final isTransactionFactorError = isTransactionRoute &&
        (errorCode == 'ERR_AUTH_INCORRECT_TOTP' ||
            errorCode == 'ERR_AUTH_GENERIC' ||
            responseDataText.contains('PASSKEY_CHALLENGE_REQUIRED'));
    final isExplicitInvalidSession = errorCode == 'ERR_AUTH_INVALID_SESSION' ||
        responseDataText.toLowerCase().contains('invalid session');

    // Detecta sessão inválida:
    // • 401 — token expirado, ausente ou rejeitado pelo servidor.
    // • 403 com ERR_AUTH_* — ex: token revogado explicitamente.
    //
    // NÃO limpamos sessão em 500: esses erros são falhas do servidor
    // (bugs, DB indisponível, etc.) e não indicam que o JWT é inválido.
    // Tratar 500 como sessão inválida derrubava o usuário por erros temporários.
    final isInvalidSession = isExplicitInvalidSession ||
        (!isTransactionFactorError &&
            (statusCode == 401 ||
                (statusCode == 403 &&
                    (errorCode.startsWith('ERR_AUTH_') ||
                        errorCode == 'ERR_AUTH_UNRECOGNIZED_DEVICE' ||
                        responseDataText.contains('JWT')))));

    if (isInvalidSession && !isAuthRoute && !_redirecting) {
      _redirecting = true;
      debugPrint(
        'TokenInterceptor: session invalidated [$statusCode/$errorCode].',
      );

      // 1. Limpar toda a sessão local
      try {
        await localDataSource.clearAll();
      } catch (_) {}
      try {
        apiClient.ref.read(sessionInvalidationProvider.notifier).emit();
      } catch (_) {}

      // 2. Agendar navegação no próximo frame UI via SchedulerBinding.
      //    É a única forma segura de navegar a partir de um interceptor assíncrono:
      //    garante que o widget tree acabou de renderizar antes de chamar o navigator.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _redirecting = false; // reset para próxima sessão
        final navigator = SnackbarHelper.navigatorKey.currentState;
        if (navigator == null) {
          debugPrint(
            'TokenInterceptor: navigator unavailable; retrying next frame.',
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
          final l10n = navigator.context.tr;
          SnackbarHelper.showWarning(
            l10n.errSessionExpired,
            title: l10n.sessionEndedTitle,
          );
        });
      });

      // IMPORTANTE: Devemos propagar o erro para que a fila do QueuedInterceptor não trave!
      handler.next(err);
      return;
    }

    handler.next(err);
  }
}
