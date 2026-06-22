import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import '../../data/datasources/security_remote_datasource.dart';
import '../../data/repositories/security_repository_impl.dart';
import '../../domain/entities/app_pin_status.dart';
import '../../domain/entities/account_security_profile.dart';
import '../../domain/entities/admin_access.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/entities/security_status.dart';
import '../../domain/entities/kfe_reserve_overview.dart';

final securityRemoteDataSourceProvider =
    Provider<SecurityRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SecurityRemoteDataSourceImpl(apiClient);
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  final remoteDataSource = ref.watch(securityRemoteDataSourceProvider);
  return SecurityRepositoryImpl(remoteDataSource: remoteDataSource);
});

final sovereigntyStatusProvider = FutureProvider<SecurityStatus>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getSovereigntyStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final kfeReserveOverviewProvider =
    FutureProvider<KfeReserveOverview>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getKfeReserveOverview();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (overview) => overview,
  );
});

final auditStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAuditStats();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});

final accountSecurityProfileProvider =
    FutureProvider<AccountSecurityProfile>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAccountSecurityProfile();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (profile) => profile,
  );
});

final appPinStatusProvider = FutureProvider<AppPinStatus>(
  (ref) async {
    final repository = ref.watch(securityRepositoryProvider);
    final result = await repository.getAppPinStatus();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (status) => status,
    );
  },
  retry: (_, __) => null,
);

final adminKeyStatusProvider =
    FutureProvider.autoDispose<AdminKeyStatus>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAdminKeyStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final pendingAdminAccessAttemptsProvider =
    FutureProvider.autoDispose<List<AdminAccessAttempt>>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getPendingAdminAttempts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (attempts) => attempts,
  );
});

final adminAuthenticatedDevicesProvider =
    FutureProvider.autoDispose<List<AdminAuthenticatedDevice>>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAdminDevices();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (devices) => devices,
  );
});

class AppEntryPinUnlockNotifier extends Notifier<bool> {
  @override
  bool build() {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated) {
      return false;
    }
    return false;
  }

  void unlock() => state = true;

  void lock() => state = false;
}

final appEntryPinUnlockedProvider =
    NotifierProvider<AppEntryPinUnlockNotifier, bool>(
  AppEntryPinUnlockNotifier.new,
);
