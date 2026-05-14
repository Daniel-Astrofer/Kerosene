import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

/// Luxury Deposit Instructions Screen — Refactored with Design System
class DepositInstructionsScreen extends StatelessWidget {
  const DepositInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  _buildSecureBadge().animate().fade().slideX(begin: -0.1, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  _buildInstructionsCard().animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xxl),
                  CyberButton(
                    text: 'ENTENDIDO',
                    onTap: () => Navigator.pop(context),
                  ).animate(delay: 300.ms).fade().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.xxl),
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
            'DEPOSITAR BTC',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSecureBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 12),
            const SizedBox(width: 6),
            Text(
              'SECURE',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.info, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Instruções de Depósito',
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Instructions list
          _buildInstructionItem(
            icon: LucideIcons.network,
            iconColor: AppColors.primary,
            label: 'Rede',
            title: 'Deposite BTC apenas via',
            highlight: 'Lightning Network',
            highlightColor: AppColors.primary,
            suffix: '.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: LucideIcons.arrowDown,
            iconColor: AppColors.success,
            label: 'Mínimo',
            title: 'O depósito mínimo é de',
            highlight: '0.000001 BTC',
            highlightColor: AppColors.success,
            suffix: '.',
            note: 'Depósitos abaixo deste valor serão perdidos.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: LucideIcons.arrowUp,
            iconColor: AppColors.warning,
            label: 'Máximo',
            title: 'O depósito máximo é de',
            highlight: '1.00 BTC',
            highlightColor: AppColors.warning,
            suffix: ' por transação.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            icon: LucideIcons.timer,
            iconColor: AppColors.secondary,
            label: 'Processamento',
            title: 'Tempo estimado:',
            highlight: '< 1 Minuto',
            highlightColor: AppColors.secondary,
            suffix: ' via Lightning.',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String title,
    required String highlight,
    required Color highlightColor,
    String suffix = '',
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    children: [
                      TextSpan(text: '$title '),
                      TextSpan(
                        text: highlight,
                        style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: suffix),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
