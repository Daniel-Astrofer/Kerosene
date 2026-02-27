import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para login
/// POST /auth/login → retorna authId (não JWT)
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<Either<Failure, String>> call(LoginParams params) async {
    return await repository.login(
      username: params.username,
      passphrase: params.passphrase,
    );
  }
}

class LoginParams extends Equatable {
  final String username;
  final String passphrase;

  const LoginParams({required this.username, required this.passphrase});

  @override
  List<Object> get props => [username, passphrase];
}
