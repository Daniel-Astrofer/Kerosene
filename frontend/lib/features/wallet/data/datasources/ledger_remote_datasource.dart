import 'package:dio/dio.dart' show Options;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class LedgerRemoteDataSource {
  /// Retrieves all ledger accounts associated with the user's wallets.
  Future<List<dynamic>> getAllLedgers();

  /// Retrieves a specific ledger account.
  Future<Map<String, dynamic>> findLedger({required String walletName});

  /// Gets the current balance of a specific wallet.
  Future<double> getBalance({required String walletName});

  /// Retrieves paginated transaction history.
  Future<List<dynamic>> getHistory({int page = 0, int size = 50});

  /// Processes an internal funds transfer between users.
  Future<Map<String, dynamic>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    required String idempotencyKey,
  });

  // 3.1 Payment Requests (Internal)
  
  /// Creates an internal payment request link.
  Future<Map<String, dynamic>> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
  });

  /// Gets public details of a payment request.
  Future<Map<String, dynamic>> getPaymentRequest(String linkId);

  /// Pays an internal payment request.
  Future<Map<String, dynamic>> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  });

  /// Deletes a ledger account.
  Future<String> deleteLedger({required String walletName});
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  final ApiClient apiClient;

  LedgerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<dynamic>> getAllLedgers() async {
    try {
      final response = await apiClient.get(AppConfig.ledgerAll);
      return response.data is List ? response.data : [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar todos ledgers: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> findLedger({required String walletName}) async {
    try {
      final response = await apiClient.get(
        AppConfig.ledgerFind,
        queryParameters: {'walletName': walletName},
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar ledger: $e');
    }
  }

  @override
  Future<double> getBalance({required String walletName}) async {
    try {
      final response = await apiClient.get(
        AppConfig.ledgerBalance,
        queryParameters: {'walletName': walletName},
      );
      return double.tryParse(response.data.toString().trim()) ?? 0.0;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar saldo: $e');
    }
  }

  @override
  Future<List<dynamic>> getHistory({int page = 0, int size = 50}) async {
    try {
      final response = await apiClient.get(
        AppConfig.ledgerHistory,
        queryParameters: {'page': page, 'size': size},
      );
      return response.data is List ? response.data : [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar histórico: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendInternalTransaction({
    required String senderWalletName,
    required String receiverWalletName,
    required double amount,
    required String idempotencyKey,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': senderWalletName,
          'receiver': receiverWalletName,
          'amount': amount,
        },
        options: Options(headers: {
          'X-Idempotency-Key': idempotencyKey,
        }),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'result': response.data};
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar transação interna: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.ledgerPaymentRequest,
        data: {
          'amount': amount,
          'receiverWalletName': receiverWalletName,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar solicitação de pagamento: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentRequest(String linkId) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.ledgerPaymentRequest}/$linkId',
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar solicitação de pagamento: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.ledgerPaymentRequestPay.replaceFirst('{linkId}', linkId),
        data: {'payerWalletName': payerWalletName},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao pagar solicitação de pagamento: $e');
    }
  }

  @override
  Future<String> deleteLedger({required String walletName}) async {
    try {
      final response = await apiClient.delete(
        '${AppConfig.ledgerDelete}/$walletName',
      );
      return response.data.toString();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao deletar ledger: $e');
    }
  }
}
