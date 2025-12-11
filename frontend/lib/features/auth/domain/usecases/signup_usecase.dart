import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
// import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cadastro (Signup)
/// API Kerosene: POST /auth/signup {username, passphrase}
class SignupUseCase {
  final AuthRepository repository;

  const SignupUseCase(this.repository);

  /// Executa o caso de uso de cadastro
  /// Parâmetros:
  /// - username: nome de usuário (mínimo 3 caracteres)
  /// - password: passphrase (mínimo 8 caracteres)
  Future<Either<Failure, String>> call({
    required String username,
    required String password,
  }) async {
    // Validações de negócio
    if (username.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Username não pode estar vazio'),
      );
    }

    if (username.length < 3) {
      return const Left(
        ValidationFailure(message: 'Username deve ter no mínimo 3 caracteres'),
      );
    }

    if (password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Passphrase não pode estar vazia'),
      );
    }

    if (password.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Passphrase deve ter no mínimo 8 caracteres',
        ),
      );
    }

    // Delega para o repositório
    // Passa username como email e name para compatibilidade
    return await repository.signup(
      email: username,
      password: password,
      name: username,
    );
  }
}
