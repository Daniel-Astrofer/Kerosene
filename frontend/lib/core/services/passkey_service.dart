import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../config/app_config.dart';
import '../utils/device_helper.dart';
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
  final PasskeyCryptographyService _cryptographyService;

  PasskeyService({
    PasskeyCryptographyService? cryptographyService,
  }) : _cryptographyService =
            cryptographyService ?? SovereignAuthService.instance;

  PasskeyService._internal() : this();

  static final PasskeyService instance = PasskeyService._internal();

  /// Registers a new passkey for the user.
  ///
  /// Following WebAuthn "Attestation" standard:
  /// signature = Ed25519Sign(privKey, authData || sha256(clientDataJSON))
  Future<Map<String, dynamic>> register({
    required String challengeHex,
    required String username,
  }) async {
    final subject = _subject(username);
    final credentialId = SovereignAuthService.generateCredentialId();
    final publicKey = await _cryptographyService.generateKeyPair(
      subject: subject,
      credentialId: credentialId,
    );
    final assertion = await _buildAssertionContext(
      challengeHex: challengeHex,
      requestType: _PasskeyRequestType.registration,
      subject: subject,
    );
    final signature = await _cryptographyService.signBytes(
      assertion.signaturePayload,
      subject: subject,
    );
    // ATTENTION: All byte-heavy fields are Base64 (Standard)
    // Signature, authData, clientDataJSON are Base64URL
    final publicKeyBase64 = _toBase64(publicKey);
    final publicKeyCoseBase64 = _toBase64(_buildPublicKeyCose(publicKey));
    final credentialIdBase64 = _toBase64(credentialId);
    final signatureBase64Url = _toBase64Url(signature);
    final authDataBase64Url = _toBase64Url(assertion.authDataBytes);
    final userHandleBase64 = _toBase64(utf8.encode(username));
    final deviceMetadata = await DeviceHelper.getDeviceMetadata();
    final deviceName = deviceMetadata.deviceName.isNotEmpty
        ? deviceMetadata.deviceName
        : await _cryptographyService.getDeviceName();

    return {
      'publicKey': publicKeyBase64,
      'public_key': publicKeyBase64,
      'publicKeyCose': publicKeyCoseBase64,
      'public_key_cose': publicKeyCoseBase64,
      'credentialId': credentialIdBase64,
      'credential_id': credentialIdBase64,
      'userHandle': userHandleBase64,
      'user_handle': userHandleBase64,
      'deviceName': deviceName,
      'device_name': deviceName,
      ...deviceMetadata.toJson(),
      'signature': signatureBase64Url,
      'authData': authDataBase64Url,
      'clientDataJSON': assertion.clientDataJson,
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
    final subject = _subject(username);
    final publicKey = await _cryptographyService.getPublicKey(
      subject: subject,
    );
    if (publicKey == null) {
      throw Exception(
          'Nenhuma passkey registrada neste dispositivo. Faça o registro primeiro.');
    }
    final credentialId =
        await _cryptographyService.getCredentialId(subject: subject) ??
            publicKey;

    final assertion = await _buildAssertionContext(
      challengeHex: challengeHex,
      requestType: _PasskeyRequestType.authentication,
      subject: subject,
    );
    final signature = await _cryptographyService.signBytes(
      assertion.signaturePayload,
      subject: subject,
    );
    final signatureBase64Url = _toBase64Url(signature);
    final authDataBase64Url = _toBase64Url(assertion.authDataBytes);

    return {
      'username': username,
      'signature': signatureBase64Url,
      'authData': authDataBase64Url,
      'clientDataJSON': assertion.clientDataJson,
      'credentialId': _toBase64(credentialId),
      'credential_id': _toBase64(credentialId),
      'id': _toBase64(credentialId),
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
  Future<bool> hasRegisteredPasskey({String? username}) async {
    return _cryptographyService.hasRegisteredKey(
      subject: username == null ? null : _subject(username),
    );
  }

  Future<_PasskeyAssertionContext> _buildAssertionContext({
    required String challengeHex,
    required _PasskeyRequestType requestType,
    required String subject,
  }) async {
    final clientDataJsonBytes = utf8.encode(
      jsonEncode({
        'type': requestType.clientDataType,
        'challenge': _toBase64Url(_hexToBytes(challengeHex)),
        'origin': AppConfig.passkeyOrigin,
        'crossOrigin': false,
      }),
    );
    final authDataBytes = _buildAuthenticatorDataBytes(
      await _cryptographyService.nextSignatureCounter(subject: subject),
    );
    final clientDataHash = sha256.convert(clientDataJsonBytes).bytes;

    return _PasskeyAssertionContext(
      clientDataJson: _toBase64Url(clientDataJsonBytes),
      authDataBytes: authDataBytes,
      signaturePayload: Uint8List.fromList([
        ...authDataBytes,
        ...clientDataHash,
      ]),
    );
  }

  /// Builds synthetic authenticatorData bytes (37 bytes).
  Uint8List _buildAuthenticatorDataBytes(int signatureCounter) {
    final rpIdHash =
        sha256.convert(utf8.encode(AppConfig.effectivePasskeyRpId)).bytes;
    final counterBytes = ByteData(4)
      ..setUint32(0, signatureCounter, Endian.big);
    return Uint8List.fromList([
      ...rpIdHash,
      0x05,
      ...counterBytes.buffer.asUint8List(),
    ]);
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

  String _subject(String username) {
    return username.trim().toLowerCase();
  }
}

enum _PasskeyRequestType {
  registration('webauthn.create'),
  authentication('webauthn.get');

  final String clientDataType;

  const _PasskeyRequestType(this.clientDataType);
}

class _PasskeyAssertionContext {
  final String clientDataJson;
  final Uint8List authDataBytes;
  final Uint8List signaturePayload;

  const _PasskeyAssertionContext({
    required this.clientDataJson,
    required this.authDataBytes,
    required this.signaturePayload,
  });
}
