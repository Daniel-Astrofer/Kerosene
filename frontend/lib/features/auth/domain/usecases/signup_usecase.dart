import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart'
    show SignupInitResult;
import '../repositories/auth_repository.dart';

// ─── Params ──────────────────────────────────────────────────────────────────

class SignupParams extends Equatable {
  final String username;
  final String passphrase;
  final String accountSecurity;
  final int? shamirTotalShares;
  final int? shamirThreshold;
  final int? multisigThreshold;

  const SignupParams({
    required this.username,
    required this.passphrase,
    this.accountSecurity = 'STANDARD',
    this.shamirTotalShares,
    this.shamirThreshold,
    this.multisigThreshold,
  });

  @override
  List<Object?> get props => [
        username,
        passphrase,
        accountSecurity,
        shamirTotalShares,
        shamirThreshold,
        multisigThreshold,
      ];
}

// ─── UseCase ─────────────────────────────────────────────────────────────────

class SignupUseCase {
  final AuthRepository repository;

  const SignupUseCase(this.repository);

  Future<Either<Failure, SignupInitResult>> call(SignupParams params) async {
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
        ValidationFailure(message: 'Senha não pode estar vazia'),
      );
    }

    return await repository.signup(
      username: params.username,
      passphrase: params.passphrase,
      accountSecurity: params.accountSecurity,
      shamirTotalShares: params.shamirTotalShares,
      shamirThreshold: params.shamirThreshold,
      multisigThreshold: params.multisigThreshold,
    );
  }
}
