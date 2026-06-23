import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

abstract class LedgerRepository {
  Future<Either<Failure, List<dynamic>>> getAllLedgers();
  Future<Either<Failure, Map<String, dynamic>>> findLedger(String walletName);
  Future<Either<Failure, double>> getBalance(String walletName);
  Future<Either<Failure, List<Transaction>>> getHistory(
      {int page = 0, int size = 50});

  Future<Either<Failure, Map<String, dynamic>>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    String? context,
  });
}
