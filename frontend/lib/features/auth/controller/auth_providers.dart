import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../main.dart' show sharedPreferencesProvider;
import '../data/datasources/auth_local_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/interceptors/token_interceptor.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/signup_usecase.dart';

final authApiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = AppConfig.apiUrl;
  final client = ApiClient(baseUrl: baseUrl, ref: ref);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  client.addInterceptor(
    TokenInterceptor(localDataSource: localDataSource, apiClient: client),
  );

  return client;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(authApiClientProvider);
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

final activationStatusProvider =
    FutureProvider.autoDispose<ActivationStatusResult>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getActivationStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final securityStatusProvider =
    FutureProvider.autoDispose<AccountSecurityStatusResult>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getSecurityStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final backupCodesStatusProvider =
    FutureProvider.autoDispose<BackupCodesStatusResult>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getBackupCodesStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUseCase(repository);
});
