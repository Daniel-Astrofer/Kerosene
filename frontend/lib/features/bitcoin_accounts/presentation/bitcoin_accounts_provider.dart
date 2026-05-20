import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bitcoin_accounts_service.dart';

final bitcoinAccountsServiceProvider = Provider<BitcoinAccountsService>((ref) {
  return LocalBitcoinAccountsService();
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
    required int dailyLimitSats,
  }) async {
    state = await AsyncValue.guard(() async {
      await _service.createInternalCard(
        label: label,
        dailyLimitSats: dailyLimitSats,
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
