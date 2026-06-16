import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tor/tor.dart';

/// Manages the embedded Tor client lifecycle using the `tor` package
/// (Foundation Devices). Based on Arti (Rust Tor implementation).
/// On activation it starts a local SOCKS5 proxy on a dynamic port.
class TorService {
  static TorService? _instance;
  static TorService get instance => _instance ??= TorService._();
  TorService._();

  bool _isRunning = false;
  int _socksPort = 9050;
  Future<bool>? _startFuture;
  Future<bool>? _restartFuture;

  bool get isRunning => _isRunning;
  int get socksPort => _socksPort;

  /// Starts the embedded Tor daemon via the `tor` package.
  /// Returns true if Tor is ready.
  Future<bool> start() async {
    if (_isRunning) return true;
    final inFlight = _startFuture;
    if (inFlight != null) return inFlight;

    _startFuture = _startInternal().whenComplete(() {
      if (!_isRunning) {
        _startFuture = null;
      }
    });
    return _startFuture!;
  }

  Future<bool> _startInternal() async {
    try {
      debugPrint('🧅 TorService: Initializing Tor (Arti) via tor package...');

      // Initialize and start the Tor proxy
      await Tor.init();
      await Tor.instance.start();

      // The `tor` package picks a free port automatically
      _socksPort = Tor.instance.port;
      _isRunning = Tor.instance.started;

      if (_isRunning) {
        debugPrint(
          '🧅 TorService: Tor (Arti) running on SOCKS5 port $_socksPort',
        );
      } else {
        debugPrint('🧅 TorService: Tor.instance.started returned false');
      }
    } catch (e) {
      debugPrint('🧅 TorService: Failed to start Tor: $e');

      // Fallback: check if a system Tor is already listening
      int fallbackPort = 9050;
      _socksPort = fallbackPort;
      debugPrint('🧅 TorService: Falling back to port $_socksPort');

      try {
        await _waitForProxyToBoot(_socksPort, timeoutSeconds: 3);
        _isRunning = true;
      } catch (err) {
        debugPrint(
          'Tor proxy is NOT answering on $_socksPort. Application may be offline.',
        );
        _isRunning = false;
      }
    }

    return _isRunning;
  }

  /// Stops the embedded Tor daemon.
  Future<void> stop() async {
    await _closeRelays();
    if (!_isRunning) return;
    try {
      await Tor.instance.stop();
    } catch (e) {
      debugPrint('🧅 TorService: Error stopping Tor: $e');
    }
    _isRunning = false;
    _startFuture = null;
    debugPrint('🧅 TorService: Tor (Arti) stopped.');
  }

  Future<bool> _restartTorProxyForStaleDescriptor() async {
    final inFlight = _restartFuture;
    if (inFlight != null) return inFlight;

    _restartFuture = () async {
      debugPrint(
        '🧅 TorService: Restarting Tor proxy after stale onion descriptor.',
      );
      try {
        if (_isRunning) {
          await Tor.instance.stop();
        }
      } catch (error) {
        debugPrint('🧅 TorService: Error stopping stale Tor proxy: $error');
      }

      _isRunning = false;
      _startFuture = null;
      final restarted = await start();
      if (restarted) {
        debugPrint(
          '🧅 TorService: Tor proxy restarted on SOCKS5 port $_socksPort.',
        );
      }
      return restarted;
    }()
        .whenComplete(() {
      _restartFuture = null;
    });

    return _restartFuture!;
  }

