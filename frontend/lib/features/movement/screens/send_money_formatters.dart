import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/movement/screens/send_destination_models.dart';

String sendShortHash(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 18) return trimmed;
  return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 8)}';
}

bool isValidInternalDestination(String value) {
  final trimmed = normalizeInternalDestination(value);
  if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('bitcoin:')) {
    return false;
  }
  final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  final username = RegExp(r'^[a-z0-9_]{3,30}$');
  return uuid.hasMatch(trimmed) || username.hasMatch(trimmed);
}

String normalizeInternalDestination(String value) {
  var trimmed = value.trim();
  while (trimmed.startsWith('@')) {
    trimmed = trimmed.substring(1).trim();
  }
  return trimmed.toLowerCase();
}

String compactInternalValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 18) return trimmed;
  return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 6)}';
}

String recentInternalDestinationTitle(
    RecentTransactionDestination destination) {
  final label = _stripLeadingAt(destination.label);
  final address = _stripLeadingAt(destination.address);
  return label == null || label.isEmpty
      ? address ?? destination.address
      : label;
}

String recentInternalDestinationSubtitle(
    RecentTransactionDestination destination) {
  final label = _stripLeadingAt(destination.label);
  if (label == null || label.isEmpty) {
    return _recentInternalDestinationKindLabel(destination.kind);
  }
  return compactInternalValue(
      _stripLeadingAt(destination.address) ?? destination.address);
}

String? _stripLeadingAt(String? value) {
  var trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return trimmed;
  while (trimmed!.startsWith('@')) {
    trimmed = trimmed.substring(1).trim();
  }
  return trimmed;
}

String _recentInternalDestinationKindLabel(
    RecentTransactionDestinationKind kind) {
  return switch (kind) {
    RecentTransactionDestinationKind.internal => 'Transferência interna',
    RecentTransactionDestinationKind.onChain => 'Endereço on-chain',
    RecentTransactionDestinationKind.lightning => 'Invoice Lightning',
  };
}

String formatBtcValue(double value, {int decimalPlaces = 8}) {
  return MoneyDisplay.format(
    amount: value,
    currency: Currency.btc,
    withSymbol: false,
    decimalPlaces: decimalPlaces,
  );
}

String walletBalanceLabel(double value) {
  return '${formatBtcValue(value, decimalPlaces: 6)} BTC';
}

String formatFiatReference({
  required double btcAmount,
  required double? btcUsd,
  required double? btcEur,
  required double? btcBrl,
  bool includeApproxPrefix = true,
}) {
  final value = MoneyDisplay.formatAmountFromBtc(
    btcAmount: btcAmount,
    currency: Currency.brl,
    btcUsd: btcUsd,
    btcEur: btcEur,
    btcBrl: btcBrl,
  );
  return includeApproxPrefix ? '≈ $value' : value;
}

String estimatedSendTime(SendDestinationAnalysis destination) {
  if (destination.isOnChain) return '~10 min';
  if (destination.isLightning) return 'Segundos';
  return 'Instantâneo';
}
