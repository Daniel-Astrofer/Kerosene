import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

/// Luxury Deposit Instructions Screen — Refactored with Design System
class DepositInstructionsScreen extends StatelessWidget {
  const DepositInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: 'Instruções de depósito',
      subtitle: 'Leitura curta e direta, no mesmo padrão do fluxo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInstructionsCard(context),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPrimaryButton(
            label: 'Entendido',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
                  'Instruções de depósito',
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
            label: 'Rede',
            title: 'Deposite BTC apenas via',
            highlight: 'Lightning Network',
            suffix: '.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.arrowDown,
            label: 'Mínimo',
            title: 'O depósito mínimo é de',
            highlight: '0.000001 BTC',
            suffix: '.',
            note: 'Depósitos abaixo deste valor serão perdidos.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.arrowUp,
            label: 'Máximo',
            title: 'O depósito máximo é de',
            highlight: '1.00 BTC',
            suffix: ' por transação.',
          ),
          _buildDivider(),
          _buildInstructionItem(
            context,
            icon: LucideIcons.timer,
            label: 'Processamento',
            title: 'Tempo estimado:',
            highlight: '< 1 Minuto',
            suffix: ' via Lightning.',
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
