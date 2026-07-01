import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/device_helper.dart';
import '../../domain/entities/external_transfer.dart';
import '../../domain/entities/fee_estimate.dart';
import '../../domain/entities/tx_status.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/onchain_address_allocation.dart';
import '../../domain/entities/wallet_network_address.dart';

export 'transaction_remote_datasource_contract.dart';
import 'transaction_remote_datasource_contract.dart';

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

  List<Map<String, dynamic>> _kfeStatementPayloads(
    Map<String, dynamic> dashboard,
  ) {
    return _parseJsonListResponse(dashboard['recentStatement']).map((item) {
      final payloadJson = item['displayPayloadJson']?.toString();
      Map<String, dynamic> payload = {};
      if (payloadJson != null && payloadJson.trim().isNotEmpty) {
        try {
          payload = _parseJsonResponse(jsonDecode(payloadJson));
        } catch (_) {}
      }
      return {
        ...payload,
        'id': payload['transactionId'] ?? item['transactionId'] ?? item['id'],
        'transactionId': payload['transactionId'] ?? item['transactionId'],
        'walletId': item['walletId'],
        'createdAt': item['createdAt'],
        'updatedAt': item['createdAt'],
      };
    }).toList();
  }

  ExternalTransfer _externalTransferFromKfePayload(
    Map<String, dynamic> payload,
  ) {
    final rail = payload['rail']?.toString().toUpperCase() ?? 'ONCHAIN';
    final direction = payload['direction']?.toString().toUpperCase() ?? '';
    final amountSats = (payload['receiverAmountSats'] as num?)?.toInt() ??
        (payload['grossAmountSats'] as num?)?.toInt() ??
        0;
    final networkFeeSats = (payload['networkFeeSats'] as num?)?.toInt() ?? 0;
    final keroseneFeeSats = (payload['keroseneFeeSats'] as num?)?.toInt() ?? 0;
    final totalDebitSats = (payload['totalDebitSats'] as num?)?.toInt() ?? 0;
    final isInbound = direction == 'INBOUND';
    return ExternalTransfer.fromJson({
      'id': payload['transactionId']?.toString() ??
          payload['id']?.toString() ??
          '',
      'network': rail,
      'transferType': isInbound ? 'ADDRESS_ISSUE' : 'OUTBOUND_PAYMENT',
      'status': payload['status']?.toString() ?? 'PENDING',
      'provider': 'KFE',
      'walletName': payload['walletId']?.toString() ??
          payload['sourceWalletId']?.toString() ??
          '',
      'destination': payload['destinationWalletId']?.toString() ??
          payload['externalReference']?.toString() ??
          '',
      'amountBtc': amountSats / 100000000.0,
      'networkFeeBtc': networkFeeSats / 100000000.0,
      'platformFeeBtc': keroseneFeeSats / 100000000.0,
      'totalDebitedBtc': totalDebitSats / 100000000.0,
      'externalReference': payload['externalReference']?.toString() ?? '',
      'blockchainTxid': payload['blockchainTxid']?.toString() ?? '',
      'paymentHash': payload['paymentHash']?.toString() ?? '',
      'expectedAmountBtc': amountSats / 100000000.0,
      'confirmations':
          payload['status']?.toString().toUpperCase() == 'SETTLED' ? 6 : 0,
      'createdAt': payload['createdAt']?.toString(),
      'updatedAt': payload['updatedAt']?.toString(),
      'context': payload['memo']?.toString() ?? '',
    });
  }

  List<ExternalTransfer> _externalTransfersFromKfeDashboard(
    Map<String, dynamic> dashboard,
  ) {
    return _kfeStatementPayloads(dashboard)
        .where((payload) {
          final rail = payload['rail']?.toString().toUpperCase();
          return rail == 'ONCHAIN' || rail == 'LIGHTNING';
        })
        .map(_externalTransferFromKfePayload)
        .toList();
  }

  Future<Map<String, dynamic>> _getKfeDashboard() async {
    final response = await apiClient.get(AppConfig.kfeDashboard);
    return _parseJsonResponse(response.data);
  }

  List<Map<String, dynamic>> _kfeWalletsFromDashboard(
    Map<String, dynamic> dashboard,
  ) {
    return _parseJsonListResponse(dashboard['wallets']);
  }

  Map<String, dynamic> _findKfeWallet(
    Map<String, dynamic> dashboard,
    String walletName,
  ) {
    final normalized = walletName.trim();
    return _kfeWalletsFromDashboard(dashboard).firstWhere(
      (wallet) => [
        wallet['walletId'],
        wallet['id'],
        wallet['label'],
        wallet['walletName'],
        wallet['name'],
      ].any((candidate) => candidate?.toString() == normalized),
      orElse: () => const {},
    );
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

  int _btcToSats(double value) => (value * 100000000).round();

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  Map<String, dynamic> _kfeTransactionPayload({
    required String idempotencyKey,
    required String rail,
    required String direction,
    String? sourceWalletId,
    String? destinationWalletId,
    required int amountSats,
    int networkFeeSats = 0,
    String? externalReference,
    String? memo,
    String? totpCode,
    String? passkeyAssertionJson,
    String? confirmationPassphrase,
    String? appPin,
  }) {
    return {
      'idempotencyKey': idempotencyKey,
      'rail': rail,
      'direction': direction,
      if (sourceWalletId != null && sourceWalletId.trim().isNotEmpty)
        'sourceWalletId': sourceWalletId.trim(),
      if (destinationWalletId != null && destinationWalletId.trim().isNotEmpty)
        if (_looksLikeUuid(destinationWalletId))
          'destinationWalletId': destinationWalletId.trim()
        else if (rail == 'INTERNAL' && direction == 'INTERNAL')
          'externalReference': destinationWalletId.trim(),
      'amountSats': amountSats,
      'networkFeeSats': networkFeeSats,
      if (externalReference != null && externalReference.trim().isNotEmpty)
        'externalReference': externalReference.trim(),
      if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
      if (totpCode != null && totpCode.trim().isNotEmpty)
        'totpCode': totpCode.trim(),
      if (passkeyAssertionJson != null &&
          passkeyAssertionJson.trim().isNotEmpty)
        'passkeyAssertionJson': passkeyAssertionJson.trim(),
      if (confirmationPassphrase != null &&
          confirmationPassphrase.trim().isNotEmpty)
        'confirmationPassphrase': confirmationPassphrase.trim(),
      if (appPin != null && appPin.trim().isNotEmpty) 'appPin': appPin.trim(),
    };
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

  PaymentLink _paymentLinkFromKfePayload(
    Map<String, dynamic> payload, {
    double? fallbackAmountBtc,
    String? fallbackDescription,
    DateTime? fallbackExpiresAt,
    Map<String, String>? metadata,
    String? referenceLabel,
  }) {
    final amountSats = (payload['amountSats'] as num?)?.toDouble() ??
        (payload['receiverAmountSats'] as num?)?.toDouble() ??
        (payload['grossAmountSats'] as num?)?.toDouble() ??
        0;
    final amountBtc =
        amountSats > 0 ? amountSats / 100000000.0 : (fallbackAmountBtc ?? 0);
    return PaymentLink.fromJson({
      'id': payload['id'] ?? payload['transactionId'],
      'amountBtc': amountBtc,
      'description': payload['memo']?.toString() ??
          fallbackDescription ??
          'Recebimento via QR',
      'depositAddress': payload['address']?.toString() ??
          payload['externalReference']?.toString() ??
          '',
      'visibility': 'PRIVATE',
      'confirmationMode': 'USER_ACTION_REQUIRED',
      'amountLocked': true,
      'referenceLabel': referenceLabel,
      'metadata': metadata ?? const <String, String>{},
      'status': payload['status']?.toString() ?? 'PENDING',
      'txid': payload['blockchainTxid']?.toString(),
      'createdAt': payload['createdAt']?.toString(),
      'paidAt': payload['settledAt']?.toString(),
      'completedAt': payload['updatedAt']?.toString(),
      'expiresAt': payload['expiresAt']?.toString() ??
          fallbackExpiresAt?.toIso8601String(),
      'paymentRail': payload['rail']?.toString() ?? 'ONCHAIN',
      'settlementStatus': payload['status']?.toString() ?? 'PENDING',
      'terminal': payload['terminal'] ?? false,
    });
  }

  String _requirePaymentLinkWalletId({
    required Map<String, String>? metadata,
    required String? referenceLabel,
  }) {
    final walletId = metadata?['walletId']?.trim();
    if (walletId != null && walletId.isNotEmpty) {
      return walletId;
    }
    final walletName =
        metadata?['walletName']?.trim() ?? referenceLabel?.trim();
    if (walletName != null && walletName.isNotEmpty) {
      return walletName;
    }
    throw const ValidationException(
      message: 'walletName is required',
      statusCode: 400,
      errorCode: 'ERR_KFE_PAYMENT_LINK_WALLET_REQUIRED',
    );
  }

  DateTime? _resolveExpiry(int? expiresInMinutes) {
    if (expiresInMinutes == null || expiresInMinutes <= 0) {
      return null;
    }
    return DateTime.now().toUtc().add(Duration(minutes: expiresInMinutes));
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
      final response = await apiClient.post(
        '${AppConfig.kfeTransactions}/quote',
        data: {
          'rail': 'ONCHAIN',
          'direction': 'OUTBOUND',
          'amountSats': _btcToSats(amount),
          'networkFeeSats': 0,
        },
      );
      final data = _parseJsonResponse(response.data);
      final networkFeeBtc =
          ((data['networkFeeSats'] as num?)?.toDouble() ?? 0) / 100000000.0;
      final receiverAmountBtc =
          ((data['receiverAmountSats'] as num?)?.toDouble() ??
                  _btcToSats(amount).toDouble()) /
              100000000.0;
      final totalDebitBtc = ((data['totalDebitSats'] as num?)?.toDouble() ??
              _btcToSats(amount).toDouble()) /
          100000000.0;
      return FeeEstimate(
        fastSatPerByte: 0,
        standardSatPerByte: 0,
        slowSatPerByte: 0,
        estimatedFastBtc: networkFeeBtc,
        estimatedStandardBtc: networkFeeBtc,
        estimatedSlowBtc: networkFeeBtc,
        amountReceived: receiverAmountBtc,
        totalToSend: totalDebitBtc,
      );
    } catch (e) {
      if (e is DioException) {
        throw _mapDioError(e);
      }
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos calcular a cotação da transação agora.',
      );
    }
  }

  @override
  Future<TxStatus> getTransactionStatus(String txid) async {
    try {
      if (!_looksLikeUuid(txid)) {
        throw const ValidationException(
          message: 'Identificador de transação KFE inválido.',
          statusCode: 400,
          errorCode: 'ERR_KFE_TRANSACTION_ID_INVALID',
        );
      }
      final response = await apiClient.get(AppConfig.kfeTransaction(txid));
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
    String? appPin,
  }) async {
    try {
      final normalizedSender =
          fromAddress.trim().isNotEmpty ? fromAddress.trim() : '';
      final deviceHash = await DeviceHelper.getDeviceHash();
      final response = await apiClient.post(
        AppConfig.kfeTransactions,
        headers: {
          'X-Device-Hash': deviceHash,
        },
        data: _kfeTransactionPayload(
          idempotencyKey: _requiredText(idempotencyKey, 'idempotencyKey'),
          rail: 'INTERNAL',
          direction: 'INTERNAL',
          sourceWalletId: normalizedSender,
          destinationWalletId: toAddress,
          amountSats: _btcToSats(amount),
          networkFeeSats: feeSatoshis,
          memo: context ?? 'transfer',
          totpCode: totpCode,
          passkeyAssertionJson: passkeyAssertionJson,
          confirmationPassphrase: confirmationPassphrase,
          appPin: appPin,
        ),
      );

      final data = _parseJsonResponse(response.data);
      if (data.isEmpty) {
        throw const ServerException(
          message:
              'O ledger confirmou a chamada, mas não retornou o status da transação.',
          errorCode: 'ERR_LEDGER_EMPTY_TRANSACTION_RESPONSE',
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

  // ==================== Deposits ====================

  @override
  Future<String> getDepositAddress() async {
    try {
      final dashboard = await _getKfeDashboard();
      final address = _kfeWalletsFromDashboard(dashboard)
          .map((wallet) => wallet['activeAddress']?.toString().trim() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');

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
      final response = await apiClient.get(AppConfig.kfeOnrampUrls);
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
  Future<List<Deposit>> getDeposits() async {
    try {
      final dashboard = await _getKfeDashboard();
      return _externalTransfersFromKfeDashboard(dashboard)
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
      final dashboard = await _getKfeDashboard();
      final deposits = _externalTransfersFromKfeDashboard(dashboard)
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
      ExternalTransfer? transfer;
      final dashboard = await _getKfeDashboard();
      for (final candidate in _externalTransfersFromKfeDashboard(dashboard)) {
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
      final requestedWalletId = _requirePaymentLinkWalletId(
        metadata: metadata,
        referenceLabel: referenceLabel,
      );
      final dashboard = await _getKfeDashboard();
      final wallet = _findKfeWallet(dashboard, requestedWalletId);
      final walletId = wallet['walletId']?.toString() ??
          wallet['id']?.toString() ??
          requestedWalletId;
      final expiresAt = _resolveExpiry(expiresInMinutes);
      final response = await apiClient.post(
        AppConfig.kfePaymentRequests,
        data: {
          'walletId': walletId,
          'rail': 'ONCHAIN',
          'amountSats': _btcToSats(amount),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (referenceLabel != null && referenceLabel.trim().isNotEmpty)
            'memo': referenceLabel.trim(),
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
          'issueFreshAddress': true,
        },
      );

      final data = _parseJsonResponse(response.data);
      return _paymentLinkFromKfePayload(
        data,
        fallbackAmountBtc: amount,
        fallbackDescription: description,
        fallbackExpiresAt: expiresAt,
        metadata: metadata,
        referenceLabel: referenceLabel,
      );
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
      final response = _looksLikeUuid(linkId)
          ? await apiClient.get(AppConfig.kfePaymentRequest(linkId))
          : await apiClient.get(AppConfig.kfePublicPaymentRequest(linkId));
      final data = _parseJsonResponse(response.data);
      return _paymentLinkFromKfePayload(data);
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
      final response = await apiClient.get(AppConfig.kfePaymentRequests);
      return _parseJsonListResponse(response.data)
          .map(_paymentLinkFromKfePayload)
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos carregar seus links de pagamento agora.',
      );
    }
  }

  @override
  Future<WalletNetworkAddress> getWalletNetworkProfile({
    required String walletName,
  }) async {
    try {
      final dashboard = await _getKfeDashboard();
      final wallet = _findKfeWallet(dashboard, walletName);
      if (wallet.isEmpty) {
        throw const ValidationException(
          message: 'Carteira não encontrada.',
          statusCode: 404,
          errorCode: 'ERR_WALLET_NOT_FOUND',
        );
      }
      return WalletNetworkAddress.fromJson({
        'walletName': wallet['label']?.toString() ?? walletName,
        'onchainAddress': wallet['activeAddress']?.toString() ?? '',
        'lightningAddress': '',
        'network': wallet['kind']?.toString() ?? '',
        'provider': 'KFE',
        'externalWalletReference':
            wallet['walletId']?.toString() ?? wallet['id']?.toString() ?? '',
        'walletMode': wallet['kind']?.toString().toUpperCase() == 'WATCH_ONLY'
            ? 'SELF_CUSTODY'
            : 'KEROSENE',
        'lightningEnabled': false,
        'lightningUnavailableReason':
            'Recebimento Lightning KFE ainda não está disponível.',
      });
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
      final dashboard = await _getKfeDashboard();
      final wallet = _findKfeWallet(dashboard, walletName);
      final walletId =
          wallet['walletId']?.toString() ?? wallet['id']?.toString() ?? '';
      if (walletId.trim().isEmpty) {
        throw const ValidationException(
          message: 'KFE wallet not found.',
          statusCode: 404,
          errorCode: 'ERR_KFE_WALLET_NOT_FOUND',
        );
      }
      final response = await apiClient.post(
        AppConfig.kfeWalletAddressRotate(walletId),
      );
      final data = _parseJsonResponse(response.data);
      return OnchainAddressAllocation.fromJson({
        'walletName': walletName,
        'onchainAddress': data['address']?.toString() ?? '',
        'expectedAmountBtc': expectedAmountBtc,
        'network': 'ONCHAIN',
        'provider': data['providerReference']?.toString() ?? 'KFE',
        'externalWalletReference': data['walletId']?.toString() ?? walletId,
        'walletMode': wallet['kind']?.toString().toUpperCase() == 'WATCH_ONLY'
            ? 'SELF_CUSTODY'
            : 'KEROSENE',
        'transferId': data['id']?.toString() ?? '',
        'transferStatus': data['status']?.toString() ?? 'ACTIVE',
        'confirmations': 0,
        'requiredConfirmations': 3,
        'blockchainTxid': '',
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos criar um endereço para esta carteira agora.',
      );
    }
  }

  @override
  Future<List<ExternalTransfer>> getExternalTransfers() async {
    try {
      final dashboard = await _getKfeDashboard();
      return _externalTransfersFromKfeDashboard(dashboard);
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
      if (!_looksLikeUuid(transferId)) {
        throw const ValidationException(
          message: 'Identificador de transação KFE inválido.',
          statusCode: 400,
          errorCode: 'ERR_KFE_TRANSACTION_ID_INVALID',
        );
      }
      final response = await apiClient.get(
        AppConfig.kfeTransaction(transferId),
      );
      return _externalTransferFromKfePayload(_parseJsonResponse(response.data));
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Não conseguimos atualizar esta movimentação agora.',
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
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
    String? appPin,
  }) async {
    try {
      final deviceHash = await DeviceHelper.getDeviceHash();
      final response = await apiClient.post(
        AppConfig.kfeTransactions,
        headers: {
          'X-Device-Hash': deviceHash,
        },
        data: TransactionRemoteDataSourceImpl.buildWithdrawRequestPayload(
          fromWalletName: fromWalletName,
          toAddress: toAddress,
          paymentRequest: paymentRequest,
          amount: amount,
          totpCode: totpCode,
          isLightning: isLightning,
          networkFeeBtc: networkFeeBtc,
          maxRoutingFeeBtc: maxRoutingFeeBtc,
          description: description,
          confirmationPassphrase: confirmationPassphrase,
          passkeyAssertionJson: passkeyAssertionJson,
          idempotencyKey: idempotencyKey,
          appPin: appPin,
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
    double networkFeeBtc = 0,
    double maxRoutingFeeBtc = 0.000001,
    String? description,
    String? confirmationPassphrase,
    String? passkeyAssertionJson,
    String? idempotencyKey,
    String? appPin,
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
    final externalReference = isLightning
        ? _requiredText(paymentRequest, 'paymentRequest')
        : _requiredText(toAddress, 'toAddress');
    final feeBtc =
        isLightning && networkFeeBtc <= 0 ? maxRoutingFeeBtc : networkFeeBtc;

    return {
      'idempotencyKey': normalizedIdempotencyKey,
      'rail': isLightning ? 'LIGHTNING' : 'ONCHAIN',
      'direction': 'OUTBOUND',
      'sourceWalletId': normalizedWalletName,
      'amountSats': (amount * 100000000).round(),
      'networkFeeSats': (feeBtc * 100000000).round(),
      'externalReference': externalReference,
      'memo': normalizedDescription ??
          (isLightning ? 'Pagamento Lightning' : 'saque para carteira externa'),
      if (totpCode != null && totpCode.trim().isNotEmpty)
        'totpCode': totpCode.trim(),
      if (passkeyAssertionJson != null &&
          passkeyAssertionJson.trim().isNotEmpty)
        'passkeyAssertionJson': passkeyAssertionJson.trim(),
      if (confirmationPassphrase != null &&
          confirmationPassphrase.trim().isNotEmpty)
        'confirmationPassphrase': confirmationPassphrase.trim(),
      if (appPin != null && appPin.trim().isNotEmpty) 'appPin': appPin.trim(),
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