  /// Polls the SOCKS port until a raw TCP connection succeeds.
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
        return;
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
      'Tor proxy did not bootstrap within $timeoutSeconds seconds.',
    );
  }

  // ==========================================
  // WEBSOCKET & RAW TCP SOCKS5 RELAY TUNNEL
  // ==========================================

  /// Map of active relay servers, keyed by 'host:port'.
  final Map<String, ServerSocket> _relayServers = {};
  final Map<String, int> _relayPorts = {};
  final Map<String, Future<int>> _relayStartFutures = {};

  Future<void> _closeRelays() async {
    final servers = List<ServerSocket>.from(_relayServers.values);
    _relayServers.clear();
    _relayPorts.clear();
    _relayStartFutures.clear();
    for (final server in servers) {
      try {
        await server.close();
      } catch (_) {}
    }
  }

  /// Starts a local TCP server that blindly relays bytes through the Tor SOCKS5 proxy.
  /// This is used to tunnel protocols like WebSockets that don't natively support SOCKS5.
  Future<int> startRelay(String targetHost, int targetPort) async {
    if (!_isRunning) {
      throw const SocketException('Cannot start relay: Tor is not running');
    }
    final key = '$targetHost:$targetPort';
    if (_relayPorts.containsKey(key)) {
      return _relayPorts[key]!;
    }
    final inFlight = _relayStartFutures[key];
    if (inFlight != null) {
      return inFlight;
    }

    final startFuture = _startRelayInternal(key, targetHost, targetPort);
    _relayStartFutures[key] = startFuture;
    try {
      return await startFuture;
    } finally {
      _relayStartFutures.remove(key);
    }
  }

  Future<int> _startRelayInternal(
    String key,
    String targetHost,
    int targetPort,
  ) async {
    final relayServer = await ServerSocket.bind('127.0.0.1', 0);
    final relayPort = relayServer.port;
    _relayServers[key] = relayServer;
    _relayPorts[key] = relayPort;

    relayServer.listen((clientSocket) async {
      debugPrint('🧅 Tor Relay: Received connection on 127.0.0.1:$relayPort');
      try {
        bool established = false;
        int relayAttempts = 0;
        const int maxRelayAttempts = 10;
        bool restartedForStaleDescriptor = false;
        Socket? torSocket;
        StreamIterator<Uint8List>? torIter;
        final readBuffer = <int>[];

        Future<Uint8List> readExact(int count) async {
          while (readBuffer.length < count) {
            if (!await torIter!.moveNext()) {
              throw SocketException(
                'Stream closed prematurely: expected $count bytes, got ${readBuffer.length}',
              );
            }
            readBuffer.addAll(torIter.current);
          }
          final result = Uint8List.fromList(readBuffer.take(count).toList());
          readBuffer.removeRange(0, count);
          return result;
        }

        while (!established && relayAttempts < maxRelayAttempts) {
          relayAttempts++;
          await torIter?.cancel();
          torSocket?.destroy();
          readBuffer.clear();

          try {
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
                await Future.delayed(const Duration(milliseconds: 1000));
              }
            }
            if (torSocket == null) {
              throw const SocketException('Could not connect to Tor SOCKS5');
            }
            torIter = StreamIterator<Uint8List>(torSocket);

            // SOCKS5 Auth Handshake
            torSocket.add([0x05, 0x01, 0x00]);
            await torSocket.flush();
            final handshakeRes = await readExact(2);
            if (handshakeRes[0] != 0x05 || handshakeRes[1] != 0x00) {
              throw SocketException('Tor SOCKS5 Handshake failed');
            }

            // SOCKS5 CONNECT request
            final request = <int>[0x05, 0x01, 0x00, 0x03];
            final domainBytes = utf8.encode(targetHost);
            request.add(domainBytes.length);
            request.addAll(domainBytes);
            request.add((targetPort >> 8) & 0xFF);
            request.add(targetPort & 0xFF);
            torSocket.add(request);
            await torSocket.flush();

            final connectRes = await readExact(4);
            if (connectRes[1] == 0x00) {
              final atyp = connectRes[3];
              if (atyp == 0x01) {
                await readExact(6);
              } else if (atyp == 0x03) {
                final len = (await readExact(1))[0];
                await readExact(len + 2);
              } else if (atyp == 0x04) {
                await readExact(18);
              }
              established = true;
              debugPrint(
                  '🧅 Tor Relay: Tunnel established to $targetHost:$targetPort');
            } else {
              final errorCode = connectRes[1];
              final errorMsg = _getSocksErrorMessage(errorCode);
              debugPrint(
                ' onion TorService [Relay]: SOCKS5 Connect failure: $errorMsg on attempt $relayAttempts/$maxRelayAttempts',
              );
              if (errorCode == 0xF2 && !restartedForStaleDescriptor) {
                restartedForStaleDescriptor = true;
                final restarted = await _restartTorProxyForStaleDescriptor();
                if (!restarted) {
                  throw const SocketException(
                    'Tor restart failed after stale onion descriptor',
                  );
                }
                relayAttempts = 0;
                continue;
              }
              if (relayAttempts >= maxRelayAttempts) {
                throw SocketException(
                  'Tor SOCKS5 to $targetHost refused after $maxRelayAttempts attempts: $errorMsg',
                );
              }
              await Future.delayed(Duration(seconds: relayAttempts * 3));
            }
          } catch (e) {
            if (relayAttempts >= maxRelayAttempts) rethrow;
            await Future.delayed(Duration(seconds: relayAttempts * 3));
          }
        }

        if (!established || torSocket == null || torIter == null) {
          throw const SocketException(
            'Failed to establish SOCKS5 connection after all retries',
          );
        }

        // Bi-Directional Pipe
        final capturedTorSocket = torSocket;
        clientSocket.listen(
          capturedTorSocket.add,
          onDone: () => capturedTorSocket.destroy(),
          onError: (e) {
            debugPrint(' onion TorService [Relay]: Client socket error: $e');
            capturedTorSocket.destroy();
          },
        );

        final capturedIter = torIter;
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

/// A wrapper class that allows a Socket to be treated as a broadcast stream.
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
