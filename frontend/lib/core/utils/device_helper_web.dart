import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper web-safe para gerenciar device hash e headers de segurança.
class DeviceHelper {
  static const String _deviceHashKey = 'device_hash_key';

  static Future<String> getDeviceHash() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHash = prefs.getString(_deviceHashKey);
    if (savedHash != null && savedHash.isNotEmpty) {
      return savedHash;
    }

    final input = 'kerosene_web_${DateTime.now().millisecondsSinceEpoch}';
    final hash = sha256.convert(utf8.encode(input)).toString();
    await prefs.setString(_deviceHashKey, hash);
    return hash;
  }

  static Future<String> getDeviceIP() async {
    return '127.0.0.1';
  }

  static Future<void> clearDeviceHash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceHashKey);
  }
}
