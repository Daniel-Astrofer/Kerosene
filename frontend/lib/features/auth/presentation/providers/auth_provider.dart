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
import '../../../../features/notifications/data/datasources/notification_remote_datasource.dart'; // Import
import '../../../../features/notifications/data/repositories/notification_repository_impl.dart'; // Import
import '../../../../features/notifications/domain/repositories/notification_repository.dart'; // Import
import '../../../../features/notifications/application/notification_service.dart'; // Import

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/background_service.dart';
import '../state/auth_state.dart';

// ==================== Providers de Dependências ====================

/// Provider do ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  // Unified Tor Routing (apiUrl already contains the relay port)
  final baseUrl = AppConfig.apiUrl;

  final client = ApiClient(baseUrl: baseUrl, ref: ref);

  final localDataSource = ref.watch(authLocalDataSourceProvider);

  // Anexar o interceptor imediatamente para evitar condições de corrida
  client.addInterceptor(
    TokenInterceptor(localDataSource: localDataSource, apiClient: client),
  );

  return client;
});

/// Provider do AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// Provider do AuthLocalDataSource
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSourceImpl(sharedPreferences);
});

/// Provider do AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

// ==================== Providers de UseCases ====================

/// Provider do LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Provider do SignupUseCase
final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUseCase(repository);
});

// ==================== Providers de Notifications ====================

/// Provider do NotificationRemoteDataSource
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return NotificationRemoteDataSourceImpl(apiClient);
    });

/// Provider do NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remote = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remote);
});

/// Provider do NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationService(repository);
});

// ==================== Provider de Estado ====================

/// StateNotifier para gerenciar o estado de autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final AuthRepository authRepository;
  final NotificationService notificationService; // Inject Service

  AuthNotifier({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.authRepository,
    required this.notificationService,
    required Ref ref,
  }) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Tracks when the async auth check completes
  final _authCheckCompleter = Completer<void>();

  /// Returns a Future that resolves when _checkAuthStatus is done.
  Future<void> get authCheckCompleted => _authCheckCompleter.future;

  /// Verificar status de autenticação ao iniciar
  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await authRepository.isAuthenticated();

      if (isAuth) {
        final result = await authRepository.getCurrentUser();
        result.fold(
          (failure) {
            // No local user cache found — could be mid-TOTP flow.
            // Do NOT wipe the token. Just go to unauthenticated so user logs in again.
            state = const AuthUnauthenticated();
          },
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
      _authCheckCompleter.complete();
    }
  }

  /// Fazer login
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
        // Clear any stale/mismatched token so it's never sent again
        await authRepository.clearInvalidSession();
        state = AuthError(failure.message);
      },
      (loginResult) {
        // Login initial phase success. JWT already saved in repository.
        // Move to TOTP state.
        state = AuthRequiresLoginTotp(username: username, passphrase: password);
      },
    );
  }

  /// Fazer cadastro
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

  /// Verificar TOTP e finalizar login
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

  /// Verificar TOTP de Login (2FA)
  Future<void> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    state = const AuthLoading();

    final result = await authRepository.verifyLoginTotp(
      username: username,
      passphrase: passphrase,
      totpCode: totpCode,
    );

    result.fold((failure) => state = AuthError(failure.message), (user) {
      state = AuthAuthenticated(user);
      notificationService.initializeAndRegister();
      startBackgroundService();
    });
  }

  /// Fazer logout
  Future<void> logout() async {
    state = const AuthLoading();

    final result = await authRepository.logout();

    result.fold((failure) => state = AuthError(failure.message), (_) {
      state = const AuthUnauthenticated();
      stopBackgroundService();
    });
  }

  /// Limpar erro
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  /// Validar passphrase (retorna true/false sem alterar estado principal)
  Future<bool> validatePassphrase(String passphrase) async {
    final result = await authRepository.validatePassphrase(passphrase);
    return result.fold((failure) => false, (isValid) => isValid);
  }
}

/// Provider do AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final signupUseCase = ref.watch(signupUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final notificationService = ref.watch(
    notificationServiceProvider,
  ); // Watch service

  return AuthNotifier(
    loginUseCase: loginUseCase,
    signupUseCase: signupUseCase,
    authRepository: authRepository,
    notificationService: notificationService, // Pass to notifier
    ref: ref,
  );
});
