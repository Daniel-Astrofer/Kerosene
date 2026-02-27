import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tor/tor.dart';

/// Manages the embedded Tor client lifecycle.
/// On activation it starts a local SOCKS5 proxy (default port 9050).
class TorService {
  static TorService? _instance;
  static TorService get instance => _instance ??= TorService._();
  TorService._();

  bool _isRunning = false;
  int _socksPort = 9050;

  bool get isRunning => _isRunning;
  int get socksPort => _socksPort;

  /// Starts the embedded Tor daemon.
  /// Returns the SOCKS5 port number (9050 by default).
  Future<int> start() async {
    // If we're already running in this isolate, return cached port
    if (_isRunning) return _socksPort;

    try {
      debugPrint('🧅 TorService: Initializing embedded Tor context...');
      await Tor.init();

      debugPrint('🧅 TorService: Starting daemon...');
      await Tor.instance.start();
      _socksPort = Tor.instance.port;

      // Wait for the SOCKS proxy to actually open to prevent "Connection refused"
      await _waitForProxyToBoot(_socksPort);

      _isRunning = true;
      debugPrint('🧅 TorService: Tor running on SOCKS5 port $_socksPort');
    } catch (e) {
      debugPrint(
        '🧅 TorService: Failed to start embedded Tor (Already running or error): $e',
      );

      // Fallback: Check if port 9050 is already listening (system Tor or previous isolate)
      // or if Tor.instance.port is already valid.
      int fallbackPort = 9050;
      try {
        if (Tor.instance.port > 0) fallbackPort = Tor.instance.port;
      } catch (_) {}

      _socksPort = fallbackPort;
      debugPrint('🧅 TorService: Falling back to port $_socksPort');

      try {
        await _waitForProxyToBoot(_socksPort, timeoutSeconds: 5);
        _isRunning = true;
      } catch (err) {
        debugPrint(
          'Tor proxy is NOT answering on $_socksPort. Application may be offline.',
        );
      }
    }

    return _socksPort;
  }

