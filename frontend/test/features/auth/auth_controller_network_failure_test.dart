import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/domain/repositories/auth_repository.dart';
import 'package:kerosene/features/auth/domain/usecases/login_usecase.dart';
import 'package:kerosene/features/auth/data/datasources/auth_remote_datasource.dart' show LoginResult;
import 'package:kerosene/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class MockLoginUseCase implements LoginUseCase {
  @override
  late final AuthRepository repository;
  @override
  Future<Either<Failure, LoginResult>> call(LoginParams params) async {
    return const Left(ServerFailure(message: 'SocketException: Failed host lookup'));
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> clearInvalidSession() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => 1);
  });
  
  group('AuthController Network Failure Tests', () {
    test('State machine should transition from AuthLoading to AuthError on SocketException during login', () async {
      final mockLoginUseCase = MockLoginUseCase();
      final mockAuthRepo = MockAuthRepository();
      
      final container = ProviderContainer(
        overrides: [
          loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ]
      );
      
      final controller = container.read(authControllerProvider.notifier);
      
      // Attempt login
      await controller.login(username: 'test', password: 'pass');
      
      // Yield to event loop because auth_controller.dart's fold doesn't await the async callback!
      await Future.delayed(const Duration(milliseconds: 100));
      
      final state = container.read(authControllerProvider);
      
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('SocketException'));
    });
  });
}
