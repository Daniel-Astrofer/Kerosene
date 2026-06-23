import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/domain/repositories/auth_repository.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/auth/domain/usecases/login_usecase.dart';
import 'package:kerosene/features/auth/domain/entities/login_result.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  late final AuthRepository repository;
  @override
  Future<Either<Failure, LoginResult>> call(LoginParams params) async {
    return const Left(
        ServerFailure(message: 'SocketException: Failed host lookup'));
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> clearInvalidSession() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SessionRetryRepository implements AuthRepository {
  int currentUserCalls = 0;
  bool? lastForceRemote;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Either<Failure, User>> getCurrentUser({
    bool forceRemote = false,
  }) async {
    currentUserCalls += 1;
    lastForceRemote = forceRemote;
    return const Left(ServerFailure(message: 'server down'));
  }

  void resetCalls() {
    currentUserCalls = 0;
    lastForceRemote = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UnauthenticatedRetryRepository implements AuthRepository {
  int availabilityChecks = 0;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<Either<Failure, void>> checkServerAvailability() async {
    availabilityChecks += 1;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'),
            (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers'), (call) async => 1);
  });

  group('AuthController Network Failure Tests', () {
    test(
        'State machine should transition from AuthLoading to AuthError on SocketException during login',
        () async {
      final mockLoginUseCase = MockLoginUseCase();
      final mockAuthRepo = MockAuthRepository();

      final container = ProviderContainer(overrides: [
        loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ]);

      final controller = container.read(authControllerProvider.notifier);

      // Attempt login
      await controller.login(username: 'test', password: 'pass');

      // Yield to event loop because auth_controller.dart's fold doesn't await the async callback!
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(authControllerProvider);

      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('SocketException'));
    });

    test('retrySessionCheck forces a remote current-user request', () async {
      final repository = SessionRetryRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(repository.lastForceRemote, isFalse);

      repository.resetCalls();
      await controller.retrySessionCheck();

      expect(repository.currentUserCalls, 1);
      expect(repository.lastForceRemote, isTrue);
      expect(
          container.read(authControllerProvider), isA<AuthServerUnavailable>());
    });

    test('retrySessionCheck probes the auth API without a local session',
        () async {
      final repository = UnauthenticatedRetryRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(repository.availabilityChecks, 0);

      await controller.retrySessionCheck();

      expect(repository.availabilityChecks, 1);
      expect(
          container.read(authControllerProvider), isA<AuthUnauthenticated>());
    });
  });
}
