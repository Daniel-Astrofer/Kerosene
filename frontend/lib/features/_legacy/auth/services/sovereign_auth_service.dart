import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kerosene/core/constants/app_copy.dart';
import 'package:kerosene/core/services/sovereign_auth_service.dart' as core;

@Deprecated(
  'Use package:kerosene/core/services/sovereign_auth_service.dart instead.',
)
class SovereignAuthService {
  final core.SovereignAuthService _delegate;

  SovereignAuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  }) : _delegate = core.SovereignAuthService(
          keyStore: core.SecureStorageSovereignKeyStore(
            secureStorage: secureStorage,
          ),
          presenceVerifier: core.LocalAuthSovereignPresenceVerifier(
            localAuth: localAuth,
          ),
        );

  Future<String> generateAndSaveKeyPair() async {
    await _delegate.verifyUserPresence(
      localizedReason: AppCopy.authReasonSovereignKeyAccess.en,
    );
    final publicKey = await _delegate.generateKeyPair();
    return base64Encode(publicKey);
  }

  Future<String> signChallenge(String challengeHex) {
    return _delegate.signChallenge(challengeHex);
  }

  Future<bool> hasHardwareKey() {
    return _delegate.hasRegisteredKey();
  }

  Future<bool> authenticate() async {
    try {
      await _delegate.verifyUserPresence(
        localizedReason: AppCopy.authReasonSovereignKeyAccess.en,
      );
      return true;
    } on core.SovereignAuthException {
      return false;
    }
  }
}
