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
import 'deposit_provider_screen.dart';
import 'deposit_lightning_invoice_screen.dart';
import 'deposit_onchain_invoice_screen.dart';

class DepositMethodScreen extends ConsumerWidget {
  final Wallet wallet;
  final double amountFiat;

  const DepositMethodScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
  });

  void _navigateToProvider(BuildContext context, String method) {
    if (method == 'Lightning') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositLightningInvoiceScreen(
            wallet: wallet,
            amountFiat: amountFiat,
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
            amountFiat: amountFiat,
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
            amountFiat: amountFiat,
            method: method,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle().animate().fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xxl),

                  _buildCategoryLabel('FIAT GATEWAY').animate(delay: 100.ms).fade(),
                  const SizedBox(height: AppSpacing.md),
                  _buildMethodCard(
                    context,
                    icon: LucideIcons.wallet,
                    title: 'Pix & Cartão',
                    subtitle: 'Depósito instantâneo via Ramps',
                    badgeText: 'TAXA 0.99%',
                    badgeColor: Theme.of(context).colorScheme.primary,
                    onTap: () => _navigateToProvider(context, 'Fiat'),
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xl),

                  _buildCategoryLabel('DEPÓSITO DIRETO').animate(delay: 300.ms).fade(),
                  const SizedBox(height: AppSpacing.md),
                  _buildMethodCard(
                    context,
                    icon: LucideIcons.zap,
                    title: 'Lightning Network',
                    subtitle: 'Instantâneo e sem taxas de rede',
                    badgeText: 'FASTEST',
                    badgeColor: Theme.of(context).colorScheme.secondary,
                    onTap: () => _navigateToProvider(context, 'Lightning'),
                  ).animate(delay: 400.ms).fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  _buildMethodCard(
                    context,
                    icon: LucideIcons.coins,
                    title: 'On-chain BTC',
                    subtitle: 'Depósito Bitcoin convencional',
                    badgeText: '3 CONFIRMS',
                    badgeColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                    badgeTextColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
                    onTap: () => _navigateToProvider(context, 'On-chain'),
                  ).animate(delay: 500.ms).fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  _buildFooterSecurity().animate(delay: 600.ms).fade(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'MÉTODO',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(LucideIcons.helpCircle, color: Theme.of(context).colorScheme.onPrimary, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como deseja\nadicionar fundos?',
          style: AppTypography.h1.copyWith(height: 1.1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Escolha sua fonte de preferência para começar.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildCategoryLabel(String label) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.primary.withOpacity(0.6),
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    Color? badgeTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: badgeColor.withOpacity(0.15), width: 1.5),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(color: badgeColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: badgeTextColor ?? badgeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Icon(LucideIcons.chevronRight, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSecurity() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, color: AppColors.primary.withOpacity(0.4), size: 14),
          const SizedBox(width: 8),
          Text(
            'BANK-GRADE ENCRYPTED SECURITY',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary.withOpacity(0.4),
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
