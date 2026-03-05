import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart'
    show authLocalDataSourceProvider, apiClientProvider;
import '../../../wallet/domain/entities/transaction.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';

// ==================== Filter Logic ====================

enum TransactionFilter {
  all('Tudo'),
  send('Enviadas'),
  receive('Recebidas');

  final String label;
  const TransactionFilter(this.label);
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return TransactionFilter.all;
});

// ==================== Core Providers ====================

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

// ==================== Transaction History (API) ====================

/// Busca o histórico de transações do endpoint GET /ledger/history
final transactionHistoryProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  // DEV MODE: Mocking Transactions
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    Transaction(
      id: "tx-xyz-1234",
      fromAddress: "Me",
      toAddress: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy",
      amountSatoshis: 150000000, // 1.5 BTC
      feeSatoshis: 500,
      status: TransactionStatus.confirmed,
      type: TransactionType.send,
      confirmations: 110,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      description: "Transfer to Savings",
    ),
    Transaction(
      id: "tx-abc-987",
      fromAddress: "External",
      toAddress: "1A1zP1e...",
      amountSatoshis: 17500000, // 0.175 BTC
      feeSatoshis: 0,
      status: TransactionStatus.confirming,
      type: TransactionType.deposit,
      confirmations: 2,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      description: "Client payment",
    ),
  ];
});

/// Histórico filtrado por tipo
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final historyAsync = ref.watch(transactionHistoryProvider);
  final filter = ref.watch(transactionFilterProvider);

  return historyAsync.whenData((txs) {
    switch (filter) {
      case TransactionFilter.all:
        return txs;
      case TransactionFilter.send:
        return txs
            .where(
              (tx) =>
                  tx.type == TransactionType.send ||
                  tx.type == TransactionType.withdrawal,
            )
            .toList();
      case TransactionFilter.receive:
        return txs
            .where(
              (tx) =>
                  tx.type == TransactionType.receive ||
                  tx.type == TransactionType.deposit,
            )
            .toList();
    }
  });
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
  final result = await repo.getDepositAddress();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (address) => address,
  );
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
  // DEV MODE: Mocking Payment Links
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    PaymentLink(
      id: "link-001",
      userId: 1,
      amountBtc: 0.05,
      description: "Freelance Design Work",
      depositAddress: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
      status: "pending",
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
});

final paymentLinkDetailProvider = FutureProvider.family<PaymentLink, String>((
  ref,
  linkId,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPaymentRequest(linkId);
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
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? fromWalletId,
    String? fromAddress,
    String? context,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.sendTransaction(
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
        fromWalletId: fromWalletId,
        fromAddress: fromAddress,
        context: context,
      );

      debugPrint('>>> Notifier: Transaction sent successfully: ${result.txid}');

      // Refresh history from API after successful transaction
      ref.invalidate(transactionHistoryProvider);

      state = AsyncActionState(result: result);
      return result;
    } catch (e, stack) {
      debugPrint('>>> Notifier Error: $e');
      debugPrint('>>> Stack: $stack');
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<TxStatus?> broadcast({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  }) async {
    state = const AsyncActionState(isLoading: true);
    final result = await _repository.broadcastTransaction(
      rawTxHex: rawTxHex,
      toAddress: toAddress,
      amount: amount,
      message: message,
    );
    return result.fold(
      (failure) {
        state = AsyncActionState(error: failure.message);
        return null;
      },
      (txStatus) {
        state = AsyncActionState(result: txStatus);
        return txStatus;
      },
    );
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
    required String receiverWalletName,
    int? expiresIn,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.createPaymentRequest(
        amount: amount,
        receiverWalletName: receiverWalletName,
        expiresIn: expiresIn,
      );
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<PaymentLink?> pay({
    required String linkId,
    required String payerWalletName,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
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

final paymentLinkNotifierProvider =
    StateNotifierProvider<PaymentLinkNotifier, AsyncActionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return PaymentLinkNotifier(repo);
    });

/// Notifier para Saques Externos
class WithdrawNotifier extends StateNotifier<AsyncActionState> {
  final TransactionRepository _repository;
  final Ref ref;

  WithdrawNotifier(this._repository, this.ref)
    : super(const AsyncActionState());

  Future<TxStatus?> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    required String totpCode,
    String? description,
    String? passkeyAssertionResponseJSON,
    String? passkeyAssertionRequestJSON,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.withdraw(
        fromWalletName: fromWalletName,
        toAddress: toAddress,
        amount: amount,
        totpCode: totpCode,
        description: description,
        passkeyAssertionResponseJSON: passkeyAssertionResponseJSON,
        passkeyAssertionRequestJSON: passkeyAssertionRequestJSON,
      );

      // Refresh history from API after withdrawal
      ref.invalidate(transactionHistoryProvider);

      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final withdrawProvider =
    StateNotifierProvider<WithdrawNotifier, AsyncActionState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return WithdrawNotifier(repo, ref);
    });
