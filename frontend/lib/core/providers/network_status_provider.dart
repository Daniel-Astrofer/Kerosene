import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Provider to expose the current network status
final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, bool>(NetworkStatusNotifier.new);

class NetworkStatusNotifier extends Notifier<bool> {
  Timer? _recoveryTimer;

  @override
  bool build() {
    ref.onDispose(_stopRecoveryCheck);
    return true;
  }

  /// Called by ApiClient when a request fails due to connection issues
  void reportError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      if (state) {
        state = false;
        // Start checking for recovery
        _startRecoveryCheck();
      }
    }
  }

  /// Manually set status (e.g., from connectivity package listen)
  void setStatus(bool isOnline) {
    if (state != isOnline) {
      state = isOnline;
    }
    if (isOnline) {
      _stopRecoveryCheck();
    } else {
      _startRecoveryCheck();
    }
  }

  void _startRecoveryCheck() {
    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (state) {
        _stopRecoveryCheck();
      }
      // Recovery is driven by successful API calls or manual retry actions.
    });
  }

  void markOnline() {
    if (!state) {
      state = true;
    }
    _stopRecoveryCheck();
  }

  /// Manually force offline status (e.g. critical wallet error)
  void forceOffline() {
    if (state) {
      state = false;
    }
    _startRecoveryCheck();
  }

  /// Manually check connection (e.g. Pull to Refresh)
  Future<void> checkConnection() async {
    // Optimistically set to online to try requests again
    // If requests fail, 'reportError' will set it back to offline
    state = true;

    // Optionally we could do a real ping here if we wanted strict checking
    // But letting the user try their action (which will likely trigger API calls)
    // is often better UX than blocking them with a ping check.
    _stopRecoveryCheck();
  }

  void _stopRecoveryCheck() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }
}
