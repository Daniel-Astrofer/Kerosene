import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/security_remote_datasource.dart';
import '../../domain/entities/app_pin_status.dart';
import '../../domain/entities/account_security_profile.dart';
import '../../domain/entities/admin_access.dart';
import '../../domain/entities/security_status.dart';
import '../../domain/entities/treasury_overview.dart';
import '../../domain/repositories/security_repository.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final SecurityRemoteDataSource remoteDataSource;

  SecurityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SecurityStatus>> getSovereigntyStatus() async {
    try {
      final json = await remoteDataSource.getSovereigntyStatus();
      return Right(SecurityStatus.fromJson(json));
    } on ServerException catch (e) {
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
  Future<Either<Failure, TreasuryOverview>> getTreasuryOverview() async {
    try {
      final json = await remoteDataSource.getTreasuryOverview();
      return Right(TreasuryOverview.fromJson(json));
    } on ServerException catch (e) {
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
  Future<Either<Failure, bool>> checkSovereignty() async {
    try {
      final result = await remoteDataSource.pingSovereignty();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendTelemetry(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.sendTelemetry(data);
      return const Right(null);
    } on ServerException catch (e) {
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
  Future<Either<Failure, Map<String, dynamic>>> reattest() async {
    try {
      final result = await remoteDataSource.reattest();
      return Right(result);
    } on ServerException catch (e) {
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
  Future<Either<Failure, Map<String, dynamic>>> getAuditStats() async {
    try {
      final result = await remoteDataSource.getAuditStats();
      return Right(result);
    } on ServerException catch (e) {
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
  Future<Either<Failure, Map<String, dynamic>>> getLatestMerkleRoot() async {
    try {
      final result = await remoteDataSource.getLatestMerkleRoot();
      return Right(result);
    } on ServerException catch (e) {
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
  Future<Either<Failure, List<dynamic>>> getMerkleHistory() async {
    try {
      final result = await remoteDataSource.getMerkleHistory();
      return Right(result);
    } on ServerException catch (e) {
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
  Future<Either<Failure, Map<String, dynamic>>> triggerAudit() async {
    try {
      final result = await remoteDataSource.triggerAudit();
      return Right(result);
    } on ServerException catch (e) {
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
  Future<Either<Failure, AccountSecurityProfile>>
      getAccountSecurityProfile() async {
    try {
      final result = await remoteDataSource.getAccountSecurityProfile();
      return Right(AccountSecurityProfile.fromJson(result));
    } on ServerException catch (e) {
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
  Future<Either<Failure, AccountSecurityProfile>> updateAccountSecurityProfile(
      AccountSecurityProfile profile) async {
    try {
      final result =
          await remoteDataSource.updateAccountSecurityProfile(profile);
      return Right(AccountSecurityProfile.fromJson(result));
    } on ServerException catch (e) {
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
  Future<Either<Failure, AppPinStatus>> getAppPinStatus() async {
    try {
      final result = await remoteDataSource.getAppPinStatus();
      return Right(AppPinStatus.fromJson(result));
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
  Future<Either<Failure, AppPinStatus>> configureAppPin({
    required bool enabled,
    String? pin,
    String? currentPin,
    String? totpCode,
  }) async {
    try {
      final result = await remoteDataSource.configureAppPin(
        enabled: enabled,
        pin: pin,
        currentPin: currentPin,
        totpCode: totpCode,
      );
      return Right(AppPinStatus.fromJson(result));
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
  Future<Either<Failure, AppPinStatus>> verifyAppPin({
    required String pin,
  }) async {
    try {
      final result = await remoteDataSource.verifyAppPin(pin: pin);
      return Right(AppPinStatus.fromJson(result));
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
  Future<Either<Failure, AdminKeyStatus>> getAdminKeyStatus() async {
    try {
      final result = await remoteDataSource.getAdminKeyStatus();
      return Right(AdminKeyStatus.fromJson(result));
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
  Future<Either<Failure, AdminKeyStatus>> createAdminKey({
    required String keyMaterialHash,
    required String deviceInstallId,
  }) async {
    try {
      final result = await remoteDataSource.createAdminKey(
        keyMaterialHash: keyMaterialHash,
        deviceInstallId: deviceInstallId,
      );
      return Right(AdminKeyStatus.fromJson(result));
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
  Future<Either<Failure, AdminKeyStatus>> revokeAdminKey() async {
    try {
      final result = await remoteDataSource.revokeAdminKey();
      return Right(AdminKeyStatus.fromJson(result));
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
  Future<Either<Failure, List<AdminAccessAttempt>>>
      getPendingAdminAttempts() async {
    try {
      return Right(await remoteDataSource.getPendingAdminAttempts());
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
  Future<Either<Failure, AdminAccessAttempt>> decideAdminAttempt({
    required String attemptId,
    required bool approve,
  }) async {
    try {
      return Right(await remoteDataSource.decideAdminAttempt(
        attemptId: attemptId,
        approve: approve,
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
  Future<Either<Failure, List<AdminAuthenticatedDevice>>>
      getAdminDevices() async {
    try {
      return Right(await remoteDataSource.getAdminDevices());
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
  Future<Either<Failure, void>> blockAdminDevice(String deviceId) async {
    try {
      await remoteDataSource.blockAdminDevice(deviceId);
      return const Right(null);
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
  Future<Either<Failure, void>> revokeAdminDevice(String deviceId) async {
    try {
      await remoteDataSource.revokeAdminDevice(deviceId);
      return const Right(null);
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
}
