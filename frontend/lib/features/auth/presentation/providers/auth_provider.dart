import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show sharedPreferencesProvider;
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/interceptors/token_interceptor.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../../../features/notifications/domain/repositories/notification_repository.dart';
import '../../../../features/notifications/application/notification_service.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/sovereign_auth_service.dart';
import '../state/auth_state.dart';

// ==================== Providers de Dependências ====================

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = AppConfig.apiUrl;
  final client = ApiClient(baseUrl: baseUrl, ref: ref);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  client.addInterceptor(
    TokenInterceptor(localDataSource: localDataSource, apiClient: client),
  );

  return client;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSourceImpl(sharedPreferences);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// ==================== Providers de UseCases ====================

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUseCase(repository);
});

// ==================== Providers de Notifications ====================

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return NotificationRemoteDataSourceImpl(apiClient);
    });

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remote = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remote);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationService(repository);
});

final sovereignAuthServiceProvider = Provider<SovereignAuthService>((ref) {
  return SovereignAuthService.instance;
});

// ==================== Provider de Estado ====================

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final AuthRepository authRepository;
  final NotificationService notificationService;
  final SovereignAuthService sovereignAuthService = SovereignAuthService.instance;

  AuthNotifier({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.authRepository,
    required this.notificationService,
    required Ref ref,
  }) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  final _authCheckCompleter = Completer<void>();
  Future<void> get authCheckCompleted => _authCheckCompleter.future;

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final result = await authRepository.getCurrentUser();
        result.fold(
          (failure) => state = const AuthUnauthenticated(),
          (user) {
            state = AuthAuthenticated(user);
            notificationService.initializeAndRegister();
            startBackgroundService();
          },
        );
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    } finally {
      if (!_authCheckCompleter.isCompleted) {
        _authCheckCompleter.complete();
      }
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await loginUseCase(
      LoginParams(username: username, passphrase: password),
    );

    result.fold(
      (failure) async {
        AudioService.instance.playError();
        await authRepository.clearInvalidSession();
        state = AuthError(failure.message);
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
    required String accountSecurity,
  }) async {
    state = const AuthLoading();
    final result = await signupUseCase(
      SignupParams(
        username: username,
        passphrase: password,
        accountSecurity: accountSecurity,
      ),
    );

    result.fold(
      (failure) {
        AudioService.instance.playError();
        state = AuthError(failure.message);
      },
      (signupResult) => state = AuthRequiresTotpSetup(
        username: username,
        passphrase: password,
        totpSecret: signupResult.totpSecret,
        qrCodeUri: signupResult.qrCodeUri,
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
      (failure) => state = AuthError(failure.message),
      (sessionId) => state = AuthTotpVerified(sessionId),
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

    result.fold((failure) => state = AuthError(failure.message), (user) {
      state = AuthAuthenticated(user);
      notificationService.initializeAndRegister();
      startBackgroundService();
    });
  }

  Future<void> logout() async {
    state = const AuthLoading();
    final result = await authRepository.logout();
    result.fold((failure) => state = AuthError(failure.message), (_) {
      state = const AuthUnauthenticated();
      stopBackgroundService();
    });
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> registerHardwareStart(String sessionId) async {
    state = const AuthLoading();
    final result = await authRepository.registerHardwareOnboardingStart(sessionId);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (challengeHex) async {
        try {
          String? publicKey = await sovereignAuthService.getPublicKey();
          publicKey ??= await sovereignAuthService.generateKeyPair();
          final signature = await sovereignAuthService.signChallenge(challengeHex);
          await registerHardwareFinish(
            sessionId: sessionId,
            publicKey: publicKey,
            deviceName: 'Smartphone',
            signature: signature,
          );
        } catch (e) {
          state = AuthError('Erro no fluxo de segurança soberana: $e');
        }
      },
    );
  }

  Future<void> registerPasskeyOnboardingStart(String sessionId) async {
    state = const AuthLoading();
    final result = await authRepository.registerPasskeyOnboardingStart(sessionId);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (optionsJson) => state = AuthPasskeyChallengeReceived(optionsJson),
    );
  }

  Future<void> registerPasskeyOnboardingFinish({
    required String sessionId,
    required Map<String, dynamic> credential,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.registerPasskeyOnboardingFinish(
      sessionId,
      credential,
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthHardwareVerified(),
    );
  }

  Future<void> registerHardwareFinish({
    required String sessionId,
    required String publicKey,
    required String deviceName,
    required String signature,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.registerHardwareOnboardingFinish(
      sessionId: sessionId,
      publicKey: publicKey,
      deviceName: deviceName,
      signature: signature,
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthHardwareVerified(),
    );
  }

  Future<void> loginWithHardware(String username) async {
    if (username.isEmpty) {
      state = const AuthError('Por favor, insira o usuário para entrar com Hardware Auth');
      return;
    }
    state = const AuthLoading();
    final result = await authRepository.hardwareLoginStart(username);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (challengeHex) async {
        try {
          final signature = await sovereignAuthService.signChallenge(challengeHex);
          final finishResult = await authRepository.hardwareLoginFinish(
            username: username,
            signature: signature,
          );
          finishResult.fold(
            (failure) => state = AuthError(failure.message),
            (user) {
              state = AuthAuthenticated(user);
              notificationService.initializeAndRegister();
              startBackgroundService();
            },
          );
        } catch (e) {
          state = AuthError('Erro na autenticação de hardware: $e');
        }
      },
    );
  }

  Future<void> registerHardwareForAccount() async {
    state = const AuthLoading();
    final result = await authRepository.registerHardwareForAccountStart();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (challenge) async {
        try {
          final publicKey = await sovereignAuthService.generateKeyPair();
          final finishResult = await authRepository.registerHardwareForAccountFinish(
            publicKey: publicKey,
            deviceName: 'Smartphone',
          );
          finishResult.fold(
            (failure) => state = AuthError(failure.message),
            (_) => _checkAuthStatus(),
          );
        } catch (e) {
          state = AuthError('Erro ao registrar chave de hardware: $e');
        }
      },
    );
  }

  Future<void> getOnboardingLink(String sessionId) async {
    state = const AuthLoading();
    final result = await authRepository.generateOnboardingLink(sessionId);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (dto) => state = AuthPaymentRequired(
        sessionId: sessionId,
        amountBtc: dto.amountBtc,
        depositAddress: dto.depositAddress,
      ),
    );
  }

  Future<void> mockConfirmOnboarding({
    required String sessionId,
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.mockConfirmOnboarding(sessionId);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) async => await loginAfterSignup(username: username, password: password),
    );
  }

  Future<void> confirmVoucher({
    required String voucherId,
    required String txid,
  }) async {
    state = const AuthLoading();
    final result = await authRepository.confirmVoucher(
      voucherId: voucherId,
      txid: txid,
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthInitial(),
    );
  }

  Future<void> loginAfterSignup({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await loginUseCase(
      LoginParams(username: username, passphrase: password),
    );
    result.fold(
      (failure) {
        AudioService.instance.playError();
        state = AuthError(failure.message);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final signupUseCase = ref.watch(signupUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return AuthNotifier(
    loginUseCase: loginUseCase,
    signupUseCase: signupUseCase,
    authRepository: authRepository,
    notificationService: notificationService,
    ref: ref,
  );
});
