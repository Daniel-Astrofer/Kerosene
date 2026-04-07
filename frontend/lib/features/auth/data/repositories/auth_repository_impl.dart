import 'package:flutter/foundation.dart';
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
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
        username: username,
        createdAt: DateTime.now(),
      );
      await localDataSource.saveUser(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao verificar TOTP: $e'));
    }
  }

  // ─── Passkey onboarding ───────────────────────────────────────────────────────
  @override
  Future<Either<Failure, String>> passkeyRegisterOnboardingStart({
    required String sessionId,
    String? username,
  }) async {
    try {
      final opts = await remoteDataSource.passkeyRegisterOnboardingStart(
        sessionId: sessionId,
        username: username,
      );
      return Right(opts);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> passkeyRegisterOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  ) async {
    try {
      await remoteDataSource.passkeyRegisterOnboardingFinish(
        sessionId,
        credential,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoginResult>> passkeyLoginFinish({
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

      // We still update the local user info if needed
      final user = UserModel(
        id: loginResult.userId.isNotEmpty ? loginResult.userId : '0',
        username: username,
        createdAt: DateTime.now(),
      );
      await localDataSource.saveUser(user);

      return Right(loginResult);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> passkeyRegisterStart(String username) async {
    try {
      final opts = await remoteDataSource.passkeyRegisterStart(username);
      return Right(opts);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OnboardingPaymentLinkDto>> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  }) async {
    try {
      final dto = await remoteDataSource.confirmOnboardingPayment(
        linkId: linkId,
        txid: txid,
      );
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OnboardingPaymentLinkDto>> getOnboardingPaymentLink(
    String linkId,
  ) async {
    try {
      final dto = await remoteDataSource.getOnboardingPaymentLink(linkId);
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      try {
        await remoteDataSource.logout();
      } catch (e) {
        debugPrint('Remote logout failed, proceeding with local clear: $e');
      }
      await localDataSource.clearAll();
      return const Right(null);
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

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // 1. Try local cache
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) return Right(cachedUser);

      // 2. Try remote if not in cache (requires valid token in intercepted headers)
      final remoteUser = await remoteDataSource.getCurrentUser();
      
      // 3. Save locally and return
      await localDataSource.saveUser(remoteUser);
      
      return Right(remoteUser as User);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on AppException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return Left(AuthFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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
              username: 'User',
              createdAt: DateTime.now(),
            );
        await localDataSource.saveUser(user);
        return Right(user);
      }
      return const Left(AuthFailure(message: 'Falha ao renovar token'));
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode, errorCode: e.errorCode));
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

  // ─── Backup Codes ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<String>>> getBackupCodes() async {
    try {
      final codes = await localDataSource.getBackupCodes();
      if (codes != null && codes.isNotEmpty) {
        return Right(codes);
      }
      return const Left(CacheFailure(message: 'Nenhum código de backup encontrado'));
    } catch (e) {
      return Left(CacheFailure(message: 'Erro ao obter os códigos de backup: $e'));
    }
  }
}
