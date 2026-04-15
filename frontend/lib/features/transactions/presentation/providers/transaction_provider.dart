import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/passkey_service.dart';
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
import '../../domain/entities/external_transfer.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/repositories/ledger_repository.dart'; // Add this
import '../../../wallet/presentation/providers/wallet_provider.dart'
    show ledgerRepositoryProvider, walletProvider;

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

List<Transaction> _mergeExternalHistory({
  required List<Transaction> ledgerTransactions,
  required List<ExternalTransfer> externalTransfers,
}) {
  final merged = <String, Transaction>{};

  void upsert(Transaction transaction) {
    final key = _transactionHistoryKey(transaction);
    final existing = merged[key];
    if (existing == null || _shouldReplaceHistoryEntry(existing, transaction)) {
      merged[key] = transaction;
    }
  }

  for (final transaction in ledgerTransactions) {
    upsert(transaction);
  }

  for (final transfer in externalTransfers) {
    upsert(transfer.toTransaction());
  }

  final history = merged.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return history;
}

String _transactionHistoryKey(Transaction transaction) {
  final blockchainTxid = transaction.blockchainTxid?.trim() ?? '';
  if (blockchainTxid.isNotEmpty) {
    return 'blockchain:$blockchainTxid';
  }
  return 'transaction:${transaction.id.trim()}';
}

bool _shouldReplaceHistoryEntry(Transaction current, Transaction candidate) {
  if (current.isInternal && !candidate.isInternal) {
    return true;
  }
  if (current.feeSatoshis == 0 && candidate.feeSatoshis > 0) {
    return true;
  }
  if (candidate.timestamp.isAfter(current.timestamp)) {
    return true;
  }
  return false;
}

Future<List<ExternalTransfer>> _loadExternalTransfersSafely(Ref ref) async {
  try {
    return await ref
        .watch(transactionRepositoryProvider)
        .getExternalTransfers();
  } catch (_) {
    return const <ExternalTransfer>[];
  }
}

// ==================== Transaction History (API) ====================

/// Busca o histórico de transações do endpoint GET /ledger/history
final transactionHistoryProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final result = await ledgerRepo.getHistory(page: 0, size: 50);
  final externalTransfers = await _loadExternalTransfersSafely(ref);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (transactions) {
      return _mergeExternalHistory(
        ledgerTransactions: transactions,
        externalTransfers: externalTransfers,
      );
    },
  );
});

