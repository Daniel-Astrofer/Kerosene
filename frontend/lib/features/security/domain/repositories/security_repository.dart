import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_pin_status.dart';
import '../entities/account_security_profile.dart';
import '../entities/security_status.dart';
import '../entities/treasury_overview.dart';

abstract class SecurityRepository {
  Future<Either<Failure, SecurityStatus>> getSovereigntyStatus();
  Future<Either<Failure, TreasuryOverview>> getTreasuryOverview();
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
  Future<Either<Failure, AppPinStatus>> getAppPinStatus();
  Future<Either<Failure, AppPinStatus>> configureAppPin({
    required bool enabled,
    String? pin,
    String? currentPin,
    String? totpCode,
  });
  Future<Either<Failure, AppPinStatus>> verifyAppPin({
    required String pin,
  });
}
