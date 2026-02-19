import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';

/// Interface do TransactionRemoteDataSource
abstract class TransactionRemoteDataSource {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<UnsignedTransaction> createUnsignedTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  });
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
  Future<PaymentLink> completePaymentLink({required String linkId});
  Future<List<PaymentLink>> getPaymentLinks();
}

/// Implementação do TransactionRemoteDataSource
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl(this.apiClient);

  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      if (data.trim().isEmpty) return {};
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
    }
    return {};
  }

  // ==================== Fee & Status ====================

  @override
  Future<FeeEstimate> estimateFee(double amount) async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsEstimateFee,
        queryParameters: {'amount': amount},
      );
      return FeeEstimate.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao estimar taxa: $e');
    }
  }

  @override
  Future<UnsignedTransaction> createUnsignedTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsCreateUnsigned,
        data: {
          'fromAddress': fromAddress,
          'toAddress': toAddress,
          'amount': amount,
          'feeSatoshis': feeSatoshis,
        },
      );
      return UnsignedTransaction.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        String? serverMsg;
        try {
          if (data is Map) {
            serverMsg = data['message'] ?? data['error'];
          } else if (data is String) {
            serverMsg = data;
          }
        } catch (_) {}

        if (serverMsg != null && serverMsg.isNotEmpty) {
          throw ServerException(message: serverMsg);
        }
      }
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao criar transação não assinada: $e',
      );
    }
  }

  @override
  Future<TxStatus> getTransactionStatus(String txid) async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsStatus,
        queryParameters: {'txid': txid},
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar status: $e');
    }
  }

  // ==================== Send & Broadcast ====================

  @override
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': fromAddress, // Backend expects 'sender'
          'receiver': toAddress, // Backend expects 'receiver'
          'amount': amount,
          'context': 'transfer',
        },
      );

      final data = _parseJsonResponse(response.data);
      return TxStatus.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar transação: $e');
    }
  }

  @override
  Future<TxStatus> broadcastTransaction(String rawTxHex) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsBroadcast, // Note: Verify if this constant exists
        data: {'rawTxHex': rawTxHex},
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao transmitir transação: $e');
    }
  }

  // ==================== Deposits ====================

  @override
  Future<String> getDepositAddress() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsDepositAddress,
        options: Options(responseType: ResponseType.plain),
      );
      // Response is a plain string (the address)
      String address = response.data.toString().trim();
      // Remove surrounding quotes if present
      if (address.startsWith('"') && address.endsWith('"')) {
        address = address.substring(1, address.length - 1);
      }
      return address;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter endereço de depósito: $e');
    }
  }

  @override
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsConfirmDeposit,
        data: {'txid': txid, 'fromAddress': fromAddress, 'amount': amount},
      );
      return Deposit.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao confirmar depósito: $e');
    }
  }

  @override
  Future<List<Deposit>> getDeposits() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsDeposits, // Note: Verify if this constant exists
      );

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Deposit.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao listar depósitos: $e');
    }
  }

  @override
  Future<double> getDepositBalance() async {
    try {
      final response = await apiClient.get(
        AppConfig
            .transactionsDepositBalance, // Note: Verify if this constant exists
      );
      return double.tryParse(response.data.toString().trim()) ?? 0;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao consultar saldo de depósitos: $e',
      );
    }
  }

  @override
  Future<Deposit> getDeposit(String txid) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.transactionsDeposit}/$txid', // Note: Verify existence
      );
      return Deposit.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar depósito: $e');
    }
  }

  // ==================== Payment Links ====================

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsCreatePaymentLink,
        data: {'amount': amount, 'description': description},
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar payment link: $e');
    }
  }

  @override
  Future<PaymentLink> getPaymentLink(String linkId) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.transactionsPaymentLink}/$linkId',
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar payment link: $e');
    }
  }

  @override
  Future<PaymentLink> confirmPaymentLink({
    required String linkId,
    required String txid,
    required String fromAddress,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.transactionsPaymentLink}/$linkId/confirm',
        data: {'txid': txid, 'fromAddress': fromAddress},
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao confirmar payment link: $e');
    }
  }

  @override
  Future<PaymentLink> completePaymentLink({required String linkId}) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.transactionsPaymentLink}/$linkId/complete',
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao completar payment link: $e');
    }
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    try {
      final response = await apiClient.get(AppConfig.transactionsPaymentLinks);

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentLink.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      // If 403, just return empty list to avoid breaking UI (backend might not be ready or scope issue)
      if (e is DioException && e.response?.statusCode == 403) {
        return [];
      }
      if (e is AppException && e.statusCode == 403) {
        return [];
      }

      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao listar payment links: $e');
    }
  }
}
