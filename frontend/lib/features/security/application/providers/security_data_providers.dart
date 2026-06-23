import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/security/data/datasources/security_remote_datasource.dart';
import 'package:kerosene/features/security/data/repositories/security_repository_impl.dart';
import 'package:kerosene/features/security/domain/repositories/security_repository.dart';

final securityRemoteDataSourceProvider =
    Provider<SecurityRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SecurityRemoteDataSourceImpl(apiClient);
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  final remoteDataSource = ref.watch(securityRemoteDataSourceProvider);
  return SecurityRepositoryImpl(remoteDataSource: remoteDataSource);
});
