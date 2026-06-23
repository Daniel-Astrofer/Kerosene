// architecture-exception: presentation still imports data after Fase 6.2 move; isolate in Fase 8.2.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/controller/auth_controller.dart' show sessionStorageScopeProvider;
import 'package:kerosene/features/financial_activity/presentation/utils/transaction_address_display.dart';
import '../../../../core/services/passkey_service.dart';
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
import '../../domain/entities/wallet_network_address.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart'
    show ledgerRepositoryProvider, walletProvider;
import '../../../wallet/presentation/state/wallet_state.dart';

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

final walletNetworkProfileProvider =
    FutureProvider.family<WalletNetworkAddress, String>(
        (ref, walletName) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    throw Exception('Usuário não autenticado');
  }

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getWalletNetworkProfile(walletName: walletName);
});

List<Transaction> _mergeExternalHistory({
  required List<Transaction> kfeTransactions,
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

  for (final transaction in kfeTransactions) {
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
  final currentScore = _historyCompletenessScore(current);
  final candidateScore = _historyCompletenessScore(candidate);
  if (candidateScore != currentScore) {
    return candidateScore > currentScore;
  }
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

int _historyCompletenessScore(Transaction transaction) {
  var score = 0;

  if (!transaction.isInternal) {
    score += 2;
  }
  if ((transaction.blockchainTxid ?? '').trim().isNotEmpty) {
    score += 6;
  }
  if ((transaction.paymentHash ?? '').trim().isNotEmpty) {
    score += 5;
  }
  if ((transaction.invoiceId ?? '').trim().isNotEmpty) {
    score += 4;
  }
  if ((transaction.externalReference ?? '').trim().isNotEmpty) {
    score += 2;
  }
  if (transaction.feeSatoshis > 0) {
    score += 1;
  }

  score += transactionAddressInformationScore(transaction);

  return score;
}

Future<List<ExternalTransfer>> _loadExternalTransfersSafely(Ref ref) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <ExternalTransfer>[];
  }

  try {
    return await ref
        .watch(transactionRepositoryProvider)
        .getExternalTransfers();
  } catch (_) {
    return const <ExternalTransfer>[];
  }
}

// ==================== Transaction History (API) ====================

/// Busca o histórico de transações a partir do dashboard KFE.
final transactionHistoryProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <Transaction>[];
  }

  final ledgerRepo = ref.watch(ledgerRepositoryProvider);
  final result = await ledgerRepo.getHistory(page: 0, size: 50);
  final externalTransfers = await _loadExternalTransfersSafely(ref);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (transactions) {
      return _mergeExternalHistory(
        kfeTransactions: transactions,
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
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <Transaction>[];
  }

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
    kfeTransactions: transactions,
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
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    throw Exception('Usuário não autenticado');
  }

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionStatus(txid);
});

// ==================== Deposit Address ====================

final depositAddressProvider = FutureProvider<String>((ref) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    throw Exception('Usuário não autenticado');
  }

  final repo = ref.watch(transactionRepositoryProvider);
  final walletState = ref.watch(walletProvider);

  if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
    final walletName = walletState.wallets.first.name.trim();
    if (walletName.isNotEmpty) {
      try {
        final profile =
            await repo.getWalletNetworkProfile(walletName: walletName);
        final onchainAddress = profile.onchainAddress.trim();
        if (onchainAddress.isNotEmpty) {
          return onchainAddress;
        }
      } catch (error) {
        throw Exception(
            'Nao foi possivel carregar o endereco on-chain real: $error');
      }
    }
  }

  throw Exception(
      'Nenhuma carteira com perfil de rede disponivel para deposito.');
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
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return 0.0;
  }

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDepositBalance();
});

final depositDetailProvider = FutureProvider.family<Deposit, String>((
  ref,
  txid,
) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    throw Exception('Usuário não autenticado');
  }

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getDeposit(txid);
});

// ==================== Payment Links ====================

final paymentLinksProvider = FutureProvider<List<PaymentLink>>((ref) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <PaymentLink>[];
  }

  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getPaymentLinks();
});

