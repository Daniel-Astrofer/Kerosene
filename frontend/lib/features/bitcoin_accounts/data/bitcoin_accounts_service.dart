import 'package:teste/core/config/app_config.dart';
import 'package:teste/core/errors/exceptions.dart';
import 'package:teste/core/network/api_client.dart';

class BitcoinAccount {
  final String id;
  final String type;
  final String custody;
  final String status;
  final String label;
  final String riskTier;
  final String? cardId;
  final String? coldWalletId;
  final int balanceAvailableSats;
  final int balancePendingSats;
  final int balanceLockedSats;
  final int balanceAutoHoldSats;
  final int observedBalanceSats;
  final bool canSign;

  const BitcoinAccount({
    required this.id,
    required this.type,
    required this.custody,
    required this.status,
    required this.label,
    required this.riskTier,
    this.cardId,
    this.coldWalletId,
    this.balanceAvailableSats = 0,
    this.balancePendingSats = 0,
    this.balanceLockedSats = 0,
    this.balanceAutoHoldSats = 0,
    this.observedBalanceSats = 0,
    this.canSign = false,
  });

  bool get isInternal => type == 'INTERNAL_CARD';
  bool get isWatchOnly => type == 'WATCH_ONLY_COLD_WALLET';

  factory BitcoinAccount.fromJson(Map<String, dynamic> json) {
    return BitcoinAccount(
      id: _string(json['id']),
      type: _string(json['type']),
      custody: _string(json['custody']),
      status: _string(json['status']),
      label: _string(json['label']),
      riskTier: _string(json['riskTier']),
      cardId: _nullableString(json['cardId']),
      coldWalletId: _nullableString(json['coldWalletId']),
      balanceAvailableSats: _int(json['balanceAvailableSats']),
      balancePendingSats: _int(json['balancePendingSats']),
      balanceLockedSats: _int(json['balanceLockedSats']),
      balanceAutoHoldSats: _int(json['balanceAutoHoldSats']),
      observedBalanceSats: _int(json['observedBalanceSats']),
      canSign: json['canSign'] == true,
    );
  }
}

class ReceivingRequestView {
  final String id;
  final String publicCode;
  final String address;
  final String bip21;
  final String status;
  final int? amountSats;
  final String? expiresAt;
  final String nextAction;

  const ReceivingRequestView({
    required this.id,
    required this.publicCode,
    required this.address,
    required this.bip21,
    required this.status,
    required this.nextAction,
    this.amountSats,
    this.expiresAt,
  });

  factory ReceivingRequestView.fromJson(Map<String, dynamic> json) {
    return ReceivingRequestView(
      id: _string(json['id']),
      publicCode: _string(json['publicCode']),
      address: _string(json['address']),
      bip21: _string(json['bip21']),
      status: _string(json['status']),
      nextAction: _string(json['nextAction']),
      amountSats: json['amountSats'] == null ? null : _int(json['amountSats']),
      expiresAt: _nullableString(json['expiresAt']),
    );
  }
}

class ColdWalletUtxo {
  final String id;
  final String txidRef;
  final int vout;
  final int amountSats;
  final int confirmations;
  final String status;

  const ColdWalletUtxo({
    required this.id,
    required this.txidRef,
    required this.vout,
    required this.amountSats,
    required this.confirmations,
    required this.status,
  });

  bool get isSpendable => status == 'UNSPENT';

  factory ColdWalletUtxo.fromJson(Map<String, dynamic> json) {
    return ColdWalletUtxo(
      id: _string(json['id']),
      txidRef: _string(json['txidRef']),
      vout: _int(json['vout']),
      amountSats: _int(json['amountSats']),
      confirmations: _int(json['confirmations']),
      status: _string(json['status']),
    );
  }
}

class PsbtWorkflowView {
  final String id;
  final String coldWalletId;
  final String unsignedPsbt;
  final String status;
  final String destinationAddress;
  final int amountSats;
  final int estimatedFeeSats;
  final String? broadcastTxidRef;
  final String? expiresAt;
  final String? createdAt;

  const PsbtWorkflowView({
    required this.id,
    required this.coldWalletId,
    required this.unsignedPsbt,
    required this.status,
    required this.destinationAddress,
    required this.amountSats,
    required this.estimatedFeeSats,
    this.broadcastTxidRef,
    this.expiresAt,
    this.createdAt,
  });

