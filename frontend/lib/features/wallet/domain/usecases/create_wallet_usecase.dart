import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class CreateWalletUseCase {
  final WalletRepository repository;

  CreateWalletUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required String passphrase,
  }) async {
    return await repository.createWallet(name: name, passphrase: passphrase);
  }
}
