import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import 'bitcoin_account_models.dart';

export 'bitcoin_account_models.dart';

enum BitcoinAccountCustody {
  internal,
  custodialOnchain,
  watchOnly,
}

extension BitcoinAccountCustodyPayload on BitcoinAccountCustody {
  String get kfeKind {
    return switch (this) {
      BitcoinAccountCustody.internal => 'INTERNAL',
      BitcoinAccountCustody.custodialOnchain => 'CUSTODIAL_ONCHAIN',
      BitcoinAccountCustody.watchOnly => 'WATCH_ONLY',
    };
  }
}

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  });

  Future<BitcoinAccount> createInternalCard({
    required String label,
  });

  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  });

  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  });

  Future<ReceivingRequestView> rotateReceiveAddress(String accountId);

  Future<BitcoinAccount> renameWallet({
    required String accountId,
    required String label,
  });

  Future<BitcoinAccount> archiveWallet(String accountId);

  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  );

  Future<ReceivingRequestView> getReceiveStatus(String requestId);

  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(String coldWalletId);

  Future<List<PsbtWorkflowView>> listColdWalletPsbt(String coldWalletId);

  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  });

  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId);

  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  });

  Future<List<TaxEventView>> listTaxEvents();

  Future<TaxEventsExportView> exportTaxEvents({required String format});

  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  });
}

class RemoteBitcoinAccountsService implements BitcoinAccountsService {
  const RemoteBitcoinAccountsService(this._api);

  final ApiClient _api;

  @override
  Future<List<BitcoinAccount>> listAccounts() async {
    final response = await _api.get(AppConfig.kfeDashboard);
    final dashboard = _requireMap(response.data, operation: 'listAccounts');
    final wallets = dashboard['wallets'];
    if (wallets is! List) {
      throw ServerException(
        message: 'Resposta inesperada do dashboard KFE.',
        errorCode: 'ERR_BITCOIN_LISTACCOUNTS_INVALID_RESPONSE',
        data: response.data,
      );
    }
    return wallets
        .map((item) => _requireMap(item, operation: 'listAccounts'))
        .map(_accountFromKfeWallet)
        .toList();
  }

