import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

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
    final digest = sha256.convert(seed).bytes;
    final xpubBody = base64UrlEncode(digest).replaceAll('=', '');
    final fingerprint =
        sha256.convert(utf8.encode(xpubBody)).toString().substring(0, 8);

    seed.fillRange(0, seed.length, 0);

    return ColdWalletPublicMaterial(
      xpub: 'xpub$xpubBody',
      fingerprint: fingerprint,
    );
  }
}
