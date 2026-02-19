import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
// import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cadastro (Signup)
/// API Kerosene: POST /auth/signup {username, passphrase}

// Parâmetros para o cadastro
class SignupParams extends Equatable {
  final String username;
  final String passphrase;

  const SignupParams({required this.username, required this.passphrase});

  @override
  List<Object> get props => [username, passphrase];
}

class SignupUseCase {
  final AuthRepository repository;

  const SignupUseCase(this.repository);

  /// Executa o caso de uso de cadastro
  /// Parâmetros:
  /// - username: nome de usuário (mínimo 3 caracteres)
  /// - password: passphrase (mínimo 8 caracteres)
  Future<Either<Failure, String>> call(SignupParams params) async {
    // Validações de negócio
    if (params.username.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Username não pode estar vazio'),
      );
    }

    if (params.username.length < 3) {
      return const Left(
        ValidationFailure(message: 'Username deve ter no mínimo 3 caracteres'),
      );
    }

    if (params.passphrase.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Passphrase não pode estar vazia'),
      );
    }

    if (params.passphrase.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Passphrase deve ter no mínimo 8 caracteres',
        ),
      );
    }

    // Delega para o repositório
    // Passa username e passphrase para o repositório
    // Nota: O repositório espera 'passphrase' mas o método signup antigo usava 'password'.
    // Ajustado para 'passphrase' conforme a Entity/Model novo.
    return await repository.signup(
      username: params.username,
      passphrase: params.passphrase,
    );
  }
}
