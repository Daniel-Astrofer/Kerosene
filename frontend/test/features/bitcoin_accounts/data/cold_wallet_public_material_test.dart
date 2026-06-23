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

    expect(
      material.xpub,
      'xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XyuvPEbvqAQY3rAPshWcMLoP2fMFMKHPJ4ZeZXYVUhLv1VMrjPC7PW6V',
    );
    expect(material.xpub, repeated.xpub);
    expect(material.fingerprint, '73c5da0a');
    expect(material.derivationPath, defaultColdWalletDerivationPath);
    expect(
      material.scriptPolicy,
      'wpkh([73c5da0a/84h/0h/0h]xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XyuvPEbvqAQY3rAPshWcMLoP2fMFMKHPJ4ZeZXYVUhLv1VMrjPC7PW6V/0/*)',
    );
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
    expect(
      withExtra.xpub,
      'xpub6CZsUXuo6AkJUfxbpYgeUt8LSFBYhWJJ2FR4ttk2wEHjE5z7ZrryvnSbQ14jqpgtWJob5sPuB3cSf8rrwDxmG11YDWY13cX9p3sfu6Tcgtb',
    );
    expect(withExtra.fingerprint, '31d167f4');
  });
}
