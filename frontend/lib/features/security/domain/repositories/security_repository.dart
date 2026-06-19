import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_pin_status.dart';
import '../entities/account_security_profile.dart';
import '../entities/admin_access.dart';
import '../entities/passkey_inventory.dart';
import '../entities/security_status.dart';
import '../entities/kfe_reserve_overview.dart';

abstract class SecurityRepository {
  Future<Either<Failure, SecurityStatus>> getSovereigntyStatus();
  Future<Either<Failure, KfeReserveOverview>> getKfeReserveOverview();
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
  Future<Either<Failure, PasskeyInventory>> blockPasskeyDevice(
    String deviceInstallId,
  );
  Future<Either<Failure, PasskeyInventory>> revokePasskeyDevice(
    String deviceInstallId,
  );
  Future<Either<Failure, AdminKeyStatus>> getAdminKeyStatus();
  Future<Either<Failure, AdminKeyStatus>> createAdminKey({
    required String keyMaterialHash,
    required String deviceInstallId,
  });
  Future<Either<Failure, AdminKeyStatus>> revokeAdminKey();
  Future<Either<Failure, List<AdminAccessAttempt>>> getPendingAdminAttempts();
  Future<Either<Failure, AdminAccessAttempt>> decideAdminAttempt({
    required String attemptId,
    required bool approve,
  });
  Future<Either<Failure, List<AdminAuthenticatedDevice>>> getAdminDevices();
  Future<Either<Failure, void>> blockAdminDevice(String deviceId);
  Future<Either<Failure, void>> revokeAdminDevice(String deviceId);
}
