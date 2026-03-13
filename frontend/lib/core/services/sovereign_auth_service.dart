import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Service to handle "Sovereign Auth" using hardware-bound Ed25519 keys
/// and biometric verification.
class SovereignAuthService {
  static const String _keySeedStorageKey = 'sovereign_auth_seed';
  static const String _publicKeyStorageKey = 'sovereign_auth_pubkey';

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _algorithm = Ed25519();

  /// singleton
  static final SovereignAuthService instance = SovereignAuthService._internal();
  SovereignAuthService._internal();

  /// Generates a new Ed25519 key pair and stores it securely.
  /// returns the Base64 encoded public key.
  Future<String> generateKeyPair() async {
    try {
      // 1. Generate a random 32-byte seed
      final keyPair = await _algorithm.newKeyPair();
      final seed = await keyPair.extractPrivateKeyBytes();
      final pubKey = await keyPair.extractPublicKey();
      
      final seedBase64 = base64Encode(seed);
      final pubKeyBase64 = base64Encode(pubKey.bytes);

      // 2. Store in secure storage
      await _storage.write(key: _keySeedStorageKey, value: seedBase64);
      await _storage.write(key: _publicKeyStorageKey, value: pubKeyBase64);

      debugPrint('🔐 [SovereignAuth] New Ed25519 key pair generated and stored.');
      return pubKeyBase64;
    } catch (e) {
      debugPrint('❌ [SovereignAuth] Error generating key pair: $e');
      rethrow;
    }
  }

  /// Gets the stored public key (Base64). Returns null if not exists.
  Future<String?> getPublicKey() async {
    return await _storage.read(key: _publicKeyStorageKey);
  }

  /// Signs a hex-encoded challenge using the stored private key.
  /// Requires biometric authentication.
  /// Returns the Base64 encoded signature.
  Future<String> signChallenge(String hexChallenge) async {
    try {
      // 1. Authenticate user biometrically
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para assinar o desafio de segurança.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) {
        throw Exception('Biometric authentication failed or canceled.');
      }

      // 2. Load seed from storage
      final seedBase64 = await _storage.read(key: _keySeedStorageKey);
      if (seedBase64 == null) {
        throw Exception('Sovereign Auth key not found. Please register first.');
      }

      final seed = base64Decode(seedBase64);
      final keyPair = await _algorithm.newKeyPairFromSeed(seed);

      // 3. Convert hex challenge to bytes
      final challengeBytes = _hexToBytes(hexChallenge);

      // 4. Sign
      final signature = await _algorithm.sign(
        challengeBytes,
        keyPair: keyPair,
      );

      final signatureBase64 = base64Encode(signature.bytes);
      debugPrint('🔐 [SovereignAuth] Challenge signed successfully.');
      return signatureBase64;
    } catch (e) {
      debugPrint('❌ [SovereignAuth] Error signing challenge: $e');
      rethrow;
    }
  }

  /// Helper to convert hex string to Uint8List
  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    if (hex.length % 2 != 0) hex = '0$hex';
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
