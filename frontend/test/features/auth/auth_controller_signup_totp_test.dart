import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/data/datasources/auth_remote_datasource.dart'
    show SignupInitResult;
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/auth/domain/repositories/auth_repository.dart';

class _SignupTotpRepository implements AuthRepository {
  int verifyTotpCalls = 0;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<Either<Failure, User>> getCurrentUser({
    bool forceRemote = false,
  }) async =>
      const Left(AuthFailure(message: 'unauthenticated'));

  @override
  Future<Either<Failure, SignupInitResult>> signup({
    required String username,
    required String passphrase,
    String accountSecurity = 'STANDARD',
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    return const Right(
      SignupInitResult(
        sessionId: 'signup_session',
        totpSecret: 'JBSWY3DPEHPK3PXP',
        qrCodeUri:
            'otpauth://totp/Kerosene:test_user?secret=JBSWY3DPEHPK3PXP&issuer=Kerosene',
        backupCodes: ['12345678'],
        totpOptional: true,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> verifyTotp({
    required String sessionId,
    String? totpCode,
  }) async {
    verifyTotpCalls += 1;
    return const Right('unexpected_remote_session');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skipTotpSetup advances with signup session without remote verify call',
      () async {
    final repository = _SignupTotpRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.signup(
      username: 'test_user',
      password: 'StrongPassphrase123!',
    );

    expect(
        container.read(authControllerProvider), isA<AuthRequiresTotpSetup>());

    await controller.skipTotpSetup();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthTotpVerified>());
    expect((state as AuthTotpVerified).sessionId, 'signup_session');
    expect(state.username, 'test_user');
    expect(repository.verifyTotpCalls, 0);
  });
}
