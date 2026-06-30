import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_value_entry_surface.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';

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
  final ValueChanged<String> onKeyTap;
  final VoidCallback onContinue;
  final double Function(String amountValue) resolveAmountBtc;
  final String recipient;
  final String recipientValue;
  final String railLabel;

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
    required this.onKeyTap,
    required this.onContinue,
    required this.resolveAmountBtc,
    required this.recipient,
    required this.recipientValue,
    required this.railLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: amount,
      builder: (context, amountValue, child) {
        final amountBtc = resolveAmountBtc(amountValue);
        final amountLabel = lockedAmountBtc > 0
            ? formatBtcValue(lockedAmountBtc)
            : MoneyDisplay.formatEditableInput(
                rawValue: amountValue,
                currency: Currency.btc,
                withSymbol: false,
              );
        final fiatLabel = formatFiatReference(
          btcAmount: amountBtc,
          btcUsd: btcUsd,
          btcEur: btcEur,
          btcBrl: btcBrl,
        );
        final amountLocked = hasPaymentLink || lockedAmountBtc > 0;
        final canContinue = amountBtc > 0 &&
            !isLoading &&
            (!destination.isOnChain || feeQuote.isReady);

        return TransactionValueEntrySurface(
          onBack: onBack,
          amountLabel: amountLabel,
          fiatReference: fiatLabel,
          details: _details(amountBtc),
          showKeypad: !amountLocked,
          onKeyTap: onKeyTap,
          ctaLabel: context.tr.continueButton,
          ctaEnabled: canContinue,
          isBusy: isLoading,
          onCta: onContinue,
        );
      },
    );
  }

  List<TransactionValueEntryDetail> _details(double amountBtc) {
    final balanceLabel = wallet == null
        ? '--'
        : '${formatBtcValue(wallet!.balance, decimalPlaces: 6)} BTC';
    final networkFeeLabel = feeQuote.isLoading
        ? 'Calculando'
        : destination.isExternal
            ? '${formatBtcValue(feeQuote.networkFeeBtc)} BTC'
            : 'Grátis';
    final recipientLabel = recipient.trim().isEmpty
        ? compactInternalValue(recipientValue)
        : recipient.trim();

    return [
      TransactionValueEntryDetail(
        label: 'Destino',
        value: recipientLabel.isEmpty ? 'Destino' : recipientLabel,
      ),
      TransactionValueEntryDetail(label: 'Rede', value: railLabel),
      TransactionValueEntryDetail(
        label: 'Saldo disponível',
        value: balanceLabel,
        numeric: true,
      ),
      TransactionValueEntryDetail(
        label: 'Taxa da rede',
        value: networkFeeLabel,
        numeric: destination.isExternal && !feeQuote.isLoading,
      ),
      TransactionValueEntryDetail(
        label: 'Tempo estimado',
        value: estimatedSendTime(destination),
      ),
    ];
  }
}
