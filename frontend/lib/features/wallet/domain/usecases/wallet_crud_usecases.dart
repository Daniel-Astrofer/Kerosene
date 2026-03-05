import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class FindWalletUseCase {
  final WalletRepository repository;

  FindWalletUseCase(this.repository);

  Future<Either<Failure, Wallet>> call(String name) async {
    return repository.findWallet(name);
  }
}

class UpdateWalletUseCase {
  final WalletRepository repository;

  UpdateWalletUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required String newName,
    required String passphrase,
  }) async {
    return repository.updateWallet(
      name: name,
      newName: newName,
      passphrase: passphrase,
    );
  }
}

class DeleteWalletUseCase {
  final WalletRepository repository;

  DeleteWalletUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String name,
    required String passphrase,
  }) async {
    return repository.deleteWallet(name: name, passphrase: passphrase);
  }
}

class GetLedgerBalanceUseCase {
  final WalletRepository repository;

  GetLedgerBalanceUseCase(this.repository);

  Future<Either<Failure, double>> call(String walletName) async {
    return repository.getBalance(walletName);
  }
}

class DeleteLedgerUseCase {
  final WalletRepository repository;

  DeleteLedgerUseCase(this.repository);

  Future<Either<Failure, String>> call(String walletName) async {
    return repository.deleteLedger(walletName);
  }
}
