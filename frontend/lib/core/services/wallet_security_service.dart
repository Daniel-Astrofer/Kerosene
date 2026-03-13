import 'package:flutter/foundation.dart';
import 'package:blockchain_utils/blockchain_utils.dart'; // Using blockchain_utils as alternative to bitcoin_flutter
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter/services.dart';

import '../security/secure_storage_service.dart';
import '../security/biometric_service.dart';

class WalletSecurityService {
  final SecureStorageService _storageService;
  final BiometricService _biometricService;

  WalletSecurityService({
    SecureStorageService? storageService,
    BiometricService? biometricService,
  }) : _storageService = storageService ?? SecureStorageService(),
       _biometricService = biometricService ?? BiometricService();

  static const String _mnemonicKey = 'secure_mnemonic';

  /// Checks if the device is secure (Not Jailbroken/Rooted)
  Future<bool> isDeviceSecure() async {
    try {
      bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      // bool developerMode = await FlutterJailbreakDetection.developerMode; // Optional check
      return !jailbroken;
    } on PlatformException {
      return false;
    }
  }

  /// Criptografa e salva a frase mnemônica no hardware seguro
  Future<bool> saveMnemonic(String mnemonic) async {
    try {
      await _storageService.write(key: _mnemonicKey, value: mnemonic);
      return true;
    } catch (e) {
      debugPrint('Error saving mnemonic: $e');
      return false;
    }
  }

  /// Tenta autenticar o usuário via Biometria ou PIN e retorna o mnemônico
  Future<String?> authenticateAndGetMnemonic() async {
    try {
      // 1. Verifica se o hardware suporta biometria
      final bool canAuthenticate = await _biometricService.canAuthenticate();

      if (!canAuthenticate) {
        debugPrint('Device not supported for authentication');
        // Se não suportar, talvez possamos retornar o mnemonico direto se estiver salvo?
        // OU exigir PIN do app (não nativo).
        // Por segurança, vamos assumir que falha se não puder autenticar nativamente.
        // MAS, em emuladores isso pode falhar.
        // Vamos tentar ler mesmo assim? Não, a ideia é proteger.
        // Fallback: Se não tem biometria, o sistema deve pedir PIN/Senha/Padrao (handled by local_auth).
        // Se o device não tem NENHUMA segurança, local_auth retorna false para canAuthenticate?
        // isDeviceSupported() retorna true se tiver lockscreen.
        return null;
      }

      // 2. Dispara o diálogo nativo
      final bool didAuthenticate = await _biometricService.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar sua carteira',
      );

      if (didAuthenticate) {
        // 3. Recupera do storage seguro
        return await _storageService.read(key: _mnemonicKey);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      return null;
    }
  }

  /// Assina uma transação Bitcoin (Hex) usando o mnemônico recuperado
  /// Implementa lógica de 'Clean Memory' para o mnemônico
  Future<String?> signTransaction({
    required String mnemonic,
    required String txHex,
    // required int inputIndex, // Not used in this simplified example
  }) async {
    // Escopo limitado para garantir limpeza de memória (best effort em Dart GC)
    String? secretMnemonic = mnemonic;
    Uint8List? seed;

    try {
      // 1. Validar mnemônico
      if (!bip39.validateMnemonic(secretMnemonic)) {
        throw Exception('Invalid Mnemonic');
      }

      // 2. Derivar Seed e Chaves
      // Usando blockchain_utils para Bitcoin
      seed = bip39.mnemonicToSeed(secretMnemonic);
      final root = Bip32Slip10Secp256k1.fromSeed(seed);

      // Derivation Path para Native Segwit (BIP84): m/84'/0'/0'/0/0
      // Ajuste conforme necessidade (Legacy m/44' etc)
      final childKey = root.derivePath("m/84'/0'/0'/0/0");
      final privateKey = childKey.privateKey;

      // 3. Assinar
      // A biblioteca blockchain_utils permite assinar dados.
      // Supondo que txHex seja o hash da transação a ser assinada (sighash)
      final txBytes = BytesUtils.fromHexString(txHex);

      // Assinatura ECDSA
      final signer = BitcoinSigner.fromKeyBytes(privateKey.raw);
      final signature = signer.signTransaction(txBytes);

      // Retornar assinatura em Hex
      return BytesUtils.toHexString(signature);
    } catch (e) {
      debugPrint('Signing error: $e');
      return null;
    } finally {
      // Clean Memory Logic
      // Zero out seed
      if (seed != null) {
        for (int i = 0; i < seed.length; i++) {
          seed[i] = 0;
        }
      }

      secretMnemonic = null;
    }
  }

  Future<String?> getAddressFromMnemonic(String mnemonic) async {
    try {
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = Bip32Slip10Secp256k1.fromSeed(seed);
      // Using Native Segwit (BIP84) as standard
      final privateKey = root.derivePath("m/84'/0'/0'/0/0");
      final publicKey = privateKey.publicKey;

      // P2WPKH Address
      final pubKeyHash = QuickCrypto.hash160(publicKey.compressed);
      return SegwitBech32Encoder.encode("bc", 0, pubKeyHash);
    } catch (e) {
      debugPrint('Error deriving address: $e');
      return null;
    }
  }

  /// Limpa o mnemônico do storage (Logout)
  Future<void> clearMnemonic() async {
    await _storageService.delete(key: _mnemonicKey);
  }
}
