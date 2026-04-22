import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/signup_usecase.dart';
import '../domain/repositories/auth_repository.dart';
import '../../notifications/application/notification_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/passkey_service.dart';
import '../../../core/errors/failures.dart';
import '../../../core/providers/alert_preferences_provider.dart';
import '../presentation/state/auth_state.dart';
import 'auth_providers.dart';

export '../presentation/state/auth_state.dart';

/// @nodoc
/// Role: AI-Native Controller for Authentication feature.
/// Responsibility: Orchestrates the state of authentication using the original logic but with Notifier (v3).
class AuthController extends Notifier<AuthState> {
  late LoginUseCase loginUseCase;
  late SignupUseCase signupUseCase;
  late AuthRepository authRepository;
  late NotificationService notificationService;
  final PasskeyService passkeyService = PasskeyService.instance;
  Timer? _onboardingPollTimer;
  bool _isPollingOnboarding = false;
  bool _isCompletingOnboarding = false;

  AuthError _mapFailureToAuthError(Failure failure) {
    return AuthError(
      failure.message,
      statusCode: failure.statusCode,
      errorCode: failure.errorCode,
    );
  }

  AuthError _mapPasskeyExceptionToAuthError(
    Object error, {
    required String fallbackMessage,
  }) {
    final raw = error.toString().trim();
    final knownCode = RegExp(
      r'(ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS|ERR_AUTH_PASSKEY_AUTH_CANCELLED)',
    ).firstMatch(raw);

    if (knownCode != null) {
      return AuthError(
        raw,
        errorCode: knownCode.group(1),
      );
    }

    return AuthError('$fallbackMessage: $raw');
  }

  @override
  AuthState build() {
    loginUseCase = ref.watch(loginUseCaseProvider);
    signupUseCase = ref.watch(signupUseCaseProvider);
    authRepository = ref.watch(authRepositoryProvider);
    notificationService = ref.watch(notificationServiceProvider);
    ref.onDispose(_stopOnboardingPolling);

    _checkAuthStatus();
    return const AuthInitial();
  }

  void _stopOnboardingPolling() {
    _onboardingPollTimer?.cancel();
    _onboardingPollTimer = null;
    _isPollingOnboarding = false;
  }

  Future<void> _syncBackgroundAlertsService() async {
    final backgroundAlertsEnabled = await loadBackgroundAlertsEnabled();
    if (backgroundAlertsEnabled) {
      await startBackgroundService();
      return;
    }
    await stopBackgroundService();
  }

