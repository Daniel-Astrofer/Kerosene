import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/network/api_client_provider.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_local_store.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';

final bitcoinAccountsServiceProvider = Provider<BitcoinAccountsService>((ref) {
  return BitcoinAccountsService(ref.watch(apiClientProvider));
});

final bitcoinAccountsLocalStoreProvider =
    Provider<BitcoinAccountsLocalStore>((ref) {
  return BitcoinAccountsLocalStore();
});

final bitcoinAccountsProvider =
    AsyncNotifierProvider<BitcoinAccountsNotifier, List<BitcoinAccount>>(
  BitcoinAccountsNotifier.new,
);

class BitcoinAccountsNotifier extends AsyncNotifier<List<BitcoinAccount>> {
  late final BitcoinAccountsService _service;

  @override
  Future<List<BitcoinAccount>> build() async {
    _service = ref.watch(bitcoinAccountsServiceProvider);
    return _service.listAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.listAccounts);
  }

  Future<void> createInternalCard(String label) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.createInternalCard(label: label);
      return _service.listAccounts();
    });
  }

  Future<void> importColdWallet({
    required String label,
    String? descriptor,
    String? xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.importColdWallet(
        label: label,
        descriptor: descriptor,
        xpub: xpub,
        fingerprint: fingerprint,
        derivationPath: derivationPath,
        scriptPolicy: scriptPolicy,
      );
      return _service.listAccounts();
    });
  }
}
