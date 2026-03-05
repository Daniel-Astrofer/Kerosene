import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../l10n/l10n_extension.dart';
import '../../../providers/signup_flow_provider.dart';

class FeeExplanationStep extends ConsumerWidget {
  const FeeExplanationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.shield_rounded,
            size: 64,
            color: CyberTheme.neonCyan,
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.feeExplanationTitle,
            style: CyberTheme.heading(size: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.feeExplanationSubtitle,
            style: CyberTheme.label(size: 15, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CyberTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CyberTheme.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: CyberTheme.neonPurple,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.feeExplanationWhereGoesTitle,
                        style: CyberTheme.heading(size: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.feeExplanationWhereGoesSubtitle,
                        style: CyberTheme.label(
                          size: 13,
                          color: CyberTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              ref.read(signupFlowProvider.notifier).nextStep();
            },
            style: CyberTheme.neonButton(CyberTheme.neonCyan),
            child: Text(context.l10n.feeExplanationContinue),
          ),
        ],
      ),
    );
  }
}
