import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/utils/api_display_text.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'deposit_lightning_invoice_screen.dart';
import 'deposit_onchain_invoice_screen.dart';

class DepositMethodScreen extends ConsumerWidget {
  final Wallet wallet;
  final double inputAmount;
  final Currency inputCurrency;

  const DepositMethodScreen({
    super.key,
    required this.wallet,
    required this.inputAmount,
    required this.inputCurrency,
  });

  void _navigateToProvider(BuildContext context, String method) {
    if (method == 'Lightning') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositLightningInvoiceScreen(
            wallet: wallet,
            inputAmount: inputAmount,
            inputCurrency: inputCurrency,
            providerName: 'Kerosene',
          ),
        ),
      );
    } else if (method == 'On-chain') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositOnchainInvoiceScreen(
            wallet: wallet,
            inputAmount: inputAmount,
            inputCurrency: inputCurrency,
            providerName: 'Kerosene',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final walletProfileAsync =
        ref.watch(walletNetworkProfileProvider(wallet.name));
    final btcAmount = MoneyDisplay.convertToBtcAmount(
      amount: inputAmount,
      currency: inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final lightningEnabled = walletProfileAsync.maybeWhen(
      data: (profile) => profile.lightningEnabled,
      orElse: () => false,
    );
    final lightningSubtitle = walletProfileAsync.when(
      data: (profile) {
        if (profile.lightningEnabled) {
          return context.tr.depositFlowLightningFastSubtitle;
        }
        final reason = profile.lightningUnavailableReason.trim();
        if (reason.isNotEmpty) {
          return ApiDisplayText.message(context, reason);
        }
        return context.tr.depositFlowLightningUnavailable;
      },
      loading: () => context.tr.depositFlowLightningChecking,
      error: (_, __) => context.tr.depositFlowLightningCheckError,
    );
    final lightningTag = walletProfileAsync.when(
      data: (profile) => profile.lightningEnabled
          ? context.tr.depositFlowLightningInstant
          : context.tr.depositFlowUnavailable,
      loading: () => context.tr.depositFlowValidating,
      error: (_, __) => context.tr.depositFlowUnavailable,
    );
    final onchainTitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.tr.depositFlowOnchainColdTitle
          : context.tr.depositFlowOnchainTitle,
      orElse: () => wallet.isSelfCustody
          ? context.tr.depositFlowOnchainColdTitle
          : context.tr.depositFlowOnchainTitle,
    );
    final onchainSubtitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.tr.depositFlowOnchainColdSubtitle
          : context.tr.depositFlowOnchainSubtitle,
      orElse: () => wallet.isSelfCustody
          ? context.tr.depositFlowOnchainColdSubtitle
          : context.tr.depositFlowOnchainSubtitle,
    );
    final onchainTag = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.tr.depositFlowColdWalletTag
          : context.tr.depositFlowConfirmationsTag,
      orElse: () => wallet.isSelfCustody
          ? context.tr.depositFlowColdWalletTag
          : context.tr.depositFlowConfirmationsTag,
    );

    return ReceiveFlowScaffold(
      title: context.tr.depositFlowMethodTitle,
      subtitle: context.tr.depositFlowMethodSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReceiveFlowSectionLabel(context.tr.depositFlowSelectedAmount),
                const SizedBox(height: 4),
                Text(
                  MoneyDisplay.format(
                    amount: inputAmount,
                    currency: inputCurrency,
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr.depositFlowEquivalentTo(
                    MoneyDisplay.format(
                      amount: btcAmount,
                      currency: Currency.btc,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                      ),
                ),
              ],
            ),
          ),
          ReceiveFlowSectionLabel(context.tr.depositFlowChooseOption),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.zap,
            title: context.tr.lightning,
            subtitle: lightningSubtitle,
            badgeText: lightningTag,
            enabled: lightningEnabled,
            onTap: lightningEnabled
                ? () => _navigateToProvider(context, 'Lightning')
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.coins,
            title: onchainTitle,
            subtitle: onchainSubtitle,
            badgeText: onchainTag,
            onTap: () => _navigateToProvider(context, 'On-chain'),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return ReceiveFlowActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      tag: badgeText,
      onTap: onTap,
      enabled: enabled,
    );
  }
}
