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

  /// Inicia registro de passkey durante onboarding (start)
  Future<Either<Failure, String>> passkeyRegisterOnboardingStart({
    required String sessionId,
    String? username,
  });

  /// Finaliza registro de passkey durante onboarding (finish)
  Future<Either<Failure, void>> passkeyRegisterOnboardingFinish(
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

  /// Onboarding Payment Link
  Future<Either<Failure, OnboardingPaymentLinkDto>> generateOnboardingLink(
    String sessionId,
  );

  /// Confirma a TX do onboarding e inicia monitoramento on-chain
  Future<Either<Failure, OnboardingPaymentLinkDto>> confirmOnboardingPayment({
    required String linkId,
    required String txid,
  });

  /// Consulta o estado atual do payment link de onboarding
  Future<Either<Failure, OnboardingPaymentLinkDto>> getOnboardingPaymentLink(
    String linkId,
  );

  /// Mock Confirm Onboarding (Dev shortcut)
  Future<Either<Failure, void>> mockConfirmOnboarding(String sessionId);

  /// Confirm Voucher payment
  Future<Either<Failure, void>> confirmVoucher({
    required String voucherId,
    required String txid,
  });
}
