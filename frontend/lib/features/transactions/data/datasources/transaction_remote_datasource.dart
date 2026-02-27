import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';

/// Top-level function for isolates
dynamic decodeJsonData(String source) => jsonDecode(source);

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
    String? context,
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

  // Payment Requests
  Future<PaymentLink> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
    int? expiresIn,
  });
  Future<PaymentLink> getPaymentRequest(String linkId);
  Future<PaymentLink> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  });
  Future<List<PaymentLink>> getPaymentLinks();

  // Withdrawals
  Future<TxStatus> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    String? description,
  });

  // Transaction History
  Future<List<Transaction>> getTransactionHistory();
}

/// Implementação do TransactionRemoteDataSource
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl(this.apiClient);

  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
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
    String? context,
  }) async {
    try {
      final idempotencyKey = const Uuid().v4();
      final requestTimestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': fromAddress,
          'receiver': toAddress,
          'amount': amount,
          'context': context ?? 'transfer',
          'idempotencyKey': idempotencyKey,
          'requestTimestamp': requestTimestamp,
        },
      );

      final data = _parseJsonResponse(response.data);
      return TxStatus.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        final respData = e.response?.data;
        String? serverMsg;
        try {
          if (respData is Map) {
            serverMsg =
                respData['message']?.toString() ??
                respData['error']?.toString();
          } else if (respData is String) {
            serverMsg = respData;
          }
        } catch (_) {}
        if (serverMsg != null && serverMsg.isNotEmpty) {
          throw ServerException(message: serverMsg);
        }
      }
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
          data = await compute<String, dynamic>(decodeJsonData, data);
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
  Future<PaymentLink> createPaymentRequest({
    required double amount,
    required String receiverWalletName,
    int? expiresIn,
  }) async {
    try {
      final dataParams = <String, dynamic>{
        'amount': amount,
        'receiverWalletName': receiverWalletName,
      };
      if (expiresIn != null) {
        dataParams['expiresIn'] = expiresIn;
      }

      final response = await apiClient.post(
        AppConfig.ledgerPaymentRequest,
        data: dataParams,
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar payment request: $e');
    }
  }

  @override
  Future<PaymentLink> getPaymentRequest(String linkId) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.ledgerPaymentRequest}/$linkId',
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar payment request: $e');
    }
  }

  @override
  Future<PaymentLink> payPaymentRequest({
    required String linkId,
    required String payerWalletName,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.ledgerPaymentRequestPay}/$linkId/pay',
        data: {'payerWalletName': payerWalletName},
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao pagar payment request: $e');
    }
  }

  @override
  Future<List<PaymentLink>> getPaymentLinks() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsPaymentLinksList,
      );

      var data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentLink.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        return [];
      }
      if (e is AppException && e.statusCode == 403) {
        return [];
      }

      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao listar payment requests: $e');
    }
  }

  // ==================== Withdrawals ====================

  @override
  Future<TxStatus> withdraw({
    required String fromWalletName,
    required String toAddress,
    required double amount,
    String? description,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsWithdraw,
        data: {
          'fromWalletName': fromWalletName,
          'toAddress': toAddress,
          'amount': amount,
          if (description != null) 'description': description,
        },
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
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
      throw ServerException(message: 'Erro ao realizar saque: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionHistory() async {
    try {
      final response = await apiClient.get(AppConfig.ledgerHistory);
      final dynamic raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      // Accept { "data": [...] } or [...] directly
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List<dynamic>;
      } else {
        return [];
      }

      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final typeStr = (m['type'] as String? ?? '').toUpperCase();
        TransactionType txType;
        switch (typeStr) {
          case 'TRANSACTION_SEND':
          case 'SEND':
          case 'WITHDRAWAL':
            txType = TransactionType.send;
            break;
          case 'TRANSACTION_RECEIVE':
          case 'RECEIVE':
          case 'DEPOSIT':
            txType = TransactionType.receive;
            break;
          default:
            txType = TransactionType.send;
        }

        final statusStr = (m['status'] as String? ?? '').toLowerCase();
        TransactionStatus txStatus;
        switch (statusStr) {
          case 'pending':
          case 'processing':
            txStatus = TransactionStatus.pending;
            break;
          case 'failed':
          case 'error':
            txStatus = TransactionStatus.failed;
            break;
          default:
            txStatus = TransactionStatus.confirmed;
        }

        final double amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
        final int amountSatoshis =
            (m['amountSatoshis'] as num?)?.toInt() ??
            (amount * 100000000).round();

        DateTime timestamp;
        try {
          timestamp = DateTime.parse(
            m['createdAt']?.toString() ??
                m['timestamp']?.toString() ??
                DateTime.now().toIso8601String(),
          );
        } catch (_) {
          timestamp = DateTime.now();
        }

        return Transaction(
          id: m['id']?.toString() ?? m['txid']?.toString() ?? '',
          fromAddress:
              m['senderUsername']?.toString() ??
              m['sender']?.toString() ??
              m['fromAddress']?.toString() ??
              '',
          toAddress:
              m['receiverUsername']?.toString() ??
              m['receiver']?.toString() ??
              m['toAddress']?.toString() ??
              '',
          amountSatoshis: amountSatoshis,
          feeSatoshis: (m['feeSatoshis'] as num?)?.toInt() ?? 0,
          status: txStatus,
          type: txType,
          confirmations: txStatus == TransactionStatus.confirmed ? 6 : 0,
          timestamp: timestamp,
          description:
              m['context']?.toString() ??
              m['description']?.toString() ??
              typeStr,
          isInternal: m['isInternal'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao buscar histórico: $e');
    }
  }
}
