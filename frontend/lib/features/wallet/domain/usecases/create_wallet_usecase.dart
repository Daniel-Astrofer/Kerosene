import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class CreateWalletUseCase {
  final WalletRepository repository;

  CreateWalletUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required String passphrase,
    String accountSecurity = 'STANDARD',
    String? xpub,
    String walletMode = 'KEROSENE',
  }) async {
    if (name.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Nome da carteira não pode estar vazio'));
    }
    if (passphrase.isEmpty) {
      return const Left(ValidationFailure(
          message: 'A seed phrase (passphrase) é obrigatória'));
    }
    return await repository.createWallet(
      name: name,
      passphrase: passphrase,
      accountSecurity: accountSecurity,
      xpub: xpub,
      walletMode: walletMode,
    );
  }
}
