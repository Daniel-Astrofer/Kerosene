import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls Ghost Mode (Tor routing). When true, all API calls
/// are routed through the local Tor SOCKS5 proxy to the .onion server.
final ghostModeProvider = StateProvider<bool>((ref) => true);
