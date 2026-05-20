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
    required double expectedAmountBtc,
  });
  Future<LightningInvoice> createLightningInvoice({
    required String idempotencyKey,
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
    String? idempotencyKey,
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

  List<ExternalTransfer> _externalTransfersFromResponse(dynamic data) {
    return _parseJsonListResponse(data).map(ExternalTransfer.fromJson).toList();
  }

  bool _isCreditedExternalStatus(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SETTLED':
      case 'CONFIRMED':
      case 'PAID':
        return true;
      default:
        return false;
    }
  }

  Deposit _depositFromExternalTransfer(ExternalTransfer transfer) {
    final transferId = [
      transfer.blockchainTxid,
      transfer.paymentHash,
      transfer.externalReference,
      transfer.invoiceId,
      transfer.id,
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => transfer.id);
    final amount = transfer.amountBtc.abs() > 0
        ? transfer.amountBtc.abs()
        : transfer.expectedAmountBtc.abs();
    final credited = _isCreditedExternalStatus(transfer.status);

    return Deposit(
      id: transfer.id.hashCode,
      userId: 0,
      txid: transferId,
      fromAddress: transfer.provider,
      toAddress: transfer.destination.isNotEmpty
          ? transfer.destination
          : transfer.walletName,
      amountBtc: amount,
      confirmations: transfer.confirmations,
      status: credited ? 'credited' : transfer.status.toLowerCase(),
      createdAt: transfer.detectedAt ?? transfer.createdAt,
      confirmedAt: transfer.settledAt,
    );
  }

  bool _matchesExternalTransfer(ExternalTransfer transfer, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }

    return [
      transfer.id,
      transfer.blockchainTxid,
      transfer.paymentHash,
      transfer.externalReference,
      transfer.invoiceId,
    ].any((candidate) => candidate.trim() == normalized);
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
                : 'Não conseguimos concluir sua solicitação agora.'));
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
      throw ServerException(
        message: 'Não conseguimos calcular a taxa agora. Tente novamente.',
      );
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
        message:
            'Não conseguimos preparar essa transação agora. Tente novamente.',
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
      throw ServerException(
        message: 'Não conseguimos atualizar o status agora.',
      );
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
      throw ServerException(
        message: 'Não conseguimos enviar a transação agora.',
      );
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
      throw ServerException(
        message: 'Não conseguimos transmitir a transação agora.',
      );
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
          message: 'Não conseguimos criar um endereço para este depósito.',
        );
      }

      return address;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos criar um endereço para este depósito.',
      );
    }
  }

  @override
  Future<Map<String, String>> getOnrampUrls() async {
    try {
      final response = await apiClient.get(AppConfig.transactionsOnrampUrls);
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      }

      if (data is Map) {
        return Map<String, dynamic>.from(
          data,
        ).map((key, value) => MapEntry(key, value?.toString() ?? ''));
      }

      throw const ServerException(
        message:
            'Não encontramos opções de compra disponíveis para esta sessão.',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos carregar as opções de compra agora.',
      );
    }
  }

  @override
  Future<Deposit> confirmDeposit({
    required String txid,
    required String fromAddress,
    required double amount,
  }) async {
    throw const ValidationException(
      message:
          'Depósitos são detectados automaticamente pelo monitoramento de rede. Aguarde a confirmação aparecer no histórico.',
      errorCode: 'ERR_DEPOSIT_MANUAL_CONFIRM_DISABLED',
    );
  }

  @override
  Future<List<Deposit>> getDeposits() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsNetworkTransfers,
      );

      var data = response.data;
      if (data is String) {
        try {
          data = await compute<String, dynamic>(decodeJsonData, data);
        } catch (_) {}
      }

      return _externalTransfersFromResponse(data)
          .where((transfer) => transfer.isInboundTransfer)
          .map(_depositFromExternalTransfer)
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos carregar seus depósitos agora.',
      );
    }
  }

  @override
  Future<double> getDepositBalance() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsNetworkTransfers,
      );
      final deposits = _externalTransfersFromResponse(response.data)
          .where(
            (transfer) =>
                transfer.isInboundTransfer &&
                _isCreditedExternalStatus(transfer.status),
          )
          .map(_depositFromExternalTransfer);
      return deposits.fold<double>(
        0,
        (total, deposit) => total + deposit.amountBtc,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos atualizar o saldo de depósitos agora.',
      );
    }
  }

  @override
  Future<Deposit> getDeposit(String txid) async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsNetworkTransfers,
      );
      ExternalTransfer? transfer;
      for (final candidate in _externalTransfersFromResponse(response.data)) {
        if (candidate.isInboundTransfer &&
            _matchesExternalTransfer(candidate, txid)) {
          transfer = candidate;
          break;
        }
      }

      if (transfer == null) {
        throw const ServerException(
          message: 'Não encontramos este depósito no monitoramento de rede.',
          statusCode: 404,
          errorCode: 'ERR_DEPOSIT_NOT_FOUND',
        );
      }

      return _depositFromExternalTransfer(transfer);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos carregar este depósito agora.',
      );
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
      throw ServerException(
        message: 'Não conseguimos criar este link de pagamento agora.',
      );
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
      throw ServerException(
        message: 'Não conseguimos atualizar este link de pagamento agora.',
      );
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
      throw ServerException(
        message: 'Não conseguimos carregar seus links de pagamento agora.',
      );
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
        data: {if (reason != null) 'reason': reason},
      );
      return PaymentLink.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos cancelar este link agora.',
      );
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
        message: 'Não conseguimos verificar as opções desta carteira agora.',
      );
    }
  }

  @override
  Future<OnchainAddressAllocation> issueOnchainAddress({
    required String walletName,
    required double expectedAmountBtc,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsNetworkOnchainAddress,
        data: {
          'walletName': walletName,
          'expectedAmountBtc': expectedAmountBtc,
        },
      );
      return OnchainAddressAllocation.fromJson(
        _parseJsonResponse(response.data),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos criar um endereço para esta carteira agora.',
      );
    }
  }

  @override
  Future<LightningInvoice> createLightningInvoice({
    required String idempotencyKey,
    required String walletName,
    required double amount,
    String? memo,
    int expiresInSeconds = 900,
  }) async {
    try {
      final response = await apiClient.post(
        AppConfig.transactionsNetworkLightningInvoice,
        data: {
          'idempotencyKey': idempotencyKey,
          'walletName': walletName,
          'amount': amount,
          'memo': memo,
          'expiresInSeconds': expiresInSeconds,
        },
      );
      return LightningInvoice.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos criar o pedido Lightning agora.',
      );
    }
  }

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() async {
    try {
      final response = await apiClient.get(
        AppConfig.transactionsNetworkTransfers,
      );
      return _externalTransfersFromResponse(response.data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos carregar suas movimentações agora.',
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
        message: 'Não conseguimos atualizar esta movimentação agora.',
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
        message: 'Não conseguimos cancelar este depósito agora.',
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
    String? idempotencyKey,
  }) async {
    try {
      final response = await apiClient.post(
        isLightning
            ? AppConfig.transactionsNetworkLightningPay
            : AppConfig.transactionsNetworkOnchainSend,
        data: TransactionRemoteDataSourceImpl.buildWithdrawRequestPayload(
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
          idempotencyKey: idempotencyKey,
        ),
      );
      return TxStatus.fromJson(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
      }
      if (e is AppException) rethrow;
      throw ServerException(
        message: isLightning
            ? 'Não conseguimos concluir o pagamento Lightning agora.'
            : 'Não conseguimos concluir o saque on-chain agora.',
      );
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildWithdrawRequestPayload({
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
    String? idempotencyKey,
  }) {
    final normalizedWalletName = _requiredText(
      fromWalletName,
      'fromWalletName',
    );
    final normalizedIdempotencyKey = _requiredText(
      idempotencyKey,
      'idempotencyKey',
    );
    final normalizedDescription = _optionalText(description);
    final normalizedTotp = _optionalText(totpCode);
    final normalizedPassphrase = _optionalText(confirmationPassphrase);
    final normalizedPasskeyAssertion = _optionalText(passkeyAssertionJson);

    if (isLightning) {
      return {
        'idempotencyKey': normalizedIdempotencyKey,
        'fromWalletName': normalizedWalletName,
        'paymentRequest': _requiredText(paymentRequest, 'paymentRequest'),
        'amount': amount,
        'maxRoutingFeeBtc': maxRoutingFeeBtc,
        'description': normalizedDescription,
        'totpCode': normalizedTotp,
        'passkeyAssertionResponseJSON': normalizedPasskeyAssertion,
        'confirmationPassphrase': normalizedPassphrase,
      };
    }

    return {
      'idempotencyKey': normalizedIdempotencyKey,
      'fromWalletName': normalizedWalletName,
      'toAddress': _requiredText(toAddress, 'toAddress'),
      'amount': amount,
      'description': normalizedDescription ?? 'saque para carteira externa',
      'totpCode': normalizedTotp,
      'passkeyAssertionResponseJSON': normalizedPasskeyAssertion,
      'confirmationPassphrase': normalizedPassphrase,
    };
  }

  static String _requiredText(String? value, String fieldName) {
    final normalized = _optionalText(value);
    if (normalized == null) {
      throw ValidationException(message: '$fieldName is required');
    }
    return normalized;
  }

  static String? _optionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