  @override
  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  }) async {
    if (custody == BitcoinAccountCustody.watchOnly) {
      throw const ValidationException(
        message:
            'Carteiras watch-only precisam ser importadas com material público.',
        statusCode: 400,
        errorCode: 'ERR_WATCH_ONLY_REQUIRES_PUBLIC_MATERIAL',
      );
    }

    final response = await _api.post(
      AppConfig.kfeWallets,
      data: kfeCreateWalletPayload(
        label: label,
        custody: custody,
      ),
    );
    return _accountFromKfeWallet(
      _requireMap(response.data, operation: 'createWallet'),
    );
  }

  @override
  Future<BitcoinAccount> createInternalCard({
    required String label,
  }) async {
    return createWallet(
      label: label,
      custody: BitcoinAccountCustody.internal,
    );
  }

  @override
  Future<BitcoinAccount> importColdWallet({
    required String label,
    required String xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final normalizedScriptPolicy = scriptPolicy.trim();
    final response = await _api.post(
      AppConfig.kfeWallets,
      data: {
        'kind': 'WATCH_ONLY',
        'label': label.trim(),
        'xpub': xpub.trim(),
        'fingerprint': fingerprint.trim(),
        'derivationPath': derivationPath.trim(),
        if (normalizedScriptPolicy.isNotEmpty)
          'descriptor': normalizedScriptPolicy,
        'issueInitialAddress': true,
      },
    );
    return _accountFromKfeWallet(
      _requireMap(response.data, operation: 'importColdWallet'),
    );
  }

  @override
  Future<ReceivingRequestView> createReceiveRequest({
    required String accountId,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  }) async {
    final response = await _api.post(
      AppConfig.kfePaymentRequests,
      data: {
        'walletId': accountId,
        'rail': 'ONCHAIN',
        if (amountSats != null) 'amountSats': amountSats,
        if (_kfeExpiresAt(expiry) != null) 'expiresAt': _kfeExpiresAt(expiry),
        'issueFreshAddress': oneTime,
      },
    );
    return _receiveRequestFromKfePaymentRequest(
      _requireMap(response.data, operation: 'createReceiveRequest'),
      fallbackAccountId: accountId,
      oneTime: oneTime,
    );
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    final response = await _api.get(
      _looksLikeUuid(requestId)
          ? AppConfig.kfePaymentRequest(requestId)
          : AppConfig.kfePublicPaymentRequest(requestId),
    );
    return _receiveRequestFromKfePaymentRequest(
      _requireMap(response.data, operation: 'getReceiveStatus'),
    );
  }

  @override
  Future<ReceivingRequestView> rotateReceiveAddress(String accountId) async {
    final response = await _api.post(
      AppConfig.kfeWalletAddressRotate(accountId),
    );
    return _receiveRequestFromKfeAddress(
      _requireMap(response.data, operation: 'rotateReceiveAddress'),
      fallbackAccountId: accountId,
    );
  }

  @override
  Future<BitcoinAccount> renameWallet({
    required String accountId,
    required String label,
  }) async {
    final response = await _api.patch(
      AppConfig.kfeWallet(accountId),
      data: {'label': label.trim()},
    );
    return _accountFromKfeWallet(
      _requireMap(response.data, operation: 'renameWallet'),
    );
  }

  @override
  Future<BitcoinAccount> archiveWallet(String accountId) async {
    final response = await _api.post(AppConfig.kfeWalletArchive(accountId));
    return _accountFromKfeWallet(
      _requireMap(response.data, operation: 'archiveWallet'),
    );
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    final response = await _api.get(AppConfig.kfePaymentRequests);
    final requests = response.data;
    if (requests is! List) {
      throw ServerException(
        message: 'Resposta inesperada da lista de requests KFE.',
        errorCode: 'ERR_KFE_RECEIVE_REQUESTS_INVALID_RESPONSE',
        data: response.data,
      );
    }
    return requests
        .map((item) => _requireMap(item, operation: 'listReceiveRequests'))
        .where((item) => (item['walletId'] ?? '').toString() == accountId)
        .map((item) => _receiveRequestFromKfePaymentRequest(
              item,
              fallbackAccountId: accountId,
            ))
        .toList();
  }

  static List<ReceivingRequestView> receiveRequestsFromKfeDashboard(
    Map<String, dynamic> dashboard,
    String accountId,
  ) {
    final wallets = dashboard['wallets'];
    if (wallets is! List) {
      throw ServerException(
        message: 'Resposta inesperada do dashboard KFE.',
        errorCode: 'ERR_BITCOIN_LISTRECEIVEREQUESTS_INVALID_RESPONSE',
        data: dashboard,
      );
    }

    for (final item in wallets) {
      final wallet = _requireMap(item, operation: 'listReceiveRequests');
      final id = (wallet['walletId'] ?? wallet['id'] ?? '').toString();
      if (id != accountId) {
        continue;
      }
      final activeAddress = wallet['activeAddress']?.toString().trim() ?? '';
      if (activeAddress.isEmpty) {
        return const <ReceivingRequestView>[];
      }
      final timestamp =
          (wallet['updatedAt'] ?? wallet['createdAt'])?.toString();
      return [
        ReceivingRequestView.fromKfeActiveAddress(
          accountId: accountId,
          address: activeAddress,
          createdAt: DateTime.tryParse(timestamp ?? ''),
        ),
      ];
    }

    return const <ReceivingRequestView>[];
  }

  static BitcoinAccount _accountFromKfeWallet(Map<String, dynamic> wallet) {
    final kind = wallet['kind']?.toString().toUpperCase() ?? 'INTERNAL';
    final isWatchOnly = kind == 'WATCH_ONLY';
    final isCustodialOnchain = kind == 'CUSTODIAL_ONCHAIN';
    final id = (wallet['walletId'] ?? wallet['id'] ?? '').toString();
    return BitcoinAccount.fromJson({
      'id': id,
      'type': isWatchOnly ? 'WATCH_ONLY_COLD_WALLET' : 'INTERNAL_CARD',
      'custody': isWatchOnly
          ? 'WATCH_ONLY'
          : isCustodialOnchain
              ? 'CUSTODIAL_ONCHAIN'
              : 'KEROSENE_CUSTODIAL',
      'status': wallet['status']?.toString() ?? 'ACTIVE',
      'label': (wallet['walletName'] ?? wallet['label'])?.toString() ?? '',
      'walletTypeDescription': wallet['walletTypeDescription']?.toString(),
      'riskTier': 'BRONZE',
      'cardId': isWatchOnly ? null : id,
      'coldWalletId': isWatchOnly ? id : null,
      'balanceAvailableSats': _intFromJson(wallet['availableSats']),
      'balancePendingSats': _intFromJson(wallet['pendingSats']),
      'balanceLockedSats': _intFromJson(wallet['lockedSats']),
      'balanceAutoHoldSats': _intFromJson(wallet['autoHoldSats']),
      'observedBalanceSats': _intFromJson(wallet['observedSats']),
      'xpubFingerprint': wallet['fingerprint']?.toString(),
      'derivationPath': wallet['derivationPath']?.toString(),
      'scriptPolicy': wallet['descriptor']?.toString(),
    });
  }

  static int _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static Map<String, dynamic> kfeCreateWalletPayload({
    required String label,
    required BitcoinAccountCustody custody,
  }) {
    return {
      'kind': custody.kfeKind,
      'label': label.trim(),
      'issueInitialAddress': false,
    };
  }

  static Map<String, dynamic> _requireMap(
    Object? data, {
    required String operation,
  }) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ServerException(
      message: 'Resposta inesperada do backend Bitcoin.',
      errorCode: 'ERR_BITCOIN_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }

  @override
  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(
    String coldWalletId,
  ) async {
    final response = await _api.get(AppConfig.kfeColdWalletUtxos(coldWalletId));
    final utxos = response.data;
    if (utxos is! List) {
      throw ServerException(
        message: 'Resposta inesperada da lista de UTXOs KFE.',
        errorCode: 'ERR_KFE_COLD_WALLET_UTXOS_INVALID_RESPONSE',
        data: response.data,
      );
    }
    return utxos
        .map((item) => _requireMap(item, operation: 'listColdWalletUtxos'))
        .map(ColdWalletUtxoView.fromJson)
        .toList();
  }

  @override
  Future<List<PsbtWorkflowView>> listColdWalletPsbt(
    String coldWalletId,
  ) async {
    final response = await _api.get(
      '${AppConfig.kfeColdWalletPsbts}?walletId=$coldWalletId',
    );
    final workflows = response.data;
    if (workflows is! List) {
      throw ServerException(
        message: 'Resposta inesperada da lista de PSBT KFE.',
        errorCode: 'ERR_KFE_COLD_WALLET_PSBT_LIST_INVALID_RESPONSE',
        data: response.data,
      );
    }
    return workflows
        .map((item) => _requireMap(item, operation: 'listColdWalletPsbt'))
        .map((item) => PsbtWorkflowView.fromJson({
              ...item,
              'coldWalletId': coldWalletId,
            }))
        .toList();
  }

  @override
  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  }) async {
    final response = await _api.post(
      AppConfig.kfeColdWalletPsbtCreate(coldWalletId),
      data: {
        'destinationAddress': destinationAddress,
        'amountSats': amountSats,
        if (feeRate != null) 'feeRateSatsPerVbyte': feeRate,
        if (selectedUtxoIds.isNotEmpty) 'inputs': _psbtInputs(selectedUtxoIds),
      },
    );
    return PsbtWorkflowView.fromJson({
      ..._requireMap(response.data, operation: 'createColdWalletPsbt'),
      'coldWalletId': coldWalletId,
    });
  }

  @override
  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId) async {
    final response = await _api.get(
      AppConfig.kfeColdWalletPsbtWorkflow(workflowId),
    );
    return PsbtWorkflowView.fromJson(
      _requireMap(response.data, operation: 'getPsbtWorkflow'),
    );
  }

  @override
  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  }) async {
    final signedResponse = await _api.post(
      AppConfig.kfeColdWalletPsbtSigned(workflowId),
      data: {'signedPsbt': signedPsbt},
    );
    if (!broadcast) {
      return PsbtWorkflowView.fromJson(
        _requireMap(signedResponse.data, operation: 'submitSignedPsbt'),
      );
    }

    final broadcastResponse = await _api.post(
      AppConfig.kfeColdWalletPsbtBroadcast(workflowId),
    );
    return PsbtWorkflowView.fromJson(
      _requireMap(broadcastResponse.data, operation: 'broadcastSignedPsbt'),
    );
  }

  @override
  Future<List<TaxEventView>> listTaxEvents() async {
    final response = await _api.get(AppConfig.kfeTaxEvents);
    final events = response.data;
    if (events is! List) {
      throw ServerException(
        message: 'Resposta inesperada dos eventos fiscais KFE.',
        errorCode: 'ERR_KFE_TAX_EVENTS_INVALID_RESPONSE',
        data: response.data,
      );
    }
    return events
        .map((item) => _requireMap(item, operation: 'listTaxEvents'))
        .map(TaxEventView.fromJson)
        .toList();
  }

  @override
  Future<TaxEventsExportView> exportTaxEvents({required String format}) async {
    final response = await _api.get(AppConfig.kfeTaxEventsExport(format));
    return TaxEventsExportView.fromJson(
      _requireMap(response.data, operation: 'exportTaxEvents'),
    );
  }

  @override
  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    final response = await _api.post(
      AppConfig.kfeTaxEventClassify(eventId),
      data: {'classification': classification},
    );
    return TaxEventView.fromJson(
      _requireMap(response.data, operation: 'classifyTaxEvent'),
    );
  }

  String? _kfeExpiresAt(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty || normalized == 'PERMANENT') return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return parsed.toUtc().toIso8601String();
    final now = DateTime.now().toUtc();
    final expiresAt = switch (normalized) {
      '15M' => now.add(const Duration(minutes: 15)),
      '1H' => now.add(const Duration(hours: 1)),
      '24H' => now.add(const Duration(hours: 24)),
      _ => null,
    };
    return expiresAt?.toIso8601String();
  }

  ReceivingRequestView _receiveRequestFromKfePaymentRequest(
    Map<String, dynamic> json, {
    String? fallbackAccountId,
    bool oneTime = true,
  }) {
    final accountId =
        (json['walletId'] ?? json['accountId'] ?? fallbackAccountId ?? '')
            .toString();
    final address = json['address']?.toString().trim() ?? '';
    final amountSats =
        json['amountSats'] == null ? null : _intFromJson(json['amountSats']);
    final amountBtc = amountSats == null
        ? null
        : (amountSats / 100000000.0).toStringAsFixed(8);
    final bip21 = amountBtc == null
        ? 'bitcoin:$address'
        : 'bitcoin:$address?amount=$amountBtc';
    final createdAt = DateTime.tryParse(
          (json['createdAt'] ?? '').toString(),
        ) ??
        DateTime.now();
    return ReceivingRequestView(
      id: (json['id'] ?? json['publicId'] ?? '').toString(),
      accountId: accountId,
      address: address,
      bip21: bip21,
      status: _receiveRequestStatus(json['status']?.toString()),
      amountSats: amountSats,
      expiry: (json['expiresAt'] ?? '').toString(),
      oneTime: oneTime,
      createdAt: createdAt,
    );
  }

  ReceivingRequestView _receiveRequestFromKfeAddress(
    Map<String, dynamic> json, {
    required String fallbackAccountId,
  }) {
    final accountId = (json['walletId'] ?? fallbackAccountId).toString();
    final address = json['address']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    return ReceivingRequestView.fromKfeActiveAddress(
      accountId: accountId,
      address: address,
      createdAt: createdAt,
    );
  }

  String _receiveRequestStatus(String? status) {
    return switch ((status ?? '').toUpperCase()) {
      'OPEN' => 'ACTIVE',
      'PAID' => 'PAID',
      'EXPIRED' => 'EXPIRED',
      'HIDDEN' => 'HIDDEN',
      'CANCELLED' => 'CANCELLED',
      _ => status ?? 'ACTIVE',
    };
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  List<Map<String, dynamic>> _psbtInputs(List<String> selectedUtxoIds) {
    return selectedUtxoIds.map((id) {
      final separator = id.lastIndexOf(':');
      if (separator <= 0 || separator == id.length - 1) {
        throw ValidationException(
          message: 'Identificador de UTXO inválido para PSBT: $id',
          statusCode: 400,
          errorCode: 'ERR_KFE_COLD_WALLET_INVALID_UTXO_ID',
        );
      }
      final vout = int.tryParse(id.substring(separator + 1));
      if (vout == null || vout < 0) {
        throw ValidationException(
          message: 'Vout inválido para PSBT: $id',
          statusCode: 400,
          errorCode: 'ERR_KFE_COLD_WALLET_INVALID_UTXO_VOUT',
        );
      }
      return {
        'txid': id.substring(0, separator),
        'vout': vout,
      };
    }).toList();
  }
}
