// ignore_for_file: deprecated_member_use

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Helper web-safe para gerenciar device hash e headers de segurança.
class DeviceHelper {
  static const String _deviceHashKey = 'device_hash_key';
  static const String _deviceInstallIdKey = 'device_install_id';

  static Future<DeviceMetadata> getDeviceMetadata() async {
    final installId = await _getDeviceInstallId();
    final userAgent = html.window.navigator.userAgent;
    final rawPlatform = html.window.navigator.platform.toString();
    final platform =
        rawPlatform.isNotEmpty && rawPlatform != 'null' ? rawPlatform : 'Web';
    final browser = _browserName(userAgent);
    return DeviceMetadata(
      deviceId: installId,
      deviceName: '$browser ${Uri.base.host}'.trim(),
      brand: browser,
      model: platform,
      serialNumber: '',
      deviceInstallId: installId,
      platform: platform,
      browser: browser,
      userAgent: userAgent,
    );
  }

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

  static Future<String> _getDeviceInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_deviceInstallIdKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final id = const Uuid().v4();
    await prefs.setString(_deviceInstallIdKey, id);
    return id;
  }

  static String _browserName(String userAgent) {
    final ua = userAgent.toLowerCase();
    if (ua.contains('firefox')) return 'Firefox';
    if (ua.contains('edg/')) return 'Edge';
    if (ua.contains('chrome')) return 'Chrome';
    if (ua.contains('safari')) return 'Safari';
    return 'Web';
  }
}

class DeviceMetadata {
  final String deviceId;
  final String deviceName;
  final String brand;
  final String model;
  final String serialNumber;
  final String deviceInstallId;
  final String platform;
  final String browser;
  final String userAgent;

  const DeviceMetadata({
    required this.deviceId,
    required this.deviceName,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    required this.deviceInstallId,
    this.platform = '',
    this.browser = '',
    this.userAgent = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'deviceInstallId': deviceInstallId,
      'platform': platform,
      'browser': browser,
      'userAgent': userAgent,
    };
  }
}
