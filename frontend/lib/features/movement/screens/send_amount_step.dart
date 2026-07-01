import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/widgets/transaction_value_entry_surface.dart';
import 'package:kerosene/features/movement/screens/send_destination_models.dart';
import 'package:kerosene/features/movement/screens/send_money_formatters.dart';

class SendAmountStep extends StatelessWidget {
  final VoidCallback onBack;
  final ValueNotifier<String> amount;
  final Currency selectedCurrency;
  final double lockedAmountBtc;
  final bool hasPaymentLink;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;
  final Wallet? wallet;
  final SendDestinationAnalysis destination;
  final SendFeeQuote feeQuote;
  final bool isLoading;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onContinue;
  final double Function(String amountValue) resolveAmountBtc;
  final String recipient;
  final String recipientValue;
  final String railLabel;
  final VoidCallback? onFiatReferenceTap;

  const SendAmountStep({
    super.key,
    required this.onBack,
    required this.amount,
    required this.selectedCurrency,
    required this.lockedAmountBtc,
    required this.hasPaymentLink,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
    required this.wallet,
    required this.destination,
    required this.feeQuote,
    required this.isLoading,
    required this.onAmountChanged,
    required this.onContinue,
    required this.resolveAmountBtc,
    required this.recipient,
    required this.recipientValue,
    required this.railLabel,
    this.onFiatReferenceTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: amount,
      builder: (context, amountValue, child) {
        final amountBtc = resolveAmountBtc(amountValue);
        final amountLocked = hasPaymentLink || lockedAmountBtc > 0;
        final amountLabel = lockedAmountBtc > 0
            ? formatBtcValue(lockedAmountBtc)
            : MoneyDisplay.formatEditableInput(
                rawValue: amountValue,
                currency: selectedCurrency,
                withSymbol: false,
              );
        final secondaryLabel = selectedCurrency == Currency.btc
            ? formatFiatReference(
                btcAmount: amountBtc,
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
              )
            : '≈ ${MoneyDisplay.formatCompact(
                amount: amountBtc,
                currency: Currency.btc,
                maxDecimalPlaces: 8,
              )}';
        final canContinue = amountBtc > 0 &&
            !isLoading &&
            (!destination.isOnChain || feeQuote.isReady);

        return TransactionValueEntrySurface(
          onBack: onBack,
          amountLabel: amountLabel,
          amountInput: amountValue,
          unitLabel: MoneyDisplay.tickerSymbolFor(selectedCurrency),
          currency: selectedCurrency,
          fiatReference: secondaryLabel,
          showKeypad: !amountLocked,
          onAmountChanged: onAmountChanged,
          onFiatReferenceTap: amountLocked ? null : onFiatReferenceTap,
          ctaLabel: context.tr.continueButton,
          ctaEnabled: canContinue,
          isBusy: isLoading,
          onCta: onContinue,
        );
      },
    );
  }
}