  /// Stops the embedded Tor daemon.
  Future<void> stop() async {
    if (!_isRunning) return;
    try {
      await Tor.instance.stop();
      debugPrint('🧅 TorService: Tor stopped.');
    } catch (e) {
      debugPrint('🧅 TorService: Error stopping Tor: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// Polls the SOCKS port until a raw TCP connection succeeds.
  /// Hardened for unstable Windows/Android environments.
  Future<void> _waitForProxyToBoot(int port, {int timeoutSeconds = 45}) async {
    debugPrint(
      '🧅 TorService: Checking if proxy is listening on 127.0.0.1:$port...',
    );
    final stopwatch = Stopwatch()..start();
    int attempts = 0;
    while (stopwatch.elapsed.inSeconds < timeoutSeconds) {
      attempts++;
      try {
        final socket = await Socket.connect(
          '127.0.0.1',
          port,
          timeout: const Duration(milliseconds: 1000),
        );
        socket.destroy();
        debugPrint(
          '🧅 TorService: Proxy is ALIVE at $port after $attempts attempts.',
        );
        return; // Success!
      } catch (_) {
        if (attempts % 5 == 0) {
          debugPrint(
            '🧅 TorService: Still waiting for port $port... (${stopwatch.elapsed.inSeconds}s)',
          );
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    throw SocketException(
      'Tor proxy did not bootstrap within $timeoutSeconds seconds. Check if Tor binary is allowed in firewall.',
    );
  }

  // ==========================================
  // WEBSOCKET & RAW TCP SOCKS5 RELAY TUNNEL
  // ==========================================

  /// Map of active relay servers, keyed by 'host:port'.
  final Map<String, ServerSocket> _relayServers = {};
  final Map<String, int> _relayPorts = {};

  /// Starts a local TCP server that blindly relays bytes through the Tor SOCKS5 proxy.
  /// This is used to tunnel protocols like WebSockets that don't natively support SOCKS5.
  /// Multiple concurrent relays to different targets are supported.
  Future<int> startRelay(String targetHost, int targetPort) async {
    final key = '$targetHost:$targetPort';
    // If a relay is already running for this specific target, return its port
    if (_relayPorts.containsKey(key)) {
      return _relayPorts[key]!;
    }

    // Bind to an ephemeral port locally
    final relayServer = await ServerSocket.bind('127.0.0.1', 0);
    final relayPort = relayServer.port;
    _relayServers[key] = relayServer;
    _relayPorts[key] = relayPort;

    relayServer.listen((clientSocket) async {
      try {
        debugPrint(
          ' onion TorService [Relay]: Incoming local connection on port $relayPort -> $targetHost:$targetPort',
        );

        // ── SOCKS5 Connect + Retry ─────────────────────────────────────────
        // Each attempt opens a FRESH Tor socket + re-does the full handshake.
        // Tor closes the TCP socket after sending an error response, so
        // reusing the same socket on retry was causing a RangeError.
        //
        // IMPORTANT: We use a StreamIterator + local byte buffer (readBuffer)
        // instead of asBroadcastStream(). Broadcast streams DROP bytes that
        // arrive between consecutive 'await for' reads. StreamIterator buffers
        // all incoming data and never loses bytes between sequential reads.
        bool established = false;
        int relayAttempts = 0;
        const int maxRelayAttempts = 3;
        Socket? torSocket;
        StreamIterator<Uint8List>? torIter;
        final readBuffer = <int>[]; // shared accumulator across readExact calls

        // Local helper: reads exactly [count] bytes using the current
        // torIter + readBuffer. Throws SocketException on premature close.
        Future<Uint8List> readExact(int count) async {
          while (readBuffer.length < count) {
            if (!await torIter!.moveNext()) {
              throw SocketException(
                'Stream closed prematurely: expected $count bytes, got ${readBuffer.length}',
              );
            }
            readBuffer.addAll(torIter!.current);
          }
          final result = Uint8List.fromList(readBuffer.take(count).toList());
          readBuffer.removeRange(0, count);
          return result;
        }

        while (!established && relayAttempts < maxRelayAttempts) {
          relayAttempts++;
          // Cancel the previous iterator and destroy the failed socket.
          await torIter?.cancel();
          torSocket?.destroy();
          readBuffer.clear();

          try {
            // ── Step 0: fresh TCP connection to the SOCKS5 proxy ────────────
            int sockAttempts = 0;
            while (sockAttempts < 5) {
              try {
                torSocket = await Socket.connect(
                  '127.0.0.1',
                  _socksPort,
                  timeout: const Duration(seconds: 5),
                );
                break;
              } catch (e) {
                sockAttempts++;
                if (sockAttempts >= 5) rethrow;
                debugPrint(
                  ' onion TorService [Relay]: SOCKS port $_socksPort not ready. Retrying ($sockAttempts/5)...',
                );
                await Future.delayed(const Duration(milliseconds: 1000));
              }
            }
            if (torSocket == null) {
              throw const SocketException('Could not connect to Tor SOCKS5');
            }
            // Create a StreamIterator — buffers ALL incoming chunks, so no
            // bytes are ever lost between sequential readExact() calls.
            torIter = StreamIterator<Uint8List>(torSocket!);

            // ── Step 1: SOCKS5 Auth Handshake ───────────────────────────────
            torSocket!.add([0x05, 0x01, 0x00]);
            await torSocket!.flush();

            final handshakeRes = await readExact(2);
            if (handshakeRes[0] != 0x05 || handshakeRes[1] != 0x00) {
              throw SocketException(
                'Tor SOCKS5 Handshake failed (got: ${handshakeRes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')})',
              );
            }

            // ── Step 2: SOCKS5 CONNECT request ──────────────────────────────
            final request = <int>[0x05, 0x01, 0x00, 0x03];
            final domainBytes = utf8.encode(targetHost);
            request.add(domainBytes.length);
            request.addAll(domainBytes);
            request.add((targetPort >> 8) & 0xFF);
            request.add(targetPort & 0xFF);
            torSocket!.add(request);
            await torSocket!.flush();

            // Read [VER, REP, RSV, ATYP] — 4 bytes
            final connectRes = await readExact(4);

            if (connectRes[1] == 0x00) {
              // ✅ Success — drain the remaining BND.ADDR + BND.PORT
              final atyp = connectRes[3];
              if (atyp == 0x01) {
                await readExact(6); // IPv4 (4) + Port (2)
              } else if (atyp == 0x03) {
                final len = (await readExact(1))[0];
                await readExact(len + 2);
              } else if (atyp == 0x04) {
                await readExact(18); // IPv6 (16) + Port (2)
              }
              established = true;
              debugPrint(
                ' onion TorService [Relay]: SOCKS5 established to $targetHost:$targetPort (attempt $relayAttempts)',
              );
            } else {
              // ❌ SOCKS error — Tor closes the TCP socket after this response.
              // The socket is destroyed at the top of the next loop iteration.
              final errorCode = connectRes[1];
              final errorMsg = _getSocksErrorMessage(errorCode);
              debugPrint(
                ' onion TorService [Relay]: SOCKS5 Connect failure: $errorMsg (0x${errorCode.toRadixString(16).padLeft(2, '0')}) on attempt $relayAttempts/$maxRelayAttempts',
              );
              if (relayAttempts >= maxRelayAttempts) {
                throw SocketException(
                  'Tor SOCKS5 to $targetHost refused after $maxRelayAttempts attempts: $errorMsg',
                );
              }
              await Future.delayed(Duration(seconds: relayAttempts * 2));
            }
          } catch (e) {
            if (relayAttempts >= maxRelayAttempts) rethrow;
            debugPrint(
              ' onion TorService [Relay]: Attempt $relayAttempts failed ($e). Retrying with fresh socket...',
            );
            await Future.delayed(Duration(seconds: relayAttempts * 2));
          }
        }

        if (!established || torSocket == null || torIter == null) {
          throw const SocketException(
            'Failed to establish SOCKS5 connection after all retries',
          );
        }

        // ── 3. Bi-Directional Pipe ──────────────────────────────────────────
        // Client -> Tor: pipe all client bytes into the Tor socket.
        final capturedTorSocket = torSocket!;
        clientSocket.listen(
          capturedTorSocket.add,
          onDone: () => capturedTorSocket.destroy(),
          onError: (e) {
            debugPrint(' onion TorService [Relay]: Client socket error: $e');
            capturedTorSocket.destroy();
          },
        );

        // Tor -> Client: first flush anything already in readBuffer (bytes
        // that arrived alongside the CONNECT response), then pump the iterator.
        final capturedIter = torIter!;
        final capturedBuffer = List<int>.from(readBuffer);
        unawaited(() async {
          try {
            if (capturedBuffer.isNotEmpty) {
              clientSocket.add(Uint8List.fromList(capturedBuffer));
            }
            while (await capturedIter.moveNext()) {
              clientSocket.add(capturedIter.current);
            }
          } catch (e) {
            debugPrint(' onion TorService [Relay]: Tor stream error: $e');
          } finally {
            clientSocket.destroy();
          }
        }());
      } catch (e) {
        debugPrint(' onion TorService [Relay]: Fatal error in relay loop: $e');
        clientSocket.destroy();
      }
    });

    debugPrint(
      ' onion TorService [Relay]: Started local proxy server at 127.0.0.1:$relayPort bridging to $targetHost:$targetPort',
    );
    return relayPort;
  }

  // _readExactBytes removed — relay now uses StreamIterator + local readBuffer
  // (see startRelay). This avoids the asBroadcastStream() data-loss bug where
  // bytes arriving between consecutive 'await for' calls were silently dropped.

  /// Maps SOCKS5 error codes (REP) to human readable messages.
  String _getSocksErrorMessage(int code) {
    return switch (code) {
      0x01 => 'General SOCKS server failure',
      0x02 => 'Connection not allowed by ruleset',
      0x03 => 'Network unreachable',
      0x04 => 'Host unreachable',
      0x05 => 'Connection refused',
      0x06 => 'TTL expired',
      0x07 => 'Command not supported',
      0x08 => 'Address type not supported',
      // Extended Tor error codes
      0xF0 => 'Onion Service Descriptor Not Found',
      0xF1 => 'Onion Service Descriptor Is Invalid',
      0xF2 => 'Onion Service Descriptor Is Stale',
      0xF3 => 'Onion Service Rendezvous Failed',
      0xF4 => 'Onion Service Intro Failed',
      0xF5 => 'Onion Service Unreachable',
      0xF6 => 'Missing Client Auth',
      0xF7 => 'Bad Client Auth',
      _ => 'Unknown SOCKS error',
    };
  }
}

/// Provides access to the singleton TorService.
final torServiceProvider = Provider<TorService>((ref) {
  return TorService.instance;
});

/// A wrapper class that allows a Socket to be treated as a broadcast stream
/// and delegated back to external networking libraries (like Dio/HttpClient).
class BroadcastSocket extends Stream<Uint8List> implements Socket {
  final Socket _socket;
  final Stream<Uint8List> _broadcastStream;

  BroadcastSocket(this._socket)
    : _broadcastStream = _socket.asBroadcastStream();

  BroadcastSocket.fromStream(this._socket, this._broadcastStream);

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _broadcastStream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Encoding get encoding => _socket.encoding;
  @override
  set encoding(Encoding e) => _socket.encoding = e;

  @override
  void add(List<int> data) => _socket.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _socket.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _socket.addStream(stream);
  @override
  Future close() => _socket.close();
  @override
  Future get done => _socket.done;
  @override
  Future flush() => _socket.flush();
  @override
  void write(Object? obj) => _socket.write(obj);
  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      _socket.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);
  @override
  void writeln([Object? obj = ""]) => _socket.writeln(obj);

  @override
  InternetAddress get address => _socket.address;
  @override
  void destroy() => _socket.destroy();
  @override
  int get port => _socket.port;
  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;
  @override
  int get remotePort => _socket.remotePort;
  @override
  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);
  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
  @override
  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);
}
