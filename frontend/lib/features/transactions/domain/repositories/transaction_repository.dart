import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/fee_estimate.dart';
import '../entities/tx_status.dart';
import '../entities/deposit.dart';
import '../entities/payment_link.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';

/// Interface abstrata do TransactionRepository
abstract class TransactionRepository {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<TxStatus> getTransactionStatus(String txid);

  // Send & Broadcast
  Future<TxStatus> sendTransaction({
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? fromWalletId,
    String? fromAddress,
    String? context,
    String? passkeySignature,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
  });
  Future<Either<Failure, TxStatus>> broadcastTransaction({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  });

  // Create Unsigned
  Future<Either<Failure, UnsignedTransaction>> createUnsignedTransaction({
    required String toAddress,
    required double amount,
    required String feeLevel,
  });

  // Deposits
  Future<Either<Failure, String>> getDepositAddress();
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  });
  Future<List<Deposit>> getDeposits();
  Future<double> getDepositBalance();
  Future<Deposit> getDeposit(String txid);

  Future<List<PaymentLink>> getPaymentLinks();

  // Withdrawals
  Future<TxStatus> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    required String totpCode,
    String? description,
    String? passkeySignature,
    String? passkeyChallenge,
  });
}
