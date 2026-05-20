import 'dart:math';

import 'bitcoin_account_models.dart';
import 'bitcoin_accounts_local_store.dart';

export 'bitcoin_account_models.dart';

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
  });

  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  });

  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  });

  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  );

  Future<ReceivingRequestView> getReceiveStatus(String requestId);
}

class LocalBitcoinAccountsService implements BitcoinAccountsService {
  LocalBitcoinAccountsService({BitcoinAccountsLocalStore? store})
      : _store = store ?? BitcoinAccountsLocalStore();

  final BitcoinAccountsLocalStore _store;

  @override
  Future<List<BitcoinAccount>> listAccounts() {
    return _store.loadAccounts();
  }

  @override
  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
  }) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final account = BitcoinAccount(
      id: 'internal-$now',
      type: 'INTERNAL_CARD',
      custody: 'KEROSENE_CUSTODIAL',
      status: 'ACTIVE',
      label: label.trim().isEmpty ? 'Kerosene BTC Card' : label.trim(),
      riskTier: 'BRONZE',
      cardId: 'card-$now',
      dailyLimitSats: dailyLimitSats,
    );
    await _store.upsertAccount(account);
    return account;
  }

  @override
  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final account = BitcoinAccount(
      id: 'watch-$now',
      type: 'WATCH_ONLY_COLD_WALLET',
      custody: 'WATCH_ONLY',
      status: 'ACTIVE',
      label: label.trim().isEmpty ? 'Cold Wallet' : label.trim(),
      riskTier: 'WATCH_ONLY',
      coldWalletId: 'cold-$now',
      xpubFingerprint: fingerprint,
      derivationPath: derivationPath,
      scriptPolicy: scriptPolicy,
    );
    await _store.upsertAccount(account);
    return account;
  }

  @override
  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  }) async {
    final now = DateTime.now();
    final entropy = Random(now.microsecondsSinceEpoch).nextInt(1 << 32);
    final id = 'receive-${now.microsecondsSinceEpoch}';
    final address = 'bc1qkerosene${entropy.toRadixString(16).padLeft(8, '0')}';
    final amountBtc = amountSats == null ? null : amountSats / 100000000;
    final bip21 = amountBtc == null
        ? 'bitcoin:$address'
        : 'bitcoin:$address?amount=${amountBtc.toStringAsFixed(8)}';
    final request = ReceivingRequestView(
      id: id,
      accountId: accountId,
      address: address,
      bip21: bip21,
      status: 'ACTIVE',
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
      createdAt: now,
    );
    await _store.upsertReceiveRequest(request);
    return request;
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    final request = await _store.findReceiveRequest(requestId);
    if (request == null) {
      throw StateError('Receive request not found');
    }
    return request;
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) {
    return _store.loadReceiveRequestsForAccount(accountId);
  }
}
