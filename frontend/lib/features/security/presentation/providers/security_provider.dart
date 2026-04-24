import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import '../../data/datasources/security_remote_datasource.dart';
import '../../data/repositories/security_repository_impl.dart';
import '../../domain/entities/app_pin_status.dart';
import '../../domain/entities/account_security_profile.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/entities/security_status.dart';
import '../../domain/entities/treasury_overview.dart';

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

final treasuryOverviewProvider = FutureProvider<TreasuryOverview>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getTreasuryOverview();
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

final appPinStatusProvider = FutureProvider<AppPinStatus>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAppPinStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
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
