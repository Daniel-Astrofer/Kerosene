import 'dart:async';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/domain/entities/user.dart';
import 'package:teste/core/services/price_websocket_service.dart';
import 'package:flutter/foundation.dart';

/// Mock Auth Controller for Storybook.
class MockAuthController extends AuthController {
  final AuthState initialOverride;

  MockAuthController({this.initialOverride = const AuthInitial()});

  @override
  AuthState build() {
    return initialOverride;
  }

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> loginWithPasskey(String username) async {}

  @override
  Future<void> verifyTotp(
      {required String username,
      required String passphrase,
      required String totpSecret,
      required String totpCode}) async {}

  @override
  Future<void> verifyLoginTotp(
      {required String username,
      required String passphrase,
      required String totpCode,
      String? preAuthToken}) async {}

  @override
  void clearError() {}
}

/// Mock Price WebSocket Service for Storybook.
class MockPriceWebSocketService implements PriceWebSocketService {
  final _priceController = StreamController<double>.broadcast();

  @override
  Stream<double> get priceStream => _priceController.stream;

  @override
  void connect() {
    debugPrint('>>> MockPriceWebSocket: Connection simulated');
    // Periodically push some mock data to keep it "alive"
    _priceController.add(67234.50);
  }

  @override
  void dispose() {
    _priceController.close();
  }
}

/// Helper for standard mock user
final mockUser = User(
  id: 'sat-001',
  username: 'Satoshi Nakamoto',
  createdAt: DateTime.now(),
);

/// Helper for authenticated state
final mockAuthenticatedState = AuthAuthenticated(mockUser);
