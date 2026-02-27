import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementação do AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // ─── Login — retorna authId para uso no TOTP posterior ───────────────────────
  @override
  Future<Either<Failure, String>> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final authId = await remoteDataSource.login(
        username: username,
        passphrase: passphrase,
      );
      // Save the passphrase locally so it can be used for signing later
      await localDataSource.saveMnemonic(passphrase);
      return Right(authId);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Verify Login TOTP — retorna User com JWT ────────────────────────────────
  @override
  Future<Either<Failure, User>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  }) async {
    try {
      final jwt = await remoteDataSource.verifyLoginTotp(
        username: username,
        totpCode: totpCode, // passphrase NOT sent — new API contract
      );

      await localDataSource.saveToken(jwt);
      // passphrase was already saved during login(); ensure it's current
      await localDataSource.saveMnemonic(passphrase);

      final user = UserModel(
        id: '0',
        email: '$username@kerosene.app',
        name: username,
        createdAt: DateTime.now(),
      );
      await localDataSource.saveUser(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Signup — resolve PoW e retorna {totpSecret, qrCodeUri} ─────────────────
  @override
  Future<Either<Failure, SignupInitResult>> signup({
    required String username,
    required String passphrase,
    String accountSecurity = 'STANDARD',
  }) async {
    try {
      final result = await remoteDataSource.signup(
        username: username,
        passphrase: passphrase,
        accountSecurity: accountSecurity,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Verify Signup TOTP — retorna sessionId (Redis, temporário) ──────────────
  @override
  Future<Either<Failure, String>> verifyTotp({
    required String username,
    required String passphrase,
    required String totpCode,
    String? totpSecret,
  }) async {
    try {
      final sessionId = await remoteDataSource.verifySignupTotp(
        username: username,
        totpCode: totpCode, // passphrase NOT sent in new API
      );

      // Store totp secret locally if provided
      if (totpSecret != null && totpSecret.isNotEmpty) {
        await localDataSource.saveTotpSecret(totpSecret);
      }

      // ⚠️ No JWT is saved here. User is NOT authenticated yet.
      // JWT is only issued after 3 Bitcoin confirmations.
      return Right(sessionId);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao verificar TOTP: $e'));
    }
  }

  // ─── Passkey onboarding ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, String>> registerPasskeyOnboardingStart(
    String sessionId,
  ) async {
    try {
      final opts = await remoteDataSource.registerPasskeyOnboardingStart(
        sessionId,
      );
      return Right(opts);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerPasskeyOnboardingFinish(
    String sessionId,
    String credentialJson,
  ) async {
    try {
      await remoteDataSource.registerPasskeyOnboardingFinish(
        sessionId,
        credentialJson,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Voucher onboarding link ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, OnboardingPaymentLinkDto>> generateOnboardingLink(
    String sessionId,
  ) async {
    try {
      final dto = await remoteDataSource.generateOnboardingLink(sessionId);
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearAll();
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao fazer logout: $e'));
    }
  }

  // ─── isAuthenticated ──────────────────────────────────────────────────────────
  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  // ─── clearInvalidSession ──────────────────────────────────────────────────────
  // Removes the token and cached user locally without calling the backend.
  // Called when the stored token is mismatched/stale so the user must re-login.
  @override
  Future<void> clearInvalidSession() async {
    try {
      await localDataSource.removeToken();
      await localDataSource.removeUser();
    } catch (_) {}
  }

  // ─── getCurrentUser ───────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) return Right(cachedUser);
      return const Left(CacheFailure(message: 'Usuário não encontrado'));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao obter usuário: $e'));
    }
  }

  // ─── refreshToken ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final newToken = await remoteDataSource.refreshToken();
      if (newToken.isNotEmpty) {
        await localDataSource.saveToken(newToken);
        final currentUser = await localDataSource.getUser();
        final user =
            currentUser ??
            UserModel(
              id: '0',
              email: 'user@kerosene.app',
              name: 'User',
              createdAt: DateTime.now(),
            );
        await localDataSource.saveUser(user);
        return Right(user);
      }
      return const Left(AuthFailure(message: 'Falha ao renovar token'));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao renovar token: $e'));
    }
  }

  // ─── validatePassphrase ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, bool>> validatePassphrase(String passphrase) async {
    try {
      final storedMnemonic = await localDataSource.getMnemonic();
      if (storedMnemonic == null) {
        return const Left(
          CacheFailure(message: 'Nenhuma passphrase salva encontrada.'),
        );
      }
      return Right(storedMnemonic == passphrase);
    } catch (e) {
      return Left(CacheFailure(message: 'Erro ao validar passphrase: $e'));
    }
  }
}
