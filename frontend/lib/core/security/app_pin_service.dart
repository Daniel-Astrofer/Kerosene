import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// Manages an in-app 6-digit PIN stored securely on device.
/// Used as fallback when the device has no system biometric/PIN.
class AppPinService {
  static const _pinKey = 'kerosene_app_pin_hash';

  final SecureStorageService _storage;

  AppPinService({SecureStorageService? storage})
    : _storage = storage ?? SecureStorageService();

  /// Returns true if an in-app PIN has already been set.
  Future<bool> hasPinSet() async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored.isNotEmpty;
  }

  /// Saves a new PIN (stored as SHA-256 hash).
  Future<void> setPin(String pin) async {
    final hash = _hash(pin);
    await _storage.write(key: _pinKey, value: hash);
  }

  /// Returns true if the provided PIN matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  /// Removes the stored PIN.
  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
