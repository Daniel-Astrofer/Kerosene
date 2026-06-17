enum PaymentRail {
  internal('INTERNAL', 'Kerosene'),
  lightning('LIGHTNING', 'Lightning'),
  onchain('ONCHAIN', 'On-chain');

  final String apiValue;
  final String label;

  const PaymentRail(this.apiValue, this.label);
}

enum PaymentFeeMode {
  senderPays('SENDER_PAYS', 'Sender pays'),
  recipientPays('RECIPIENT_PAYS', 'Recipient pays');

  final String apiValue;
  final String label;

  const PaymentFeeMode(this.apiValue, this.label);
}

enum PaymentIntentStatus {
  created('CREATED'),
  quoted('QUOTED'),
  confirmed('CONFIRMED'),
  processing('PROCESSING'),
  acceptedByProvider('ACCEPTED_BY_PROVIDER'),
  requiresReconciliation('REQUIRES_RECONCILIATION'),
  settled('SETTLED'),
  failed('FAILED'),
  canceled('CANCELED'),
  expired('EXPIRED');

  final String apiValue;

  const PaymentIntentStatus(this.apiValue);

  bool get isTerminal {
    return switch (this) {
      PaymentIntentStatus.settled ||
      PaymentIntentStatus.failed ||
      PaymentIntentStatus.canceled ||
      PaymentIntentStatus.expired =>
        true,
      _ => false,
    };
  }
}

enum OnchainSpeed {
  economy('ECONOMY', 'Economy'),
  normal('NORMAL', 'Normal'),
  fast('FAST', 'Fast');

  final String apiValue;
  final String label;

  const OnchainSpeed(this.apiValue, this.label);
}

class PaymentQuoteDraft {
  final PaymentRail rail;
  final PaymentFeeMode feeMode;
  final String amountFiat;
  final String fiatCurrency;
  final String asset;
  final String? receiverIdentifier;
  final String? externalDestination;
  final OnchainSpeed? speed;

  const PaymentQuoteDraft({
    required this.rail,
    required this.feeMode,
    required this.amountFiat,
    this.fiatCurrency = 'BRL',
    this.asset = 'BTC',
    this.receiverIdentifier,
    this.externalDestination,
    this.speed,
  });

  Map<String, dynamic> toJson() {
    return {
      'rail': rail.apiValue,
      'feeMode': feeMode.apiValue,
      'amountFiat': amountFiat,
      'fiatCurrency': fiatCurrency,
      'asset': asset,
      if (receiverIdentifier?.trim().isNotEmpty == true)
        'receiverIdentifier': receiverIdentifier!.trim(),
      if (externalDestination?.trim().isNotEmpty == true)
        'externalDestination': externalDestination!.trim(),
      if (speed != null) 'speed': speed!.apiValue,
    };
  }
}

class ReceivingCapabilities {
  final bool canReceiveInternal;
  final bool canReceiveLightning;
  final bool canReceiveOnchain;
  final PaymentRail preferredRail;
  final List<String> missingRequirements;
  final String receiverDisplayName;
  final String? internalWalletId;
  final List<PaymentRail> availableRails;
  final PaymentLimits limits;

  const ReceivingCapabilities({
    required this.canReceiveInternal,
    required this.canReceiveLightning,
    required this.canReceiveOnchain,
    required this.preferredRail,
    required this.missingRequirements,
    required this.receiverDisplayName,
    this.internalWalletId,
    required this.availableRails,
    required this.limits,
  });

  factory ReceivingCapabilities.fromJson(Map<String, dynamic> json) {
    final limitsJson = _mapFrom(json['limits']);
    return ReceivingCapabilities(
      canReceiveInternal: json['canReceiveInternal'] == true,
      canReceiveLightning: json['canReceiveLightning'] == true,
      canReceiveOnchain: json['canReceiveOnchain'] == true,
      preferredRail: _railFromApi(json['preferredRail']),
      missingRequirements: _stringList(json['missingRequirements']),
      receiverDisplayName:
          json['receiverDisplayName']?.toString().trim() ?? 'Kerosene user',
      internalWalletId: json['internalWalletId']?.toString().trim(),
      availableRails: _stringList(json['availableRails'])
          .map(_railFromApi)
          .toList(growable: false),
      limits: PaymentLimits.fromJson(limitsJson),
    );
  }
}

class PaymentLimits {
  final String asset;
  final List<String> fiatCurrencies;
  final int minInternalSats;
  final int minLightningSats;
  final int minOnchainSats;

  const PaymentLimits({
    required this.asset,
    required this.fiatCurrencies,
    required this.minInternalSats,
    required this.minLightningSats,
    required this.minOnchainSats,
  });

  factory PaymentLimits.fromJson(Map<String, dynamic> json) {
    return PaymentLimits(
      asset: json['asset']?.toString() ?? 'BTC',
      fiatCurrencies: _stringList(json['fiatCurrencies']),
      minInternalSats: _intFrom(json['minInternalSats']),
      minLightningSats: _intFrom(json['minLightningSats']),
      minOnchainSats: _intFrom(json['minOnchainSats']),
    );
  }
}

