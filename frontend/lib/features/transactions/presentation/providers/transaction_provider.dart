import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_transaction_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show authLocalDataSourceProvider;
import '../../../wallet/domain/entities/transaction.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';

// ==================== Core Providers ====================

final _transactionApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  );
});

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
      final apiClient = ref.watch(_transactionApiClientProvider);
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

// ==================== Fee Estimation ====================

final feeEstimateProvider = FutureProvider.family<FeeEstimate, double>((
  ref,
  amount,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.estimateFee(amount);
});

// ==================== Transaction Status ====================

final txStatusProvider = FutureProvider.family<TxStatus, String>((
  ref,
  txid,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionStatus(txid);
});

// ==================== Deposit Address ====================

final depositAddressProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDepositAddress();
});

// ==================== Deposits ====================

final depositsProvider = FutureProvider<List<Deposit>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDeposits();
});

final depositBalanceProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDepositBalance();
});

final depositDetailProvider = FutureProvider.family<Deposit, String>((
  ref,
  txid,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDeposit(txid);
});

// ==================== Payment Links ====================

final paymentLinksProvider = FutureProvider<List<PaymentLink>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPaymentLinks();
});

final paymentLinkDetailProvider = FutureProvider.family<PaymentLink, String>((
  ref,
  linkId,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPaymentLink(linkId);
});

// ==================== Action Notifiers ====================

/// State for async operations
class AsyncActionState {
  final bool isLoading;
  final String? error;
  final dynamic result;

  const AsyncActionState({this.isLoading = false, this.error, this.result});

  AsyncActionState copyWith({bool? isLoading, String? error, dynamic result}) {
    return AsyncActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

/// Notifier para envio de transações Bitcoin
class SendTransactionNotifier extends StateNotifier<AsyncActionState> {
  final TransactionRepository _repository;
  final Ref ref;

  SendTransactionNotifier(this._repository, this.ref)
    : super(const AsyncActionState());

  Future<TxStatus?> send({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.sendTransaction(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
      );

      // Save locally
      final transaction = Transaction(
        id: result.txid,
        fromAddress: fromAddress,
        toAddress: toAddress,
        amountSatoshis: (amount * 100000000).toInt(),
        feeSatoshis: feeSatoshis,
        status: TransactionStatus.confirmed,
        type: TransactionType.send,
        confirmations: 6,
        timestamp: DateTime.now(),
        description: "Sent Bitcoin",
      );

      await ref
          .read(transactionHistoryProvider.notifier)
          .addTransaction(transaction);

      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<TxStatus?> broadcast(String rawTxHex) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.broadcastTransaction(rawTxHex);
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final sendTransactionProvider =
    StateNotifierProvider<SendTransactionNotifier, AsyncActionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return SendTransactionNotifier(repo, ref);
    });

/// Notifier para confirmar depósitos
class ConfirmDepositNotifier extends StateNotifier<AsyncActionState> {
  final TransactionRepository _repository;

  ConfirmDepositNotifier(this._repository) : super(const AsyncActionState());

  Future<Deposit?> confirm({
    required String txid,
    required String fromAddress,
    required double amount,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.confirmDeposit(
        txid: txid,
        fromAddress: fromAddress,
        amount: amount,
      );
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final confirmDepositProvider =
    StateNotifierProvider<ConfirmDepositNotifier, AsyncActionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return ConfirmDepositNotifier(repo);
    });

/// Notifier para Payment Links
class PaymentLinkNotifier extends StateNotifier<AsyncActionState> {
  final TransactionRepository _repository;

  PaymentLinkNotifier(this._repository) : super(const AsyncActionState());

  Future<PaymentLink?> create({
    required double amount,
    required String description,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.createPaymentLink(
        amount: amount,
        description: description,
      );
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<PaymentLink?> confirmPayment({
    required String linkId,
    required String txid,
    required String fromAddress,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.confirmPaymentLink(
        linkId: linkId,
        txid: txid,
        fromAddress: fromAddress,
      );
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<PaymentLink?> complete(String linkId) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.completePaymentLink(linkId);
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final paymentLinkNotifierProvider =
    StateNotifierProvider<PaymentLinkNotifier, AsyncActionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return PaymentLinkNotifier(repo);
    });

// ==================== Local Persistence ====================

final localTransactionServiceProvider = Provider(
  (ref) => LocalTransactionService(),
);

class TransactionHistoryNotifier extends StateNotifier<List<Transaction>> {
  final LocalTransactionService _service;
  TransactionHistoryNotifier(this._service) : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('>>> TransactionHistoryNotifier: Starting initialization');
      final transactions = await _service.getTransactions();
      debugPrint('>>> TransactionHistoryNotifier: Loaded ${transactions.length} transactions');
      state = transactions;
    } catch (e) {
      debugPrint('>>> TransactionHistoryNotifier: Error during initialization: $e');
    }
  }

  Future<void> loadTransactions() async {
    try {
      debugPrint('>>> TransactionHistoryNotifier: Loading transactions');
      state = await _service.getTransactions();
      debugPrint('>>> TransactionHistoryNotifier: Loaded ${state.length} transactions');
    } catch (e) {
      debugPrint('>>> TransactionHistoryNotifier: Error loading transactions: $e');
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _service.saveTransaction(transaction);
    state = [transaction, ...state];
  }
}

final transactionHistoryProvider =
    StateNotifierProvider<TransactionHistoryNotifier, List<Transaction>>((ref) {
      final service = ref.watch(localTransactionServiceProvider);
      return TransactionHistoryNotifier(service);
    });
