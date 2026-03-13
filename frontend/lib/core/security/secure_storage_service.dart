import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Options for iOS: Key accessible only when the device is unlocked
  IOSOptions _getIOSOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  /// Options for Android: Enable EncryptedSharedPreferences
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  /// Save a value securely
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      debugPrint('SecureStorageService: Error writing key $key: $e');
      rethrow;
    }
  }

  /// Read a value securely
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(
        key: key,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      debugPrint('SecureStorageService: Error reading key $key: $e');
      return null;
    }
  }

  /// Delete a value securely
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(
        key: key,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      debugPrint('SecureStorageService: Error deleting key $key: $e');
      rethrow;
    }
  }

  /// Delete all values
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll(
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      debugPrint('SecureStorageService: Error deleting all: $e');
      rethrow;
    }
  }
}
