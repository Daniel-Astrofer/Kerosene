import 'package:teste/features/auth/controller/auth_controller.dart';

class TestAuthController extends AuthController {
  final AuthState initialState;

  TestAuthController({
    AuthState initialOverride = const AuthUnauthenticated(),
  }) : initialState = initialOverride;

  @override
  AuthState build() => initialState;

  @override
  Future<void> loginWithPasskey(
    String username, {
    int remainingChallengeRenewals = 0,
  }) async {
    state = initialState;
  }
}
