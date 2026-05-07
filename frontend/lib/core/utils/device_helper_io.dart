import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Helper para gerenciar device hash e headers de segurança
class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _deviceHashKey = 'device_hash_key'; // Hardcoded key
  static const String _deviceInstallIdKey = 'device_install_id';

  static Future<DeviceMetadata> getDeviceMetadata() async {
    final installId = await _getDeviceInstallId();
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final serial = _allowedSerial(info.data['serialNumber']?.toString());
        final brand =
            _clean(info.brand.isNotEmpty ? info.brand : info.manufacturer);
        final model = _clean(info.model);
        return DeviceMetadata(
          deviceId: installId,
          deviceName: _joinName([brand, model], fallback: info.device),
          brand: brand,
          model: model,
          // Android/iOS frequently restrict hardware serial access. In that case
          // deviceInstallId is the stable local substitute for audit identity.
          serialNumber: serial,
          deviceInstallId: installId,
          platform: 'Android ${info.version.release}',
        );
      }

      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return DeviceMetadata(
          deviceId: installId,
          deviceName: _clean(info.name).isNotEmpty
              ? _clean(info.name)
              : _joinName([info.utsname.machine, info.model]),
          brand: 'Apple',
          model:
              _clean(info.model.isNotEmpty ? info.model : info.utsname.machine),
          // iOS does not expose the device serial number to apps.
          // deviceInstallId is the stable local substitute for audit identity.
          serialNumber: '',
          deviceInstallId: installId,
          platform: '${info.systemName} ${info.systemVersion}'.trim(),
        );
      }

      final platform = Platform.operatingSystem;
      final hostname = Platform.localHostname;
      return DeviceMetadata(
        deviceId: installId,
        deviceName: hostname.isNotEmpty ? hostname : 'Desktop Kerosene',
        brand: platform,
        model: Platform.operatingSystemVersion,
        serialNumber: '',
        deviceInstallId: installId,
        platform: platform,
      );
    } catch (_) {
      return DeviceMetadata(
        deviceId: installId,
        deviceName: 'Dispositivo Kerosene',
        deviceInstallId: installId,
        platform: Platform.operatingSystem,
      );
    }
  }

  /// Gera ou recupera o device hash
  static Future<String> getDeviceHash() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar se já existe um hash salvo
    String? savedHash = prefs.getString(_deviceHashKey);
    if (savedHash != null && savedHash.isNotEmpty) {
      return savedHash;
    }

    // Gerar novo hash baseado nas informações do dispositivo
    String deviceId = await _getDeviceIdentifier();
    String hash = _generateHash(deviceId);

    // Salvar para uso futuro
    await prefs.setString(_deviceHashKey, hash);

    return hash;
  }

  /// Obtém identificador único do dispositivo
  static Future<String> _getDeviceIdentifier() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.id}_${androidInfo.model}_${androidInfo.device}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.systemVersion}';
      } else {
        // Fallback estável para Windows/Desktop
        // Usamos o hostname + um sufixo estático
        final computerName = Platform.localHostname;
        return 'kerosene_desktop_v1_$computerName';
      }
    } catch (e) {
      // Em caso de erro, gerar ID baseado em timestamp
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Gera hash SHA-256 do identificador
  static String _generateHash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Obtém o IP do dispositivo
  static Future<String> getDeviceIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  /// Limpa o device hash salvo (útil para logout)
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

  static String _allowedSerial(String? raw) {
    final value = _clean(raw ?? '');
    if (value.isEmpty || value.toLowerCase() == 'unknown') {
      return '';
    }
    return value;
  }

  static String _joinName(List<String?> parts, {String fallback = ''}) {
    final cleaned = parts
        .map((part) => _clean(part ?? ''))
        .where((part) => part.isNotEmpty)
        .toList();
    if (cleaned.isNotEmpty) {
      return cleaned.join(' ');
    }
    final fallbackClean = _clean(fallback);
    return fallbackClean.isNotEmpty ? fallbackClean : 'Dispositivo Kerosene';
  }

  static String _clean(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
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
