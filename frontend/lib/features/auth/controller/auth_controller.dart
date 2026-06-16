import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/signup_usecase.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/datasources/auth_remote_datasource.dart' show LoginResult;
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
  final PasskeyService passkeyService = PasskeyService.instance;
  Timer? _onboardingPollTimer;
  bool _isPollingOnboarding = false;
  bool _isCompletingOnboarding = false;
  static const int _maxTransparentChallengeRenewals = 2;
  static final RegExp _passkeyErrorCodePattern = RegExp(
    r'(ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS|ERR_AUTH_PASSKEY_AUTH_CANCELLED|ERR_AUTH_PASSKEY_NOT_REGISTERED|ERR_AUTH_PASSKEY_CORRUPTED_KEY_MATERIAL)',
  );
  static final RegExp _hexChallengePattern = RegExp(r'^[0-9a-fA-F]{64}$');

  AuthError _mapFailureToAuthError(Failure failure) {
    return AuthError(
      failure.message,
      statusCode: failure.statusCode,
      errorCode: failure.errorCode,
      data: failure.data,
    );
  }

  AuthError _mapPasskeyExceptionToAuthError(
    Object error, {
    required String fallbackMessage,
  }) {
    final raw = error.toString().trim();
    final knownCode = _passkeyErrorCodePattern.firstMatch(raw);

    if (knownCode != null) {
      return AuthError(
        raw,
        errorCode: knownCode.group(1),
      );
    }

    return AuthError('$fallbackMessage: $raw');
  }

  bool _isPasskeyChallengeExpired(Failure failure) {
    final code = failure.errorCode ?? '';
    return code == 'CHALLENGE_EXPIRED' || code == 'AUTH_012';
  }

  @override
  AuthState build() {
    loginUseCase = ref.watch(loginUseCaseProvider);
    signupUseCase = ref.watch(signupUseCaseProvider);
    authRepository = ref.watch(authRepositoryProvider);
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
    String? username,
    String? password,
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
    String? username,
    String? password,
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
      case 'VERIFYING_ACTIVATION':
      case 'verifying_activation':
        return 'Depósito localizado. Agora faltam confirmações na rede para liberar o recebimento.';
      case 'completed':
        return 'Depósito confirmado. Sua conta agora pode receber fundos.';
      case 'expired':
        return 'O endereço de depósito expirou. Gere um novo depósito para continuar.';
      default:
        return 'Para receber fundos dentro da plataforma, deposite algum valor primeiro.';
    }
  }

  Future<void> _pollOnboardingPaymentStatus({
    required String linkId,
    String? username,
    String? password,
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

    try {
      _isPollingOnboarding = true;
      final result = await authRepository.getActivationStatus();

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
        (status) {
          final latestState = state;
          if (latestState is! AuthPaymentRequired ||
              latestState.paymentLinkId != linkId) {
            _stopOnboardingPolling();
            return;
          }

          state = latestState.copyWith(
            amountBtc: status.amountBtc > 0
                ? status.amountBtc
                : latestState.amountBtc,
            depositAddress: status.depositAddress.isNotEmpty
                ? status.depositAddress
                : latestState.depositAddress,
            paymentStatus: status.paymentStatus.isNotEmpty
                ? status.paymentStatus
                : latestState.paymentStatus,
            statusMessage: status.warningMessage.isNotEmpty
                ? status.warningMessage
                : _statusMessageForPaymentStatus(status.paymentStatus),
            isSubmitting: false,
            clearError: true,
          );

          if (status.activated) {
            _completeOnboardingAndLogin(
              username: username,
              password: password,
            );
          } else if (status.paymentStatus == 'expired') {
            _stopOnboardingPolling();
          }
        },
      );
    } catch (error) {
      final latestState = state;
      if (latestState is AuthPaymentRequired &&
          latestState.paymentLinkId == linkId) {
        state = latestState.copyWith(
          isSubmitting: false,
          errorMessage: 'Erro inesperado: $error',
        );
      }
    } finally {
      _isPollingOnboarding = false;
    }
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
    try {
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
    } catch (e) {
      state = AuthError('Erro inesperado: $e');
    }
  }

  Future<void> signup({
    required String username,
    required String password,
    String accountSecurity = 'STANDARD',
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    try {
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
          sessionId: signupResult.sessionId,
          totpSecret: signupResult.totpSecret,
          qrCodeUri: signupResult.qrCodeUri,
          backupCodes: signupResult.backupCodes,
          totpOptional: signupResult.totpOptional,
        ),
      );
    } catch (e) {
      state = AuthError('Erro inesperado: $e');
    }
  }

  Future<void> verifyTotp({
    required String username,
    required String passphrase,
    required String totpSecret,
    required String totpCode,
  }) async {
    final currentState = state;
    if (currentState is! AuthRequiresTotpSetup) {
      state = const AuthError(
        'Sessão de cadastro inválida. Reinicie a criação da conta.',
      );
      return;
    }

    state = const AuthLoading();
    final result = await authRepository.verifyTotp(
      sessionId: currentState.sessionId,
      totpCode: totpCode,
    );

    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (sessionId) => state = AuthTotpVerified(sessionId, username),
    );
  }

  Future<void> skipTotpSetup() async {
    final currentState = state;
    if (currentState is! AuthRequiresTotpSetup) {
      state = const AuthError(
        'Sessão de cadastro inválida. Reinicie a criação da conta.',
      );
      return;
    }

    if (!currentState.totpOptional) {
      state = const AuthError(
        'TOTP é obrigatório para este perfil de segurança.',
      );
      return;
    }

    state = AuthTotpVerified(currentState.sessionId, currentState.username);
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
      unawaited(_syncBackgroundAlertsService());
    });
  }

  Future<void> logout() async {
    _stopOnboardingPolling();
    try {
      state = const AuthLoading();
      await authRepository.logout();
      await stopBackgroundService();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Erro ao sair: $e');
    }
  }

  void markSessionInvalidated() {
    _stopOnboardingPolling();
    state = const AuthUnauthenticated();
    unawaited(stopBackgroundService());
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

  Future<void> loginWithPasskey(
    String username, {
    int remainingChallengeRenewals = _maxTransparentChallengeRenewals,
  }) async {
    username = username.trim();
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

          await finishResult.fold(
            (failure) async {
              final renewedChallenge = _extractPasskeyChallenge(failure);
              if (renewedChallenge == null) {
                if (_isPasskeyChallengeExpired(failure) &&
                    remainingChallengeRenewals > 0) {
                  await loginWithPasskey(
                    username,
                    remainingChallengeRenewals: remainingChallengeRenewals - 1,
                  );
                  return;
                }
                state = _mapFailureToAuthError(failure);
                return;
              }

              final renewedCredential = await passkeyService.authenticate(
                challengeHex: renewedChallenge,
                username: username,
              );
              final renewedFinish = await authRepository.passkeyLoginFinish(
                username: username,
                credential: renewedCredential,
              );
              await renewedFinish.fold(
                (secondFailure) async {
                  if (_isPasskeyChallengeExpired(secondFailure) &&
                      remainingChallengeRenewals > 0) {
                    await loginWithPasskey(
                      username,
                      remainingChallengeRenewals:
                          remainingChallengeRenewals - 1,
                    );
                    return;
                  }
                  state = _mapFailureToAuthError(secondFailure);
                },
                (loginResult) async =>
                    _completePasskeyLogin(username, loginResult),
              );
            },
            (loginResult) async => _completePasskeyLogin(username, loginResult),
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

  void _completePasskeyLogin(String username, LoginResult loginResult) {
    if (loginResult.requiresTotp) {
      state = AuthRequiresLoginTotp(
        username: username,
        passphrase: '',
        preAuthToken: loginResult.jwt,
      );
    } else {
      _checkAuthStatus();
    }
  }

  String? _extractPasskeyChallenge(Failure failure) {
    final challenge = _extractChallengeFromValue(failure.data);
    if (challenge != null) {
      return challenge;
    }

    const marker = 'PASSKEY_CHALLENGE_REQUIRED:';
    final markerIndex = failure.message.indexOf(marker);
    if (markerIndex < 0) {
      return null;
    }
    final value = failure.message.substring(markerIndex + marker.length).trim();
    return _hexChallengePattern.hasMatch(value) ? value : null;
  }

  String? _extractChallengeFromValue(Object? value) {
    if (value is Map) {
      final direct = value['challenge']?.toString().trim();
      if (direct != null && _hexChallengePattern.hasMatch(direct)) {
        return direct;
      }
      return _extractChallengeFromValue(value['data']);
    }
    return null;
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
              debugPrint('Passkey registered successfully.');
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

          await finishResult.fold(
            (failure) async {
              state = _mapFailureToAuthError(failure);
            },
            (_) async {
              AudioService.instance.playTransaction();
              await _checkAuthStatus();
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

  Future<void> _loadActivationDepositState({
    required String sessionId,
  }) async {
    final result = await authRepository.getActivationStatus();
    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (status) {
        state = AuthPaymentRequired(
          sessionId: sessionId,
          paymentLinkId: status.paymentLinkId,
          amountBtc: status.amountBtc,
          depositAddress: status.depositAddress,
          paymentStatus: status.paymentStatus.isNotEmpty
              ? status.paymentStatus
              : 'pending',
          statusMessage: status.warningMessage.isNotEmpty
              ? status.warningMessage
              : _statusMessageForPaymentStatus(status.paymentStatus),
        );

        if (status.paymentLinkId.isNotEmpty) {
          _startOnboardingPolling(linkId: status.paymentLinkId);
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
    try {
      state = const AuthLoading();
      await _loadActivationDepositState(sessionId: sessionId);
    } catch (e) {
      state = AuthError('Erro inesperado: $e');
    }
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

    try {
      state = currentState.copyWith(
        isSubmitting: true,
        statusMessage: 'Atualizando o status do depósito de ativação...',
        clearError: true,
      );

      final result = await authRepository.getActivationStatus();

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
        (status) {
          final latestState = state;
          if (latestState is! AuthPaymentRequired) {
            return;
          }

          state = latestState.copyWith(
            paymentStatus: status.paymentStatus.isNotEmpty
                ? status.paymentStatus
                : latestState.paymentStatus,
            statusMessage: status.warningMessage.isNotEmpty
                ? status.warningMessage
                : _statusMessageForPaymentStatus(status.paymentStatus),
            isSubmitting: false,
            errorMessage: status.activated
                ? null
                : 'A confirmação manual por TXID foi descontinuada. Faça o depósito pelo fluxo de recebimento do app e aguarde o monitoramento automático.',
            clearError: status.activated,
          );

          if (status.activated) {
            _completeOnboardingAndLogin(
              username: username,
              password: password,
            );
            return;
          }

          if (status.paymentStatus == 'expired') {
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
    } catch (e) {
      if (state is AuthPaymentRequired) {
        state = (state as AuthPaymentRequired).copyWith(
          isSubmitting: false,
          errorMessage: 'Erro inesperado: $e',
        );
      } else {
        state = AuthError('Erro inesperado: $e');
      }
    }
  }

  Future<void> continueAfterOnboardingPayment({
    String? username,
    String? password,
  }) async {
    _stopOnboardingPolling();
    final result = await authRepository.getActivationStatus();
    result.fold(
      (failure) => state = _mapFailureToAuthError(failure),
      (status) {
        if (status.activated) {
          unawaited(_checkAuthStatus());
          return;
        }

        final currentState = state;
        if (currentState is AuthPaymentRequired) {
          state = currentState.copyWith(
            paymentStatus: status.paymentStatus,
            statusMessage: status.warningMessage.isNotEmpty
                ? status.warningMessage
                : _statusMessageForPaymentStatus(status.paymentStatus),
            amountBtc: status.amountBtc > 0
                ? status.amountBtc
                : currentState.amountBtc,
            depositAddress: status.depositAddress.isNotEmpty
                ? status.depositAddress
                : currentState.depositAddress,
            clearError: true,
          );
        }
      },
    );
  }
}

/// Provider to expose the controller to the UI.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
