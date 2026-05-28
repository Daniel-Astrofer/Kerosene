import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('critical mobile ARB keys keep the same placeholders', () {
    final root = Directory.current;
    final en = _loadArb('${root.path}/lib/core/l10n/app_en.arb');
    final pt = _loadArb('${root.path}/lib/core/l10n/app_pt.arb');
    final es = _loadArb('${root.path}/lib/core/l10n/app_es.arb');

    final criticalKeys = <String>{
      ..._messageKeys(en).where(
        (key) =>
            key.startsWith('apiDisplay') ||
            key.startsWith('appEntry') ||
            key.startsWith('auth') ||
            key.startsWith('depositFlow') ||
            key.startsWith('depositInstructions') ||
            key.startsWith('depositLedger') ||
            key.startsWith('depositLightning') ||
            key.startsWith('depositQr') ||
            key.startsWith('detail') ||
            key.startsWith('home') ||
            key.startsWith('mining') ||
            key.startsWith('onchainDeposit') ||
            key.startsWith('paymentConfirmation') ||
            key.startsWith('profile') ||
            key.startsWith('receiveQr') ||
            key.startsWith('receiveHub') ||
            key.startsWith('receivePaymentLink') ||
            key.startsWith('receiveScreen') ||
            key.startsWith('security') ||
            key.startsWith('sendMoney') ||
            key.startsWith('settingsUi') ||
            key.startsWith('transactionVisual') ||
            key.startsWith('withdrawReceipt') ||
            key.startsWith('withdrawUi') ||
            key.startsWith('walletCard') ||
            key.startsWith('walletConfig'),
      ),
      ..._criticalErrorKeys,
    };

    for (final key in criticalKeys) {
      expect(pt.containsKey(key), isTrue, reason: 'pt missing $key');
      expect(es.containsKey(key), isTrue, reason: 'es missing $key');
      expect(_placeholders(pt, key), _placeholders(en, key), reason: key);
      expect(_placeholders(es, key), _placeholders(en, key), reason: key);
    }
  });
}

const _criticalErrorKeys = <String>{
  'errInvalidNetworkAddress',
  'errCustodyProviderUnavailable',
  'errPayloadTooLarge',
  'errPasskeyDeviceNotLinked',
  'errPasskeyRequired',
  'errPasskeyWrongDevice',
  'errPasskeyRejected',
  'errPasskeyLinkGuidance',
  'errReceiverNotReady',
  'errOnchainReceiverMethodNotFound',
  'errOnchainInvalidAddress',
  'errOnchainAmountBelowDust',
  'errOnchainInsufficientFundsForFee',
  'errLightningInsufficientLiquidity',
  'errLightningRouteNotFound',
  'errLightningReceiverMethodNotFound',
  'errQuoteExpired',
  'errQuoteChanged',
  'errNetAmountNegative',
  'errInsufficientBalanceForFees',
};

Map<String, dynamic> _loadArb(String path) {
  final raw = File(path).readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) {
  return arb.keys
      .where((key) => !key.startsWith('@') && key != '@@locale')
      .toSet();
}

Set<String> _placeholders(Map<String, dynamic> arb, String key) {
  final metadata = arb['@$key'];
  if (metadata is! Map<String, dynamic>) {
    return const {};
  }
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, dynamic>) {
    return const {};
  }
  return placeholders.keys.toSet();
}
