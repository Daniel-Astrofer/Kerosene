import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Provider for the Tor API URL.
/// This allows components like ApiClient and WebSocket to reactively
/// update when the Tor relay is established on a dynamic port.
class TorApiUrlNotifier extends Notifier<String> {
  @override
  String build() => AppConfig.apiUrl;

  void updateUrl(String newUrl) {
    state = newUrl;
  }
}

final torApiUrlProvider = NotifierProvider<TorApiUrlNotifier, String>(TorApiUrlNotifier.new);
