import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Provider to expose the current network status
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
      return NetworkStatusNotifier();
    });

class NetworkStatusNotifier extends StateNotifier<bool> {
  NetworkStatusNotifier() : super(true);

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
  }

  void _startRecoveryCheck() {
    // Basic retry mechanism - could be improved with real ping
    // For now, let's assume if the user retries an action and it succeeds, we are back online.
    // Or we can poll a health endpoint.
    // Implementing a simple periodic check:
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (state) {
        timer.cancel();
        return;
      }
      // Ideally we would double check connectivity here with a simple HEAD request
      // For simplicity in this step, we will rely on ApiClient success or manual Retry button
    });
  }

  void markOnline() {
    if (!state) state = true;
  }

  /// Manually force offline status (e.g. critical wallet error)
  void forceOffline() {
    if (state) state = false;
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
  }
}
