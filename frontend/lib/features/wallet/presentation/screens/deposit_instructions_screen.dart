import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

/// Luxury Deposit Instructions Screen — Refactored with Design System
class DepositInstructionsScreen extends StatelessWidget {
  const DepositInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: context.l10n.depositInstructionsTitle,
      subtitle: context.l10n.depositInstructionsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInstructionsCard(context),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPrimaryButton(
            label: context.l10n.depositInstructionsUnderstood,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return ReceiveFlowPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  color: receiveFlowTextColor,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.depositInstructionsTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          _buildInstructionItem(
            context,
            icon: LucideIcons.network,
            label: context.l10n.depositInstructionsNetworkLabel,
            title: context.l10n.depositInstructionsNetworkTitle,
            highlight: 'Lightning Network',
            suffix: '.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.arrowDown,
            label: context.l10n.depositInstructionsMinimumLabel,
            title: context.l10n.depositInstructionsMinimumTitle,
            highlight: '0.000001 BTC',
            suffix: '.',
            note: context.l10n.depositInstructionsMinimumNote,
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.arrowUp,
            label: context.l10n.depositInstructionsMaximumLabel,
            title: context.l10n.depositInstructionsMaximumTitle,
            highlight: '1.00 BTC',
            suffix: context.l10n.depositInstructionsMaximumSuffix,
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.timer,
            label: context.l10n.depositInstructionsProcessingLabel,
            title: context.l10n.depositInstructionsProcessingTitle,
            highlight: context.l10n.depositInstructionsProcessingHighlight,
            suffix: context.l10n.depositInstructionsProcessingSuffix,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: receiveFlowDividerColor,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }

  Widget _buildInstructionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String title,
    required String highlight,
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
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: Icon(icon, color: receiveFlowTextColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowFaintTextColor,
                      ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                        ),
                    children: [
                      TextSpan(text: '$title '),
                      TextSpan(
                        text: highlight,
                        style: TextStyle(
                          color: receiveFlowTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: suffix),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowFaintTextColor,
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
