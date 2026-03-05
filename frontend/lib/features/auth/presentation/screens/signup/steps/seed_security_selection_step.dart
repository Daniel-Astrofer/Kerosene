import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../l10n/l10n_extension.dart';
import '../../../providers/signup_flow_provider.dart';

class SeedSecuritySelectionStep extends ConsumerStatefulWidget {
  const SeedSecuritySelectionStep({super.key});

  @override
  ConsumerState<SeedSecuritySelectionStep> createState() =>
      _SeedSecuritySelectionStepState();
}

class _SeedSecuritySelectionStepState
    extends ConsumerState<SeedSecuritySelectionStep> {
  SeedSecurityOption _selectedOption = SeedSecurityOption.standard;

  // For SLIP-39
  int _slip39TotalShares = 5;
  int _slip39Threshold = 3;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.shield_rounded,
            size: 56,
            color: CyberTheme.neonCyan,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.seedSecurityTitle,
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.seedSecuritySubtitle,
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildOptionCard(
            title: context.l10n.seedStandardTitle,
            description: context.l10n.seedStandardDesc,
            icon: Icons.article_rounded,
            value: SeedSecurityOption.standard,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: context.l10n.seedSlip39Title,
            description: context.l10n.seedSlip39Desc,
            icon: Icons.hub_rounded,
            value: SeedSecurityOption.slip39,
          ),
          if (_selectedOption == SeedSecurityOption.slip39)
            _buildSlip39Config(context),

          const SizedBox(height: 16),
          _buildOptionCard(
            title: context.l10n.seedMultisigTitle,
            description: context.l10n.seedMultisigDesc,
            icon: Icons.security_rounded,
            value: SeedSecurityOption.multisig2fa,
            borderColor: CyberTheme.neonPurple, // Highlight this as premium
          ),

          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(signupFlowProvider.notifier)
                  .setSeedSecurityOption(_selectedOption);
              if (_selectedOption == SeedSecurityOption.slip39) {
                ref
                    .read(signupFlowProvider.notifier)
                    .setSlip39Config(_slip39TotalShares, _slip39Threshold);
              }
              ref.read(signupFlowProvider.notifier).nextStep();
            },
            style: CyberTheme.neonButton(CyberTheme.neonCyan),
            child: Text(context.l10n.seedSecurityContinue),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required SeedSecurityOption value,
    Color borderColor = CyberTheme.border,
  }) {
    final isSelected = _selectedOption == value;
    final activeColor = borderColor == CyberTheme.border
        ? CyberTheme.neonCyan
        : borderColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : CyberTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? CyberTheme.glow(activeColor, blur: 8) : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : CyberTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? activeColor : CyberTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: CyberTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? activeColor : CyberTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlip39Config(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CyberTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.seedSlip39ConfigTitle,
            style: const TextStyle(
              color: CyberTheme.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.seedSlip39TotalShares,
                style: const TextStyle(color: CyberTheme.textPrimary),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _slip39TotalShares > 2
                        ? () => setState(() {
                            _slip39TotalShares--;
                            if (_slip39Threshold > _slip39TotalShares) {
                              _slip39Threshold = _slip39TotalShares;
                            }
                          })
                        : null,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$_slip39TotalShares',
                    style: const TextStyle(
                      color: CyberTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: _slip39TotalShares < 15
                        ? () => setState(() => _slip39TotalShares++)
                        : null,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.seedSlip39Threshold,
                style: const TextStyle(color: CyberTheme.textPrimary),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _slip39Threshold > 2
                        ? () => setState(() => _slip39Threshold--)
                        : null,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$_slip39Threshold',
                    style: const TextStyle(
                      color: CyberTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: _slip39Threshold < _slip39TotalShares
                        ? () => setState(() => _slip39Threshold++)
                        : null,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: CyberTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.seedSlip39Summary(
              _slip39Threshold,
              _slip39TotalShares,
            ),
            style: const TextStyle(
              color: CyberTheme.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
