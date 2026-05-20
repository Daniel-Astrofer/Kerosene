import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/providers/shared_preferences_provider.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/domain/entities/user.dart';
import 'package:teste/features/home/presentation/screens/home_loading_screen.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wallet loading error does not logout the active session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    final authController = _TrackingAuthController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authControllerProvider.overrideWith(() => authController),
          walletProvider.overrideWith(() => _FailingWalletNotifier()),
        ],
        child: const MaterialApp(home: HomeLoadingScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authController.logoutCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _TrackingAuthController extends AuthController {
  int logoutCalls = 0;

  @override
  AuthState build() => AuthAuthenticated(_testUser);

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    state = const AuthUnauthenticated();
  }
}

class _FailingWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => const WalletInitial();

  @override
  Future<void> refresh() async {
    state = const WalletError('Rede temporariamente indisponível');
  }
}

final _testUser = User(
  id: 'user-1',
  username: 'satoshi',
  createdAt: DateTime(2026, 1, 1),
);
