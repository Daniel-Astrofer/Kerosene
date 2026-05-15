import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'deposit_lightning_invoice_screen.dart';
import 'deposit_onchain_invoice_screen.dart';

class DepositProviderScreen extends ConsumerWidget {
  final Wallet wallet;
  final double amountFiat;
  final String method;

  const DepositProviderScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
    required this.method,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle().animate().fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  _buildProviderCard(
                    context,
                    name: 'MoonPay',
                    description: 'Pix, Visa, Mastercard, Apple Pay',
                    iconData: LucideIcons.moon,
                    badgeText: 'RECOMENDADO',
                    badgeColor: Theme.of(context).colorScheme.primary,
                  ).animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  _buildProviderCard(
                    context,
                    name: 'Banxa',
                    description: 'Pix, Transferência, Cartão',
                    iconData: LucideIcons.arrowDownUp,
                    badgeText: 'RÁPIDO',
                    badgeColor: AppColors.success,
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  _buildProviderCard(
                    context,
                    name: 'Mt Pelerin',
                    description: 'Sem KYC até R\$ 5.000',
                    iconData: LucideIcons.landmark,
                    badgeText: 'PRIVADO',
                    badgeColor: AppColors.warning,
                  ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLightning(BuildContext context, String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositLightningInvoiceScreen(
          wallet: wallet,
          amountFiat: amountFiat,
          providerName: provider,
        ),
      ),
    );
  }

  void _navigateToOnchain(BuildContext context, String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositOnchainInvoiceScreen(
          wallet: wallet,
          amountFiat: amountFiat,
          providerName: provider,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'PROVEDORES',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como deseja\ncomprar?',
          style: AppTypography.h1.copyWith(height: 1.1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Selecione o melhor provedor para Pix ou Cartão.',
          style: AppTypography.bodyMedium
              .copyWith(color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData iconData,
    String? badgeText,
    Color? badgeColor,
  }) {
    final color = badgeColor ?? Theme.of(context).colorScheme.primary;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: color,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildNetworkButton(
                  icon: LucideIcons.zap,
                  label: 'Lightning',
                  onTap: () => _navigateToLightning(context, name),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNetworkButton(
                  icon: LucideIcons.link,
                  label: 'On-chain',
                  onTap: () => _navigateToOnchain(context, name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style:
                  AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
