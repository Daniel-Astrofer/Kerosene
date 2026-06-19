import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kerosene/core/constants/app_copy.dart';

final class SovereignAuthErrorCodes {
  static const noLocalCredentials = 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS';
  static const authCancelled = 'ERR_AUTH_PASSKEY_AUTH_CANCELLED';
  static const keyNotFound = 'ERR_AUTH_PASSKEY_NOT_REGISTERED';
  static const corruptedKeyMaterial = 'ERR_AUTH_PASSKEY_CORRUPTED_KEY_MATERIAL';
  static const invalidChallenge = 'ERR_AUTH_PASSKEY_INVALID_CHALLENGE';
  static const storageFailure = 'ERR_AUTH_PASSKEY_STORAGE_FAILURE';
  static const signingFailure = 'ERR_AUTH_PASSKEY_SIGNING_FAILURE';

  const SovereignAuthErrorCodes._();
}

class SovereignAuthException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const SovereignAuthException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'SovereignAuthException($code): $message';
}

abstract interface class PasskeyCryptographyService {
  Future<Uint8List> generateKeyPair();
  Future<Uint8List?> getPublicKey();
  Future<bool> hasRegisteredKey();
  Future<String> getDeviceName();
  Future<Uint8List> signBytes(
    Uint8List data, {
    String? localizedReason,
  });
  Future<String> signChallenge(String hexChallenge);
  Future<int> nextSignatureCounter();
}

abstract interface class SovereignKeyStore {
  Future<void> saveKeyMaterial({
    required Uint8List privateKeySeed,
    required Uint8List publicKey,
  });
  Future<Uint8List?> readPrivateKeySeed();
  Future<Uint8List?> readPublicKey();
  Future<int> nextSignatureCounter();
}

class SecureStorageSovereignKeyStore implements SovereignKeyStore {
  static const String _privateKeySeedStorageKey = 'sovereign_auth_seed';
  static const String _publicKeyStorageKey = 'sovereign_auth_pubkey';
  static const String _signatureCounterStorageKey = 'sovereign_auth_sign_count';

  final FlutterSecureStorage _secureStorage;

  SecureStorageSovereignKeyStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  IOSOptions _iosOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  AndroidOptions _androidOptions() => const AndroidOptions();

  @override
  Future<void> saveKeyMaterial({
    required Uint8List privateKeySeed,
    required Uint8List publicKey,
  }) async {
    try {
      await _secureStorage.write(
        key: _privateKeySeedStorageKey,
        value: base64Encode(privateKeySeed),
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );
      await _secureStorage.write(
        key: _publicKeyStorageKey,
        value: base64Encode(publicKey),
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );
      await _secureStorage.write(
        key: _signatureCounterStorageKey,
        value: '0',
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );
    } catch (error) {
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.storageFailure,
        message: 'Unable to save the device key securely.',
        cause: error,
      );
    }
  }

  @override
  Future<Uint8List?> readPrivateKeySeed() async {
    return _readBytes(_privateKeySeedStorageKey);
  }

  @override
  Future<Uint8List?> readPublicKey() async {
    return _readBytes(_publicKeyStorageKey);
  }

  @override
  Future<int> nextSignatureCounter() async {
    try {
      final currentRaw = await _secureStorage.read(
        key: _signatureCounterStorageKey,
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );
      final current = int.tryParse(currentRaw ?? '') ?? 0;
      final next = current + 1;

      await _secureStorage.write(
        key: _signatureCounterStorageKey,
        value: next.toString(),
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );

      return next;
    } catch (error) {
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.storageFailure,
        message: 'Unable to update the device key securely.',
        cause: error,
      );
    }
  }

  Future<Uint8List?> _readBytes(String key) async {
    try {
      final storedValue = await _secureStorage.read(
        key: key,
        iOptions: _iosOptions(),
        aOptions: _androidOptions(),
      );
      if (storedValue == null || storedValue.trim().isEmpty) {
        return null;
      }
      return Uint8List.fromList(base64Decode(storedValue));
    } on FormatException catch (error) {
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.corruptedKeyMaterial,
        message: 'The device key needs to be registered again on this device.',
        cause: error,
      );
    } catch (error) {
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.storageFailure,
        message: 'Unable to access the secure device key.',
        cause: error,
      );
    }
  }
}

