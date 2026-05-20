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
  final int dailyLimitSats;
  final String? xpubFingerprint;
  final String? derivationPath;
  final String? scriptPolicy;

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
    this.dailyLimitSats = 0,
    this.xpubFingerprint,
    this.derivationPath,
    this.scriptPolicy,
  });

  bool get isInternal =>
      type == 'INTERNAL_CARD' || custody.contains('KEROSENE');

  bool get isWatchOnly =>
      type == 'WATCH_ONLY_COLD_WALLET' || custody == 'WATCH_ONLY';

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
      riskTier: json['riskTier'] as String? ?? 'BRONZE',
      cardId: json['cardId'] as String?,
      coldWalletId: json['coldWalletId'] as String?,
      balanceAvailableSats: _intFromJson(json['balanceAvailableSats']),
      balancePendingSats: _intFromJson(json['balancePendingSats']),
      balanceLockedSats: _intFromJson(json['balanceLockedSats']),
      balanceAutoHoldSats: _intFromJson(json['balanceAutoHoldSats']),
      observedBalanceSats: _intFromJson(json['observedBalanceSats']),
      dailyLimitSats: _intFromJson(json['dailyLimitSats']),
      xpubFingerprint: json['xpubFingerprint'] as String?,
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
        'riskTier': riskTier,
        'cardId': cardId,
        'coldWalletId': coldWalletId,
        'balanceAvailableSats': balanceAvailableSats,
        'balancePendingSats': balancePendingSats,
        'balanceLockedSats': balanceLockedSats,
        'balanceAutoHoldSats': balanceAutoHoldSats,
        'observedBalanceSats': observedBalanceSats,
        'dailyLimitSats': dailyLimitSats,
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

  factory ReceivingRequestView.fromJson(Map<String, dynamic> json) {
    return ReceivingRequestView(
      id: json['id'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      bip21: json['bip21'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      amountSats: json['amountSats'] as int?,
      expiry: json['expiry'] as String? ?? '1H',
      oneTime: json['oneTime'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
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
}

class TaxEventView {
  final String id;
  final String eventType;
  final String asset;
  final int quantitySats;
  final String classification;
  final String sourceRef;
  final String createdAt;

  const TaxEventView({
    required this.id,
    required this.eventType,
    required this.asset,
    required this.quantitySats,
    required this.classification,
    required this.sourceRef,
    required this.createdAt,
  });

  factory TaxEventView.fromJson(Map<String, dynamic> json) {
    return TaxEventView(
      id: json['id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      asset: json['asset'] as String? ?? 'BTC',
      quantitySats: json['quantitySats'] as int? ?? 0,
      classification: json['classification'] as String? ?? '',
      sourceRef: json['sourceRef'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
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
      };
}
