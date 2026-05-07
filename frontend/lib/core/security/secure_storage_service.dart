import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Keep secrets available only while the device is unlocked and prevent
  /// migration through device backups.
  IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: false,
      );

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        resetOnError: true,
        migrateOnAlgorithmChange: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

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
