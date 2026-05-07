import 'package:bip39/bip39.dart' as bip39;
import 'package:blockchain_utils/blockchain_utils.dart';

const String defaultColdWalletDerivationPath = "m/84'/0'/0'";
const String defaultColdWalletScriptPolicy = 'SINGLE_SIG';

class ColdWalletPublicMaterial {
  final String xpub;
  final String fingerprint;
  final String derivationPath;
  final String scriptPolicy;

  const ColdWalletPublicMaterial({
    required this.xpub,
    required this.fingerprint,
    required this.derivationPath,
    this.scriptPolicy = defaultColdWalletScriptPolicy,
  });

  Map<String, String> toImportPayload() => {
        'xpub': xpub,
        'fingerprint': fingerprint,
        'derivationPath': derivationPath,
        'scriptPolicy': scriptPolicy,
      };
}

class ColdWalletPublicMaterialDeriver {
  const ColdWalletPublicMaterialDeriver();

  ColdWalletPublicMaterial derive({
    required String mnemonic,
    String extraWord = '',
    String derivationPath = defaultColdWalletDerivationPath,
  }) {
    final normalizedMnemonic = mnemonic.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (!bip39.validateMnemonic(normalizedMnemonic)) {
      throw const FormatException('Invalid BIP39 recovery phrase.');
    }

    final seed = bip39.mnemonicToSeed(
      normalizedMnemonic,
      passphrase: extraWord,
    );
    try {
      final root = Bip32Slip10Secp256k1.fromSeed(seed);
      final accountKey = root.derivePath(derivationPath);
      return ColdWalletPublicMaterial(
        xpub: accountKey.publicKey.toExtended,
        fingerprint: root.fingerPrint.toHex(),
        derivationPath: derivationPath,
      );
    } finally {
      seed.fillRange(0, seed.length, 0);
    }
  }
}