  void _startOnboardingPolling({
    required String linkId,
    required String username,
    required String password,
  }) {
    _stopOnboardingPolling();
    _onboardingPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_pollOnboardingPaymentStatus(
        linkId: linkId,
        username: username,
        password: password,
      ));
    });
  }

  void _completeOnboardingAndLogin({
    required String username,
    required String password,
  }) {
    if (_isCompletingOnboarding) {
      return;
    }

    _isCompletingOnboarding = true;
    _stopOnboardingPolling();
    unawaited(
      continueAfterOnboardingPayment(
        username: username,
        password: password,
      ).whenComplete(() {
        _isCompletingOnboarding = false;
      }),
    );
  }

  String _statusMessageForPaymentStatus(String status) {
    switch (status) {
      case 'verifying_onboarding':
        return 'Pagamento localizado. Agora faltam 3 confirmações na rede para ativar sua conta.';
      case 'completed':
        return 'Pagamento confirmado. Finalizando sua conta...';
      case 'expired':
        return 'O link de pagamento expirou. Gere um novo para continuar.';
      case 'paid':
        return 'Pagamento identificado. Aguardando a liberação final.';
      default:
        return 'O link público continua em polling. Envie o valor exato e cole o TXID quando sua wallet mostrar a transação.';
    }
  }

  Future<void> _pollOnboardingPaymentStatus({
    required String linkId,
    required String username,
    required String password,
  }) async {
    if (_isPollingOnboarding) {
      return;
    }

    final currentState = state;
    if (currentState is! AuthPaymentRequired ||
        currentState.paymentLinkId != linkId) {
      _stopOnboardingPolling();
      return;
    }

    _isPollingOnboarding = true;
    final result = await authRepository.getOnboardingPaymentLink(linkId);
    _isPollingOnboarding = false;

    result.fold(
      (failure) {
        final latestState = state;
        if (latestState is AuthPaymentRequired &&
            latestState.paymentLinkId == linkId) {
          state = latestState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          );
        }
      },
      (linkDto) {
        final latestState = state;
        if (latestState is! AuthPaymentRequired ||
            latestState.paymentLinkId != linkId) {
          _stopOnboardingPolling();
          return;
        }

        state = latestState.copyWith(
          amountBtc: linkDto.amountBtc,
          depositAddress: linkDto.depositAddress,
          paymentStatus: linkDto.status,
          statusMessage: _statusMessageForPaymentStatus(linkDto.status),
          isSubmitting: false,
          clearError: true,
        );

        if (linkDto.status == 'completed') {
          _completeOnboardingAndLogin(
            username: username,
            password: password,
          );
        } else if (linkDto.status == 'expired') {
          _stopOnboardingPolling();
        }
      },
    );
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final result = await authRepository.getCurrentUser();
        result.fold(
          (failure) {
            if (failure is AuthFailure) {
              // Token actually expired or invalid
              state = const AuthUnauthenticated();
            } else {
              // Server is down or no network, preserve session visually and show unavailable
              state = AuthServerUnavailable(failure.message);
            }
          },
          (user) {
            state = AuthAuthenticated(user);
            notificationService.initializeAndRegister();
            unawaited(_syncBackgroundAlertsService());
          },
        );
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthServerUnavailable(e.toString());
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _stopOnboardingPolling();
    state = const AuthLoading();
    final result = await loginUseCase(
      LoginParams(username: username, passphrase: password),
    );

    result.fold(
      (failure) async {
        AudioService.instance.playError();
        await authRepository.clearInvalidSession();
        state = _mapFailureToAuthError(failure);
      },
      (loginResult) {
        if (loginResult.requiresTotp) {
          state = AuthRequiresLoginTotp(
            username: username,
            passphrase: password,
            preAuthToken: loginResult.jwt,
          );
        } else {
          _checkAuthStatus();
        }
      },
    );
  }

  Future<void> signup({
    required String username,
    required String password,
    String accountSecurity = 'STANDARD',
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    state = const AuthLoading();
    final result = await signupUseCase(
      SignupParams(
        username: username,
        passphrase: password,
        accountSecurity: accountSecurity,
        shamirTotalShares: shamirTotalShares,
        shamirThreshold: shamirThreshold,
        multisigThreshold: multisigThreshold,
      ),
    );

    result.fold(
      (failure) {
        AudioService.instance.playError();
        state = _mapFailureToAuthError(failure);
      },
      (signupResult) => state = AuthRequiresTotpSetup(
        username: username,
        passphrase: password,
        totpSecret: signupResult.totpSecret,
        qrCodeUri: signupResult.qrCodeUri,
        backupCodes: signupResult.backupCodes,
      ),
    );
  }

  Future<void> verifyTotp({
    required String username,
    required String passphrase,
    required String totpSecret,
    required String totpCode,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.verifyTotp(
      username: username,
      passphrase: passphrase,
      totpCode: totpCode,
      totpSecret: totpSecret,
    );

    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (sessionId) => state = AuthTotpVerified(sessionId, username),
    );
  }

  Future<void> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
    String? preAuthToken,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.verifyLoginTotp(
      username: username,
      passphrase: passphrase,
      totpCode: totpCode,
      preAuthToken: preAuthToken,
    );

    result.fold((failure) => state = _mapFailureToAuthError(failure), (user) {
      state = AuthAuthenticated(user);
      notificationService.initializeAndRegister();
      unawaited(_syncBackgroundAlertsService());
    });
  }

  Future<void> logout() async {
    _stopOnboardingPolling();
    state = const AuthLoading();
    await authRepository.logout();
    state = const AuthUnauthenticated();
    stopBackgroundService();
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> retrySessionCheck() async {
    state = const AuthLoading();
    await _checkAuthStatus();
  }

  Future<void> loginWithPasskey(String username) async {
    if (username.isEmpty) {
      state = const AuthError(
          'Por favor, insira o usuário para entrar com Passkey');
      return;
    }
    state = const AuthLoading();

    // 1. Get challenge from backend
    final startResult = await authRepository.passkeyLoginStart(username);

    await startResult.fold(
      (failure) async {
        state = _mapFailureToAuthError(failure);
      },
      (challengeHex) async {
        try {
          // 2. Sign challenge with device key (biometric-gated)
          final credential = await passkeyService.authenticate(
            challengeHex: challengeHex,
            username: username,
          );

          // 3. Finish login with backend (credential already has the right structure)
          final finishResult = await authRepository.passkeyLoginFinish(
            username: username,
            credential: credential,
          );

          finishResult.fold(
            (failure) => state = _mapFailureToAuthError(failure),
            (loginResult) {
              if (loginResult.requiresTotp) {
                state = AuthRequiresLoginTotp(
                  username: username,
                  passphrase: '',
                  preAuthToken: loginResult.jwt,
                );
              } else {
                _checkAuthStatus();
              }
            },
          );
        } catch (e) {
          state = _mapPasskeyExceptionToAuthError(
            e,
            fallbackMessage: 'Erro na autenticação via passkey',
          );
        }
      },
    );
  }

  Future<void> registerPasskey() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) {
      state = const AuthError(
          'Você precisa estar logado para registrar uma passkey');
      return;
    }

    final username = currentState.user.name;
    state = const AuthLoading();

    // 1. Get challenge from backend
    final startResult = await authRepository.passkeyRegisterStart(username);

    await startResult.fold(
      (failure) async {
        state = _mapFailureToAuthError(failure);
      },
      (challengeHex) async {
        try {
          // 2. Register passkey (generates key pair + signs challenge with biometric)
          final credential = await passkeyService.register(
            challengeHex: challengeHex,
            username: username,
          );

          // 3. Finish registration with backend
          final finishResult =
              await authRepository.passkeyRegisterFinish(credential);

          await finishResult.fold(
            (failure) async {
              state = _mapFailureToAuthError(failure);
            },
            (_) async {
              final refreshedUser = await authRepository.getCurrentUser();
              refreshedUser.fold(
                (_) => state = AuthAuthenticated(currentState.user),
                (user) => state = AuthAuthenticated(user),
              );
              debugPrint(
                '🔐 Passkey registered successfully for ${currentState.user.name}',
              );
            },
          );
        } catch (e) {
          state = _mapPasskeyExceptionToAuthError(
            e,
            fallbackMessage: 'Erro no registro de passkey',
          );
        }
      },
    );
  }

  Future<void> registerPasskeyOnboarding(String sessionId) async {
    final currentState = state;
    String? username;
    if (currentState is AuthTotpVerified) {
      username = currentState.username;
    }

    state = const AuthLoading();

    // 1. Get challenge from backend
    final result = await authRepository.passkeyRegisterOnboardingStart(
      sessionId: sessionId,
      username: username,
    );

    await result.fold(
      (failure) async {
        state = _mapFailureToAuthError(failure);
      },
      (challengeHex) async {
        try {
          final effectiveUsername =
              username ?? 'User_${sessionId.substring(0, 4)}';

          // 2. Register passkey (generates key pair + signs challenge with biometric)
          final credential = await passkeyService.register(
            challengeHex: challengeHex,
            username: effectiveUsername,
          );

          // 3. Finish registration with backend
          final finishResult =
              await authRepository.passkeyRegisterOnboardingFinish(
            sessionId,
            credential,
          );

          finishResult.fold(
            (failure) => state = _mapFailureToAuthError(failure),
            (_) {
              AudioService.instance.playTransaction();
              state = const AuthHardwareVerified();
            },
          );
        } catch (e) {
          state = _mapPasskeyExceptionToAuthError(
            e,
            fallbackMessage: 'Erro no registro de passkey',
          );
        }
      },
    );
  }

  Future<void> getOnboardingLink({
    required String sessionId,
    required String username,
    required String password,
  }) async {
    _stopOnboardingPolling();
    state = const AuthLoading();
    final result = await authRepository.generateOnboardingLink(sessionId);
    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (linkDto) {
        state = AuthPaymentRequired(
          sessionId: sessionId,
          paymentLinkId: linkDto.linkId,
          amountBtc: linkDto.amountBtc,
          depositAddress: linkDto.depositAddress,
          paymentStatus: linkDto.status,
          statusMessage: _statusMessageForPaymentStatus(linkDto.status),
        );

        _startOnboardingPolling(
          linkId: linkDto.linkId,
          username: username,
          password: password,
        );
      },
    );
  }

  Future<void> submitOnboardingPayment({
    required String linkId,
    required String txid,
    required String username,
    required String password,
  }) async {
    final currentState = state;
    if (currentState is! AuthPaymentRequired) {
      return;
    }

    final cleanTxid = txid.trim();
    if (cleanTxid.isEmpty) {
      state = currentState.copyWith(
        errorMessage: 'Cole o TXID da transação on-chain para continuar.',
      );
      return;
    }

    state = currentState.copyWith(
      isSubmitting: true,
      submittedTxid: cleanTxid,
      statusMessage: 'Validando a transação na rede Bitcoin...',
      clearError: true,
    );

    final result = await authRepository.confirmOnboardingPayment(
      linkId: linkId,
      txid: cleanTxid,
    );

    result.fold(
      (failure) {
        final latestState = state;
        if (latestState is AuthPaymentRequired) {
          state = latestState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          );
        } else {
          state = _mapFailureToAuthError(failure);
        }
      },
      (linkDto) {
        final latestState = state;
        if (latestState is! AuthPaymentRequired) {
          return;
        }

        state = latestState.copyWith(
          paymentStatus: linkDto.status,
          submittedTxid: cleanTxid,
          statusMessage: _statusMessageForPaymentStatus(linkDto.status),
          isSubmitting: false,
          clearError: true,
        );

        if (linkDto.status == 'completed') {
          _completeOnboardingAndLogin(
            username: username,
            password: password,
          );
          return;
        }

        if (linkDto.status == 'expired') {
          _stopOnboardingPolling();
          return;
        }

        _startOnboardingPolling(
          linkId: linkId,
          username: username,
          password: password,
        );
        unawaited(_pollOnboardingPaymentStatus(
          linkId: linkId,
          username: username,
          password: password,
        ));
      },
    );
  }

  Future<void> continueAfterOnboardingPayment({
    required String username,
    required String password,
  }) async {
    await login(username: username, password: password);
  }

  Future<void> mockConfirmOnboarding({
    required String sessionId,
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.mockConfirmOnboarding(sessionId);

    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (_) => login(username: username, password: password),
    );
  }
}

/// Provider to expose the controller to the UI.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
