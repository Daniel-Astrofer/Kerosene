import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../network/api_client_provider.dart';

/// Provider to expose the current network status
final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, bool>(NetworkStatusNotifier.new);

class NetworkStatusNotifier extends Notifier<bool> {
  Timer? _recoveryTimer;
  bool _isCheckingConnection = false;

  @override
  bool build() {
    ref.onDispose(() => _recoveryTimer?.cancel());
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
    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      if (state) {
        _stopRecoveryCheck();
        return;
      }
      unawaited(checkConnection());
    });
  }

  void _stopRecoveryCheck() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
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
  Future<bool> checkConnection() async {
    if (_isCheckingConnection) {
      return state;
    }

    _isCheckingConnection = true;
    try {
      await ref.read(apiClientProvider).get(AppConfig.sovereigntyPing);
      markOnline();
      return true;
    } catch (error) {
      if (error is NetworkException) {
        state = false;
        _startRecoveryCheck();
        return false;
      }

      // If the server answered with any application error, the network path is alive.
      markOnline();
      return true;
    } finally {
      _isCheckingConnection = false;
    }
  }
}
