import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/login_result.dart';
import '../../../../core/utils/device_helper.dart';
import '../../data/datasources/auth_remote_datasource.dart'
    show
        SignupInitResult,
        ActivationStatusResult,
        AccountSecurityStatusResult,
        BackupCodesStatusResult,
        AdminLoginResult,
        TotpSetupResult,
        OnboardingPaymentLinkDto;

/// Interface do repositório de autenticação
abstract class AuthRepository {
  /// Login — returns LoginResult with userId and JWT
  Future<Either<Failure, LoginResult>> login({
    required String username,
    required String passphrase,
  });

  Future<Either<Failure, AdminLoginResult>> startAdminLogin({
    required String username,
    required String password,
    required String adminKeyProof,
    required DeviceMetadata deviceMetadata,
  });

  Future<Either<Failure, AdminLoginResult>> pollAdminLogin(String attemptId);

  /// Signup — resolve PoW e retorna {totpSecret, qrCodeUri}
  Future<Either<Failure, SignupInitResult>> signup({
    required String username,
    required String passphrase,
    String accountSecurity,
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
  });

  /// Fazer logout
  Future<Either<Failure, void>> logout();

  /// Obter usuário atual.
  Future<Either<Failure, User>> getCurrentUser({bool forceRemote = false});

  /// Verificar se a API de autenticação está respondendo.
  Future<Either<Failure, void>> checkServerAvailability();

  /// Obter Backup Codes do cache local
  Future<Either<Failure, List<String>>> getBackupCodes();

  /// Verificar se o usuário está autenticado
  Future<bool> isAuthenticated();

  /// Limpar sessão inválida (token corrompido/mismatched) sem chamar o backend
  Future<void> clearInvalidSession();

  /// Refresh token
  Future<Either<Failure, User>> refreshToken();

  /// Verificar TOTP de cadastro — retorna sessionId (Redis, temporário)
  Future<Either<Failure, String>> verifyTotp({
    required String sessionId,
    String? totpCode,
  });

  /// Verificar TOTP de Login (2FA) — retorna User com JWT
  Future<Either<Failure, User>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
    String? preAuthToken,
  });

  /// Validar passphrase localmente
  Future<Either<Failure, bool>> validatePassphrase(String passphrase);

  /// Inicia registro de passkey durante onboarding (start)
  Future<Either<Failure, String>> passkeyRegisterOnboardingStart({
    required String sessionId,
    String? username,
  });

  /// Finaliza registro de passkey durante onboarding (finish)
  Future<Either<Failure, LoginResult>> passkeyRegisterOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  );

  /// Inicia login via passkey (busca opções WebAuthn)
  Future<Either<Failure, String>> passkeyLoginStart(String username);

  /// Finaliza login via passkey (envia credencial WebAuthn)
  Future<Either<Failure, LoginResult>> passkeyLoginFinish({
    required String username,
    required Map<String, dynamic> credential,
  });

  /// Inicia registro de passkey para usuário logado — retorna PublicKeyCredentialCreationOptions JSON
  Future<Either<Failure, String>> passkeyRegisterStart(String username);

  /// Finaliza registro de passkey para usuário logado
  Future<Either<Failure, void>> passkeyRegisterFinish(
      Map<String, dynamic> credential);

  Future<Either<Failure, ActivationStatusResult>> getActivationStatus();

  Future<Either<Failure, ActivationStatusResult>> createActivationDepositLink();

  Future<Either<Failure, ActivationStatusResult>> confirmActivationPayment({
    required String linkId,
    required String txid,
  });

  Future<Either<Failure, AccountSecurityStatusResult>> getSecurityStatus();

  Future<Either<Failure, TotpSetupResult>> setupTotp();

  Future<Either<Failure, BackupCodesStatusResult>> verifyTotpSetup({
    required String totpCode,
  });

  Future<Either<Failure, void>> disableTotp();

  Future<Either<Failure, BackupCodesStatusResult>> getBackupCodesStatus();

  Future<Either<Failure, BackupCodesStatusResult>> regenerateBackupCodes();

  /// Confirma a TX do onboarding e inicia monitoramento on-chain
  Future<Either<Failure, OnboardingPaymentLinkDto>> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  });

  /// Consulta o estado atual do payment link de onboarding
  Future<Either<Failure, OnboardingPaymentLinkDto>> getOnboardingPaymentLink(
    String linkId,
  );
}
