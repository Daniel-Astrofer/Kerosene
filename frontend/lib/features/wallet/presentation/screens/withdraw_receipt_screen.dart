import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/l10n/l10n_extension.dart';

class WithdrawReceiptScreen extends StatelessWidget {
  final String amountBtc;
  final String toAddress;
  final String txId;
  final String feeBtc;
  final String walletName;
  final DateTime timestamp;
  final bool isLightning;

  const WithdrawReceiptScreen({
    super.key,
    required this.amountBtc,
    required this.toAddress,
    required this.txId,
    required this.feeBtc,
    required this.walletName,
    required this.timestamp,
    this.isLightning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            _buildSuccessIcon(context),
            const SizedBox(height: AppSpacing.xl),
            _buildAmountSection(context),
            const SizedBox(height: AppSpacing.xxl),
            _buildDetailsCard(context),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CyberButton(
                text: context.l10n.done.toUpperCase(),
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ).animate(delay: 800.ms).fade().slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success.withOpacity(0.1),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        LucideIcons.check,
        color: AppColors.success,
        size: 48,
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).shimmer(delay: 800.ms);
  }

  Widget _buildAmountSection(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.withdrawSuccess.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ).animate(delay: 200.ms).fade(),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              amountBtc,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05), width: 1.5),
      ),
      child: Column(
        children: [
          _buildDetailRow(context, context.l10n.walletName, walletName),
          const Divider(height: AppSpacing.xl, thickness: 0.5, color: Colors.white10),
          _buildDetailRow(context, isLightning ? "INVOICE" : "CARTEIRA", toAddress, isAddress: true),
          const Divider(height: AppSpacing.xl, thickness: 0.5, color: Colors.white10),
          _buildDetailRow(context, "HORÁRIO", dateFormat.format(timestamp)),
          const Divider(height: AppSpacing.xl, thickness: 0.5, color: Colors.white10),
          _buildDetailRow(context, "TAXA", "₿ $feeBtc"),
          const Divider(height: AppSpacing.xl, thickness: 0.5, color: Colors.white10),
          _buildDetailRow(context, "STATUS", "CONFIRMADO", color: AppColors.success),
          const Divider(height: AppSpacing.xl, thickness: 0.5, color: Colors.white10),
          _buildDetailRow(context, "ID DA TRANSAÇÃO", txId, isAddress: true),
        ],
      ),
    ).animate(delay: 500.ms).fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isAddress = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontFamily: 'JetBrainsMono',
                  color: color ?? Theme.of(context).colorScheme.onPrimary,
                  fontSize: isAddress ? 12 : 14,
                  fontWeight: color != null ? FontWeight.w900 : FontWeight.w400,
                ),
                maxLines: isAddress ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAddress)
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  HapticFeedback.mediumImpact();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ],
    );
  }
}
