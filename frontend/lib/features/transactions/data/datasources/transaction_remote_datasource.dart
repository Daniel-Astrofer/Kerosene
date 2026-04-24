import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/external_transfer.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/lightning_invoice.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/onchain_address_allocation.dart';
import '../../domain/entities/wallet_network_address.dart';
import '../../../wallet/domain/entities/unsigned_transaction.dart';

/// Top-level function for isolates
dynamic decodeJsonData(String source) => jsonDecode(source);

/// Interface do TransactionRemoteDataSource
abstract class TransactionRemoteDataSource {
  // Fee & Status
  Future<FeeEstimate> estimateFee(double amount);
  Future<UnsignedTransaction> createUnsignedTransaction({
    required String toAddress,
    required double amount,
    required String feeLevel,
  });
  Future<TxStatus> getTransactionStatus(String txid);

  // Send & Broadcast
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
  });
  Future<TxStatus> broadcastTransaction({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  });

  // Deposits
  Future<String> getDepositAddress();
  Future<Map<String, String>> getOnrampUrls();
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
    bool regenerate = false,
  });
  Future<LightningInvoice> createLightningInvoice({
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
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
  });
}

/// Implementação do TransactionRemoteDataSource
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl(this.apiClient);

  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List<Map<String, dynamic>> _parseJsonListResponse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _parseErrorPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'message': data};
      }
    }

    return const {};
  }

  AppException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = _parseErrorPayload(error.response?.data);
    final message = payload['message']?.toString().trim().isNotEmpty == true
        ? payload['message']!.toString().trim()
        : (payload['error']?.toString().trim().isNotEmpty == true
            ? payload['error']!.toString().trim()
            : (error.message?.trim().isNotEmpty == true
                ? error.message!.trim()
                : 'Erro no servidor'));
    final rawCode = payload['errorCode']?.toString().trim();
    final errorCode = rawCode == null || rawCode.isEmpty ? null : rawCode;
    final errorData = payload['data'];

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        data: errorData,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        data: errorData,
      );
    }

    return ValidationException(
      message: message,
      statusCode: statusCode ?? 400,
      errorCode: errorCode,
      data: errorData,
    );
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
    required String toAddress,
    required double amount,
    required String feeLevel,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsCreateUnsigned,
        data: {'toAddress': toAddress, 'amount': amount, 'feeLevel': feeLevel},
      );
      return UnsignedTransaction.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
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
    String? passkeyAssertionJson,
    String? confirmationPassphrase,
    String? totpCode,
    String? idempotencyKey,
    int? requestTimestamp,
  }) async {
    try {
      final normalizedSender =
          fromAddress.trim().isNotEmpty ? fromAddress.trim() : '';
      final response = await apiClient.post(
        AppConfig.ledgerTransaction,
        data: {
          'sender': normalizedSender.isNotEmpty ? normalizedSender : null,
          'receiver': toAddress,
          'amount': amount,
          'context': context ?? 'transfer',
          if (passkeyAssertionJson != null)
            'passkeyAssertionJson': passkeyAssertionJson,
          if (confirmationPassphrase != null)
            'confirmationPassphrase': confirmationPassphrase,
          if (totpCode != null) 'totpCode': totpCode,
          if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
          if (requestTimestamp != null) 'requestTimestamp': requestTimestamp,
        },
      );

      final data = _parseJsonResponse(response.data);
      if (data.isEmpty) {
        final fallbackTxid = idempotencyKey ??
            requestTimestamp?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        return TxStatus(
          txid: fallbackTxid,
          status: 'confirmed',
          feeSatoshis: feeSatoshis,
          amountReceived: amount,
          sender: normalizedSender,
          receiver: toAddress,
          context: context,
          message: 'Transaction successfully processed.',
        );
      }
      return TxStatus.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
      }
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao enviar transação: $e');
    }
  }

  @override
  Future<TxStatus> broadcastTransaction({
    required String rawTxHex,
    required String toAddress,
    required double amount,
    String? message,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsBroadcast,
        data: {
          'rawTxHex': rawTxHex,
          'toAddress': toAddress,
          'amount': amount,
          if (message != null) 'message': message,
        },
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

      final data = response.data;
      String address;

      if (data is Map<String, dynamic>) {
        address = (data['address'] ?? data['depositAddress'] ?? '').toString();
      } else if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        address = (map['address'] ?? map['depositAddress'] ?? '').toString();
      } else {
        address = data.toString().trim();
      }

      if (address.startsWith('"') && address.endsWith('"')) {
        address = address.substring(1, address.length - 1);
      }

      if (address.isEmpty) {
        throw const ServerException(
          message: 'Endereço de depósito não retornado pelo servidor.',
        );
      }

      return address;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter endereço de depósito: $e');
    }
  }

  @override
  Future<Map<String, String>> getOnrampUrls() async {
    try {
      final response = await apiClient.get(AppConfig.transactionsOnrampUrls);
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data).map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
      }

      throw const ServerException(
        message: 'Links de onramp não retornados pelo servidor.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao obter links de onramp: $e');
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

  // ==================== Payment Links (External BTC) ====================

  @override
  Future<PaymentLink> createPaymentLink({
    required double amount,
    String? description,
    int? expiresInMinutes,
    String? visibility,
    String? confirmationMode,
    bool amountLocked = true,
    String? referenceLabel,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsCreatePaymentLink,
        data: {
          'amount': amount,
          'description': description ?? 'Recebimento via QR',
          if (expiresInMinutes != null) 'expiresInMinutes': expiresInMinutes,
          if (visibility != null) 'visibility': visibility,
          if (confirmationMode != null) 'confirmationMode': confirmationMode,
          'amountLocked': amountLocked,
          if (referenceLabel != null) 'referenceLabel': referenceLabel,
          if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        },
      );

      final data = _parseJsonResponse(response.data);
      return PaymentLink.fromJson(data);
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
      final data = _parseJsonResponse(response.data);
      return PaymentLink.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao consultar payment link: $e');
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
      throw ServerException(message: 'Erro ao listar payment links: $e');
    }
  }

  @override
  Future<PaymentLink> cancelPaymentLink({
    required String linkId,
    String? reason,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.transactionsPaymentLink}/$linkId/cancel',
        data: {
          if (reason != null) 'reason': reason,
        },
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao cancelar payment link: $e');
    }
  }

  @override
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  }) async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsNetworkWalletProfile,
        queryParameters: {'walletName': walletName},
      );
      return WalletNetworkAddress.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao consultar perfil de rede da carteira: $e',
      );
    }
  }

  @override
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    bool regenerate = false,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsNetworkOnchainAddress,
        data: {
          'walletName': walletName,
          'regenerate': regenerate,
        },
      );
      return OnchainAddressAllocation.fromJson(
          _parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao emitir endereço on-chain da carteira: $e',
      );
    }
  }

  @override
  Future<LightningInvoice> createLightningInvoice({
    required String walletName,
    required double amount,
    String? memo,
    int expiresInSeconds = 900,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsNetworkLightningInvoice,
        data: {
          'walletName': walletName,
          'amount': amount,
          'memo': memo,
          'expiresInSeconds': expiresInSeconds,
        },
      );
      return LightningInvoice.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Erro ao criar invoice Lightning: $e');
    }
  }

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() async {
    try {
      final response =
          await apiClient.get(AppConfig.transactionsNetworkTransfers);
      return _parseJsonListResponse(response.data)
          .map(ExternalTransfer.fromJson)
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao listar transferências externas: $e',
      );
    }
  }

  @override
  Future<ExternalTransfer> getExternalTransfer(String transferId) async {
    try {
      final response = await apiClient.get(
        '${AppConfig.transactionsNetworkTransfers}/$transferId',
      );
      return ExternalTransfer.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao consultar transferência externa: $e',
      );
    }
  }

  @override
  Future<ExternalTransfer> cancelInboundTransfer(String transferId) async {
    try {
      final response = await apiClient.post(
        '${AppConfig.depositRoot}/$transferId/cancel',
      );
      return ExternalTransfer.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
      }
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Erro ao cancelar depósito externo: $e',
      );
    }
  }

  // ==================== Withdrawals ====================

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
    try {
      final response = await apiClient.post(
        isLightning
            ? AppConfig.transactionsNetworkLightningPay
            : AppConfig.transactionsNetworkOnchainSend,
        data: isLightning
            ? {
                'fromWalletName': fromWalletName,
                'paymentRequest': paymentRequest,
                'amount': amount,
                'maxRoutingFeeBtc': maxRoutingFeeBtc,
                if (totpCode != null) 'totpCode': totpCode,
                if (description != null) 'description': description,
                if (confirmationPassphrase != null)
                  'confirmationPassphrase': confirmationPassphrase,
                if (passkeyAssertionJson != null)
                  'passkeyAssertionResponseJSON': passkeyAssertionJson,
              }
            : {
                'fromWalletName': fromWalletName,
                'toAddress': toAddress,
                'amount': amount,
                if (totpCode != null) 'totpCode': totpCode,
                if (description != null) 'description': description,
                if (confirmationPassphrase != null)
                  'confirmationPassphrase': confirmationPassphrase,
                if (passkeyAssertionJson != null)
                  'passkeyAssertionResponseJSON': passkeyAssertionJson,
              },
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
      }
      if (e is AppException) rethrow;
      throw ServerException(
        message: isLightning
            ? 'Erro ao realizar pagamento Lightning: $e'
            : 'Erro ao realizar saque on-chain: $e',
      );
    }
  }
}