final externalTransfersProvider = FutureProvider<List<ExternalTransfer>>((
  ref,
) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <ExternalTransfer>[];
  }

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
    String? appPin,
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
        appPin: appPin,
      );

      // Refresh history from API after successful transaction
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      await ref.read(walletProvider.notifier).refresh();

      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      final challenge = _extractPasskeyChallenge(e);
      if (challenge != null) {
        return _retrySendWithPasskeyChallenge(
          initialChallenge: challenge,
          toAddress: toAddress,
          amount: amount,
          feeSatoshis: feeSatoshis,
          fromWalletId: fromWalletId,
          fromAddress: fromAddress,
          context: context,
          confirmationPassphrase: confirmationPassphrase,
          totpCode: totpCode,
          idempotencyKey: idempotencyKey,
          requestTimestamp: requestTimestamp,
          appPin: appPin,
        );
      }

      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<TxStatus?> _retrySendWithPasskeyChallenge({
    required String initialChallenge,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? fromWalletId,
    String? fromAddress,
    String? context,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
    String? appPin,
  }) async {
    var challenge = initialChallenge;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final assertionJson = await _buildPasskeyAssertionJson(challenge);
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
          appPin: appPin,
        );

        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(depositsProvider);
        ref.invalidate(depositBalanceProvider);
        await ref.read(walletProvider.notifier).refresh();
        state = AsyncActionState(result: result);
        return result;
      } catch (signErr) {
        final renewedChallenge = _extractPasskeyChallenge(signErr);
        if (renewedChallenge == null ||
            renewedChallenge == challenge ||
            attempt == 1) {
          state = AsyncActionState(error: signErr.toString());
          return null;
        }
        challenge = renewedChallenge;
      }
    }
    return null;
  }

  void reset() => state = const AsyncActionState();
}

final sendTransactionProvider =
    NotifierProvider<SendTransactionNotifier, AsyncActionState>(
        SendTransactionNotifier.new);

/// Notifier para Payment Links
class PaymentLinkNotifier extends Notifier<AsyncActionState> {
  late TransactionRepository _repository;

  @override
  AsyncActionState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    return const AsyncActionState();
  }

  Future<PaymentLink?> create({
    required double amount,
    required String receiverWalletName,
    int? expiresIn,
  }) async {
    state = const AsyncActionState(isLoading: true);
    try {
      final result = await _repository.createPaymentLink(
        amount: amount,
        description: 'Recebimento $receiverWalletName',
        expiresInMinutes: 60,
        visibility: 'PRIVATE',
        confirmationMode: 'USER_ACTION_REQUIRED',
        amountLocked: true,
        referenceLabel: receiverWalletName,
        metadata: {
          'walletName': receiverWalletName,
          'rail': 'ONCHAIN',
          'source': 'receive_flow',
        },
      );
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      await ref.read(walletProvider.notifier).refresh();
      state = AsyncActionState(result: result);
      return result;
    } catch (e) {
      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<TxStatus?> pay({
    required String linkId,
    required String payerWalletName,
    String? totpCode,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
    String? appPin,
  }) async {
    state = const AsyncActionState(isLoading: true);
    final operationIdempotencyKey = idempotencyKey?.trim().isNotEmpty == true
        ? idempotencyKey!.trim()
        : const Uuid().v4();
    try {
      final link = await _repository.getPaymentLink(linkId);
      final result = await _repository.withdraw(
        fromWalletName: payerWalletName,
        toAddress: link.depositAddress,
        amount: link.amountBtc,
        description: link.description.isNotEmpty
            ? link.description
            : 'Pagamento de link',
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: passkeyAssertionJson,
        totpCode: totpCode,
        idempotencyKey: operationIdempotencyKey,
        appPin: appPin,
      );
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);
      await ref.read(walletProvider.notifier).refresh();
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
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
    String? appPin,
  }) async {
    state = const AsyncActionState(isLoading: true);
    final operationIdempotencyKey = idempotencyKey?.trim().isNotEmpty == true
        ? idempotencyKey!.trim()
        : const Uuid().v4();
    try {
      final result = await _repository.withdraw(
        fromWalletName: fromWalletName,
        toAddress: toAddress,
        paymentRequest: paymentRequest,
        amount: amount,
        totpCode: totpCode,
        isLightning: isLightning,
        networkFeeBtc: networkFeeBtc,
        maxRoutingFeeBtc: maxRoutingFeeBtc,
        description: description,
        confirmationPassphrase: confirmationPassphrase,
        passkeyAssertionJson: passkeyAssertionJson,
        idempotencyKey: operationIdempotencyKey,
        appPin: appPin,
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
      final challenge = _extractPasskeyChallenge(e);
      if (challenge != null) {
        return _retryWithdrawWithPasskeyChallenge(
          initialChallenge: challenge,
          fromWalletName: fromWalletName,
          toAddress: toAddress,
          paymentRequest: paymentRequest,
          amount: amount,
          totpCode: totpCode,
          isLightning: isLightning,
          networkFeeBtc: networkFeeBtc,
          maxRoutingFeeBtc: maxRoutingFeeBtc,
          description: description,
          confirmationPassphrase: confirmationPassphrase,
          idempotencyKey: operationIdempotencyKey,
          appPin: appPin,
        );
      }

      state = AsyncActionState(error: e.toString());
      return null;
    }
  }

  Future<TxStatus?> _retryWithdrawWithPasskeyChallenge({
    required String initialChallenge,
    required String fromWalletName,
    String? toAddress,
    String? paymentRequest,
    required double amount,
    String? totpCode,
    bool isLightning = false,
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    required String idempotencyKey,
    String? appPin,
  }) async {
    var challenge = initialChallenge;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final assertionJson = await _buildPasskeyAssertionJson(challenge);
        final result = await _repository.withdraw(
          fromWalletName: fromWalletName,
          toAddress: toAddress,
          paymentRequest: paymentRequest,
          amount: amount,
          totpCode: totpCode,
          isLightning: isLightning,
          networkFeeBtc: networkFeeBtc,
          maxRoutingFeeBtc: maxRoutingFeeBtc,
          description: description,
          confirmationPassphrase: confirmationPassphrase,
          passkeyAssertionJson: assertionJson,
          idempotencyKey: idempotencyKey,
          appPin: appPin,
        );

        ref.invalidate(transactionHistoryProvider);
        ref.invalidate(depositsProvider);
        ref.invalidate(depositBalanceProvider);
        ref.invalidate(externalTransfersProvider);
        await ref.read(walletProvider.notifier).refresh();
        state = AsyncActionState(result: result);
        return result;
      } catch (signErr) {
        final renewedChallenge = _extractPasskeyChallenge(signErr);
        if (renewedChallenge == null ||
            renewedChallenge == challenge ||
            attempt == 1) {
          state = AsyncActionState(error: signErr.toString());
          return null;
        }
        challenge = renewedChallenge;
      }
    }
    return null;
  }

  void reset() => state = const AsyncActionState();
}

