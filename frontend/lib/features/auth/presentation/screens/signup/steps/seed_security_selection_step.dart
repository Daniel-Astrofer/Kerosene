import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/cyber_theme.dart';
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
            'Seed Security',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to protect your wallet recovery phrase. Kerosene offers advanced security options for high-net-worth setups.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildOptionCard(
            title: 'Standard',
            description:
                'A single 12, 18, or 24-word recovery phrase. Best for general use and simplicity.',
            icon: Icons.article_rounded,
            value: SeedSecurityOption.standard,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: 'Shamir SLIP-39 (Multi-part)',
            description:
                'Split your seed into multiple pieces. Requires a minimum threshold of pieces to recover (e.g., 3-of-5). Best for distributed physical storage.',
            icon: Icons.hub_rounded,
            value: SeedSecurityOption.slip39,
          ),
          if (_selectedOption == SeedSecurityOption.slip39)
            _buildSlip39Config(),

          const SizedBox(height: 16),
          _buildOptionCard(
            title: '2FA Multisig Vault',
            description:
                'A 2-of-3 Multisig wallet. Kerosene acts as a co-signer and requires TOTP authorization for withdrawals. Protects against local device theft.',
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
            child: const Text('Continue'),
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

  Widget _buildSlip39Config() {
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
          const Text(
            'SLIP-39 Configuration',
            style: TextStyle(
              color: CyberTheme.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Shares (Pieces)',
                style: TextStyle(color: CyberTheme.textPrimary),
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
                'Required Threshold',
                style: TextStyle(color: CyberTheme.textPrimary),
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
            'Requires $_slip39Threshold out of $_slip39TotalShares shares to restore the wallet.',
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
