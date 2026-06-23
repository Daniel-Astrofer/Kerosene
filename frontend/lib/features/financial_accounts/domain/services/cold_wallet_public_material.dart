import 'package:bip39/bip39.dart' as bip39;
import 'package:blockchain_utils/blockchain_utils.dart';

const defaultColdWalletDerivationPath = "m/84'/0'/0'";
const defaultColdWalletScriptPolicy = 'wpkh';

class ColdWalletPublicMaterial {
  final String xpub;
  final String fingerprint;
  final String derivationPath;
  final String scriptPolicy;

  const ColdWalletPublicMaterial({
    required this.xpub,
    required this.fingerprint,
    this.derivationPath = defaultColdWalletDerivationPath,
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
  }) {
    final normalizedMnemonic = mnemonic.trim().toLowerCase();
    if (!bip39.validateMnemonic(normalizedMnemonic)) {
      throw ArgumentError.value(
          mnemonic, 'mnemonic', 'Invalid BIP39 mnemonic.');
    }

    final seed = bip39.mnemonicToSeed(
      normalizedMnemonic,
      passphrase: extraWord.trim(),
    );
    try {
      final root = Bip32Slip10Secp256k1.fromSeed(seed);
      final account = root.derivePath(defaultColdWalletDerivationPath);
      final xpub = account.publicKey.toExtended;
      final fingerprint = root.fingerPrint.toHex();

      return ColdWalletPublicMaterial(
        xpub: xpub,
        fingerprint: fingerprint,
        scriptPolicy: _watchOnlyDescriptor(
          fingerprint: fingerprint,
          xpub: xpub,
        ),
      );
    } finally {
      seed.fillRange(0, seed.length, 0);
    }
  }

  String _watchOnlyDescriptor({
    required String fingerprint,
    required String xpub,
  }) {
    final accountPath = defaultColdWalletDerivationPath
        .replaceFirst(RegExp(r'^m/'), '')
        .replaceAll("'", 'h');
    return '$defaultColdWalletScriptPolicy([$fingerprint/$accountPath]$xpub/0/*)';
  }
}
