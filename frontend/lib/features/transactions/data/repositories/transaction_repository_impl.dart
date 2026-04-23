import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import 'package:teste/features/auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/external_transfer.dart';
import '../../domain/entities/lightning_invoice.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/wallet_network_address.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  Future<void> _checkAuth() async {
    final token = await authLocalDataSource.getToken();
    if (token == null) {
      throw const AuthException(message: 'Usuário não autenticado');
    }
  }

  // ==================== Fee & Status ====================

  @override
  Future<FeeEstimate> estimateFee(double amount) async {
    await _checkAuth();
    return remoteDataSource.estimateFee(amount);
  }

  @override
  Future<TxStatus> getTransactionStatus(String txid) async {
    await _checkAuth();
    return remoteDataSource.getTransactionStatus(txid);
  }

  // ==================== Send & Broadcast ====================

  @override
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
  }) async {
    debugPrint('>>> REPO: sendTransaction called');
    debugPrint('>>> Amount: $amount, Fee: $feeSatoshis');
    debugPrint('>>> FromWallet: $fromWalletId');

    // Do not short-circuit transaction actions on a local token read. The
    // TokenInterceptor attaches the session when available, and the backend is
    // the source of truth for 401/403. This keeps the request from being blocked
    // locally with "Usuário não autenticado" before it reaches the server.

    debugPrint(
      '>>> Repo: Always routing to Ledger (Off-chain/Internal/Withdrawal via Backend)...',
    );
    debugPrint('>>> Sender: [REDACTED]');
    debugPrint('>>> Receiver: [REDACTED]');

    try {
      final senderHint = (fromWalletId != null && fromWalletId.trim().isNotEmpty)
          ? fromWalletId.trim()
          : (fromAddress != null && fromAddress.trim().isNotEmpty)
              ? fromAddress.trim()
              : '';
      final result = await remoteDataSource.sendTransaction(
        fromAddress: senderHint,
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
        context: context,
        passkeyAssertionJson: passkeyAssertionJson,
        confirmationPassphrase: confirmationPassphrase,
        totpCode: totpCode,
        idempotencyKey: idempotencyKey,
        requestTimestamp: requestTimestamp,
      );
      debugPrint('>>> Ledger Transaction Success: ${result.txid}');
      return result;
    } catch (e) {
      debugPrint('>>> Ledger Transaction Failed: $e');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, TxStatus>> broadcastTransaction({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  }) async {
    try {
      final result = await remoteDataSource.broadcastTransaction(
        rawTxHex: rawTxHex,
        toAddress: toAddress,
        amount: amount,
        message: message,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao transmitir transação: $e'));
    }
  }

  @override
  Future<Either<Failure, UnsignedTransaction>> createUnsignedTransaction({
    required String toAddress,
    required double amount,
    required String feeLevel,
  }) async {
    try {
      await _checkAuth();
      final result = await remoteDataSource.createUnsignedTransaction(
        toAddress: toAddress,
        amount: amount,
        feeLevel: feeLevel,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao criar transação: $e'));
    }
  }

  // ==================== Deposits ====================

  @override
  Future<Either<Failure, String>> getDepositAddress() async {
    try {
      await _checkAuth();
      final result = await remoteDataSource.getDepositAddress();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao obter endereço: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getOnrampUrls() async {
    try {
      await _checkAuth();
      final result = await remoteDataSource.getOnrampUrls();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(
        UnknownFailure(message: 'Erro ao obter links de onramp: $e'),
      );
    }
  }

  @override
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  }) async {
    await _checkAuth();
    return remoteDataSource.confirmDeposit(
      txid: txid,
      fromAddress: fromAddress,
      amount: amount,
    );
  }

  @override
  Future<List<Deposit>> getDeposits() async {
    await _checkAuth();
    return remoteDataSource.getDeposits();
  }

  @override
  Future<double> getDepositBalance() async {
    await _checkAuth();
    return remoteDataSource.getDepositBalance();
  }

  @override
  Future<Deposit> getDeposit(String txid) async {
    await _checkAuth();
    return remoteDataSource.getDeposit(txid);
  }

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    String? description,
  }) async {
    await _checkAuth();
    return remoteDataSource.createPaymentLink(
      amount: amount,
      description: description,
    );
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    await _checkAuth();
    return remoteDataSource.getPaymentLink(linkId);
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    await _checkAuth();
    return remoteDataSource.getPaymentLinks();
  }

  @override
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  }) async {
    await _checkAuth();
    return remoteDataSource.getWalletNetworkProfile(walletName: walletName);
  }

  @override
  Future<WalletNetworkAddress> issueOnchainAddress({
    required String walletName,
    bool regenerate = false,
  }) async {
    await _checkAuth();
    return remoteDataSource.issueOnchainAddress(
      walletName: walletName,
      regenerate: regenerate,
    );
  }

  @override
  Future<LightningInvoice> createLightningInvoice({
    required String walletName,
    required double amount,
    String? memo,
    int expiresInSeconds = 900,
  }) async {
    await _checkAuth();
    return remoteDataSource.createLightningInvoice(
      walletName: walletName,
      amount: amount,
      memo: memo,
      expiresInSeconds: expiresInSeconds,
    );
  }

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() async {
    await _checkAuth();
    return remoteDataSource.getExternalTransfers();
  }

  @override
  Future<ExternalTransfer> getExternalTransfer(String transferId) async {
    await _checkAuth();
    return remoteDataSource.getExternalTransfer(transferId);
  }

  @override
  Future<TxStatus> withdraw({
    required String fromWalletName,
    String? toAddress,
    String? paymentRequest,
    required double amount,
    String? totpCode,
    bool isLightning = false,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
  }) async {
    // Same as sendTransaction: let the HTTP layer/backend decide auth status.
    return remoteDataSource.withdraw(
      fromWalletName: fromWalletName,
      toAddress: toAddress,
      paymentRequest: paymentRequest,
      amount: amount,
      totpCode: totpCode,
      isLightning: isLightning,
      maxRoutingFeeBtc: maxRoutingFeeBtc,
      description: description,
      confirmationPassphrase: confirmationPassphrase,
      passkeyAssertionJson: passkeyAssertionJson,
    );
  }
}
