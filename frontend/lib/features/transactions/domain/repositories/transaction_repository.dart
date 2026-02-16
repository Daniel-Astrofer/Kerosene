import '../entities/fee_estimate.dart';
import '../entities/tx_status.dart';
import '../entities/deposit.dart';
import '../entities/payment_link.dart';

/// Interface abstrata do TransactionRepository
abstract class TransactionRepository {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<TxStatus> getTransactionStatus(String txid);

  // Send & Broadcast
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  });
  Future<TxStatus> broadcastTransaction(String rawTxHex);

  // Deposits
  Future<String> getDepositAddress();
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  });
  Future<List<Deposit>> getDeposits();
  Future<double> getDepositBalance();
  Future<Deposit> getDeposit(String txid);

  // Payment Links
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
  });
  Future<PaymentLink> getPaymentLink(String linkId);
  Future<PaymentLink> confirmPaymentLink({
    required String linkId,
    required String txid,
    required String fromAddress,
  });
  Future<PaymentLink> completePaymentLink(String linkId);
  Future<List<PaymentLink>> getPaymentLinks();
}
