class BitcoinAccount {
  final String id;
  final String type;
  final String custody;
  final String status;
  final String label;
  final String walletTypeDescription;
  final String riskTier;
  final String? cardId;
  final String? coldWalletId;
  final int balanceAvailableSats;
  final int balancePendingSats;
  final int balanceLockedSats;
  final int balanceAutoHoldSats;
  final int observedBalanceSats;
  final String? xpubFingerprint;
  final String? derivationPath;
  final String? scriptPolicy;

  const BitcoinAccount({
    required this.id,
    required this.type,
    required this.custody,
    required this.status,
    required this.label,
    this.walletTypeDescription = '',
    required this.riskTier,
    this.cardId,
    this.coldWalletId,
    this.balanceAvailableSats = 0,
    this.balancePendingSats = 0,
    this.balanceLockedSats = 0,
    this.balanceAutoHoldSats = 0,
    this.observedBalanceSats = 0,
    this.xpubFingerprint,
    this.derivationPath,
    this.scriptPolicy,
  });

  bool get isInternal =>
      type == 'INTERNAL_CARD' ||
      custody == 'KEROSENE_CUSTODIAL' ||
      custody == 'INTERNAL';

  bool get isCustodialOnchain => custody == 'CUSTODIAL_ONCHAIN';

  bool get isWatchOnly =>
      type == 'WATCH_ONLY_COLD_WALLET' || custody == 'WATCH_ONLY';

  bool get isActive => status == 'ACTIVE';

  String get custodyDisplayLabel {
    if (isWatchOnly) return 'Cold wallet';
    if (isCustodialOnchain) return 'Custodial on-chain';
    return 'Carteira global';
  }

  int get totalSats =>
      balanceAvailableSats +
      balancePendingSats +
      balanceLockedSats +
      balanceAutoHoldSats +
      observedBalanceSats;

