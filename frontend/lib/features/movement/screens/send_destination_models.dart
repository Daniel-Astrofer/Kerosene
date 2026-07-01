import 'package:kerosene/core/utils/bitcoin_network.dart';

enum SendDestinationType {
  empty,
  internal,
  paymentLink,
  onChain,
  lightning,
  invalid,
}

class SendDestinationAnalysis {
  final SendDestinationType type;
  final String normalizedValue;
  final String? paymentLinkId;
  final double? amountBtc;
  final String? label;
  final String? message;
  final BitcoinNetworkKind detectedOnchainNetwork;

  const SendDestinationAnalysis({
    required this.type,
    required this.normalizedValue,
    this.paymentLinkId,
    this.amountBtc,
    this.label,
    this.message,
    this.detectedOnchainNetwork = BitcoinNetworkKind.unknown,
  });

  bool get isEmpty => type == SendDestinationType.empty;
  bool get isValid => type != SendDestinationType.empty && !isInvalid;
  bool get isInvalid => type == SendDestinationType.invalid;
  bool get isInternal => type == SendDestinationType.internal;
  bool get isPaymentLink => type == SendDestinationType.paymentLink;
  bool get isOnChain => type == SendDestinationType.onChain;
  bool get isLightning => type == SendDestinationType.lightning;
  bool get isExternal => isOnChain || isLightning;
  bool get hasLockedAmount => amountBtc != null && amountBtc! > 0;
}

class SendFeeQuote {
  final double requestedAmountBtc;
  final double receiverAmountBtc;
  final double platformFeeRate;
  final double platformFeeBtc;
  final double networkFeeBtc;
  final double totalDebitedBtc;
  final double? feeRateSatPerByte;
  final bool isLoading;
  final Object? error;

  const SendFeeQuote({
    required this.requestedAmountBtc,
    required this.receiverAmountBtc,
    required this.platformFeeRate,
    required this.platformFeeBtc,
    required this.networkFeeBtc,
    required this.totalDebitedBtc,
    this.feeRateSatPerByte,
    this.isLoading = false,
    this.error,
  });

  bool get hasAmount => requestedAmountBtc > 0;
  bool get isReady => hasAmount && !isLoading && error == null;
  double get totalFeesBtc => platformFeeBtc + networkFeeBtc;
}
