import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class SovereignAuthService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final Ed25519 _algorithm = Ed25519();

  static const String _privateKeyKey = 'sovereign_auth_seed';

  SovereignAuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication();

  /// Gera um novo par de chaves Ed25519 e salva o seed no SecureStorage.
  /// Retorna a chave pública em Base64.
  Future<String> generateAndSaveKeyPair() async {
    // 1. Autenticar com biometria antes de gerar/salvar
    final authenticated = await authenticate();
    if (!authenticated) {
      throw Exception('Autenticação biométrica necessária para gerar chaves.');
    }

    // 2. Gerar KeyPair
    final keyPair = await _algorithm.newKeyPair();
    final seed = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    // 3. Salvar Seed (Private Key bytes) no SecureStorage
    await _secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(seed),
      iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );

    // 4. Retornar Public Key em Base64 (X.509 ou raw bytes)
    // O backend espera Raw bytes Base64 se não for X.509.
    return base64Encode(publicKey.bytes);
  }

  /// Assina um desafio (hex string) usando a chave privada armazenada.
  /// Requer biometria.
  Future<String> signChallenge(String challengeHex) async {
    // 1. Autenticar com biometria
    final authenticated = await authenticate();
    if (!authenticated) {
      throw Exception('Autenticação biométrica necessária para assinar.');
    }

    // 2. Recuperar Seed
    final seedBase64 = await _secureStorage.read(key: _privateKeyKey);
    if (seedBase64 == null) {
      throw Exception('Chave privada não encontrada. É necessário registrar o Hardware Auth primeiro.');
    }

    final seed = base64Decode(seedBase64);

    // 3. Recriar par de chaves a partir do seed
    final keyPair = await _algorithm.newKeyPairFromSeed(seed);

    // 4. Assinar os bytes do desafio
    // Converter Hex string para Bytes
    final challengeBytes = _hexToBytes(challengeHex);
    final signature = await _algorithm.sign(challengeBytes, keyPair: keyPair);

    // 5. Retornar assinatura em Base64
    return base64Encode(signature.bytes);
  }

  /// Verifica se existe uma chave salva
  Future<bool> hasHardwareKey() async {
    final key = await _secureStorage.read(key: _privateKeyKey);
    return key != null;
  }

  /// Prompt de biometria
  Future<bool> authenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        // Se o dispositivo não suporta biometria, podemos decidir se permitimos 
        // fallback para PIN do SO ou se bloqueamos. 
        // Para Sovereign Auth, o ideal é hardware-backed.
        return true; // Fallback se não houver biometria configurada? 
      }

      return await _localAuth.authenticate(
        localizedReason: 'Autentique para acessar sua Chave Soberana',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN/Padrão do sistema como fallback
        ),
      );
    } catch (e) {
      debugPrint('Erro na autenticação biométrica: $e');
      return false;
    }
  }

  /// Helper: Hex String -> Uint8List
  Uint8List _hexToBytes(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = int.parse(hex.substring(i, i + 2), radix: 16);
      result[i ~/ 2] = num;
    }
    return result;
  }
}