  factory PsbtWorkflowView.fromJson(Map<String, dynamic> json) {
    return PsbtWorkflowView(
      id: _string(json['id']),
      coldWalletId: _string(json['coldWalletId']),
      unsignedPsbt: _string(json['unsignedPsbt']),
      status: _string(json['status']),
      destinationAddress: _string(json['destinationAddress']),
      amountSats: _int(json['amountSats']),
      estimatedFeeSats: _int(json['estimatedFeeSats']),
      broadcastTxidRef: _nullableString(json['broadcastTxidRef']),
      expiresAt: _nullableString(json['expiresAt']),
      createdAt: _nullableString(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coldWalletId': coldWalletId,
        'status': status,
        'destinationAddress': destinationAddress,
        'amountSats': amountSats,
        'estimatedFeeSats': estimatedFeeSats,
        'broadcastTxidRef': broadcastTxidRef,
        'expiresAt': expiresAt,
        'createdAt': createdAt,
      };
}

class TaxEventView {
  final String id;
  final String eventType;
  final String asset;
  final int quantitySats;
  final String classification;
  final String? sourceRef;
  final String? accountId;
  final String? cardId;
  final String? walletId;
  final String? createdAt;
  final String? purgeAfter;

  const TaxEventView({
    required this.id,
    required this.eventType,
    required this.asset,
    required this.quantitySats,
    required this.classification,
    this.sourceRef,
    this.accountId,
    this.cardId,
    this.walletId,
    this.createdAt,
    this.purgeAfter,
  });

  factory TaxEventView.fromJson(Map<String, dynamic> json) {
    return TaxEventView(
      id: _string(json['id']),
      eventType: _string(json['eventType']),
      asset: _string(json['asset']),
      quantitySats: _int(json['quantitySats']),
      classification: _string(json['classification']),
      sourceRef: _nullableString(json['sourceRef']),
      accountId: _nullableString(json['accountId']),
      cardId: _nullableString(json['cardId']),
      walletId: _nullableString(json['walletId']),
      createdAt: _nullableString(json['createdAt']),
      purgeAfter: _nullableString(json['purgeAfter']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventType': eventType,
        'asset': asset,
        'quantitySats': quantitySats,
        'classification': classification,
        'sourceRef': sourceRef,
        'accountId': accountId,
        'cardId': cardId,
        'walletId': walletId,
        'createdAt': createdAt,
        'purgeAfter': purgeAfter,
      };
}

class TaxExportView {
  final String format;
  final String filename;
  final String educationalNotice;
  final String? content;
  final List<TaxEventView> events;

  const TaxExportView({
    required this.format,
    required this.filename,
    required this.educationalNotice,
    this.content,
    this.events = const [],
  });

  factory TaxExportView.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    return TaxExportView(
      format: _string(json['format']),
      filename: _string(json['filename']),
      educationalNotice: _string(json['educationalNotice']),
      content: _nullableString(json['content']),
      events: rawEvents is List
          ? rawEvents
              .whereType<Map<String, dynamic>>()
              .map(TaxEventView.fromJson)
              .toList()
          : const [],
    );
  }
}

class BitcoinAccountsService {
  final ApiClient _api;

  BitcoinAccountsService(this._api);

  Future<List<BitcoinAccount>> listAccounts() async {
    try {
      final response = await _api.get(AppConfig.bitcoinAccounts);
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(BitcoinAccount.fromJson)
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
          message: 'Nao conseguimos carregar suas contas Bitcoin agora.');
    }
  }

  Future<BitcoinAccount> createInternalCard({required String label}) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountsInternalCard,
      data: {'label': label, 'riskTier': 'BRONZE'},
    );
    return BitcoinAccount.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<BitcoinAccount> importColdWallet({
    required String label,
    String? descriptor,
    String? xpub,
    required String fingerprint,
    required String derivationPath,
    required String scriptPolicy,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinAccountsColdWallet,
      data: {
        'label': label,
        if (descriptor != null && descriptor.trim().isNotEmpty)
          'descriptor': descriptor.trim(),
        if (xpub != null && xpub.trim().isNotEmpty) 'xpub': xpub.trim(),
        'fingerprint': fingerprint.trim(),
        'derivationPath': derivationPath.trim(),
        'scriptPolicy': scriptPolicy,
      },
    );
    return BitcoinAccount.fromJson(Map<String, dynamic>.from(response.data));
  }

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
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<ReceivingRequestView> getReceiveStatus(String requestId) async {
    final response = await _api.get(
      AppConfig.bitcoinReceiveRequestStatus(requestId),
    );
    return ReceivingRequestView.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<ReceivingRequestView> sendReceiveAction({
    required String requestId,
    required String action,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinReceiveRequestUserAction(requestId),
      data: {'action': action},
    );
    return ReceivingRequestView.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<ColdWalletUtxo>> listColdWalletUtxos(String coldWalletId) async {
    final response =
        await _api.get(AppConfig.bitcoinColdWalletUtxos(coldWalletId));
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ColdWalletUtxo.fromJson)
        .toList();
  }

  Future<List<PsbtWorkflowView>> listPsbtWorkflows(String coldWalletId) async {
    final response =
        await _api.get(AppConfig.bitcoinColdWalletPsbt(coldWalletId));
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PsbtWorkflowView.fromJson)
        .toList();
  }

  Future<PsbtWorkflowView> createPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    required int feeRate,
    required List<String> selectedUtxoIds,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinColdWalletPsbt(coldWalletId),
      data: {
        'destinationAddress': destinationAddress.trim(),
        'amountSats': amountSats,
        'feeRate': feeRate,
        'selectedUtxoIds': selectedUtxoIds,
      },
    );
    return PsbtWorkflowView.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  }) async {
    final response = await _api.post(
      AppConfig.bitcoinPsbtSigned(workflowId),
      data: {'signedPsbt': signedPsbt.trim(), 'broadcast': broadcast},
    );
    return PsbtWorkflowView.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<TaxEventView>> listTaxEvents() async {
    final response = await _api.get(AppConfig.bitcoinTaxEvents);
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaxEventView.fromJson)
        .toList();
  }

  Future<TaxExportView> exportTaxEvents(String format) async {
    final response = await _api.get(AppConfig.bitcoinTaxEventsExport(format));
    return TaxExportView.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    await _api.post(
      AppConfig.bitcoinTaxEventClassify(eventId),
      data: {'classification': classification},
    );
  }
}

String _string(dynamic value) => value?.toString() ?? '';
String? _nullableString(dynamic value) => value?.toString();
int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
