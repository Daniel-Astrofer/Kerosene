import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
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
  /// - params: Objeto contendo username e passphrase
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Delega para o repositório
    // Passa username como email para compatibilidade
    return await repository.login(
      username: params.username,
      passphrase: params.passphrase,
    );
  }
}

// Parâmetros para o login
class LoginParams extends Equatable {
  final String username;
  final String passphrase;

  const LoginParams({required this.username, required this.passphrase});

  @override
  List<Object> get props => [username, passphrase];
}
