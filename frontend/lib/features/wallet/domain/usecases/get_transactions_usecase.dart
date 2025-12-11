import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../repositories/wallet_repository.dart';

/// Caso de uso: Obter transações de uma carteira
/// Retorna histórico de transações ordenado por data (mais recente primeiro)
class GetTransactionsUseCase {
  final WalletRepository repository;

  const GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<Transaction>>> call({
    required String walletId,
    int limit = 50,
    int offset = 0,
  }) async {
    // Validação: limite razoável para performance
    if (limit > 100) {
      return const Left(
        ValidationFailure(
          message: 'Limite máximo de 100 transações por requisição',
        ),
      );
    }

    final result = await repository.getTransactions(
      walletId: walletId,
      limit: limit,
      offset: offset,
    );

    return result.fold(
      (failure) => Left(failure),
      (transactions) {
        // Ordenar por timestamp (mais recente primeiro)
        final sortedTransactions = List<Transaction>.from(transactions)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Right(sortedTransactions);
      },
    );
  }
}
