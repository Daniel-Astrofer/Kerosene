import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/security_remote_datasource.dart';
import '../../domain/entities/account_security_profile.dart';
import '../../domain/entities/security_status.dart';
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
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
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountSecurityProfile>>
      updateAccountSecurityProfile(AccountSecurityProfile profile) async {
    try {
      final result =
          await remoteDataSource.updateAccountSecurityProfile(profile);
      return Right(AccountSecurityProfile.fromJson(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
