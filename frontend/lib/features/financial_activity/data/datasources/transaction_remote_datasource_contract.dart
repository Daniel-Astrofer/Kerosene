import '../../domain/entities/deposit.dart';
import '../../domain/entities/external_transfer.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/onchain_address_allocation.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/wallet_network_address.dart';

/// Interface do TransactionRemoteDataSource
abstract class TransactionRemoteDataSource {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<TxStatus> getTransactionStatus(String txid);

  // Send
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    String? context,
    String? passkeyAssertionJson,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
    String? appPin,
  });

  // Deposits
  Future<String> getDepositAddress();
  Future<Map<String, String>> getOnrampUrls();
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
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  });
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  });
  Future<List<ExternalTransfer>> getExternalTransfers();
  Future<ExternalTransfer> getExternalTransfer(String transferId);

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
    String? appPin,
  });
}