class PaymentQuote {
  final String paymentIntentId;
  final DateTime? quoteExpiresAt;
  final PaymentRail rail;
  final PaymentFeeMode feeMode;
  final String receiverDisplayName;
  final String receiverAmountFiat;
  final int receiverAmountSats;
  final String totalDebitFiat;
  final int totalDebitSats;
  final String networkFeeFiat;
  final int networkFeeSats;
  final String keroseneFeeFiat;
  final int keroseneFeeSats;
  final List<String> warnings;
  final bool requiresConfirmation;

  const PaymentQuote({
    required this.paymentIntentId,
    required this.quoteExpiresAt,
    required this.rail,
    required this.feeMode,
    required this.receiverDisplayName,
    required this.receiverAmountFiat,
    required this.receiverAmountSats,
    required this.totalDebitFiat,
    required this.totalDebitSats,
    required this.networkFeeFiat,
    required this.networkFeeSats,
    required this.keroseneFeeFiat,
    required this.keroseneFeeSats,
    required this.warnings,
    required this.requiresConfirmation,
  });

  factory PaymentQuote.fromJson(Map<String, dynamic> json) {
    return PaymentQuote(
      paymentIntentId: json['paymentIntentId']?.toString() ?? '',
      quoteExpiresAt: DateTime.tryParse(
        json['quoteExpiresAt']?.toString() ?? '',
      ),
      rail: _railFromApi(json['rail']),
      feeMode: _feeModeFromApi(json['feeMode']),
      receiverDisplayName:
          json['receiverDisplayName']?.toString() ?? 'Recipient',
      receiverAmountFiat: json['receiverAmountFiat']?.toString() ?? '',
      receiverAmountSats: _intFrom(json['receiverAmountSats']),
      totalDebitFiat: json['totalDebitFiat']?.toString() ?? '',
      totalDebitSats: _intFrom(json['totalDebitSats']),
      networkFeeFiat: json['networkFeeFiat']?.toString() ?? '',
      networkFeeSats: _intFrom(json['networkFeeSats']),
      keroseneFeeFiat: json['keroseneFeeFiat']?.toString() ?? '',
      keroseneFeeSats: _intFrom(json['keroseneFeeSats']),
      warnings: _stringList(json['warnings']),
      requiresConfirmation: json['requiresConfirmation'] == true,
    );
  }
}

class PaymentStatus {
  final String paymentIntentId;
  final PaymentIntentStatus status;
  final PaymentRail rail;
  final PaymentFeeMode feeMode;
  final String receiverDisplayName;
  final int receiverAmountSats;
  final int totalDebitSats;
  final int networkFeeSats;
  final int keroseneFeeSats;
  final DateTime? quoteExpiresAt;
  final String? failureCode;
  final String? failureMessage;
  final List<String> warnings;

  const PaymentStatus({
    required this.paymentIntentId,
    required this.status,
    required this.rail,
    required this.feeMode,
    required this.receiverDisplayName,
    required this.receiverAmountSats,
    required this.totalDebitSats,
    required this.networkFeeSats,
    required this.keroseneFeeSats,
    required this.quoteExpiresAt,
    required this.failureCode,
    required this.failureMessage,
    required this.warnings,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      paymentIntentId: json['paymentIntentId']?.toString() ?? '',
      status: _statusFromApi(json['status']),
      rail: _railFromApi(json['rail']),
      feeMode: _feeModeFromApi(json['feeMode']),
      receiverDisplayName:
          json['receiverDisplayName']?.toString() ?? 'Recipient',
      receiverAmountSats: _intFrom(json['receiverAmountSats']),
      totalDebitSats: _intFrom(json['totalDebitSats']),
      networkFeeSats: _intFrom(json['networkFeeSats']),
      keroseneFeeSats: _intFrom(json['keroseneFeeSats']),
      quoteExpiresAt: DateTime.tryParse(
        json['quoteExpiresAt']?.toString() ?? '',
      ),
      failureCode: json['failureCode']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      warnings: _stringList(json['warnings']),
    );
  }
}

PaymentRail _railFromApi(Object? value) {
  final normalized = value?.toString().toUpperCase() ?? '';
  return PaymentRail.values.firstWhere(
    (rail) => rail.apiValue == normalized,
    orElse: () => PaymentRail.internal,
  );
}

PaymentFeeMode _feeModeFromApi(Object? value) {
  final normalized = value?.toString().toUpperCase() ?? '';
  return PaymentFeeMode.values.firstWhere(
    (mode) => mode.apiValue == normalized,
    orElse: () => PaymentFeeMode.senderPays,
  );
}

PaymentIntentStatus _statusFromApi(Object? value) {
  final normalized = value?.toString().toUpperCase() ?? '';
  return PaymentIntentStatus.values.firstWhere(
    (status) => status.apiValue == normalized,
    orElse: () => PaymentIntentStatus.created,
  );
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}

int _intFrom(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
