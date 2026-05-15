import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_provider.dart';
import '../../data/datasources/security_remote_datasource.dart';
import '../../data/repositories/security_repository_impl.dart';
import '../../domain/repositories/security_repository.dart';
import '../../domain/entities/security_status.dart';

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

final auditStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(securityRepositoryProvider);
  final result = await repository.getAuditStats();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});
