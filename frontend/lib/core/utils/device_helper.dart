import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Helper para gerenciar device hash e headers de segurança
class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Gera ou recupera o device hash
  static Future<String> getDeviceHash() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar se já existe um hash salvo
    String? savedHash = prefs.getString(AppConfig.deviceHashKey);
    if (savedHash != null && savedHash.isNotEmpty) {
      return savedHash;
    }

    // Gerar novo hash baseado nas informações do dispositivo
    String deviceId = await _getDeviceIdentifier();
    String hash = _generateHash(deviceId);

    // Salvar para uso futuro
    await prefs.setString(AppConfig.deviceHashKey, hash);

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
        // Fallback para outras plataformas
        return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
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

  /// Cria headers de segurança para requisições
  static Future<Map<String, String>> getSecurityHeaders() async {
    final deviceHash = await getDeviceHash();
    final deviceIP = await getDeviceIP();

    return {'X-Device-Hash': deviceHash, 'X-Forwarded-For': deviceIP};
  }

  /// Limpa o device hash salvo (útil para logout)
  static Future<void> clearDeviceHash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.deviceHashKey);
  }
}
