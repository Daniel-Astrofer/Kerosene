

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:blockchain_utils/blockchain_utils.dart';



class Bip39{


  static String createPhrase({required MnemonicLength length,   }){

    final mnemonic = Mnemonic.generate(
      Language.portuguese,
      length: length,
    );
    return mnemonic.sentence;
  }

  static bool validatePasspharse({required String passphrase }){

    final result = Bip39MnemonicValidator();
    return result.isValid(passphrase);

}

}




