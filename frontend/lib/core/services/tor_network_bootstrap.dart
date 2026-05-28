import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'tor_service.dart';

typedef TorApiUrlUpdater = void Function(String url);

Future<bool> bootstrapTorNetwork({
  required TorService torService,
  required TorApiUrlUpdater updateApiUrl,
}) async {
  try {
    debugPrint('🚀 Starting Tor Network Bootstrap...');
    final torStarted = await torService.start();

    if (!torStarted) {
      AppConfig.isTorEnabled = false;
      debugPrint('⚠️ Tor is UNAVAILABLE. Requests will remain blocked.');
      return false;
    }

    final host = Uri.parse(AppConfig.onionBaseUrl).host;
    final relayPort = await torService.startRelay(host, 80);
    final newApiUrl = 'http://127.0.0.1:$relayPort';

    AppConfig.apiUrl = newApiUrl;
    AppConfig.isTorEnabled = true;
    updateApiUrl(newApiUrl);

    debugPrint('✅ Tor Network Ready.');
    debugPrint(
      '🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> http://$host',
    );
    return true;
  } catch (error, stackTrace) {
    AppConfig.isTorEnabled = false;
    debugPrint('❌ CRITICAL ERROR: Tor or Relay failed to start: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
