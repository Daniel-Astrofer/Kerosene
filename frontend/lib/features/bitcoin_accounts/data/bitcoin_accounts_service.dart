import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import 'bitcoin_account_models.dart';

export 'bitcoin_account_models.dart';

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
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
    final response = await _api.get(AppConfig.bitcoinAccounts);
    return _requireList(
      response.data,
      operation: 'listAccounts',
    ).map(BitcoinAccount.fromJson).toList();
  }

  @override
  Future<BitcoinAccount> createInternalCard({
    required String label,
    required int dailyLimitSats,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountsInternalCard,
      data: {
        'label': label,
        'riskTier': _riskTierForDailyLimit(dailyLimitSats),
      },
    );
    return BitcoinAccount.fromJson(
      _requireMap(response.data, operation: 'createInternalCard'),
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
    final response = await _api.post(
      AppConfig.bitcoinAccountsColdWallet,
      data: {
        'label': label,
        'xpub': xpub,
        'fingerprint': fingerprint,
        'derivationPath': derivationPath,
        'scriptPolicy': scriptPolicy,
      },
    );
    return BitcoinAccount.fromJson(
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
      AppConfig.bitcoinAccountReceiveRequests(accountId),
      data: {
        if (amountSats != null) 'amountSats': amountSats,
        'expiry': expiry,
        'oneTime': oneTime,
      },
    );
    return ReceivingRequestView.fromJson(
      _requireMap(response.data, operation: 'createReceiveRequest'),
      fallbackAccountId: accountId,
    );
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    final response = await _api.get(
      AppConfig.bitcoinReceiveRequestStatus(requestId),
    );
    return ReceivingRequestView.fromJson(
      _requireMap(response.data, operation: 'getReceiveStatus'),
    );
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    try {
      final response = await _api.get(
        AppConfig.bitcoinAccountReceiveRequests(accountId),
      );
      return _receiveRequestList(response.data, accountId);
    } on ValidationException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        return const <ReceivingRequestView>[];
      }
      rethrow;
    }
  }

  static String _riskTierForDailyLimit(int dailyLimitSats) {
    if (dailyLimitSats >= 50000000) return 'GOLD';
    if (dailyLimitSats >= 10000000) return 'SILVER';
    return 'BRONZE';
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

  static List<Map<String, dynamic>> _requireList(
    Object? data, {
    required String operation,
  }) {
    if (data is List) {
      return data
          .map((item) => _requireMap(item, operation: operation))
          .toList();
    }
    throw ServerException(
      message: 'Resposta inesperada do backend Bitcoin.',
      errorCode: 'ERR_BITCOIN_${operation.toUpperCase()}_INVALID_RESPONSE',
      data: data,
    );
  }

  static List<ReceivingRequestView> _receiveRequestList(
    Object? data,
    String accountId,
  ) {
    Object? source = data;
    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      source = map['requests'] ?? map['items'] ?? map['content'] ?? map['data'];
    }
    if (source is! List) {
      throw ServerException(
        message: 'Resposta inesperada do backend Bitcoin.',
        errorCode: 'ERR_BITCOIN_LISTRECEIVEREQUESTS_INVALID_RESPONSE',
        data: data,
      );
    }

    return source
        .map((item) => _requireMap(item, operation: 'listReceiveRequests'))
        .map(
          (item) => ReceivingRequestView.fromJson(
            item,
            fallbackAccountId: accountId,
          ),
        )
        .toList();
  }

  @override
  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(
    String coldWalletId,
  ) async {
    final response = await _api.get(AppConfig.bitcoinColdWalletUtxos(
      coldWalletId,
    ));
    return _requireList(
      response.data,
      operation: 'listColdWalletUtxos',
    ).map(ColdWalletUtxoView.fromJson).toList();
  }

  @override
  Future<List<PsbtWorkflowView>> listColdWalletPsbt(
    String coldWalletId,
  ) async {
    final response = await _api.get(AppConfig.bitcoinColdWalletPsbt(
      coldWalletId,
    ));
    return _requireList(
      response.data,
      operation: 'listColdWalletPsbt',
    ).map(PsbtWorkflowView.fromJson).toList();
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
      AppConfig.bitcoinColdWalletPsbt(coldWalletId),
      data: {
        'destinationAddress': destinationAddress,
        'amountSats': amountSats,
        if (feeRate != null) 'feeRate': feeRate,
        if (selectedUtxoIds.isNotEmpty) 'selectedUtxoIds': selectedUtxoIds,
      },
    );
    return PsbtWorkflowView.fromJson(
      _requireMap(response.data, operation: 'createColdWalletPsbt'),
    );
  }

  @override
  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId) async {
    final response = await _api.get(AppConfig.bitcoinPsbt(workflowId));
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
    final response = await _api.post(
      AppConfig.bitcoinPsbtSigned(workflowId),
      data: {
        'signedPsbt': signedPsbt,
        'broadcast': broadcast,
      },
    );
    return PsbtWorkflowView.fromJson(
      _requireMap(response.data, operation: 'submitSignedPsbt'),
    );
  }

  @override
  Future<List<TaxEventView>> listTaxEvents() async {
    final response = await _api.get(AppConfig.bitcoinTaxEvents);
    return _requireList(
      response.data,
      operation: 'listTaxEvents',
    ).map(TaxEventView.fromJson).toList();
  }

  @override
  Future<TaxEventsExportView> exportTaxEvents({required String format}) async {
    final response = await _api.get(AppConfig.bitcoinTaxEventsExport(format));
    return TaxEventsExportView.fromJson(
      _requireMap(response.data, operation: 'exportTaxEvents'),
    );
  }

  @override
  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    await _api.post(
      AppConfig.bitcoinTaxEventClassify(eventId),
      data: {'classification': classification},
    );

    final events = await listTaxEvents();
    return events.firstWhere(
      (event) => event.id == eventId,
      orElse: () => TaxEventView(
        id: eventId,
        eventType: '',
        asset: 'BTC',
        quantitySats: 0,
        classification: classification,
        sourceRef: '',
        createdAt: '',
      ),
    );
  }
}
