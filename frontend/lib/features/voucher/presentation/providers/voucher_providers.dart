import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/features/voucher/data/datasources/voucher_remote_datasource.dart';
import 'package:teste/features/voucher/data/repositories/voucher_repository_impl.dart';
import 'package:teste/features/voucher/domain/repositories/voucher_repository.dart';

final voucherRemoteDataSourceProvider = Provider<VoucherRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VoucherRemoteDataSourceImpl(apiClient);
});

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final remoteDataSource = ref.watch(voucherRemoteDataSourceProvider);
  return VoucherRepositoryImpl(remoteDataSource: remoteDataSource);
});
