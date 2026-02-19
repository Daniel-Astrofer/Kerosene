import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Interface do repositório de autenticação
/// Define o contrato que a camada de dados deve implementar
abstract class AuthRepository {
  /// Fazer login com username e passphrase
  Future<Either<Failure, User>> login({
    required String username,
    required String passphrase,
  });

  /// Fazer cadastro e retornar URI TOTP
  Future<Either<Failure, String>> signup({
    required String username,
    required String passphrase,
  });

  /// Fazer logout
  Future<Either<Failure, void>> logout();

  /// Obter usuário atual do cache
  Future<Either<Failure, User>> getCurrentUser();

  /// Verificar se o usuário está autenticado
  Future<bool> isAuthenticated();

  /// Refresh token
  Future<Either<Failure, User>> refreshToken();

  /// Verificar TOTP
  Future<Either<Failure, User>> verifyTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  });

  /// Verificar TOTP para Login (2FA)
  Future<Either<Failure, User>> verifyLoginTotp({
    required String username,
    required String passphrase,
    required String totpCode,
  });

  /// Validar passphrase localmente
  Future<Either<Failure, bool>> validatePassphrase(String passphrase);
}
