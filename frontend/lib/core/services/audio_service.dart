import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Riverpod provider to inject the AudioService.
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

class AudioService {
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();

  // Create an AudioCache instance inside AudioPlayer for preloading.
  AudioPlayer? _player;

  bool _isInit = false;
  bool _isInitialing = false;

  /// Defines all relative paths to the synthesized sounds in assets/sounds/
  static const String _kLoginSound = 'sounds/login.wav';
  static const String _kGhostOnSound = 'sounds/ghost_on.wav';
  static const String _kGhostOffSound = 'sounds/ghost_off.wav';
  static const String _kTransactionSound = 'sounds/transaction.wav';
  static const String _kErrorSound = 'sounds/error.wav';

  /// Initializes the service and pre-caches the audio files for zero-latency playback.
  Future<void> init() async {
    if (_isInit || _isInitialing) return;
    _isInitialing = true;
    try {
      final player = AudioPlayer()
        ..setReleaseMode(ReleaseMode.stop)
        ..setPlayerMode(PlayerMode.lowLatency);

      /*
      await player.audioCache.loadAll([
        _kLoginSound,
        _kGhostOnSound,
        _kGhostOffSound,
        _kTransactionSound,
        _kErrorSound,
      ]);
      */
      
      _player = player;
      _isInit = true;
      debugPrint('🎵 AudioService: Initialized (Sounds skipped if missing).');
    } catch (e) {
      debugPrint('🎵 AudioService: Failed to init audio cache: $e');
    } finally {
      _isInitialing = false;
    }
  }

  // --- Playback Methods --- //

  /// Plays the fast tech boot sequence.
  Future<void> playLogin() async {
    await _playFile(_kLoginSound);
  }

  /// Plays the deep stealth wub.
  Future<void> playGhostOn() async {
    await _playFile(_kGhostOnSound);
  }

  /// Plays the high-pitch chirp down.
  Future<void> playGhostOff() async {
    await _playFile(_kGhostOffSound);
  }

  /// Plays the futuristic confirmation chime.
  Future<void> playTransaction() async {
    await _playFile(_kTransactionSound);
  }

  /// Plays the cyber glitch buzz.
  Future<void> playError() async {
    await _playFile(_kErrorSound);
  }

  /// Core helper to actually play a file.
  Future<void> _playFile(String assetPath) async {
    if (!_isInit) await init();
    if (_player == null) return;
    try {
      // Re-initialize a fast play request without creating a new player entirely
      await _player!.stop();
      await _player!.play(AssetSource(assetPath), volume: 1.0);
    } catch (e) {
      debugPrint('🎵 AudioService: Failed to play $assetPath -> $e');
    }
  }

  /// Stop any currently playing audio.
  Future<void> stop() async {
    if (_isInit && _player != null) {
      await _player!.stop();
    }
  }
}
