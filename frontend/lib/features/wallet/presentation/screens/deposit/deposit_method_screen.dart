import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
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
          return 'Invoice BOLT11 com expiração e cópia rápida';
        }
        final reason = profile.lightningUnavailableReason.trim();
        if (reason.isNotEmpty) {
          return reason;
        }
        return 'Lightning indisponível neste ambiente.';
      },
      loading: () => 'Validando disponibilidade operacional do backend.',
      error: (_, __) =>
          'Não foi possível validar a rota Lightning nesta tentativa.',
    );
    final lightningTag = walletProfileAsync.when(
      data: (profile) =>
          profile.lightningEnabled ? 'Instantâneo' : 'Indisponível',
      loading: () => 'Validando',
      error: (_, __) => 'Indisponível',
    );
    final onchainTitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? 'On-chain (wallet própria)'
          : 'On-chain (Kerosene)',
      orElse: () => wallet.isSelfCustody
          ? 'On-chain (wallet própria)'
          : 'On-chain (Kerosene)',
    );
    final onchainSubtitle = walletProfileAsync.maybeWhen(
      data: (profile) => profile.isSelfCustody
          ? 'Endereço derivado do seu XPUB. O backend apenas monitora o recebimento.'
          : 'Endereço Bitcoin custodial com monitoramento até a confirmação.',
      orElse: () => wallet.isSelfCustody
          ? 'Endereço derivado do seu XPUB. O backend apenas monitora o recebimento.'
          : 'Endereço Bitcoin custodial com monitoramento até a confirmação.',
    );
    final onchainTag = walletProfileAsync.maybeWhen(
      data: (profile) =>
          profile.isSelfCustody ? 'XPUB auditado' : '3 confirmações',
      orElse: () => wallet.isSelfCustody ? 'XPUB auditado' : '3 confirmações',
    );

    return ReceiveFlowScaffold(
      title: 'Método de depósito',
      subtitle: 'Depósito direto por Bitcoin on-chain ou Lightning.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReceiveFlowSectionLabel('Valor escolhido'),
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
                  'Equivale a ${MoneyDisplay.format(amount: btcAmount, currency: Currency.btc)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                      ),
                ),
              ],
            ),
          ),
          const ReceiveFlowSectionLabel('Depósito direto'),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.zap,
            title: 'Lightning Network',
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
