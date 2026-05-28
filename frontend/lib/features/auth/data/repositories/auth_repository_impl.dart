import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/device_helper.dart';
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
      // Persist only final JWTs. A pre_auth_token is temporary and must not be
      // stored as the session token, otherwise the backend JWT filter will
      // reject later requests with "invalid compact jwt".
      if (!loginResult.requiresTotp &&
          loginResult.jwt.isNotEmpty &&
          loginResult.jwt.contains('.')) {
        await localDataSource.saveToken(loginResult.jwt);
        await _saveSessionUser(
          userId: loginResult.userId,
          username: username,
        );
      } else {
        await localDataSource.removeToken();
      }
      return Right(loginResult);
    } on AuthException catch (e) {
      return Left(AuthFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminLoginResult>> startAdminLogin({
    required String username,
    required String password,
    required String adminKeyProof,
    required DeviceMetadata deviceMetadata,
  }) async {
    try {
      final result = await remoteDataSource.startAdminLogin(
        username: username,
        password: password,
        adminKeyProof: adminKeyProof,
        deviceMetadata: deviceMetadata,
      );
      if (result.token.isNotEmpty && result.token.contains('.')) {
        final parsed = LoginResult.fromResponseData(result.token);
        await localDataSource.saveToken(parsed.jwt);
        await _saveSessionUser(
          userId: parsed.userId,
          username: username,
          role: 'ADMIN',
          isAdmin: true,
        );
      }
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } on AppException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminLoginResult>> pollAdminLogin(
      String attemptId) async {
    try {
      final result = await remoteDataSource.pollAdminLogin(attemptId);
      if (result.token.isNotEmpty) {
        final parsed = LoginResult.fromResponseData(result.token);
        if (parsed.jwt.isNotEmpty && parsed.jwt.contains('.')) {
          await localDataSource.saveToken(parsed.jwt);
          await _saveSessionUser(
            userId: parsed.userId,
            username: 'Admin',
            role: 'ADMIN',
            isAdmin: true,
          );
        }
      }
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
    } on AppException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        data: e.data,
      ));
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
      final token = preAuthToken?.trim() ?? '';
      if (token.isEmpty) {
        return const Left(
          AuthFailure(
            message:
                'Sessão de autenticação inválida. Faça login novamente para continuar.',
            statusCode: 401,
            errorCode: 'ERR_AUTH_INVALID_PREAUTH',
          ),
        );
      }

      final jwt = await remoteDataSource.verifyLoginTotp(
        username: username,
        totpCode: totpCode,
        preAuthToken: token,
      );

      await localDataSource.saveToken(jwt);

      final user = UserModel(
        id: '0',
        username: username,
        createdAt: DateTime.now(),
      );
      await localDataSource.saveUser(user);
      return Right(user);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  }) async {
    try {
      final result = await remoteDataSource.signup(
        username: username,
        passphrase: passphrase,
        accountSecurity: accountSecurity,
        shamirTotalShares: shamirTotalShares,
        shamirThreshold: shamirThreshold,
        multisigThreshold: multisigThreshold,
      );
      await localDataSource.saveBackupCodes(result.backupCodes);
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Verify Signup TOTP — retorna sessionId (Redis, temporário) ──────────────
  @override
  Future<Either<Failure, String>> verifyTotp({
    required String sessionId,
    String? totpCode,
  }) async {
    try {
      final verifiedSessionId = await remoteDataSource.verifySignupTotp(
        sessionId: sessionId,
        totpCode: totpCode,
      );

      return Right(verifiedSessionId);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoginResult>> passkeyRegisterOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  ) async {
    try {
      final loginResult =
          await remoteDataSource.passkeyRegisterOnboardingFinish(
        sessionId,
        credential,
      );
      if (loginResult.jwt.isNotEmpty) {
        await localDataSource.saveToken(loginResult.jwt);
      }
      return Right(loginResult);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Account activation deposit flow ─────────────────────────────────────────
  @override
  Future<Either<Failure, ActivationStatusResult>> getActivationStatus() async {
    try {
      final dto = await remoteDataSource.getActivationStatus();
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActivationStatusResult>>
      createActivationDepositLink() async {
    try {
      final dto = await remoteDataSource.createActivationDepositLink();
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActivationStatusResult>> confirmActivationPayment({
    required String linkId,
    required String txid,
  }) async {
    try {
      final dto = await remoteDataSource.confirmActivationPayment(
        linkId: linkId,
        txid: txid,
      );
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountSecurityStatusResult>>
      getSecurityStatus() async {
    try {
      final dto = await remoteDataSource.getSecurityStatus();
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TotpSetupResult>> setupTotp() async {
    try {
      final dto = await remoteDataSource.setupTotp();
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BackupCodesStatusResult>> verifyTotpSetup({
    required String totpCode,
  }) async {
    try {
      final dto = await remoteDataSource.verifyTotpSetup(totpCode: totpCode);
      if (dto.newlyGeneratedCodes.isNotEmpty) {
        await localDataSource.saveBackupCodes(dto.newlyGeneratedCodes);
      }
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disableTotp() async {
    try {
      await remoteDataSource.disableTotp();
      await localDataSource.removeTotpSecret();
      await localDataSource.removeBackupCodes();
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BackupCodesStatusResult>>
      getBackupCodesStatus() async {
    try {
      final dto = await remoteDataSource.getBackupCodesStatus();
      if (dto.newlyGeneratedCodes.isNotEmpty) {
        await localDataSource.saveBackupCodes(dto.newlyGeneratedCodes);
      }
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BackupCodesStatusResult>>
      regenerateBackupCodes() async {
    try {
      final dto = await remoteDataSource.regenerateBackupCodes();
      if (dto.newlyGeneratedCodes.isNotEmpty) {
        await localDataSource.saveBackupCodes(dto.newlyGeneratedCodes);
      }
      return Right(dto);
    } on AppException catch (e) {
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      } catch (_) {
        debugPrint('Remote logout failed; clearing local session.');
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
        return Left(AuthFailure(
            message: e.message,
            statusCode: e.statusCode,
            errorCode: e.errorCode,
            data: e.data));
      }
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao obter usuário: $e'));
    }
  }

  Future<void> _saveSessionUser({
    required String username,
    String? userId,
    String role = 'USER',
    bool isAdmin = false,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      return;
    }

    await localDataSource.saveUser(UserModel(
      id: userId != null && userId.trim().isNotEmpty ? userId.trim() : '0',
      username: normalizedUsername,
      role: role,
      isAdmin: isAdmin,
      createdAt: DateTime.now(),
    ));
  }

  // ─── refreshToken ─────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final newToken = await remoteDataSource.refreshToken();
      if (newToken.isNotEmpty) {
        await localDataSource.saveToken(newToken);
        final currentUser = await localDataSource.getUser();
        final user = currentUser ??
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
      return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          data: e.data));
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
      return const Left(
          CacheFailure(message: 'Nenhum código de backup encontrado'));
    } catch (e) {
      return Left(
          CacheFailure(message: 'Erro ao obter os códigos de backup: $e'));
    }
  }
}
