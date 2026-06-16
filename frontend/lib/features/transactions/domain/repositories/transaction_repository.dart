import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/fee_estimate.dart';
import '../entities/tx_status.dart';
import '../entities/deposit.dart';
import '../entities/payment_link.dart';
import '../entities/external_transfer.dart';
import '../entities/lightning_invoice.dart';
import '../entities/onchain_address_allocation.dart';
import '../entities/wallet_network_address.dart';
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
    String? passkeyAssertionJson,
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
  Future<Either<Failure, Map<String, String>>> getOnrampUrls();
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  });
  Future<List<Deposit>> getDeposits();
  Future<double> getDepositBalance();
  Future<Deposit> getDeposit(String txid);

  Future<PaymentLink> createPaymentLink({
    required double amount,
    String? description,
    int? expiresInMinutes,
    String? visibility,
    String? confirmationMode,
    bool amountLocked = true,
    String? referenceLabel,
    Map<String, String>? metadata,
  });
  Future<PaymentLink> getPaymentLink(String linkId);
  Future<List<PaymentLink>> getPaymentLinks();
  Future<PaymentLink> cancelPaymentLink({
    required String linkId,
    String? reason,
  });

  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  });
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  });
  Future<LightningInvoice> createLightningInvoice({
    required String idempotencyKey,
    required String walletName,
    required double amount,
    String? memo,
    int expiresInSeconds = 900,
  });
  Future<List<ExternalTransfer>> getExternalTransfers();
  Future<ExternalTransfer> getExternalTransfer(String transferId);
  Future<ExternalTransfer> cancelInboundTransfer(String transferId);

  // Withdrawals
  Future<TxStatus> withdraw({
    required String fromWalletName,
    String? toAddress,
    String? paymentRequest,
    required double amount,
    String? totpCode,
    bool isLightning = false,
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
  });
}
