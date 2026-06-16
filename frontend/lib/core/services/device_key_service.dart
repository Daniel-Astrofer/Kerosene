import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../constants/app_copy.dart';
import '../utils/device_helper.dart';

class DeviceKeyChallenge {
  final String challengeId;
  final String challenge;
  final int expiresInSeconds;
  final String onionServiceId;
  final String algorithm;
  final String canonicalization;

  const DeviceKeyChallenge({
    required this.challengeId,
    required this.challenge,
    required this.expiresInSeconds,
    required this.onionServiceId,
    required this.algorithm,
    required this.canonicalization,
  });

  factory DeviceKeyChallenge.fromJson(Map<String, dynamic> json) {
    return DeviceKeyChallenge(
      challengeId: (json['challengeId'] ?? '').toString(),
      challenge: (json['challenge'] ?? '').toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 90,
      onionServiceId: (json['onionServiceId'] ?? '').toString(),
      algorithm: (json['algorithm'] ?? 'Ed25519').toString(),
      canonicalization:
          (json['canonicalization'] ?? 'KEROSENE_JSON_V1').toString(),
    );
  }
}

class DeviceKeyService {
  DeviceKeyService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuthentication,
    Ed25519? algorithm,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuthentication = localAuthentication ?? LocalAuthentication(),
        _algorithm = algorithm ?? Ed25519();

  DeviceKeyService._internal() : this();

  static final DeviceKeyService instance = DeviceKeyService._internal();

  static const String _activeCredentialKey = 'device_key_active_credential';
  static const String _privateSeedKey = 'device_key_seed';
  static const String _publicKeyKey = 'device_key_public';
  static const String _counterKey = 'device_key_counter';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuthentication;
  final Ed25519 _algorithm;

  IOSOptions _iosOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  AndroidOptions _androidOptions() => const AndroidOptions();

