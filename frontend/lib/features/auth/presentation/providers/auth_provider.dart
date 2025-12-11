import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show sharedPreferencesProvider;
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../state/auth_state.dart';

// ==================== Providers de Dependências ====================

/// Provider do ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: AppConfig.apiUrl);
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

// ==================== Provider de Estado ====================

/// StateNotifier para gerenciar o estado de autenticação
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final AuthRepository authRepository;

  AuthNotifier({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Verificar status de autenticação ao iniciar
  Future<void> _checkAuthStatus() async {
    final isAuth = await authRepository.isAuthenticated();

    if (isAuth) {
      final result = await authRepository.getCurrentUser();
      result.fold(
        (failure) => state = const AuthUnauthenticated(),
        (user) => state = AuthAuthenticated(user),
      );
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Fazer login
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await loginUseCase(username: username, password: password);

    result.fold((failure) {
      if (failure.message == 'REQ_LOGIN_2FA') {
        state = AuthRequiresLoginTotp(username: username, passphrase: password);
      } else {
        state = AuthError(failure.message);
      }
    }, (user) => state = AuthAuthenticated(user));
  }

  /// Fazer cadastro
  Future<void> signup({
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await signupUseCase(username: username, password: password);

    result.fold(
      (failure) => state = AuthError(failure.message),
      (totpSecret) => state = AuthRequiresTotpSetup(
        username: username,
        passphrase: password,
        totpSecret: totpSecret,
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
    );

    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
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

    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
    );
  }

  /// Fazer logout
  Future<void> logout() async {
    state = const AuthLoading();

    final result = await authRepository.logout();

    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthUnauthenticated(),
    );
  }

  /// Limpar erro
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

/// Provider do AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final signupUseCase = ref.watch(signupUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return AuthNotifier(
    loginUseCase: loginUseCase,
    signupUseCase: signupUseCase,
    authRepository: authRepository,
  );
});
