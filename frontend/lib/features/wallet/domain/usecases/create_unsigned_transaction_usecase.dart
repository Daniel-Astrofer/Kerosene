import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/unsigned_transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class CreateUnsignedTransactionUseCase {
  final TransactionRepository repository;

  CreateUnsignedTransactionUseCase(this.repository);

  Future<Either<Failure, UnsignedTransaction>> call({
    required String toAddress,
    required double amountBTC,
    required String feeLevel,
  }) async {
    return await repository.createUnsignedTransaction(
      toAddress: toAddress,
      amount: amountBTC,
      feeLevel: feeLevel,
    );
  }
}
