import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper para gerenciar device hash e headers de segurança
class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _deviceHashKey = 'device_hash_key'; // Hardcoded key

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
}
