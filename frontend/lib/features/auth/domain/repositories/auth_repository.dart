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
    String credentialJson,
  );

  /// Onboarding Payment Link
  Future<Either<Failure, OnboardingPaymentLinkDto>> generateOnboardingLink(
    String sessionId,
  );
}