  factory BitcoinAccount.fromJson(Map<String, dynamic> json) {
    return BitcoinAccount(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'INTERNAL_CARD',
      custody: json['custody'] as String? ?? 'KEROSENE_CUSTODIAL',
      status: json['status'] as String? ?? 'ACTIVE',
      label: json['label'] as String? ?? '',
      walletTypeDescription: json['walletTypeDescription'] as String? ?? '',
      riskTier: json['riskTier'] as String? ?? 'BRONZE',
      cardId: json['cardId'] as String?,
      coldWalletId: json['coldWalletId'] as String?,
      balanceAvailableSats: _intFromJson(json['balanceAvailableSats']),
      balancePendingSats: _intFromJson(json['balancePendingSats']),
      balanceLockedSats: _intFromJson(json['balanceLockedSats']),
      balanceAutoHoldSats: _intFromJson(json['balanceAutoHoldSats']),
      observedBalanceSats: _intFromJson(json['observedBalanceSats']),
      xpubFingerprint:
          (json['xpubFingerprint'] ?? json['fingerprint']) as String?,
      derivationPath: json['derivationPath'] as String?,
      scriptPolicy: json['scriptPolicy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'custody': custody,
        'status': status,
        'label': label,
        'walletTypeDescription': walletTypeDescription,
        'riskTier': riskTier,
        'cardId': cardId,
        'coldWalletId': coldWalletId,
        'balanceAvailableSats': balanceAvailableSats,
        'balancePendingSats': balancePendingSats,
        'balanceLockedSats': balanceLockedSats,
        'balanceAutoHoldSats': balanceAutoHoldSats,
        'observedBalanceSats': observedBalanceSats,
        'xpubFingerprint': xpubFingerprint,
        'derivationPath': derivationPath,
        'scriptPolicy': scriptPolicy,
      };

  static int _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class ReceivingRequestView {
  final String id;
  final String accountId;
  final String address;
  final String bip21;
  final String status;
  final int? amountSats;
  final String expiry;
  final bool oneTime;
  final DateTime createdAt;

  const ReceivingRequestView({
    required this.id,
    required this.accountId,
    required this.address,
    required this.bip21,
    required this.status,
    required this.amountSats,
    required this.expiry,
    required this.oneTime,
    required this.createdAt,
  });

  ReceivingRequestView copyWith({String? status}) {
    return ReceivingRequestView(
      id: id,
      accountId: accountId,
      address: address,
      bip21: bip21,
      status: status ?? this.status,
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
      createdAt: createdAt,
    );
  }

  factory ReceivingRequestView.fromJson(
    Map<String, dynamic> json, {
    String? fallbackAccountId,
  }) {
    final createdAt = (json['createdAt'] ?? json['expiresAt'])?.toString();
    return ReceivingRequestView(
      id: json['id'] as String? ?? '',
      accountId:
          (json['accountId'] ?? json['cardId'] ?? fallbackAccountId ?? '')
              .toString(),
      address: json['address'] as String? ?? '',
      bip21: json['bip21'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      amountSats: _nullableIntFromJson(json['amountSats']),
      expiry: (json['expiry'] ?? json['expiresAt'] ?? '').toString(),
      oneTime: json['oneTime'] as bool? ?? true,
      createdAt: DateTime.tryParse(createdAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory ReceivingRequestView.fromKfeActiveAddress({
    required String accountId,
    required String address,
    int? amountSats,
    String expiry = '',
    bool oneTime = false,
    DateTime? createdAt,
  }) {
    final normalizedAddress = address.trim();
    final amountBtc = amountSats == null
        ? null
        : (amountSats / 100000000.0).toStringAsFixed(8);
    final bip21 = amountBtc == null
        ? 'bitcoin:$normalizedAddress'
        : 'bitcoin:$normalizedAddress?amount=$amountBtc';
    return ReceivingRequestView(
      id: 'kfe:$accountId:$normalizedAddress',
      accountId: accountId,
      address: normalizedAddress,
      bip21: bip21,
      status: 'ACTIVE',
      amountSats: amountSats,
      expiry: expiry,
      oneTime: oneTime,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'address': address,
        'bip21': bip21,
        'status': status,
        'amountSats': amountSats,
        'expiry': expiry,
        'oneTime': oneTime,
        'createdAt': createdAt.toIso8601String(),
      };

  static int? _nullableIntFromJson(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class ColdWalletUtxoView {
  final String id;
  final String txidRef;
  final int vout;
  final int amountSats;
  final int confirmations;
  final String status;

  const ColdWalletUtxoView({
    required this.id,
    required this.txidRef,
    required this.vout,
    required this.amountSats,
    required this.confirmations,
    required this.status,
  });

  bool get isSpendable => status.toUpperCase() == 'UNSPENT';

  factory ColdWalletUtxoView.fromJson(Map<String, dynamic> json) {
    final txid = (json['txidRef'] ?? json['txid'] ?? '').toString();
    final vout = _intFromJson(json['vout']);
    return ColdWalletUtxoView(
      id: (json['id'] ?? '$txid:$vout').toString(),
      txidRef: txid,
      vout: vout,
      amountSats: _intFromJson(json['amountSats'] ?? json['valueSats']),
      confirmations: _intFromJson(json['confirmations']),
      status: (json['status'] ?? 'UNSPENT').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'txidRef': txidRef,
        'vout': vout,
        'amountSats': amountSats,
        'confirmations': confirmations,
        'status': status,
      };
}

class PsbtWorkflowView {
  final String id;
  final String coldWalletId;
  final String unsignedPsbt;
  final String status;
  final String destinationAddress;
  final int amountSats;
  final int estimatedFeeSats;
  final String? broadcastTxid;
  final String? broadcastTxidRef;
  final String expiresAt;
  final String createdAt;

  const PsbtWorkflowView({
    required this.id,
    required this.coldWalletId,
    required this.unsignedPsbt,
    required this.status,
    required this.destinationAddress,
    required this.amountSats,
    required this.estimatedFeeSats,
    this.broadcastTxid,
    this.broadcastTxidRef,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get awaitsSignature {
    final normalized = status.toUpperCase();
    return normalized == 'CREATED' ||
        normalized == 'WAITING_EXTERNAL_SIGNATURE' ||
        normalized == 'UNSIGNED_CREATED' ||
        normalized == 'DRAFT';
  }

  factory PsbtWorkflowView.fromJson(Map<String, dynamic> json) {
    return PsbtWorkflowView(
      id: (json['workflowId'] ?? json['id'] ?? json['psbtHash'] ?? '').toString(),
      coldWalletId: (json['coldWalletId'] ?? json['walletId'] ?? '').toString(),
      unsignedPsbt: (json['unsignedPsbt'] ?? json['psbt'] ?? '').toString(),
      status: (json['status'] ?? 'WAITING_EXTERNAL_SIGNATURE').toString(),
      destinationAddress: (json['destinationAddress'] ?? '').toString(),
      amountSats: _intFromJson(json['amountSats']),
      estimatedFeeSats: _intFromJson(
        json['estimatedFeeSats'] ?? json['feeSats'],
      ),
      broadcastTxid: json['broadcastTxid']?.toString(),
      broadcastTxidRef: json['broadcastTxidRef']?.toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coldWalletId': coldWalletId,
        'unsignedPsbt': unsignedPsbt,
        'status': status,
        'destinationAddress': destinationAddress,
        'amountSats': amountSats,
        'estimatedFeeSats': estimatedFeeSats,
        'broadcastTxid': broadcastTxid,
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
  final String sourceRef;
  final String createdAt;
  final String? accountId;
  final String? cardId;
  final String? walletId;
  final String? purgeAfter;

  const TaxEventView({
    required this.id,
    required this.eventType,
    required this.asset,
    required this.quantitySats,
    required this.classification,
    required this.sourceRef,
    required this.createdAt,
    this.accountId,
    this.cardId,
    this.walletId,
    this.purgeAfter,
  });

  factory TaxEventView.fromJson(Map<String, dynamic> json) {
    return TaxEventView(
      id: (json['id'] ?? '').toString(),
      eventType: (json['eventType'] ?? '').toString(),
      asset: (json['asset'] ?? 'BTC').toString(),
      quantitySats: _intFromJson(json['quantitySats']),
      classification: (json['classification'] ?? '').toString(),
      sourceRef: (json['sourceRef'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      accountId: json['accountId']?.toString(),
      cardId: json['cardId']?.toString(),
      walletId: json['walletId']?.toString(),
      purgeAfter: json['purgeAfter']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventType': eventType,
        'asset': asset,
        'quantitySats': quantitySats,
        'classification': classification,
        'sourceRef': sourceRef,
        'createdAt': createdAt,
        'accountId': accountId,
        'cardId': cardId,
        'walletId': walletId,
        'purgeAfter': purgeAfter,
      };
}

class TaxEventsExportView {
  final String format;
  final String filename;
  final String educationalNotice;
  final String? content;
  final List<TaxEventView> events;

  const TaxEventsExportView({
    required this.format,
    required this.filename,
    required this.educationalNotice,
    this.content,
    this.events = const [],
  });

  factory TaxEventsExportView.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    return TaxEventsExportView(
      format: (json['format'] ?? 'json').toString(),
      filename: (json['filename'] ?? 'kerosene-tax-events.json').toString(),
      educationalNotice: (json['educationalNotice'] ?? '').toString(),
      content: json['content']?.toString(),
      events: rawEvents is List
          ? rawEvents
              .whereType<Map>()
              .map((item) => TaxEventView.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'filename': filename,
        'educationalNotice': educationalNotice,
        'content': content,
        'events': events.map((event) => event.toJson()).toList(),
      };
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
