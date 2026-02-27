import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';
import '../../../wallet/domain/entities/transaction.dart';
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
  }) async {
    debugPrint('>>> REPO: sendTransaction called');
    debugPrint('>>> Amount: $amount, Fee: $feeSatoshis');
    debugPrint('>>> FromWallet: $fromWalletId');

    await _checkAuth();

    debugPrint(
      '>>> Repo: Always routing to Ledger (Off-chain/Internal/Withdrawal via Backend)...',
    );
    debugPrint('>>> Sender: [REDACTED]');
    debugPrint('>>> Receiver: [REDACTED]');

    try {
      final result = await remoteDataSource.sendTransaction(
        fromAddress: fromAddress ?? fromWalletId ?? '',
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
        context: context,
      );
      debugPrint('>>> Ledger Transaction Success: ${result.txid}');
      return result;
    } catch (e) {
      debugPrint('>>> Ledger Transaction Failed: $e');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, TxStatus>> broadcastTransaction(
    String rawTxHex,
  ) async {
    try {
      final result = await remoteDataSource.broadcastTransaction(rawTxHex);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Erro ao transmitir transação: $e'));
    }
  }

  @override
  Future<Either<Failure, UnsignedTransaction>> createUnsignedTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  }) async {
    try {
      await _checkAuth();
      final result = await remoteDataSource.createUnsignedTransaction(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
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

  // ==================== Payment Requests ====================

  @override
  Future<PaymentLink> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
    int? expiresIn,
  }) async {
    await _checkAuth();
    return remoteDataSource.createPaymentRequest(
      amount: amount,
      receiverWalletName: receiverWalletName,
      expiresIn: expiresIn,
    );
  }

  @override
  Future<PaymentLink> getPaymentRequest(String linkId) async {
    // Payment requests might be public for scanning, but we follow datasource
    return remoteDataSource.getPaymentRequest(linkId);
  }

  @override
  Future<PaymentLink> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  }) async {
    await _checkAuth();
    return remoteDataSource.payPaymentRequest(
      linkId: linkId,
      payerWalletName: payerWalletName,
    );
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    await _checkAuth();
    return remoteDataSource.getPaymentLinks();
  }

  @override
  Future<TxStatus> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    String? description,
  }) async {
    await _checkAuth();
    return remoteDataSource.withdraw(
      fromWalletName: fromWalletName,
      toAddress: toAddress,
      amount: amount,
      description: description,
    );
  }

  @override
  Future<List<Transaction>> getTransactionHistory() async {
    return remoteDataSource.getTransactionHistory();
  }
}