abstract interface class SovereignPresenceVerifier {
  Future<void> ensureLocalCredentialsAvailable();
  Future<void> verifyUserPresence({required String localizedReason});
}

class LocalAuthSovereignPresenceVerifier implements SovereignPresenceVerifier {
  final LocalAuthentication _localAuthentication;

  LocalAuthSovereignPresenceVerifier({
    LocalAuthentication? localAuth,
  }) : _localAuthentication = localAuth ?? LocalAuthentication();

  @override
  Future<void> ensureLocalCredentialsAvailable() async {
    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (canCheckBiometrics || isSupported) {
        return;
      }

      throw const SovereignAuthException(
        code: SovereignAuthErrorCodes.noLocalCredentials,
        message:
            'Configure biometrics or a device screen lock before using the device key.',
      );
    } on LocalAuthException catch (error) {
      throw _mapLocalAuthException(error);
    } on MissingPluginException catch (error) {
      throw _unsupportedLocalAuth(error);
    } on PlatformException catch (error) {
      throw _unsupportedLocalAuth(error);
    } on UnimplementedError catch (error) {
      throw _unsupportedLocalAuth(error);
    } on UnsupportedError catch (error) {
      throw _unsupportedLocalAuth(error);
    }
  }

  @override
  Future<void> verifyUserPresence({required String localizedReason}) async {
    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!didAuthenticate) {
        throw const SovereignAuthException(
          code: SovereignAuthErrorCodes.authCancelled,
          message: 'Device confirmation was cancelled.',
        );
      }
    } on LocalAuthException catch (error) {
      throw _mapLocalAuthException(error);
    } on MissingPluginException catch (error) {
      throw _unsupportedLocalAuth(error);
    } on PlatformException catch (error) {
      throw _unsupportedLocalAuth(error);
    } on UnimplementedError catch (error) {
      throw _unsupportedLocalAuth(error);
    } on UnsupportedError catch (error) {
      throw _unsupportedLocalAuth(error);
    }
  }

  SovereignAuthException _unsupportedLocalAuth(Object error) {
    return SovereignAuthException(
      code: SovereignAuthErrorCodes.noLocalCredentials,
      message:
          'Passkey confirmation requires biometrics or a local device lock on a supported platform.',
      cause: error,
    );
  }

  SovereignAuthException _mapLocalAuthException(LocalAuthException error) {
    switch (error.code) {
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return const SovereignAuthException(
          code: SovereignAuthErrorCodes.noLocalCredentials,
          message:
              'Configure biometrics or a device screen lock before using the device key.',
        );
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
        return const SovereignAuthException(
          code: SovereignAuthErrorCodes.authCancelled,
          message: 'Device confirmation was cancelled.',
        );
      default:
        return SovereignAuthException(
          code: error.code.name,
          message: error.description?.trim().isNotEmpty == true
              ? error.description!.trim()
              : error.code.name,
          cause: error,
        );
    }
  }
}

abstract interface class SovereignDeviceNameProvider {
  Future<String> getDeviceName();
}

