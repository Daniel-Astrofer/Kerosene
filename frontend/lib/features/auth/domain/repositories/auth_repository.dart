import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../../data/datasources/auth_remote_datasource.dart'
    show SignupInitResult, OnboardingPaymentLinkDto, LoginResult;

/// Interface do repositório de autenticação
abstract class AuthRepository {
  /// Login — returns LoginResult with userId and JWT
  Future<Either<Failure, LoginResult>> login({
    required String username,
    required String passphrase,
  });

  /// Signup — resolve PoW e retorna {totpSecret, qrCodeUri}
  Future<Either<Failure, SignupInitResult>> signup({
    required String username,
    required String passphrase,
    String accountSecurity,
  });

  /// Fazer logout
  Future<Either<Failure, void>> logout();

  /// Obter usuário atual do cache
  Future<Either<Failure, User>> getCurrentUser();

  /// Verificar se o usuário está autenticado
  Future<bool> isAuthenticated();

  /// Limpar sessão inválida (token corrompido/mismatched) sem chamar o backend
  Future<void> clearInvalidSession();

  /// Refresh token
  Future<Either<Failure, User>> refreshToken();

  /// Verificar TOTP de cadastro — retorna sessionId (Redis, temporário)
  Future<Either<Failure, String>> verifyTotp({
    required String username,
    required String passphrase,
    required String totpCode,
    String? totpSecret,
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

  /// Passkey Onboarding (Start) - Returns PublicKeyCredentialCreationOptions JSON
  Future<Either<Failure, String>> registerPasskeyOnboardingStart(
    String sessionId,
  );

  /// Passkey Onboarding (Finish)
  Future<Either<Failure, void>> registerPasskeyOnboardingFinish(
    String sessionId,
    Map<String, dynamic> credential,
  );

  /// Inicia login via passkey — retorna PublicKeyCredentialRequestOptions JSON
  Future<Either<Failure, String>> passkeyLoginStart(String username);

  /// Finaliza login via passkey — retorna User logado
  Future<Either<Failure, User>> passkeyLoginFinish({
    required String username,
    required Map<String, dynamic> credential,
  });

  /// Inicia registro de passkey para usuário logado — retorna PublicKeyCredentialCreationOptions JSON
  Future<Either<Failure, String>> passkeyRegisterStart();

  /// Finaliza registro de passkey para usuário logado
  Future<Either<Failure, void>> passkeyRegisterFinish(Map<String, dynamic> credential);

  // Sovereign Auth (Hardware Ed25519)
  
  /// Inicia registro de hardware (onboarding)
  Future<Either<Failure, String>> registerHardwareOnboardingStart(String sessionId);

  /// Finaliza registro de hardware (onboarding)
  Future<Either<Failure, void>> registerHardwareOnboardingFinish({
    required String sessionId,
    required String publicKey,
    required String deviceName,
    required String signature,
  });

  /// Inicia registro de hardware (logado)
  Future<Either<Failure, String>> registerHardwareForAccountStart();

  /// Finaliza registro de hardware (logado)
  Future<Either<Failure, void>> registerHardwareForAccountFinish({
    required String publicKey,
    required String deviceName,
  });

  /// Inicia login via hardware (busca desafio)
  Future<Either<Failure, String>> hardwareLoginStart(String username);

  /// Finaliza login via hardware (envia assinatura)
  Future<Either<Failure, User>> hardwareLoginFinish({
    required String username,
    required String signature,
  });

  /// Onboarding Payment Link
  Future<Either<Failure, OnboardingPaymentLinkDto>> generateOnboardingLink(
    String sessionId,
  );

  /// Mock Confirm Onboarding (Dev shortcut)
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId);

  /// Confirm Voucher payment
  Future<Either<Failure, void>> confirmVoucher({
    required String voucherId,
    required String txid,
  });
}
