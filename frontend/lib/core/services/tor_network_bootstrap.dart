import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'tor_service.dart';

typedef TorApiUrlUpdater = void Function(String url);

@visibleForTesting
class TorBootstrapTarget {
  const TorBootstrapTarget({
    required this.requiresTor,
    required this.apiUrl,
    required this.targetHost,
    required this.targetPort,
  });

  final bool requiresTor;
  final String apiUrl;
  final String targetHost;
  final int targetPort;
}

@visibleForTesting
TorBootstrapTarget resolveTorBootstrapTarget(String rawUrl) {
  final apiUrl = rawUrl.trim();
  final uri = Uri.parse(apiUrl);
  final host = uri.host.toLowerCase();
  final targetPort = _resolveTargetPort(uri);

  return TorBootstrapTarget(
    requiresTor: host.endsWith('.onion'),
    apiUrl:
        apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl,
    targetHost: host,
    targetPort: targetPort,
  );
}

int _resolveTargetPort(Uri uri) {
  if (uri.hasPort) {
    return uri.port;
  }
  if (uri.scheme == 'https') {
    return 443;
  }
  return 80;
}

Future<bool> bootstrapTorNetwork({
  required TorService torService,
  required TorApiUrlUpdater updateApiUrl,
}) async {
  try {
    final target = resolveTorBootstrapTarget(AppConfig.onionBaseUrl);

    if (!target.requiresTor) {
      AppConfig.isTorEnabled = false;
      debugPrint(
        '🧅 Refusing non-onion mobile API URL. Configure KERO_NODE_*_URL with a .onion address: ${target.apiUrl}',
      );
      return false;
    }

    debugPrint('🚀 Starting Tor Network Bootstrap...');
    final torStarted = await torService.start();

    if (!torStarted) {
      AppConfig.isTorEnabled = false;
      debugPrint('⚠️ Tor is UNAVAILABLE. Requests will remain blocked.');
      return false;
    }

    final relayPort =
        await torService.startRelay(target.targetHost, target.targetPort);
    final newApiUrl = 'http://127.0.0.1:$relayPort';

    AppConfig.activeNodeUrl = target.apiUrl;
    AppConfig.apiUrl = newApiUrl;
    AppConfig.isTorEnabled = true;
    updateApiUrl(newApiUrl);

    debugPrint('✅ Tor Network Ready.');
    debugPrint(
      '🌐 Unified Tor Relay Active: ${AppConfig.apiUrl} -> ${target.apiUrl}',
    );
    return true;
  } catch (error, stackTrace) {
    AppConfig.isTorEnabled = false;
    debugPrint('❌ CRITICAL ERROR: Tor or Relay failed to start: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
