import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import 'bitcoin_account_models.dart';

export 'bitcoin_account_models.dart';

abstract class BitcoinAccountsService {
  Future<List<BitcoinAccount>> listAccounts();

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
  Future<BitcoinAccount> createInternalCard({
    required String label,
  }) async {
    final response = await _api.post(
      AppConfig.kfeWallets,
      data: {
        'kind': 'INTERNAL',
        'name': _walletNameEnum(label),
        'label': label,
        'issueInitialAddress': false,
      },
    );
    return _accountFromKfeWallet(
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
      AppConfig.kfeWallets,
      data: {
        'kind': 'WATCH_ONLY',
        'name': _walletNameEnum(label),
        'label': label,
        'xpub': xpub,
        'fingerprint': fingerprint,
        'derivationPath': derivationPath,
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
    final address = await _activeOrRotatedAddress(accountId);
    return _kfeReceiveRequest(
      accountId: accountId,
      address: address,
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
    );
  }

  @override
  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    if (requestId.startsWith('kfe:')) {
      final parts = requestId.split(':');
      return _kfeReceiveRequest(
        accountId: parts.length > 1 ? parts[1] : '',
        address: parts.length > 2 ? parts.sublist(2).join(':') : '',
        expiry: '',
        oneTime: true,
      );
    }
    throw const ValidationException(
      message: 'Status de recebimento legado não está disponível no KFE.',
      statusCode: 410,
      errorCode: 'ERR_KFE_RECEIVE_STATUS_UNAVAILABLE',
    );
  }

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    final dashboardResponse = await _api.get(AppConfig.kfeDashboard);
    final dashboard = _requireMap(
      dashboardResponse.data,
      operation: 'listReceiveRequestsDashboard',
    );
    return receiveRequestsFromKfeDashboard(dashboard, accountId);
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
    final id = (wallet['walletId'] ?? wallet['id'] ?? '').toString();
    return BitcoinAccount.fromJson({
      'id': id,
      'type': isWatchOnly ? 'WATCH_ONLY_COLD_WALLET' : 'INTERNAL_CARD',
      'custody': isWatchOnly ? 'WATCH_ONLY' : 'KEROSENE_CUSTODIAL',
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

  static String _walletNameEnum(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return switch (normalized) {
      'investimento' || 'investment' || 'reserva' => 'INVESTMENT',
      'veiculo' || 'vehicle' => 'VEHICLE',
      'futuros_gastos' ||
      'futuro_gastos' ||
      'gastos_futuros' ||
      'gastos_mensais' =>
        'FUTURE_EXPENSES',
      'dia_a_dia' || 'daily' => 'DAILY',
      _ => 'DAILY',
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
    return const <ColdWalletUtxoView>[];
  }

  @override
  Future<List<PsbtWorkflowView>> listColdWalletPsbt(
    String coldWalletId,
  ) async {
    return const <PsbtWorkflowView>[];
  }

  @override
  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  }) async {
    throw const ValidationException(
      message:
          'Criação de PSBT para cold wallet ainda não está disponível no KFE.',
      statusCode: 501,
      errorCode: 'ERR_KFE_COLD_WALLET_PSBT_UNAVAILABLE',
    );
  }

  @override
  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId) async {
    throw const ValidationException(
      message: 'Consulta de PSBT ainda não está disponível no KFE.',
      statusCode: 501,
      errorCode: 'ERR_KFE_COLD_WALLET_PSBT_UNAVAILABLE',
    );
  }

  @override
  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  }) async {
    throw const ValidationException(
      message: 'Envio de PSBT assinado ainda não está disponível no KFE.',
      statusCode: 501,
      errorCode: 'ERR_KFE_COLD_WALLET_PSBT_UNAVAILABLE',
    );
  }

  @override
  Future<List<TaxEventView>> listTaxEvents() async {
    return const <TaxEventView>[];
  }

  @override
  Future<TaxEventsExportView> exportTaxEvents({required String format}) async {
    return TaxEventsExportView(
      format: format,
      filename: 'kerosene-tax-events.$format',
      educationalNotice:
          'Eventos fiscais financeiros legados ainda não foram migrados para o KFE.',
    );
  }

  @override
  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    return TaxEventView(
      id: eventId,
      eventType: '',
      asset: 'BTC',
      quantitySats: 0,
      classification: classification,
      sourceRef: '',
      createdAt: '',
    );
  }

  Future<String> _activeOrRotatedAddress(String accountId) async {
    final dashboardResponse = await _api.get(AppConfig.kfeDashboard);
    final dashboard = _requireMap(
      dashboardResponse.data,
      operation: 'createReceiveRequestDashboard',
    );
    final wallets = dashboard['wallets'];
    if (wallets is List) {
      for (final item in wallets) {
        final wallet = _requireMap(item, operation: 'createReceiveRequest');
        final id = (wallet['walletId'] ?? wallet['id'] ?? '').toString();
        if (id == accountId) {
          final activeAddress = wallet['activeAddress']?.toString().trim();
          if (activeAddress != null && activeAddress.isNotEmpty) {
            return activeAddress;
          }
          break;
        }
      }
    }

    final rotateResponse = await _api.post(
      AppConfig.kfeWalletAddressRotate(accountId),
    );
    final rotated = _requireMap(
      rotateResponse.data,
      operation: 'createReceiveRequestRotate',
    );
    final address = rotated['address']?.toString().trim() ?? '';
    if (address.isEmpty) {
      throw const ServerException(
        message: 'KFE não retornou endereço de recebimento.',
        errorCode: 'ERR_KFE_RECEIVE_ADDRESS_EMPTY',
      );
    }
    return address;
  }

  ReceivingRequestView _kfeReceiveRequest({
    required String accountId,
    required String address,
    int? amountSats,
    required String expiry,
    required bool oneTime,
  }) {
    return ReceivingRequestView.fromKfeActiveAddress(
      accountId: accountId,
      address: address,
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
    );
  }
}
