import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

/// Caso de uso: Obter carteiras do usuário
/// Retorna lista de carteiras ordenadas por saldo (maior primeiro)
class GetWalletsUseCase {
  final WalletRepository repository;

  const GetWalletsUseCase(this.repository);

  Future<Either<Failure, List<Wallet>>> call() async {
    final result = await repository.getWallets();

    return result.fold(
      (failure) => Left(failure),
      (wallets) {
        // Ordenar por saldo (maior primeiro)
        final sortedWallets = List<Wallet>.from(wallets)
          ..sort((a, b) => b.balanceSatoshis.compareTo(a.balanceSatoshis));

        return Right(sortedWallets);
      },
    );
  }
}
