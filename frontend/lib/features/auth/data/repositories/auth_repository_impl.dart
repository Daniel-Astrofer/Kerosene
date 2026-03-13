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

  // ─── Login — returns LoginResult with userId + JWT ────────────────────────────
  @override
  Future<Either<Failure, LoginResult>> login({
    required String username,
    required String passphrase,
  }) async {
    try {
      final loginResult = await remoteDataSource.login(
        username: username,
        passphrase: passphrase,
      );
      // Save the JWT (or preAuthToken) from the login response immediately 
      // so it can be used for the TOTP verification step.
      if (loginResult.jwt.isNotEmpty) {
        await localDataSource.saveToken(loginResult.jwt);
      }
      
      // Save the passphrase locally so it can be used for signing later
      await localDataSource.saveMnemonic(passphrase);
      return Right(loginResult);
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
    String? preAuthToken,
  }) async {
    try {
      final token = preAuthToken ?? await localDataSource.getToken() ?? '';
      
      final jwt = await remoteDataSource.verifyLoginTotp(
        username: username,
        totpCode: totpCode,
        preAuthToken: token,
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

      // According to API_REFERENCE.md Section 1.1: "Returns JWT"
      // WRONG: Actual server log shows it returns a sessionId (hex), not a JWT.
      // Saving it as a token causes the interceptor to send invalid Bearer headers.
      // We do NOT save it as a token here.

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
    Map<String, dynamic> credential,
  ) async {
    try {
      await remoteDataSource.registerPasskeyOnboardingFinish(
        sessionId,
        credential,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Real Passkey Login/Register ──────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> passkeyLoginStart(String username) async {
    try {
      final opts = await remoteDataSource.passkeyLoginStart(username);
      return Right(opts);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> passkeyLoginFinish({
    required String username,
    required Map<String, dynamic> credential,
  }) async {
    try {
      final loginResult = await remoteDataSource.passkeyLoginFinish(
        username,
        credential,
      );

      if (loginResult.jwt.isNotEmpty) {
        await localDataSource.saveToken(loginResult.jwt);
      }

      final user = UserModel(
        id: loginResult.userId.isNotEmpty ? loginResult.userId : '0',
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

  @override
  Future<Either<Failure, String>> passkeyRegisterStart() async {
    try {
      final opts = await remoteDataSource.passkeyRegisterStart();
      return Right(opts);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> passkeyRegisterFinish(
    Map<String, dynamic> credential,
  ) async {
    try {
      await remoteDataSource.passkeyRegisterFinish(credential);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Sovereign Auth (Hardware Ed25519) ──────────────────────────────────────────

  @override
  Future<Either<Failure, String>> registerHardwareOnboardingStart(
    String sessionId,
  ) async {
    try {
      final challenge = await remoteDataSource.hardwareRegisterStart(sessionId);
      return Right(challenge);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerHardwareOnboardingFinish({
    required String sessionId,
    required String publicKey,
    required String deviceName,
    required String signature,
  }) async {
    try {
      await remoteDataSource.hardwareRegisterFinish(
        sessionId: sessionId,
        publicKey: publicKey,
        deviceName: deviceName,
        signature: signature,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> registerHardwareForAccountStart() async {
    try {
      final challenge = await remoteDataSource.hardwareRegisterForAccountStart();
      return Right(challenge);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerHardwareForAccountFinish({
    required String publicKey,
    required String deviceName,
  }) async {
    try {
      await remoteDataSource.hardwareRegisterForAccountFinish(
        publicKey: publicKey,
        deviceName: deviceName,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> hardwareLoginStart(String username) async {
    try {
      final challenge = await remoteDataSource.getHardwareChallenge(username);
      return Right(challenge);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> hardwareLoginFinish({
    required String username,
    required String signature,
  }) async {
    try {
      final loginResult = await remoteDataSource.verifyHardwareSignature(
        username: username,
        signature: signature,
      );

      if (loginResult.jwt.isNotEmpty) {
        await localDataSource.saveToken(loginResult.jwt);
      }

      final user = UserModel(
        id: loginResult.userId.isNotEmpty ? loginResult.userId : '0',
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

  @override
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId) async {
    try {
      await remoteDataSource.mockConfirmOnboarding(sessionId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmVoucher({
    required String voucherId,
    required String txid,
  }) async {
    try {
      await remoteDataSource.confirmVoucher(voucherId: voucherId, txid: txid);
      return const Right(null);
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