  Future<Map<String, dynamic>> register({
    required DeviceKeyChallenge challenge,
    required String username,
    required String sessionId,
  }) async {
    _validateChallenge(challenge);
    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername.isEmpty) {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_INVALID_USERNAME',
        'Não foi possível identificar o usuário da chave deste dispositivo.',
      );
    }

    await _ensureLocalCredentialsAvailable();
    final keyPair = await _algorithm.newKeyPair();
    final privateKeySeed =
        Uint8List.fromList(await keyPair.extractPrivateKeyBytes());
    final publicKey = Uint8List.fromList(
      (await keyPair.extractPublicKey()).bytes,
    );
    final publicKeySha256 = _base64Url(sha256.convert(publicKey).bytes);
    final metadata = await DeviceHelper.getDeviceMetadata();
    final credentialId = _credentialId(
      publicKey: publicKey,
      username: normalizedUsername,
      deviceInstallId: metadata.deviceInstallId,
    );

    final counter = await _nextCounter(
      username: normalizedUsername,
      credentialId: credentialId,
    );
    final issuedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = _canonicalJson({
      'algorithm': 'Ed25519',
      'challenge': challenge.challenge,
      'challengeId': challenge.challengeId,
      'counter': counter,
      'credentialId': credentialId,
      'deviceInstallId': metadata.deviceInstallId,
      'issuedAtEpochSeconds': issuedAt,
      'onionServiceId': challenge.onionServiceId,
      'publicKeySha256': publicKeySha256,
      'sessionId': sessionId,
      'type': 'REGISTER_DEVICE_KEY',
      'username': normalizedUsername,
      'version': 1,
    });
    final signature = await _signPayload(
      payload,
      privateKeySeed: privateKeySeed,
    );
    await _saveKeyMaterial(
      username: normalizedUsername,
      credentialId: credentialId,
      privateKeySeed: privateKeySeed,
      publicKey: publicKey,
    );

    return {
      'publicKey': _base64Url(publicKey),
      'publicKeySha256': publicKeySha256,
      'credentialId': credentialId,
      'userHandle': _base64Url(utf8.encode(normalizedUsername)),
      'deviceName': metadata.deviceName,
      'deviceInstallId': metadata.deviceInstallId,
      'keyStorage': 'SECURE_STORAGE',
      ...metadata.toJson(),
      'signedPayload': payload,
      'signature': signature,
    };
  }

  Future<Map<String, dynamic>> authenticate({
    required DeviceKeyChallenge challenge,
    required String username,
  }) async {
    _validateChallenge(challenge);
    final normalizedUsername = _normalizeUsername(username);
    final credentialId = await _readActiveCredentialId(normalizedUsername);
    if (credentialId == null || credentialId.isEmpty) {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_NOT_REGISTERED',
        'Nenhuma chave deste dispositivo foi registrada para este usuário.',
      );
    }

    final privateKeySeed = await _readPrivateKeySeed(
      username: normalizedUsername,
      credentialId: credentialId,
    );
    if (privateKeySeed == null) {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_NOT_REGISTERED',
        'A chave deste dispositivo não está disponível neste aparelho.',
      );
    }

    final metadata = await DeviceHelper.getDeviceMetadata();
    final counter = await _nextCounter(
      username: normalizedUsername,
      credentialId: credentialId,
    );
    final issuedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = _canonicalJson({
      'challenge': challenge.challenge,
      'challengeId': challenge.challengeId,
      'counter': counter,
      'credentialId': credentialId,
      'deviceInstallId': metadata.deviceInstallId,
      'issuedAtEpochSeconds': issuedAt,
      'onionServiceId': challenge.onionServiceId,
      'type': 'AUTH_DEVICE_KEY',
      'username': normalizedUsername,
      'version': 1,
    });
    final signature = await _signPayload(
      payload,
      privateKeySeed: privateKeySeed,
    );

    return {
      'username': normalizedUsername,
      'credentialId': credentialId,
      'deviceInstallId': metadata.deviceInstallId,
      'signedPayload': payload,
      'signature': signature,
    };
  }

  Future<bool> hasRegisteredDeviceKey(String username) async {
    final credentialId =
        await _readActiveCredentialId(_normalizeUsername(username));
    return credentialId != null && credentialId.isNotEmpty;
  }

  String canonicalJsonForTesting(Map<String, Object> values) {
    return _canonicalJson(values);
  }

  Future<String> _signPayload(
    String payload, {
    required Uint8List privateKeySeed,
  }) async {
    await _verifyUserPresence();
    final keyPair = await _algorithm.newKeyPairFromSeed(privateKeySeed);
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return _base64Url(signature.bytes);
  }

  Future<void> _ensureLocalCredentialsAvailable() async {
    final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    final isSupported = await _localAuthentication.isDeviceSupported();
    if (!canCheckBiometrics && !isSupported) {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_NO_LOCAL_CREDENTIALS',
        'Configure biometria ou bloqueio de tela para usar a chave deste dispositivo.',
      );
    }
  }

  Future<void> _verifyUserPresence() async {
    final didAuthenticate = await _localAuthentication.authenticate(
      localizedReason: AppCopy.authReasonSovereignKeyAccess.en,
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
    if (!didAuthenticate) {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_AUTH_CANCELLED',
        'A confirmação do dispositivo foi cancelada.',
      );
    }
  }

  Future<void> _saveKeyMaterial({
    required String username,
    required String credentialId,
    required Uint8List privateKeySeed,
    required Uint8List publicKey,
  }) async {
    await _secureStorage.write(
      key: _storageKey(_privateSeedKey, username, credentialId),
      value: base64.encode(privateKeySeed),
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
    await _secureStorage.write(
      key: _storageKey(_publicKeyKey, username, credentialId),
      value: base64.encode(publicKey),
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
    await _secureStorage.write(
      key: _activeCredentialStorageKey(username),
      value: credentialId,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<Uint8List?> _readPrivateKeySeed({
    required String username,
    required String credentialId,
  }) async {
    final value = await _secureStorage.read(
      key: _storageKey(_privateSeedKey, username, credentialId),
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return Uint8List.fromList(base64.decode(value));
  }

  Future<String?> _readActiveCredentialId(String username) {
    return _secureStorage.read(
      key: _activeCredentialStorageKey(username),
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<int> _nextCounter({
    required String username,
    required String credentialId,
  }) async {
    final key = _storageKey(_counterKey, username, credentialId);
    final currentRaw = await _secureStorage.read(
      key: key,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
    final next = (int.tryParse(currentRaw ?? '') ?? 0) + 1;
    await _secureStorage.write(
      key: key,
      value: next.toString(),
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
    return next;
  }

  void _validateChallenge(DeviceKeyChallenge challenge) {
    if (challenge.challengeId.isEmpty ||
        challenge.challenge.isEmpty ||
        challenge.onionServiceId.isEmpty ||
        challenge.algorithm != 'Ed25519' ||
        challenge.canonicalization != 'KEROSENE_JSON_V1') {
      throw const DeviceKeyException(
        'ERR_AUTH_DEVICE_KEY_INVALID_CHALLENGE',
        'O challenge da chave deste dispositivo é inválido.',
      );
    }
  }

  String _canonicalJson(Map<String, Object> values) {
    final keys = values.keys.toList()..sort();
    final buffer = StringBuffer('{');
    for (var index = 0; index < keys.length; index++) {
      if (index > 0) buffer.write(',');
      final key = keys[index];
      buffer
        ..write(_quoteJson(key))
        ..write(':')
        ..write(_renderCanonicalValue(values[key]));
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _renderCanonicalValue(Object? value) {
    if (value is String) return _quoteJson(value);
    if (value is int) return value.toString();
    if (value is bool) return value.toString();
    throw ArgumentError(
        'Canonical JSON v1 only supports string, int and bool.');
  }

  String _quoteJson(String value) {
    final buffer = StringBuffer('"');
    for (final codePoint in value.runes) {
      switch (codePoint) {
        case 0x22:
          buffer.write(r'\"');
          break;
        case 0x5c:
          buffer.write(r'\\');
          break;
        case 0x08:
          buffer.write(r'\b');
          break;
        case 0x0c:
          buffer.write(r'\f');
          break;
        case 0x0a:
          buffer.write(r'\n');
          break;
        case 0x0d:
          buffer.write(r'\r');
          break;
        case 0x09:
          buffer.write(r'\t');
          break;
        default:
          if (codePoint < 0x20) {
            buffer.write(
              r'\u' + codePoint.toRadixString(16).padLeft(4, '0'),
            );
          } else {
            buffer.writeCharCode(codePoint);
          }
      }
    }
    buffer.write('"');
    return buffer.toString();
  }

  String _credentialId({
    required Uint8List publicKey,
    required String username,
    required String deviceInstallId,
  }) {
    return _base64Url(
      sha256.convert([
        ...publicKey,
        ...utf8.encode(username),
        ...utf8.encode(deviceInstallId),
      ]).bytes,
    );
  }

  String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _subjectToken(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');

  String _activeCredentialStorageKey(String username) {
    return '$_activeCredentialKey.${_subjectToken(username)}';
  }

  String _storageKey(String baseKey, String username, String credentialId) {
    return '$baseKey.${_subjectToken(username)}.$credentialId';
  }
}

class DeviceKeyException implements Exception {
  final String code;
  final String message;

  const DeviceKeyException(this.code, this.message);

  @override
  String toString() => 'DeviceKeyException($code): $message';
}
