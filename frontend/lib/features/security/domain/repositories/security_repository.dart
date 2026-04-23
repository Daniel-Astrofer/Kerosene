import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_security_profile.dart';
import '../entities/security_status.dart';

abstract class SecurityRepository {
  Future<Either<Failure, SecurityStatus>> getSovereigntyStatus();
  Future<Either<Failure, bool>> checkSovereignty();
  Future<Either<Failure, void>> sendTelemetry(Map<String, dynamic> data);
  Future<Either<Failure, Map<String, dynamic>>> reattest();

  // Audit
  Future<Either<Failure, Map<String, dynamic>>> getAuditStats();
  Future<Either<Failure, Map<String, dynamic>>> getLatestMerkleRoot();
  Future<Either<Failure, List<dynamic>>> getMerkleHistory();
  Future<Either<Failure, Map<String, dynamic>>> triggerAudit();

  Future<Either<Failure, AccountSecurityProfile>> getAccountSecurityProfile();
  Future<Either<Failure, AccountSecurityProfile>> updateAccountSecurityProfile(
    AccountSecurityProfile profile,
  );
}
