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
  }) async {
    debugPrint('>>> REPO: sendTransaction called');
    debugPrint('>>> To: $toAddress, Amount: $amount, Fee: $feeSatoshis');
    debugPrint('>>> FromWallet: $fromWalletId, FromAddress: $fromAddress');

    await _checkAuth();

    debugPrint(
      '>>> Repo: Always routing to Ledger (Off-chain/Internal/Withdrawal via Backend)...',
    );
    debugPrint('>>> Sender: ${fromWalletId ?? fromAddress}');
    debugPrint('>>> Receiver: $toAddress');

    // Sempre usar /ledger/transaction
    // O backend deve decidir se á interna ou saáda para rede (withdrawal)
    // Preference: fromAddress (BTC Address) > fromWalletId (UUID)
    // Reason: Backend likely looks up wallet by address if 'sender' parameter is used.
    try {
      final result = await remoteDataSource.sendTransaction(
        fromAddress: fromAddress ?? fromWalletId ?? '',
        toAddress: toAddress,
        amount: amount,
        feeSatoshis: feeSatoshis,
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

  // ==================== Payment Links ====================

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
  }) async {
    await _checkAuth();
    return remoteDataSource.createPaymentLink(
      amount: amount,
      description: description,
    );
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    // Payment links might be public? Assuming auth required for now based on previous code relying on token
    // But previous code didn't use `token` in getPaymentLink method (Step 935: `getPaymentLink` method lines 318-328 did NOT use `token` param in signature or body).
    // Wait, step 935 `getPaymentLink(String linkId)` implementation:
    /*
      @override
      Future<PaymentLink> getPaymentLink(String linkId) async {
        try {
          final response = await apiClient.get(
            '${AppConfig.transactionsPaymentLink}/$linkId',
          );
          return PaymentLink.fromJson(_parseJsonResponse(response.data));
        } catch (e) {
          throw ServerException(message: 'Erro ao buscar payment link: $e');
        }
      }
    */
    // It did NOT use token. So I don't need `_checkAuth()` here.
    return remoteDataSource.getPaymentLink(linkId);
  }

  @override
  Future<PaymentLink> confirmPaymentLink({
    required String linkId,
    required String txid,
    required String fromAddress,
  }) async {
    // Previous implementation also didn't use token?
    // Step 935: `confirmPaymentLink` (331-345) did NOT use token.
    return remoteDataSource.confirmPaymentLink(
      linkId: linkId,
      txid: txid,
      fromAddress: fromAddress,
    );
  }

  @override
  Future<PaymentLink> completePaymentLink(String linkId) async {
    await _checkAuth();
    return remoteDataSource.completePaymentLink(linkId: linkId);
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    await _checkAuth();
    return remoteDataSource.getPaymentLinks();
  }
}
