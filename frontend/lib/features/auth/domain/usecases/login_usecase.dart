import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para login
/// API Kerosene: POST /auth/login {username, passphrase}
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  /// Executa o caso de uso de login
  /// Parâmetros:
  /// - username: nome de usuário
  /// - password: passphrase
  Future<Either<Failure, User>> call({
    required String username,
    required String password,
  }) async {
    // Validações de negócio
    if (username.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Username não pode estar vazio'),
      );
    }

    if (password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Passphrase não pode estar vazia'),
      );
    }

    // Delega para o repositório
    // Passa username como email para compatibilidade
    return await repository.login(email: username, password: password);
  }
}
