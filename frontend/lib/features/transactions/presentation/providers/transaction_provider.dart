import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/sovereign_auth_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/controller/auth_local_provider.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/repositories/ledger_repository.dart'; // Add this
import '../../../wallet/presentation/providers/wallet_provider.dart'
    show ledgerRepositoryProvider;

// ==================== Filter Logic ====================

enum TransactionFilter {
  all('Tudo'),
  send('Enviadas'),
  receive('Recebidas');

  final String label;
  const TransactionFilter(this.label);
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.all;

  void updateFilter(TransactionFilter filter) => state = filter;
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
        TransactionFilterNotifier.new);

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
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final result = await ledgerRepo.getHistory(page: 0, size: 50);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (transactions) {
      final sortedTransactions = List<Transaction>.from(transactions)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sortedTransactions;
    },
  );
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

final transactionsByWalletProvider =
    FutureProvider.family<List<Transaction>, String>((ref, address) async {
  final historyAsync = await ref.watch(transactionHistoryProvider.future);
  return historyAsync
      .where((tx) => tx.fromAddress == address || tx.toAddress == address)
      .toList();
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
  final historyAsync = await ref.watch(transactionHistoryProvider.future);
  return historyAsync
      .where((t) =>
          t.type == TransactionType.receive ||
          t.type == TransactionType.deposit)
      .map((t) => Deposit(
            id: t.id.hashCode,
            userId: 0,
            txid: t.id,
            fromAddress: t.fromAddress,
            toAddress: t.toAddress,
            amountBtc: t.amountSatoshis / 100000000,
            confirmations: t.confirmations,
            status: t.status == TransactionStatus.confirmed
                ? 'credited'
                : 'pending',
            createdAt: t.timestamp,
          ))
      .toList();
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
  final repo = ref.watch(ledgerRepositoryProvider);
  final result = await repo.getPaymentRequest(linkId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => PaymentLink.fromJson(data),
  );
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
class SendTransactionNotifier extends Notifier<AsyncActionState> {
  late TransactionRepository _repository;

  @override
  AsyncActionState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    return const AsyncActionState();
  }

  Future<TxStatus?> send({
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? fromWalletId,
    String? fromAddress,
    String? context,
    String? passkeySignature,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
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
        passkeySignature: passkeySignature,
        confirmationPassphrase: confirmationPassphrase,
        totpCode: totpCode,
        idempotencyKey: idempotencyKey,
        requestTimestamp: requestTimestamp,
      );

      debugPrint('>>> Notifier: Transaction sent successfully: ${result.txid}');

      // Refresh history from API after successful transaction
      ref.invalidate(transactionHistoryProvider);

      state = AsyncActionState(result: result);
      return result;
    } catch (e, stack) {
      debugPrint('>>> Notifier Error: $e');
      debugPrint('>>> Stack: $stack');

      final errorStr = e.toString();
      if (errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
        try {
          // Extract challenge from error message (format: "PASSKEY_CHALLENGE_REQUIRED:<challenge>")
          final challenge = errorStr
              .split('PASSKEY_CHALLENGE_REQUIRED:')
              .last
              .split('"')
              .first
              .trim();
          debugPrint(
              '>>> Notifier: Passkey challenge required. Challenge: $challenge');

          SnackbarHelper.showSuccess(
              'Assinatura biométrica necessária para esta transação.');

          // Sign the challenge using Sovereign Passkey (Ed25519)
          final signature =
              await SovereignAuthService.instance.signChallenge(challenge);

          debugPrint('>>> Notifier: Challenge signed. Retrying transaction...');

          // Retry with signature
          final result = await _repository.sendTransaction(
            toAddress: toAddress,
            amount: amount,
            feeSatoshis: feeSatoshis,
            fromWalletId: fromWalletId,
            fromAddress: fromAddress,
            context: context,
            passkeySignature: signature,
            confirmationPassphrase: confirmationPassphrase,
            totpCode: totpCode,
            idempotencyKey: idempotencyKey,
            requestTimestamp: requestTimestamp,
          );

          ref.invalidate(transactionHistoryProvider);
          state = AsyncActionState(result: result);
          return result;
        } catch (signErr) {
          debugPrint('>>> Notifier: Sign/Retry failed: $signErr');
          state = AsyncActionState(error: signErr.toString());
          return null;
        }
      }

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
    NotifierProvider<SendTransactionNotifier, AsyncActionState>(
        SendTransactionNotifier.new);

/// Notifier para confirmar depósitos
class ConfirmDepositNotifier extends Notifier<AsyncActionState> {
  late TransactionRepository _repository;

  @override
  AsyncActionState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    return const AsyncActionState();
  }

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
    NotifierProvider<ConfirmDepositNotifier, AsyncActionState>(
        ConfirmDepositNotifier.new);

/// Notifier para Payment Links
class PaymentLinkNotifier extends Notifier<AsyncActionState> {
  late LedgerRepository _ledgerRepository;

  @override
  AsyncActionState build() {
    _ledgerRepository = ref.watch(ledgerRepositoryProvider);
    return const AsyncActionState();
  }

  Future<PaymentLink?> create({
    required double amount,
    required String receiverWalletName,
    int? expiresIn,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _ledgerRepository.createPaymentRequest(
        amount: amount,
        receiverWalletName: receiverWalletName,
      );

      return result.fold(
        (failure) {
          state = AsyncActionState(error: failure.message);
          return null;
        },
        (data) {
          final link = PaymentLink.fromJson(data);
          state = AsyncActionState(result: link);
          return link;
        },
      );
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
      final result = await _ledgerRepository.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
      );

      return result.fold(
        (failure) {
          state = AsyncActionState(error: failure.message);
          return null;
        },
        (data) {
          final link = PaymentLink.fromJson(data);
          state = AsyncActionState(result: link);
          return link;
        },
      );
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final paymentLinkNotifierProvider =
    NotifierProvider<PaymentLinkNotifier, AsyncActionState>(
        PaymentLinkNotifier.new);

/// Notifier para Saques Externos
class WithdrawNotifier extends Notifier<AsyncActionState> {
  late TransactionRepository _repository;

  @override
  AsyncActionState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    return const AsyncActionState();
  }

  Future<TxStatus?> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    required String totpCode,
    String? description,
    String? passkeySignature,
    String? passkeyChallenge,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.withdraw(
        fromWalletName: fromWalletName,
        toAddress: toAddress,
        amount: amount,
        totpCode: totpCode,
        description: description,
        passkeySignature: passkeySignature,
        passkeyChallenge: passkeyChallenge,
      );

      // Refresh history from API after withdrawal
      ref.invalidate(transactionHistoryProvider);

      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
        try {
          final challenge = errorStr
              .split('PASSKEY_CHALLENGE_REQUIRED:')
              .last
              .split('"')
              .first
              .trim();
          debugPrint(
              '>>> Notifier: Passkey challenge required for withdrawal. Challenge: $challenge');

          SnackbarHelper.showSuccess(
              'Assinatura biométrica necessária para confirmar o saque.');

          final signature =
              await SovereignAuthService.instance.signChallenge(challenge);

          debugPrint('>>> Notifier: Withdrawal challenge signed. Retrying...');

          final result = await _repository.withdraw(
            fromWalletName: fromWalletName,
            toAddress: toAddress,
            amount: amount,
            totpCode: totpCode,
            description: description,
            passkeySignature: signature,
            passkeyChallenge: challenge,
          );

          ref.invalidate(transactionHistoryProvider);
          state = AsyncActionState(result: result);
          return result;
        } catch (signErr) {
          debugPrint('>>> Notifier: Withdrawal sign/retry failed: $signErr');
          state = AsyncActionState(error: signErr.toString());
          return null;
        }
      }

      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  void reset() => state = const AsyncActionState();
}

final withdrawProvider =
    NotifierProvider<WithdrawNotifier, AsyncActionState>(WithdrawNotifier.new);
