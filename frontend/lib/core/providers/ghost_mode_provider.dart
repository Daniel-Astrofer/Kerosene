import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls Ghost Mode (Tor routing). When true, all API calls
/// are routed through the local Tor SOCKS5 proxy to the .onion server.
class GhostModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void update(bool newValue) => state = newValue;
}

final ghostModeProvider = NotifierProvider<GhostModeNotifier, bool>(GhostModeNotifier.new);
