import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';

/// Interface do TransactionRemoteDataSource
abstract class TransactionRemoteDataSource {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<TxStatus> getTransactionStatus(String txid);

  // Send & Broadcast
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    required String token,
  });
  Future<TxStatus> broadcastTransaction(String rawTxHex);

  // Deposits
  Future<String> getDepositAddress();
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
    required String token,
  });
  Future<List<Deposit>> getDeposits(String token);
  Future<double> getDepositBalance(String token);
  Future<Deposit> getDeposit(String txid);

  // Payment Links
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
    required String token,
  });
  Future<PaymentLink> getPaymentLink(String linkId);
  Future<PaymentLink> confirmPaymentLink({
    required String linkId,
    required String txid,
    required String fromAddress,
  });
  Future<PaymentLink> completePaymentLink({
    required String linkId,
    required String token,
  });
  Future<List<PaymentLink>> getPaymentLinks(String token);
}

/// Implementação do TransactionRemoteDataSource
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl(this.apiClient);

  Future<Map<String, String>> _getHeaders(String token) async {
    final securityHeaders = await DeviceHelper.getSecurityHeaders();
    return {...securityHeaders, 'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
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
      throw ServerException(message: 'Erro ao estimar taxa: $e');
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
      throw ServerException(message: 'Erro ao consultar status: $e');
    }
  }

  // ==================== Send & Broadcast ====================

  @override
  @override
  Future<TxStatus> sendTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int feeSatoshis,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': fromAddress,
          'receiver': toAddress,
          'amount': amount,
          'context':
              'transfer', // Using 'transfer' as context or description if available
          // 'feeSatoshis': feeSatoshis, // Ledger API might not accept this, but we can try sending it or omit
        },
        headers: headers,
      );

      final data = _parseJsonResponse(response.data);
      // If response is just a success message or similar, we might need to construct a mock TxStatus or parse what we can
      // Assuming it might return the transaction details
      return TxStatus.fromJson(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao enviar transação: $e');
    }
  }

  @override
  Future<TxStatus> broadcastTransaction(String rawTxHex) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsBroadcast,
        data: {'rawTxHex': rawTxHex},
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
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
      throw ServerException(message: 'Erro ao obter endereço de depósito: $e');
    }
  }

  @override
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        AppConfig.transactionsConfirmDeposit,
        data: {'txid': txid, 'fromAddress': fromAddress, 'amount': amount},
        headers: headers,
      );
      return Deposit.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      throw ServerException(message: 'Erro ao confirmar depósito: $e');
    }
  }

  @override
  Future<List<Deposit>> getDeposits(String token) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.transactionsDeposits,
        headers: headers,
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
      throw ServerException(message: 'Erro ao listar depósitos: $e');
    }
  }

  @override
  Future<double> getDepositBalance(String token) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.transactionsDepositBalance,
        headers: headers,
        options: Options(responseType: ResponseType.plain),
      );
      return double.tryParse(response.data.toString().trim()) ?? 0;
    } catch (e) {
      throw ServerException(
        message: 'Erro ao consultar saldo de depósitos: $e',
      );
    }
  }

  @override
  Future<Deposit> getDeposit(String txid) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.transactionsDeposit}/$txid',
      );
      return Deposit.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar depósito: $e');
    }
  }

  // ==================== Payment Links ====================

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    required String description,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        AppConfig.transactionsCreatePaymentLink,
        data: {'amount': amount, 'description': description},
        headers: headers,
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
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
      throw ServerException(message: 'Erro ao confirmar payment link: $e');
    }
  }

  @override
  Future<PaymentLink> completePaymentLink({
    required String linkId,
    required String token,
  }) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.post(
        '${AppConfig.transactionsPaymentLink}/$linkId/complete',
        headers: headers,
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      throw ServerException(message: 'Erro ao completar payment link: $e');
    }
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks(String token) async {
    try {
      final headers = await _getHeaders(token);
      final response = await apiClient.get(
        AppConfig.transactionsPaymentLinks,
        headers: headers,
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
            .map((e) => PaymentLink.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw ServerException(message: 'Erro ao listar payment links: $e');
    }
  }
}
