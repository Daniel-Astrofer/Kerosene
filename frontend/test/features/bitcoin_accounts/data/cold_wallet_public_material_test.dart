import 'package:kerosene/features/bitcoin_accounts/data/cold_wallet_public_material.dart';
import 'package:test/test.dart';

void main() {
  test('derives public watch-only material without exposing the seed', () {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const deriver = ColdWalletPublicMaterialDeriver();

    final material = deriver.derive(mnemonic: mnemonic);
    final repeated = deriver.derive(mnemonic: mnemonic);
    final payload = material.toImportPayload();

    expect(material.xpub, startsWith('xpub'));
    expect(material.xpub, repeated.xpub);
    expect(material.fingerprint, hasLength(8));
    expect(material.derivationPath, defaultColdWalletDerivationPath);
    expect(material.scriptPolicy, defaultColdWalletScriptPolicy);
    expect(payload.keys, isNot(contains('mnemonic')));
    expect(payload.keys, isNot(contains('seed')));
    expect(payload.keys, isNot(contains('extraWord')));
    expect(payload.values.join(' '), isNot(contains('abandon')));
  });

  test('uses the optional extra word in public material derivation', () {
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const deriver = ColdWalletPublicMaterialDeriver();

    final standard = deriver.derive(mnemonic: mnemonic);
    final withExtra = deriver.derive(
      mnemonic: mnemonic,
      extraWord: 'offline-only',
    );

    expect(withExtra.xpub, isNot(standard.xpub));
    expect(withExtra.fingerprint, isNot(standard.fingerprint));
  });
}
