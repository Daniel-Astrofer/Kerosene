import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../auth/controller/auth_controller.dart'
    show sessionStorageScopeProvider;
import 'package:kerosene/features/financial_accounts/application/providers/bitcoin_accounts_service_provider.dart';
import 'package:kerosene/features/financial_accounts/domain/services/bitcoin_accounts_service.dart';
export 'package:kerosene/features/financial_accounts/application/providers/bitcoin_accounts_service_provider.dart';

const int maxActiveColdWallets = 2;

class BitcoinAccountsNotifier extends AsyncNotifier<List<BitcoinAccount>> {
  late BitcoinAccountsService _service;

  @override
  Future<List<BitcoinAccount>> build() async {
    final sessionScope = ref.watch(sessionStorageScopeProvider);
    _service = ref.watch(bitcoinAccountsServiceProvider);
    if (sessionScope == null) {
      return const <BitcoinAccount>[];
    }
    return _service.listAccounts();
  }

  Future<void> refresh() async {
    final previousAccounts = state.asData?.value ?? const <BitcoinAccount>[];
    state = const AsyncLoading<List<BitcoinAccount>>();
    try {
      state = AsyncValue.data(await _service.listAccounts());
    } catch (error, stackTrace) {
      if (previousAccounts.isNotEmpty) {
        state = AsyncValue.data(previousAccounts);
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<BitcoinAccount> createInternalCard({
    required String label,
  }) async {
    return createWallet(
      label: label,
      custody: BitcoinAccountCustody.internal,
    );
  }

  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  }) async {
    final previousAccounts = state.asData?.value ?? const <BitcoinAccount>[];
    try {
      _ensureCustodyAvailable(custody);
      final created = await _service.createWallet(
        label: label,
        custody: custody,
      );
      await _refreshAfterMutation(
        fallbackAccounts: _mergeAccount(previousAccounts, created),
      );
      return created;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final previousAccounts = state.asData?.value ?? const <BitcoinAccount>[];
    try {
      _ensureCustodyAvailable(BitcoinAccountCustody.watchOnly);
      final imported = await _service.importColdWallet(
        label: label,
        xpub: xpub,
        fingerprint: fingerprint,
        derivationPath: derivationPath,
        scriptPolicy: scriptPolicy,
      );
      await _refreshAfterMutation(
        fallbackAccounts: _mergeAccount(previousAccounts, imported),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<ReceivingRequestView> rotateReceiveAddress({
    required String accountId,
  }) async {
    final rotated = await _service.rotateReceiveAddress(accountId);
    state = await AsyncValue.guard(_service.listAccounts);
    return rotated;
  }

  Future<void> renameWallet({
    required String accountId,
    required String label,
  }) async {
    state = await AsyncValue.guard(() async {
      await _service.renameWallet(accountId: accountId, label: label);
      return _service.listAccounts();
    });
  }

  Future<void> archiveWallet({
    required String accountId,
  }) async {
    state = await AsyncValue.guard(() async {
      await _service.archiveWallet(accountId);
      return _service.listAccounts();
    });
  }

  void _ensureCustodyAvailable(BitcoinAccountCustody custody) {
    final accounts = state.asData?.value ?? const <BitcoinAccount>[];
    final activeWallets = accounts
        .where((account) =>
            account.isActive && _accountMatchesCustody(account, custody))
        .length;
    final maxWallets =
        custody == BitcoinAccountCustody.watchOnly ? maxActiveColdWallets : 1;
    if (activeWallets >= maxWallets) {
      throw ValidationException(
        message: custody == BitcoinAccountCustody.watchOnly
            ? 'Voce pode criar no maximo duas carteiras frias.'
            : 'Ja existe uma carteira ativa para este metodo de custodia.',
        statusCode: 409,
        errorCode: 'ERR_WALLET_CUSTODY_ALREADY_EXISTS',
      );
    }
  }

  bool _accountMatchesCustody(
    BitcoinAccount account,
    BitcoinAccountCustody custody,
  ) {
    return switch (custody) {
      BitcoinAccountCustody.internal =>
        account.isInternal && !account.isCustodialOnchain,
      BitcoinAccountCustody.custodialOnchain => account.isCustodialOnchain,
      BitcoinAccountCustody.watchOnly => account.isWatchOnly,
    };
  }

  Future<void> _refreshAfterMutation({
    required List<BitcoinAccount> fallbackAccounts,
  }) async {
    try {
      final refreshed = await _service.listAccounts();
      state = AsyncValue.data(_mergeAccounts(refreshed, fallbackAccounts));
    } catch (_) {
      state = AsyncValue.data(fallbackAccounts);
    }
  }

  List<BitcoinAccount> _mergeAccount(
    List<BitcoinAccount> accounts,
    BitcoinAccount account,
  ) {
    return _mergeAccounts(accounts, [account]);
  }

  List<BitcoinAccount> _mergeAccounts(
    List<BitcoinAccount> primary,
    List<BitcoinAccount> fallback,
  ) {
    final byId = <String, BitcoinAccount>{
      for (final account in primary) account.id: account,
    };
    for (final account in fallback) {
      if (account.id.trim().isEmpty) {
        continue;
      }
      byId.putIfAbsent(account.id, () => account);
    }
    return byId.values.toList(growable: false);
  }
}

final bitcoinAccountsProvider =
    AsyncNotifierProvider<BitcoinAccountsNotifier, List<BitcoinAccount>>(
  BitcoinAccountsNotifier.new,
);

final bitcoinAccountReceiveRequestsProvider =
    FutureProvider.family<List<ReceivingRequestView>, String>(
        (ref, accountId) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <ReceivingRequestView>[];
  }

  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listReceiveRequestsForAccount(accountId);
});

final bitcoinColdWalletUtxosProvider =
    FutureProvider.family<List<ColdWalletUtxoView>, String>(
        (ref, coldWalletId) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <ColdWalletUtxoView>[];
  }

  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listColdWalletUtxos(coldWalletId);
});

final bitcoinColdWalletPsbtsProvider =
    FutureProvider.family<List<PsbtWorkflowView>, String>(
        (ref, coldWalletId) async {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <PsbtWorkflowView>[];
  }

  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listColdWalletPsbt(coldWalletId);
});

final kfeTaxEventsProvider = FutureProvider<List<TaxEventView>>((ref) {
  final sessionScope = ref.watch(sessionStorageScopeProvider);
  if (sessionScope == null) {
    return const <TaxEventView>[];
  }

  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listTaxEvents();
});