class DefaultSovereignDeviceNameProvider
    implements SovereignDeviceNameProvider {
  final DateTime Function() _clock;

  DefaultSovereignDeviceNameProvider({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  @override
  Future<String> getDeviceName() async {
    return 'KeroseneDevice ${_clock().year}';
  }
}

/// Handles Ed25519 passkey material with secure storage and local auth.
class SovereignAuthService implements PasskeyCryptographyService {
  static final SovereignAuthService instance = SovereignAuthService._internal();

  final SovereignKeyStore _keyStore;
  final SovereignPresenceVerifier _presenceVerifier;
  final SovereignDeviceNameProvider _deviceNameProvider;
  final Ed25519 _algorithm;

  SovereignAuthService({
    SovereignKeyStore? keyStore,
    SovereignPresenceVerifier? presenceVerifier,
    SovereignDeviceNameProvider? deviceNameProvider,
    Ed25519? algorithm,
  })  : _keyStore = keyStore ?? SecureStorageSovereignKeyStore(),
        _presenceVerifier =
            presenceVerifier ?? LocalAuthSovereignPresenceVerifier(),
        _deviceNameProvider =
            deviceNameProvider ?? DefaultSovereignDeviceNameProvider(),
        _algorithm = algorithm ?? Ed25519();

  SovereignAuthService._internal() : this();

  @override
  Future<Uint8List> generateKeyPair() async {
    await _presenceVerifier.ensureLocalCredentialsAvailable();

    try {
      final keyPair = await _algorithm.newKeyPair();
      final privateKeySeed =
          Uint8List.fromList(await keyPair.extractPrivateKeyBytes());
      final publicKey = Uint8List.fromList(
        (await keyPair.extractPublicKey()).bytes,
      );

      await _keyStore.saveKeyMaterial(
        privateKeySeed: privateKeySeed,
        publicKey: publicKey,
      );

      return publicKey;
    } catch (error) {
      _logFailure('generateKeyPair', error);
      if (error is SovereignAuthException) {
        rethrow;
      }
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.storageFailure,
        message: 'Unable to prepare the device key securely.',
        cause: error,
      );
    }
  }

  @override
  Future<Uint8List?> getPublicKey() {
    return _keyStore.readPublicKey();
  }

  @override
  Future<bool> hasRegisteredKey() async {
    final publicKey = await _keyStore.readPublicKey();
    return publicKey != null;
  }

  @override
  Future<String> getDeviceName() {
    return _deviceNameProvider.getDeviceName();
  }

  Future<void> verifyUserPresence({String? localizedReason}) {
    return _presenceVerifier.verifyUserPresence(
      localizedReason:
          localizedReason ?? AppCopy.authReasonSovereignKeyAccess.en,
    );
  }

  @override
  Future<String> signChallenge(String hexChallenge) async {
    final challengeBytes = _decodeHex(hexChallenge);
    final signature = await signBytes(challengeBytes);
    return base64Encode(signature);
  }

  @override
  Future<Uint8List> signBytes(
    Uint8List data, {
    String? localizedReason,
  }) async {
    if (data.isEmpty) {
      throw const SovereignAuthException(
        code: SovereignAuthErrorCodes.invalidChallenge,
        message: 'Secure confirmation could not be prepared.',
      );
    }

    await verifyUserPresence(localizedReason: localizedReason);

    try {
      final privateKeySeed = await _keyStore.readPrivateKeySeed();
      if (privateKeySeed == null) {
        throw const SovereignAuthException(
          code: SovereignAuthErrorCodes.keyNotFound,
          message:
              'No device key is registered on this device. Register this device first.',
        );
      }

      final keyPair = await _algorithm.newKeyPairFromSeed(privateKeySeed);
      final signature = await _algorithm.sign(data, keyPair: keyPair);
      return Uint8List.fromList(signature.bytes);
    } catch (error) {
      _logFailure('signBytes', error);
      if (error is SovereignAuthException) {
        rethrow;
      }
      throw SovereignAuthException(
        code: SovereignAuthErrorCodes.signingFailure,
        message: 'Unable to confirm with the device key.',
        cause: error,
      );
    }
  }

  @override
  Future<int> nextSignatureCounter() {
    return _keyStore.nextSignatureCounter();
  }

  Uint8List _decodeHex(String hex) {
    final normalized = hex.replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
      throw const SovereignAuthException(
        code: SovereignAuthErrorCodes.invalidChallenge,
        message: 'Challenge must be a valid hexadecimal string.',
      );
    }

    final evenLengthHex =
        normalized.length.isEven ? normalized : '0$normalized';
    final bytes = Uint8List(evenLengthHex.length ~/ 2);

    for (var index = 0; index < bytes.length; index++) {
      final start = index * 2;
      bytes[index] = int.parse(
        evenLengthHex.substring(start, start + 2),
        radix: 16,
      );
    }

    return bytes;
  }

  void _logFailure(String operation, Object error) {
    debugPrint('SovereignAuthService.$operation failed: $error');
  }
}
