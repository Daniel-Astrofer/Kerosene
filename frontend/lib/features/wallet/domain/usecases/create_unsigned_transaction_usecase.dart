import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/unsigned_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class CreateUnsignedTransactionUseCase {
  final TransactionRepository repository;

  CreateUnsignedTransactionUseCase(this.repository);

  Future<Either<Failure, UnsignedTransaction>> call({
    required String fromAddress,
    required String toAddress,
    required double amountBTC,
    required int feeSatoshis,
  }) async {
    return await repository.createUnsignedTransaction(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amountBTC,
      feeSatoshis: feeSatoshis,
    );
  }
}