final pagedTransactionHistoryProvider =
    FutureProvider.family<List<Transaction>, ({int page, int size})>((
  ref,
  request,
) async {
  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final result = await ledgerRepo.getHistory(
    page: request.page,
    size: request.size,
  );
  final transactions = result.fold<List<Transaction>>(
    (failure) => throw Exception(failure.message),
    (transactions) => transactions,
  );

  if (request.page != 0) {
    return transactions;
  }

  final externalTransfers = await _loadExternalTransfersSafely(ref);
  final merged = _mergeExternalHistory(
    ledgerTransactions: transactions,
    externalTransfers: externalTransfers,
  );
  return merged.take(request.size).toList();
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

final externalTransfersProvider = FutureProvider<List<ExternalTransfer>>((
  ref,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final transfers = await repo.getExternalTransfers();
  final sorted = List<ExternalTransfer>.from(transfers)
    ..sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
  return sorted;
});

final externalTransferDetailProvider =
    FutureProvider.family<ExternalTransfer, String>((ref, transferId) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getExternalTransfer(transferId);
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
    String? passkeyAssertionJson,
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
        passkeyAssertionJson: passkeyAssertionJson,
        confirmationPassphrase: confirmationPassphrase,
        totpCode: totpCode,
        idempotencyKey: idempotencyKey,
        requestTimestamp: requestTimestamp,
      );

      debugPrint('>>> Notifier: Transaction sent successfully: ${result.txid}');

      // Refresh history from API after successful transaction
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      await ref.read(walletProvider.notifier).refresh();

      state = AsyncActionState(result: result);
      return result;
    } catch (e, stack) {
      debugPrint('>>> Notifier Error: $e');
      debugPrint('>>> Stack: $stack');

      final errorStr = e.toString();
      if (errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
        try {
          final challenge = _extractPasskeyChallenge(e);
          if (challenge == null) {
            throw StateError(
              'Não foi possível extrair o challenge da passkey da resposta do servidor.',
            );
          }
          debugPrint(
              '>>> Notifier: Passkey challenge required. Challenge: $challenge');

          SnackbarHelper.showSuccess(
              'Assinatura biométrica necessária para esta transação.');

          final assertionJson = await _buildPasskeyAssertionJson(challenge);

          debugPrint('>>> Notifier: Challenge signed. Retrying transaction...');

          // Retry with signature
          final result = await _repository.sendTransaction(
            toAddress: toAddress,
            amount: amount,
            feeSatoshis: feeSatoshis,
            fromWalletId: fromWalletId,
            fromAddress: fromAddress,
            context: context,
            passkeyAssertionJson: assertionJson,
            confirmationPassphrase: confirmationPassphrase,
            totpCode: totpCode,
            idempotencyKey: idempotencyKey,
            requestTimestamp: requestTimestamp,
          );

          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(depositsProvider);
          ref.invalidate(depositBalanceProvider);
          await ref.read(walletProvider.notifier).refresh();
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
          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(depositsProvider);
          ref.invalidate(depositBalanceProvider);
          ref.read(walletProvider.notifier).refresh();
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
    String? totpCode,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _ledgerRepository.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
        totpCode: totpCode,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: passkeyAssertionJson,
      );

      return result.fold<Future<PaymentLink?>>(
        (failure) => _handlePayFailure(
          failure.message,
          linkId: linkId,
          payerWalletName: payerWalletName,
          totpCode: totpCode,
          confirmationPassphrase: confirmationPassphrase,
        ),
        (data) async => _completePayment(data),
      );
    } catch (e) {
      return _handlePayFailure(
        e,
        linkId: linkId,
        payerWalletName: payerWalletName,
        totpCode: totpCode,
        confirmationPassphrase: confirmationPassphrase,
      );
    }
  }

  Future<PaymentLink?> _handlePayFailure(
    Object error, {
    required String linkId,
    required String payerWalletName,
    String? totpCode,
    String? confirmationPassphrase,
  }) async {
    final errorStr = error.toString();
    if (!errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
      state = AsyncActionState(error: errorStr);
      return null;
    }

    try {
      final challenge = _extractPasskeyChallenge(error);
      if (challenge == null) {
        throw StateError(
          'Não foi possível extrair o challenge da passkey da resposta do servidor.',
        );
      }

      debugPrint(
          '>>> Notifier: Passkey challenge required for payment link. Challenge: $challenge');
      SnackbarHelper.showSuccess(
          'Assinatura biométrica necessária para confirmar o pagamento.');

      final assertionJson = await _buildPasskeyAssertionJson(challenge);
      final result = await _ledgerRepository.payPaymentRequest(
        linkId: linkId,
        payerWalletName: payerWalletName,
        totpCode: totpCode,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: assertionJson,
      );

      return result.fold<PaymentLink?>(
        (failure) {
          state = AsyncActionState(error: failure.message);
          return null;
        },
        _completePayment,
      );
    } catch (signErr) {
      state = AsyncActionState(error: signErr.toString());
      return null;
    }
  }

  PaymentLink _completePayment(Map<String, dynamic> data) {
    final link = PaymentLink.fromJson(data);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(depositsProvider);
    ref.invalidate(depositBalanceProvider);
    ref.read(walletProvider.notifier).refresh();
    state = AsyncActionState(result: link);
    return link;
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
    String? toAddress,
    String? paymentRequest,
    required double amount,
    String? totpCode,
    bool isLightning = false,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.withdraw(
        fromWalletName: fromWalletName,
        toAddress: toAddress,
        paymentRequest: paymentRequest,
        amount: amount,
        totpCode: totpCode,
        isLightning: isLightning,
        maxRoutingFeeBtc: maxRoutingFeeBtc,
        description: description,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: passkeyAssertionJson,
      );

      // Refresh history from API after withdrawal
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      ref.invalidate(externalTransfersProvider);
      await ref.read(walletProvider.notifier).refresh();

      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('PASSKEY_CHALLENGE_REQUIRED')) {
        try {
          final challenge = _extractPasskeyChallenge(e);
          if (challenge == null) {
            throw StateError(
              'Não foi possível extrair o challenge da passkey da resposta do servidor.',
            );
          }
          debugPrint(
              '>>> Notifier: Passkey challenge required for withdrawal. Challenge: $challenge');

          SnackbarHelper.showSuccess(
              'Assinatura biométrica necessária para confirmar o saque.');

          final assertionJson = await _buildPasskeyAssertionJson(challenge);

          debugPrint('>>> Notifier: Withdrawal challenge signed. Retrying...');

          final result = await _repository.withdraw(
            fromWalletName: fromWalletName,
            toAddress: toAddress,
            paymentRequest: paymentRequest,
            amount: amount,
            totpCode: totpCode,
            isLightning: isLightning,
            maxRoutingFeeBtc: maxRoutingFeeBtc,
            description: description,
            confirmationPassphrase: confirmationPassphrase,
            passkeyAssertionJson: assertionJson,
          );

          ref.invalidate(transactionHistoryProvider);
          ref.invalidate(depositsProvider);
          ref.invalidate(depositBalanceProvider);
          ref.invalidate(externalTransfersProvider);
          await ref.read(walletProvider.notifier).refresh();
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

String? _extractPasskeyChallenge(Object error) {
  const marker = 'PASSKEY_CHALLENGE_REQUIRED:';
  final rawError = error.toString().trim();
  final candidates = <String>[rawError];

  try {
    final decoded = jsonDecode(rawError);
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim();
      final nestedError = decoded['error']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        candidates.insert(0, message);
      }

      if (nestedError != null && nestedError.isNotEmpty) {
        candidates.add(nestedError);
      }
    }
  } catch (_) {}

  final hexPattern = RegExp(
    '${RegExp.escape(marker)}([0-9a-fA-F]+)',
  );

  for (final candidate in candidates) {
    final hexMatch = hexPattern.firstMatch(candidate);
    if (hexMatch != null) {
      return hexMatch.group(1);
    }

    final markerIndex = candidate.indexOf(marker);
    if (markerIndex < 0) {
      continue;
    }

    var challenge = candidate.substring(markerIndex + marker.length).trim();
    challenge = challenge.replaceFirst(RegExp(r"""^['"]+"""), '');
    challenge = challenge.replaceFirst(RegExp(r"""['",}\]\s]+$"""), '');

    if (challenge.isNotEmpty) {
      return challenge;
    }
  }

  return null;
}

Future<String> _buildPasskeyAssertionJson(String challenge) async {
  final credential = await PasskeyService.instance.authenticate(
    challengeHex: challenge,
    username: 'transaction',
  );
  return jsonEncode(credential);
}
