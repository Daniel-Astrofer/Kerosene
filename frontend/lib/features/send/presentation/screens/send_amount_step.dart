import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_amount_surface.dart';
import 'package:kerosene/features/send/presentation/screens/send_destination_models.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';

class SendAmountStep extends StatelessWidget {
  final Widget topBar;
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
    required this.topBar,
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

  static const Color internalBlack = KeroseneBrandTokens.backgroundSoft;
  static const Color internalPressed = KeroseneBrandTokens.surface;
  static const Color internalBorder = KeroseneBrandTokens.border;
  static const Color internalText = KeroseneBrandTokens.textPrimary;
  static const Color internalMutedText = KeroseneBrandTokens.textSecondary;
  static const Color internalOutline = KeroseneBrandTokens.textMuted;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: internalBlack,
      child: ValueListenableBuilder<String>(
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
          final balanceLabel = wallet == null
              ? '--'
              : '${formatBtcValue(wallet!.balance, decimalPlaces: 6)} BTC';
          final amountLocked = hasPaymentLink || lockedAmountBtc > 0;
          final networkFeeLabel = feeQuote.isLoading
              ? 'Calculando'
              : '${formatBtcValue(feeQuote.networkFeeBtc)} BTC';
          final networkFeeFiatLabel = feeQuote.isLoading
              ? ''
              : formatFiatReference(
                  btcAmount: feeQuote.networkFeeBtc,
                  btcUsd: btcUsd,
                  btcEur: btcEur,
                  btcBrl: btcBrl,
                  includeApproxPrefix: false,
                );
          final canContinue = amountBtc > 0 &&
              !isLoading &&
              (!destination.isOnChain || feeQuote.isReady);

          return LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final width = constraints.maxWidth;
              final compact = height < 760;
              final dense = height < 680;
              final sidePadding = width < 380 ? 18.0 : 24.0;
              final amountFontSize = width < 360
                  ? 42.0
                  : dense
                      ? 46.0
                      : compact
                          ? 50.0
                          : 56.0;
              final verticalGap = dense
                  ? 10.0
                  : compact
                      ? 14.0
                      : 20.0;
              final keypadMaxWidth =
                  width < 390 ? width - sidePadding * 2 : 360.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  0,
                  sidePadding,
                  dense ? 10 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sidePadding > 20 ? 0 : 0,
                      ),
                      child: topBar,
                    ),
                    const Spacer(),
                    _AmountDisplay(
                      amountLabel: amountLabel,
                      unitLabel: MoneyDisplay.symbolFor(selectedCurrency),
                      fiatLabel: fiatLabel,
                      muted: amountLocked,
                      amountFontSize: amountFontSize,
                    ),
                    SizedBox(height: verticalGap),
                    _SendDetails(
                      rows: [
                        _SendDetailRowData(
                          label: 'Destino',
                          value: recipient.isEmpty ? 'Destino' : recipient,
                          secondaryValue: compactInternalValue(recipientValue),
                        ),
                        _SendDetailRowData(
                          label: 'Rede',
                          value: railLabel,
                        ),
                        _SendDetailRowData(
                          label: 'Saldo disponível',
                          value: balanceLabel,
                        ),
                        _SendDetailRowData(
                          label: 'Taxa da rede',
                          value: networkFeeLabel,
                          secondaryValue: networkFeeFiatLabel.isEmpty
                              ? null
                              : networkFeeFiatLabel,
                          loading: feeQuote.isLoading,
                        ),
                        _SendDetailRowData(
                          label: 'Tempo estimado',
                          value: estimatedSendTime(destination),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!amountLocked) ...[
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                keypadMaxWidth.clamp(280.0, 360.0).toDouble(),
                          ),
                          child: TransactionKeypad(
                            mode: TransactionKeypadMode.decimal,
                            onKeyTap: onKeyTap,
                            textColor: internalText,
                            mutedTextColor: internalMutedText,
                            pressedColor: internalPressed,
                          ),
                        ),
                      ),
                      SizedBox(height: dense ? 10 : 14),
                    ] else
                      SizedBox(height: dense ? 12 : 18),
                    TransactionPrimaryButton(
                      label: context.tr.continueButton,
                      enabled: canContinue,
                      isLoading: isLoading,
                      onTap: onContinue,
                      backgroundColor: internalText,
                      foregroundColor: KeroseneBrandTokens.background,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final String amountLabel;
  final String unitLabel;
  final String fiatLabel;
  final bool muted;
  final double amountFontSize;

  const _AmountDisplay({
    required this.amountLabel,
    required this.unitLabel,
    required this.fiatLabel,
    required this.muted,
    required this.amountFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor =
        muted ? SendAmountStep.internalMutedText : SendAmountStep.internalText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: amountFontSize + 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: FittedBox(
              key: ValueKey('$amountLabel $unitLabel'),
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: amountLabel),
                    TextSpan(
                      text: ' $unitLabel',
                      style: AppTypography.captionLarge.copyWith(
                        color: SendAmountStep.internalMutedText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppTypography.amountInput(
                  isBtc: unitLabel.toUpperCase() == 'BTC',
                  color: amountColor,
                ).copyWith(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: Text(
            fiatLabel,
            key: ValueKey(fiatLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.captionLarge.copyWith(
              color: SendAmountStep.internalMutedText,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SendDetails extends StatelessWidget {
  final List<_SendDetailRowData> rows;

  const _SendDetails({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: SendAmountStep.internalBorder.withValues(alpha: 0.72),
            ),
          _SendDetailLine(row: rows[index]),
        ],
      ],
    );
  }
}

class _SendDetailLine extends StatelessWidget {
  final _SendDetailRowData row;

  const _SendDetailLine({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: row.secondaryValue == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SendAmountStep.internalMutedText,
                      fontSize: 14,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    child: row.loading
                        ? SizedBox(
                            key: ValueKey('${row.label}-loading'),
                            width: 76,
                            height: 13,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: SendAmountStep.internalMutedText
                                    .withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          )
                        : Text(
                            row.value,
                            key: ValueKey('${row.label}:${row.value}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTypography.financial(
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: SendAmountStep.internalText,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                  ),
                  if (!row.loading &&
                      row.secondaryValue != null &&
                      row.secondaryValue!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      row.secondaryValue!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SendAmountStep.internalOutline,
                                  fontSize: 12,
                                  height: 1.15,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendDetailRowData {
  final String label;
  final String value;
  final String? secondaryValue;
  final bool loading;

  const _SendDetailRowData({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.loading = false,
  });
}
