import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../transactions/domain/entities/tx_status.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class BroadcastTransactionUseCase {
  final TransactionRepository repository;

  BroadcastTransactionUseCase(this.repository);

  Future<Either<Failure, TxStatus>> call({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  }) async {
    return await repository.broadcastTransaction(
      rawTxHex: rawTxHex,
      toAddress: toAddress,
      amount: amount,
      message: message,
    );
  }
}
