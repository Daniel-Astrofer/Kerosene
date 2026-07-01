import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/features/auth/controller/auth_local_provider.dart';
import 'package:kerosene/features/movement/data/datasources/transaction_remote_datasource.dart';
import 'package:kerosene/features/movement/data/repositories/transaction_repository_impl.dart';
import 'package:kerosene/features/movement/domain/repositories/transaction_repository.dart';

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRemoteDataSourceImpl(apiClient);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final remoteDataSource = ref.watch(transactionRemoteDataSourceProvider);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);
  return TransactionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});