final withdrawProvider =
    NotifierProvider<WithdrawNotifier, AsyncActionState>(WithdrawNotifier.new);

String? _extractPasskeyChallenge(Object error) {
  const marker = 'PASSKEY_CHALLENGE_REQUIRED:';
  final rawError = error.toString().trim();
  final candidates = <String>[rawError];

  if (error is AppException) {
    candidates.insert(0, error.message);
    _appendPasskeyChallengeCandidates(candidates, error.data);
  } else if (error is Failure) {
    candidates.insert(0, error.message);
    _appendPasskeyChallengeCandidates(candidates, error.data);
  }

  try {
    final decoded = jsonDecode(rawError);
    if (decoded is Map) {
      _appendPasskeyChallengeCandidates(candidates, decoded);
    }
  } catch (_) {}

  final hexPattern = RegExp(
    '${RegExp.escape(marker)}([0-9a-fA-F]+)',
  );

  for (final candidate in candidates) {
    final trimmedCandidate = candidate.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(trimmedCandidate)) {
      return trimmedCandidate;
    }

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

void _appendPasskeyChallengeCandidates(List<String> candidates, Object? value) {
  if (value == null) {
    return;
  }

  if (value is Map) {
    for (final key in const ['challenge', 'message', 'error', 'guidance']) {
      final candidate = value[key]?.toString().trim();
      if (candidate != null && candidate.isNotEmpty) {
        candidates.add(candidate);
      }
    }
    _appendPasskeyChallengeCandidates(candidates, value['data']);
    return;
  }

  if (value is Iterable) {
    for (final item in value) {
      _appendPasskeyChallengeCandidates(candidates, item);
    }
    return;
  }

  final candidate = value.toString().trim();
  if (candidate.isNotEmpty) {
    candidates.add(candidate);
  }
}

Future<String> _buildPasskeyAssertionJson(String challenge) async {
  final credential = await PasskeyService.instance.authenticate(
    challengeHex: challenge,
    username: 'transaction',
  );
  return jsonEncode(credential);
}
