import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/api_display_text.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';
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
          return context.l10n.depositFlowLightningFastSubtitle;
        }
        final reason = profile.lightningUnavailableReason.trim();
        if (reason.isNotEmpty) {
          return ApiDisplayText.message(context, reason);
        }
        return context.l10n.depositFlowLightningUnavailable;
      },
      loading: () => context.l10n.depositFlowLightningChecking,
      error: (_, __) => context.l10n.depositFlowLightningCheckError,
    );
    final lightningTag = walletProfileAsync.when(
      data: (profile) => profile.lightningEnabled
          ? context.l10n.depositFlowLightningInstant
          : context.l10n.depositFlowUnavailable,
      loading: () => context.l10n.depositFlowValidating,
      error: (_, __) => context.l10n.depositFlowUnavailable,
    );
    final onchainTitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.l10n.depositFlowOnchainColdTitle
          : context.l10n.depositFlowOnchainTitle,
      orElse: () => wallet.isSelfCustody
          ? context.l10n.depositFlowOnchainColdTitle
          : context.l10n.depositFlowOnchainTitle,
    );
    final onchainSubtitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.l10n.depositFlowOnchainColdSubtitle
          : context.l10n.depositFlowOnchainSubtitle,
      orElse: () => wallet.isSelfCustody
          ? context.l10n.depositFlowOnchainColdSubtitle
          : context.l10n.depositFlowOnchainSubtitle,
    );
    final onchainTag = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? context.l10n.depositFlowColdWalletTag
          : context.l10n.depositFlowConfirmationsTag,
      orElse: () => wallet.isSelfCustody
          ? context.l10n.depositFlowColdWalletTag
          : context.l10n.depositFlowConfirmationsTag,
    );

    return ReceiveFlowScaffold(
      title: context.l10n.depositFlowMethodTitle,
      subtitle: context.l10n.depositFlowMethodSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReceiveFlowSectionLabel(context.l10n.depositFlowSelectedAmount),
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
                  context.l10n.depositFlowEquivalentTo(
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
          ReceiveFlowSectionLabel(context.l10n.depositFlowChooseOption),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.zap,
            title: context.l10n.lightning,
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
