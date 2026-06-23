import 'package:kerosene/core/utils/bitcoin_network.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';

SendDestinationAnalysis currentSendDestinationAnalysis({
  required String? pendingPaymentLinkId,
  required String lockedRecipientAddress,
  required double lockedAmountBtc,
  required String? lockedRecipientLabel,
  required String input,
}) {
  if (pendingPaymentLinkId != null) {
    return SendDestinationAnalysis(
      type: SendDestinationType.paymentLink,
      normalizedValue: lockedRecipientAddress.isNotEmpty
          ? lockedRecipientAddress
          : pendingPaymentLinkId,
      paymentLinkId: pendingPaymentLinkId,
      amountBtc: lockedAmountBtc > 0 ? lockedAmountBtc : null,
      label: lockedRecipientLabel,
    );
  }

  final locked = lockedRecipientAddress.trim();
  if (locked.isNotEmpty) {
    final lockedAnalysis = analyzeSendDestination(locked);
    return SendDestinationAnalysis(
      type: lockedAnalysis.type,
      normalizedValue: lockedAnalysis.normalizedValue,
      paymentLinkId: lockedAnalysis.paymentLinkId,
      amountBtc:
          lockedAmountBtc > 0 ? lockedAmountBtc : lockedAnalysis.amountBtc,
      label: lockedRecipientLabel ?? lockedAnalysis.label,
      message: lockedAnalysis.message,
      detectedOnchainNetwork: lockedAnalysis.detectedOnchainNetwork,
    );
  }

  return analyzeSendDestination(input);
}

SendDestinationAnalysis analyzeSendDestination(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const SendDestinationAnalysis(
      type: SendDestinationType.empty,
      normalizedValue: '',
    );
  }

  final linkId = QrPaymentParser.extractPaymentLinkId(trimmed);
  if (linkId != null) {
    return SendDestinationAnalysis(
      type: SendDestinationType.paymentLink,
      normalizedValue: linkId,
      paymentLinkId: linkId,
    );
  }

  final parsed = QrPaymentParser.decode(trimmed);
  final normalized = parsed?.preferredDestination.trim().isNotEmpty == true
      ? parsed!.preferredDestination.trim()
      : stripLightningPrefix(trimmed);

  if (looksLikeLightningRequest(normalized)) {
    return SendDestinationAnalysis(
      type: SendDestinationType.lightning,
      normalizedValue: normalized,
      amountBtc: parsed?.amountBtc ?? extractLightningAmountBtc(normalized),
      label: parsed?.label,
      message: parsed?.message,
    );
  }

  if (looksLikeBitcoinAddress(normalized)) {
    return SendDestinationAnalysis(
      type: SendDestinationType.onChain,
      normalizedValue: normalized,
      amountBtc: parsed?.amountBtc,
      label: parsed?.label,
      message: parsed?.message,
      detectedOnchainNetwork: inferBitcoinNetworkFromAddress(normalized),
    );
  }

  final internalCandidate = normalizeInternalDestination(normalized);
  if (isValidInternalDestination(internalCandidate)) {
    return SendDestinationAnalysis(
      type: SendDestinationType.internal,
      normalizedValue: internalCandidate,
      amountBtc: parsed?.amountBtc,
      label: parsed?.label,
      message: parsed?.message,
    );
  }

  return SendDestinationAnalysis(
    type: SendDestinationType.invalid,
    normalizedValue: normalized,
  );
}

String stripLightningPrefix(String value) {
  final trimmed = value.trim();
  return trimmed.toLowerCase().startsWith('lightning:')
      ? trimmed.substring(10).trim()
      : trimmed;
}

bool looksLikeLightningRequest(String value) {
  final trimmed = stripLightningPrefix(value);
  if (trimmed.isEmpty) return false;
  final lower = trimmed.toLowerCase();
  return RegExp(r'^(lnbc|lntb|lnbcrt)[0-9][0-9a-z]+$').hasMatch(lower) ||
      RegExp(r'^lnurl[0-9a-z]+$').hasMatch(lower) ||
      looksLikeLightningAddress(trimmed);
}

bool looksLikeLightningAddress(String value) {
  final trimmed = value.trim();
  if (trimmed.length > 254 || trimmed.contains(RegExp(r'\s'))) {
    return false;
  }
  return RegExp(
    r'^[a-zA-Z0-9._%+\-]{1,64}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$',
  ).hasMatch(trimmed);
}

bool looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

double? extractLightningAmountBtc(String value) {
  final withoutPrefix = stripLightningPrefix(value);
  final match = RegExp(
    r'^ln(?:bc|tb|bcrt)(\d+)([munp]?)1',
  ).firstMatch(withoutPrefix.toLowerCase());
  if (match == null) return null;
  final amount = double.tryParse(match.group(1) ?? '');
  if (amount == null || amount <= 0) return null;

  final multiplier = switch (match.group(2)) {
    'm' => 0.001,
    'u' => 0.000001,
    'n' => 0.000000001,
    'p' => 0.000000000001,
    _ => 1.0,
  };
  return amount * multiplier;
}
