import 'package:flutter/material.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/features/movement/widgets/receive_flow_ui.dart';

/// Displays a fiat reference line showing the BTC equivalent of an amount.
///
/// Converts [amountBtc] to fiat using the current exchange rates and formats
/// it into a localized string to help users understand the fiat value of their transaction.
class FiatReferenceLine extends StatelessWidget {
  /// The amount in Bitcoin to be converted and displayed.
  final double amountBtc;

  const FiatReferenceLine({
    super.key,
    required this.amountBtc,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr.withdrawUiEquivalentTo(
        MoneyDisplay.format(amount: amountBtc, currency: Currency.btc),
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: receiveFlowMutedTextColor,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

/// A card warning the user that self-custody wallets are blocked
/// from certain types of operations.
///
/// Displays an alert icon alongside an informative title and body text.
class SelfCustodyBlockedCard extends StatelessWidget {
  const SelfCustodyBlockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                KeroseneIcons.review,
                color: receiveFlowTextColor,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr.withdrawUiColdWalletTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: receiveFlowTextColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr.withdrawUiColdWalletBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
