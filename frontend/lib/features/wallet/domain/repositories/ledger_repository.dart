import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';

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

  // 3.1 Payment Requests (Internal)
  Future<Either<Failure, Map<String, dynamic>>> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
  });

  Future<Either<Failure, Map<String, dynamic>>> getPaymentRequest(
      String linkId);

  Future<Either<Failure, Map<String, dynamic>>> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
    String? totpCode,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
  });

  Future<Either<Failure, String>> deleteLedger(String walletName);
}
