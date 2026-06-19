import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client_provider.dart';
import '../data/bitcoin_accounts_service.dart';

final bitcoinAccountsServiceProvider = Provider<BitcoinAccountsService>((ref) {
  return RemoteBitcoinAccountsService(ref.watch(apiClientProvider));
});

class BitcoinAccountsNotifier extends AsyncNotifier<List<BitcoinAccount>> {
  late BitcoinAccountsService _service;

  @override
  Future<List<BitcoinAccount>> build() async {
    _service = ref.watch(bitcoinAccountsServiceProvider);
    return _service.listAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BitcoinAccount>>();
    state = await AsyncValue.guard(_service.listAccounts);
  }

  Future<void> createInternalCard({
    required String label,
  }) async {
    await createWallet(
      label: label,
      custody: BitcoinAccountCustody.internal,
    );
  }

  Future<void> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  }) async {
    state = await AsyncValue.guard(() async {
      _ensureCustodyAvailable(custody);
      await _service.createWallet(
        label: label,
        custody: custody,
      );
      return _service.listAccounts();
    });
  }

  Future<void> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    state = await AsyncValue.guard(() async {
      _ensureCustodyAvailable(BitcoinAccountCustody.watchOnly);
      await _service.importColdWallet(
        label: label,
        xpub: xpub,
        fingerprint: fingerprint,
        derivationPath: derivationPath,
        scriptPolicy: scriptPolicy,
      );
      return _service.listAccounts();
    });
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
    final exists = accounts.any((account) {
      if (!account.isActive) {
        return false;
      }
      return _accountMatchesCustody(account, custody);
    });
    if (exists) {
      throw ValidationException(
        message: 'Ja existe uma carteira ativa para este metodo de custodia.',
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
}

final bitcoinAccountsProvider =
    AsyncNotifierProvider<BitcoinAccountsNotifier, List<BitcoinAccount>>(
  BitcoinAccountsNotifier.new,
);

final bitcoinAccountReceiveRequestsProvider =
    FutureProvider.family<List<ReceivingRequestView>, String>(
        (ref, accountId) async {
  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listReceiveRequestsForAccount(accountId);
});

final bitcoinColdWalletUtxosProvider =
    FutureProvider.family<List<ColdWalletUtxoView>, String>(
        (ref, coldWalletId) async {
  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listColdWalletUtxos(coldWalletId);
});

final bitcoinColdWalletPsbtsProvider =
    FutureProvider.family<List<PsbtWorkflowView>, String>(
        (ref, coldWalletId) async {
  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listColdWalletPsbt(coldWalletId);
});

final kfeTaxEventsProvider = FutureProvider<List<TaxEventView>>((ref) {
  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listTaxEvents();
});
