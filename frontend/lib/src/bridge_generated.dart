// Bridge for Tor client via the `tor` Flutter package (Foundation Devices).
// Replaces the old Rust FFI approach which failed on Android due to
// missing cross-compiled libnative.so.
//
// The `tor` package handles Arti compilation for all platforms automatically
// via Cargokit, so no manual cross-compilation is needed.

import 'package:tor/tor.dart';

/// High-level Dart API that wraps the `tor` package from Foundation Devices.
/// Drop-in replacement for the old NativeImpl that used flutter_rust_bridge FFI.
class NativeImpl {
  NativeImpl();

  /// Starts the Arti Tor client asynchronously.
  /// Returns a status message when the client has been started.
  Future<String> startTorClient() async {
    await Tor.init();
    await Tor.instance.start();
    final port = Tor.instance.port;
    return 'Tor Client (Arti) started. SOCKS5 proxy running on 127.0.0.1:$port';
  }

  /// Returns the SOCKS5 port that Tor is listening on.
  int get socksPort => Tor.instance.port;

  /// Whether Tor has fully started.
  bool get isStarted => Tor.instance.started;

  /// Stops the Tor client.
  Future<void> stop() async {
    await Tor.instance.stop();
  }
}
