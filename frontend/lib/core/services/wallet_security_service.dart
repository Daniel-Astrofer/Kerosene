import 'package:flutter/foundation.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:safe_device/safe_device.dart';

import '../security/secure_storage_service.dart';
import '../security/biometric_service.dart';

class WalletSecurityService {
  final SecureStorageService _storageService;
  final BiometricService _biometricService;

  WalletSecurityService({
    SecureStorageService? storageService,
    BiometricService? biometricService,
  })  : _storageService = storageService ?? SecureStorageService(),
        _biometricService = biometricService ?? BiometricService();

  static const String _mnemonicKey = 'secure_mnemonic';

  /// Verifica integridade: Bloqueia Root/Jailbreak e Emuladores
  Future<bool> isDeviceSecure() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      bool isRealDevice = await SafeDevice.isRealDevice;
      return !isJailBroken && isRealDevice;
    } catch (e) {
      return false; // Fail safe: bloqueia em caso de erro
    }
  }

  String _mnemonicStorageKey(String? storageScope) {
    final scope = storageScope?.trim();
    if (scope == null || scope.isEmpty) {
      return _mnemonicKey;
    }
    return '${_mnemonicKey}_$scope';
  }

  Future<bool> saveMnemonic(String mnemonic, {String? storageScope}) async {
    try {
      await _storageService.write(
        key: _mnemonicStorageKey(storageScope),
        value: mnemonic,
      );

      if (storageScope != null && storageScope.trim().isNotEmpty) {
        await _storageService.delete(key: _mnemonicKey);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving mnemonic: $e');
      return false;
    }
  }

  Future<String?> authenticateAndGetMnemonic({String? storageScope}) async {
    try {
      final bool canAuthenticate = await _biometricService.canAuthenticate();
      if (!canAuthenticate) return null;

      final bool didAuthenticate = await _biometricService.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar sua carteira',
      );

      if (didAuthenticate) {
        return await _storageService.read(
          key: _mnemonicStorageKey(storageScope),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> signTransaction({
    required String mnemonic,
    required String txHex,
  }) async {
    Uint8List? seed;
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid Mnemonic');
      }
      seed = bip39.mnemonicToSeed(mnemonic);
      final root = Bip32Slip10Secp256k1.fromSeed(seed);
      final childKey = root.derivePath("m/84'/0'/0'/0/0");
      final txBytes = BytesUtils.fromHexString(txHex);
      // ignore: deprecated_member_use
      final signature = BitcoinSigner.fromKeyBytes(childKey.privateKey.raw)
          .signTransaction(txBytes);
      return BytesUtils.toHexString(signature);
    } catch (e) {
      return null;
    } finally {
      if (seed != null) seed.fillRange(0, seed.length, 0); // Wipe da RAM
    }
  }

  Future<String?> getAddressFromMnemonic(String mnemonic) async {
    try {
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = Bip32Slip10Secp256k1.fromSeed(seed);
      final privateKey = root.derivePath("m/84'/0'/0'/0/0");
      final pubKeyHash = QuickCrypto.hash160(privateKey.publicKey.compressed);
      return SegwitBech32Encoder.encode("bc", 0, pubKeyHash);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearMnemonic({String? storageScope}) async {
    await _storageService.delete(key: _mnemonicStorageKey(storageScope));
    if (storageScope != null && storageScope.trim().isNotEmpty) {
      await _storageService.delete(key: _mnemonicKey);
    }
  }
}
