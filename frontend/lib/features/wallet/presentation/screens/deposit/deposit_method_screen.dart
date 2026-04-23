import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'deposit_provider_screen.dart';
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
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositProviderScreen(
            wallet: wallet,
            inputAmount: inputAmount,
            inputCurrency: inputCurrency,
            method: method,
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
    final btcAmount = MoneyDisplay.convertToBtcAmount(
      amount: inputAmount,
      currency: inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowScaffold(
      title: 'Método de depósito',
      subtitle: 'Mesmo fluxo visual, com opções compatíveis com cada rota.',
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
          const SizedBox(height: AppSpacing.lg),
          const ReceiveFlowSectionLabel('Gateway fiat'),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.wallet,
            title: 'Pix e cartão',
            subtitle: 'Fluxo via provedores externos com checkout interno',
            badgeText: 'Onramp',
            onTap: () => _navigateToProvider(context, 'Fiat'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const ReceiveFlowSectionLabel('Depósito direto'),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.zap,
            title: 'Lightning Network',
            subtitle: 'Invoice BOLT11 com expiração e cópia rápida',
            badgeText: 'Instantâneo',
            onTap: () => _navigateToProvider(context, 'Lightning'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMethodCard(
            icon: LucideIcons.coins,
            title: 'On-chain BTC',
            subtitle: 'Endereço Bitcoin para depósito com confirmações',
            badgeText: '3 confirmações',
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
    required VoidCallback onTap,
  }) {
    return ReceiveFlowActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      tag: badgeText,
      onTap: onTap,
    );
  }
}
