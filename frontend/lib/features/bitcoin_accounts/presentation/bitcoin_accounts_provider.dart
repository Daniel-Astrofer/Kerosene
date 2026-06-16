import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = await AsyncValue.guard(() async {
      await _service.createInternalCard(
        label: label,
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

final bitcoinTaxEventsProvider = FutureProvider<List<TaxEventView>>((ref) {
  final service = ref.watch(bitcoinAccountsServiceProvider);
  return service.listTaxEvents();
});
