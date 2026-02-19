import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _localAuth;

  BiometricService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  /// Check if biometric authentication or device PIN is available and enrolled.
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      // If hardware is supported, check if any biometrics or PIN/Pattern are set up
      if (canCheckBiometrics || isDeviceSupported) {
        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        // Return true if hardware is supported AND (biometrics are enrolled OR we assume PIN is fallback)
        // local_auth doesn't have a direct "isPinSet" check, but authenticate() will fail
        // quickly if nothing is set when biometricOnly is false.
        // However, if getAvailableBiometrics is empty, it's a strong signal they might not have security.
        return availableBiometrics.isNotEmpty || isDeviceSupported;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error checking support: $e');
      return false;
    }
  }

  /// Returns true ONLY if biometric hardware is present AND has at least one face/fingerprint enrolled.
  Future<bool> isBiometricEnrolled() async {
    try {
      if (await _localAuth.canCheckBiometrics) {
        final enrolled = await _localAuth.getAvailableBiometrics();
        return enrolled.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate the user with biometrics or device credentials
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isSupported = await canAuthenticate();
      if (!isSupported) {
        debugPrint('BiometricService: Device not supported');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows PIN/Pattern as fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Authentication error: $e');
      return false;
    }
  }

  /// Get available biometrics (FaceID, TouchID, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error getting biometrics: $e');
      return [];
    }
  }
}
