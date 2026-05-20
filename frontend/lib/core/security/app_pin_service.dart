import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'secure_storage_service.dart';

class AppPinService {
  AppPinService({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  static const _pinKey = 'kerosene.app_pin.hash';
  static const _saltLength = 24;

  final SecureStorageService _storage;

  Future<bool> get hasPin async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored.contains(':');
  }

  Future<void> setPin(String pin) async {
    _validatePin(pin);
    final salt = _randomSalt();
    final digest = _hashPin(pin, salt);
    await _storage.write(key: _pinKey, value: '$salt:$digest');
  }

  Future<bool> verifyPin(String pin) async {
    if (!_isValidPinShape(pin)) {
      return false;
    }

    final stored = await _storage.read(key: _pinKey);
    if (stored == null || !stored.contains(':')) {
      return false;
    }

    final parts = stored.split(':');
    if (parts.length != 2) {
      return false;
    }

    return _constantTimeEquals(_hashPin(pin, parts[0]), parts[1]);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  void _validatePin(String pin) {
    if (!_isValidPinShape(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain 4 to 12 digits.');
    }
  }

  bool _isValidPinShape(String pin) {
    return RegExp(r'^\d{4,12}$').hasMatch(pin);
  }

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final rounds = List<int>.filled(10000, 0);
    var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (final _ in rounds) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64UrlEncode(digest);
  }

  bool _constantTimeEquals(String a, String b) {
    final left = utf8.encode(a);
    final right = utf8.encode(b);
    if (left.length != right.length) {
      return false;
    }

    var diff = 0;
    for (var index = 0; index < left.length; index++) {
      diff |= left[index] ^ right[index];
    }
    return diff == 0;
  }
}
