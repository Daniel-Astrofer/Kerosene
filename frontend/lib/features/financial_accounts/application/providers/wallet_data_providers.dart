import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/network/api_client_provider.dart';
import 'package:kerosene/core/services/wallet_security_service.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/financial_accounts/data/datasources/ledger_remote_datasource.dart';
import 'package:kerosene/features/financial_accounts/data/datasources/wallet_remote_datasource.dart';
import 'package:kerosene/features/financial_accounts/data/repositories/ledger_repository_impl.dart';
import 'package:kerosene/features/financial_accounts/data/repositories/wallet_repository_impl.dart';
import 'package:kerosene/features/financial_accounts/domain/repositories/ledger_repository.dart';
import 'package:kerosene/features/financial_accounts/domain/repositories/wallet_repository.dart';
import 'package:kerosene/features/financial_activity/application/providers/transaction_data_providers.dart'
    as financial_activity_data;
import 'package:kerosene/features/financial_activity/data/datasources/transaction_remote_datasource.dart';
import 'package:kerosene/features/financial_activity/domain/repositories/transaction_repository.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = LedgerRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);
  return LedgerRepositoryImpl(
    remoteDataSource: remoteDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = WalletRemoteDataSourceImpl(apiClient);
  final ledgerRemoteDataSource = LedgerRemoteDataSourceImpl(apiClient);
  final transactionRemoteDataSource =
      TransactionRemoteDataSourceImpl(apiClient);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return WalletRepositoryImpl(
    remoteDataSource: remoteDataSource,
    ledgerRemoteDataSource: ledgerRemoteDataSource,
    transactionRemoteDataSource: transactionRemoteDataSource,
    authLocalDataSource: authLocalDataSource,
    walletSecurityService: WalletSecurityService(),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ref.watch(financial_activity_data.transactionRepositoryProvider);
});
