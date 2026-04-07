import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'sovereign_auth_service.dart';

/// Passkey service that delegates to SovereignAuthService (Ed25519 + biometric).
///
/// The standard WebAuthn `passkeys` package cannot work with .onion domains
/// because Android's Credential Manager validates rp.id against Digital Asset Links.
/// Instead, we use our own Ed25519 key pair stored in FlutterSecureStorage,
/// gated by biometric authentication via local_auth.
///
/// The backend expects:
///   Registration: { publicKey, publicKeyCose, credentialId, userHandle, deviceName, signature, authData, clientDataJSON }
///   Login:        { username, signature, authData, clientDataJSON }
class PasskeyService {
  PasskeyService._();
  static final PasskeyService instance = PasskeyService._();

  final SovereignAuthService _sovereignAuth = SovereignAuthService.instance;

  /// Registers a new passkey for the user.
  ///
  /// Following WebAuthn "Attestation" standard:
  /// signature = Ed25519Sign(privKey, authData || sha256(clientDataJSON))
  Future<Map<String, dynamic>> register({
    required String challengeHex,
    required String username,
  }) async {
    // 1. Generate fresh key pair (stored in secure storage)
    final pubKeyBytes = await _sovereignAuth.generateKeyPair();
    
    // 2. Build synthetic clientDataJSON and authData
    final clientDataJsonBytes = utf8.encode(jsonEncode({
      'type': 'webauthn.create',
      'challenge': _toBase64Url(_hexToBytes(challengeHex)),
      'origin': 'android:apk-key-hash:kerosene',
      'crossOrigin': false,
    }));
    final clientDataJson = _toBase64Url(clientDataJsonBytes);
    final authDataBytes = _buildAuthenticatorDataBytes();

    // 3. Compute signature over (authData + sha256(UTF8(clientDataJSON_string)))
    final clientDataHash = sha256.convert(clientDataJsonBytes).bytes;
    final signatureData = Uint8List.fromList([...authDataBytes, ...clientDataHash]);
    
    // 4. Sign (triggers biometric prompt)
    final signatureBytes = await _sovereignAuth.signBytes(signatureData);

    // 5. Build final payload (Mixed Base64 as per documentation)
    final deviceName = await _sovereignAuth.getDeviceName();
    
    // ATTENTION: All byte-heavy fields are Base64 (Standard)
    // Signature, authData, clientDataJSON are Base64URL
    final publicKeyBase64 = _toBase64(pubKeyBytes);
    final publicKeyCoseBase64 = _toBase64(_buildPublicKeyCose(pubKeyBytes));
    final signatureBase64Url = _toBase64Url(signatureBytes);
    final authDataBase64Url = _toBase64Url(authDataBytes);
    final userHandleBase64 = _toBase64(utf8.encode(username));

    return {
      'publicKey': publicKeyBase64,
      'public_key': publicKeyBase64,
      'publicKeyCose': publicKeyCoseBase64,
      'public_key_cose': publicKeyCoseBase64,
      'credentialId': publicKeyBase64,
      'credential_id': publicKeyBase64,
      'userHandle': userHandleBase64,
      'user_handle': userHandleBase64,
      'deviceName': deviceName,
      'device_name': deviceName,
      'signature': signatureBase64Url,
      'authData': authDataBase64Url,
      'clientDataJSON': clientDataJson,
    };
  }

  /// Authenticates using an existing passkey.
  /// 
  /// Purpose: Performs POST /auth/passkey/verify (Login)
  /// Campos: username, signature, authData, clientDataJSON (Exactly 4 fields)
  Future<Map<String, dynamic>> authenticate({
    required String challengeHex,
    required String username,
  }) async {
    // 1. Get the stored public key
    final pubKeyBytes = await _sovereignAuth.getPublicKey();
    if (pubKeyBytes == null) {
      throw Exception('Nenhuma passkey registrada neste dispositivo. Faça o registro primeiro.');
    }

    // 2. Build synthetic authData and clientDataJSON
    final clientDataJsonBytes = utf8.encode(jsonEncode({
      'type': 'webauthn.get',
      'challenge': _toBase64Url(_hexToBytes(challengeHex)),
      'origin': 'android:apk-key-hash:kerosene',
      'crossOrigin': false,
    }));
    final clientDataJson = _toBase64Url(clientDataJsonBytes);
    final authDataBytes = _buildAuthenticatorDataBytes();

    // 3. Compute signature over (authData + sha256(UTF8(clientDataJSON_string)))
    final clientDataHash = sha256.convert(clientDataJsonBytes).bytes;
    final signatureData = Uint8List.fromList([...authDataBytes, ...clientDataHash]);

    // 4. Sign (triggers biometric prompt)
    final signatureBytes = await _sovereignAuth.signBytes(signatureData);
    final signatureBase64Url = _toBase64Url(signatureBytes);
    final authDataBase64Url = _toBase64Url(authDataBytes);

    return {
      'username': username,
      'signature': signatureBase64Url,
      'authData': authDataBase64Url,
      'clientDataJSON': clientDataJson,
      'credentialId': _toBase64(pubKeyBytes),
      'credential_id': _toBase64(pubKeyBytes),
      'id': _toBase64(pubKeyBytes),
    };
  }

  /// Builds a proper COSE key map for Ed25519 (alg -8).
  /// Structure: map with `kty=1`, `alg=-8`, `crv=6`, and `x=<PubKey>`.
  Uint8List _buildPublicKeyCose(Uint8List pubKey) {
    // a4 (map 4), 01 01 (kty 1), 03 27 (alg -8), 20 06 (crv 6), 21 58 20 (x 32-bytes)
    final header = [0xA4, 0x01, 0x01, 0x03, 0x27, 0x20, 0x06, 0x21, 0x58, 0x20];
    return Uint8List.fromList([...header, ...pubKey]);
  }





  /// Checks if a passkey is already registered on this device.
  Future<bool> hasRegisteredPasskey() async {
    final pubKey = await _sovereignAuth.getPublicKey();
    return pubKey != null;
  }

  /// Builds a minimal synthetic authenticatorData bytes (37 bytes).
  Uint8List _buildAuthenticatorDataBytes() {

    // 32 zero bytes for rpIdHash (not validated for .onion typically)
    // flags: 0x05 = UP (bit 0) + UV (bit 2) = user present + user verified
    // counter: 4 zero bytes
    final data = List<int>.filled(32, 0) + [0x05] + [0, 0, 0, 0];
    return Uint8List.fromList(data);
  }

  /// Helper to convert Hex to Uint8List
  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    if (hex.length % 2 != 0) hex = '0$hex';
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Standard Base64 (with padding)
  String _toBase64(List<int> bytes) {
    return base64.encode(bytes);
  }

  /// Standard Base64Url (no padding)
  String _toBase64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
