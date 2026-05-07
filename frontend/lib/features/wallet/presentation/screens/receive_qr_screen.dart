import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

/// Premium Wallet Receive QR Screen - Refactored
class ReceiveQrScreen extends ConsumerWidget {
  final String amountDisplay;
  final String paymentUri;
  final String? label;

  const ReceiveQrScreen({
    super.key,
    required this.amountDisplay,
    required this.paymentUri,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReceiveFlowScaffold(
      title: context.l10n.receiveQrTitle,
      subtitle: context.l10n.receiveQrSubtitle,
      child: Column(
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Column(
              children: [
                Text(
                  "₿ $amountDisplay",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'JetBrainsMono',
                        color: receiveFlowTextColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                if (label != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPanel(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: QrImageView(
                    data: paymentUri,
                    version: QrVersions.auto,
                    size: MediaQuery.of(context).orientation ==
                            Orientation.landscape
                        ? 180
                        : 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.receiveScanToPay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActions(context),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionIconButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(ClipboardData(text: paymentUri));
              SnackbarHelper.showSuccess(context.l10n.receiveQrCopied);
            },
            icon: LucideIcons.copy,
            label: context.l10n.copy.toUpperCase(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionIconButton(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            icon: LucideIcons.share2,
            label: context.l10n.share.toUpperCase(),
          ),
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _ActionIconButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowSecondaryButton(
      onTap: onTap,
      icon: icon,
      label: label,
    );
  }
}
