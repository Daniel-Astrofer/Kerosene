import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.authLocalDataSource,
  });

  Future<String> _getToken() async {
    final token = await authLocalDataSource.getToken();
    if (token == null)
      throw const AuthException(message: 'Usuário não autenticado');
    return token;
  }

  // ==================== Fee & Status ====================

  @override
  Future<FeeEstimate> estimateFee(double amount) async {
    return remoteDataSource.estimateFee(amount);
  }

  @override
  Future<TxStatus> getTransactionStatus(String txid) async {
    return remoteDataSource.getTransactionStatus(txid);
  }

  // ==================== Send & Broadcast ====================

  @override
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  }) async {
    final token = await _getToken();
    return remoteDataSource.sendTransaction(
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      feeSatoshis: feeSatoshis,
      token: token,
    );
  }

  @override
  Future<TxStatus> broadcastTransaction(String rawTxHex) async {
    return remoteDataSource.broadcastTransaction(rawTxHex);
  }

  // ==================== Deposits ====================

  @override
  Future<String> getDepositAddress() async {
    return remoteDataSource.getDepositAddress();
  }

  @override
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  }) async {
    final token = await _getToken();
    return remoteDataSource.confirmDeposit(
      txid: txid,
      fromAddress: fromAddress,
      amount: amount,
      token: token,
    );
  }

  @override
  Future<List<Deposit>> getDeposits() async {
    final token = await _getToken();
    return remoteDataSource.getDeposits(token);
  }

  @override
  Future<double> getDepositBalance() async {
    final token = await _getToken();
    return remoteDataSource.getDepositBalance(token);
  }

  @override
  Future<Deposit> getDeposit(String txid) async {
    return remoteDataSource.getDeposit(txid);
  }

  // ==================== Payment Links ====================

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
  }) async {
    final token = await _getToken();
    return remoteDataSource.createPaymentLink(
      amount: amount,
      description: description,
      token: token,
    );
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    return remoteDataSource.getPaymentLink(linkId);
  }

  @override
  Future<PaymentLink> confirmPaymentLink({
    required String linkId,
    required String txid,
    required String fromAddress,
  }) async {
    return remoteDataSource.confirmPaymentLink(
      linkId: linkId,
      txid: txid,
      fromAddress: fromAddress,
    );
  }

  @override
  Future<PaymentLink> completePaymentLink(String linkId) async {
    final token = await _getToken();
    return remoteDataSource.completePaymentLink(linkId: linkId, token: token);
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    final token = await _getToken();
    return remoteDataSource.getPaymentLinks(token);
  }
}
