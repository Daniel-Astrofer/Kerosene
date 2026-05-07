import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

/// Luxury QR Deposit Screen — Refactored with Design System
class LuxuryQrDepositScreen extends StatelessWidget {
  final String address;
  final double? amountBtc;
  final String networkLabel;

  const LuxuryQrDepositScreen({
    super.key,
    required this.address,
    this.amountBtc,
    this.networkLabel = 'LIGHTNING NETWORK',
  });

  String get _qrData {
    if (amountBtc != null && amountBtc! > 0) {
      return 'bitcoin:$address?amount=${amountBtc!.toStringAsFixed(8)}';
    }
    return 'bitcoin:$address';
  }

  String get _shortAddress {
    if (address.length > 20) {
      return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowScaffold(
      title: context.l10n.depositQrReceiveTitle,
      subtitle: context.l10n.depositQrReceiveSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (amountBtc != null && amountBtc! > 0) ...[
            _buildAmountHeader(context),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildQrCard(),
          const SizedBox(height: AppSpacing.md),
          _buildSubtitles(context),
          const SizedBox(height: AppSpacing.md),
          _buildAddressSection(context),
          const SizedBox(height: AppSpacing.md),
          _buildActionRow(context),
          if (amountBtc == null || amountBtc! <= 0) ...[
            const SizedBox(height: AppSpacing.md),
            ReceiveFlowPrimaryButton(
              label: context.l10n.depositQrSetAmount,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAmountHeader(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            amountBtc!.toStringAsFixed(8),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: receiveFlowTextColor,
                  fontSize: 40,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w400,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'BTC',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: receiveFlowMutedTextColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return ReceiveFlowPanel(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 200,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitles(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            context.l10n.depositQrScanTitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.depositQrBitcoinOnlyWarning,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  height: 1.35,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(context.l10n.depositQrAddressLabel),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortAddress,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowTextColor,
                        fontFamily: 'JetBrainsMono',
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ReceiveFlowSecondaryButton(
                label: context.l10n.depositQrCopy,
                icon: LucideIcons.copy,
                fullWidth: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: address));
                  SnackbarHelper.showSuccess(context.l10n.depositQrCopied);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryActionButton(
            icon: LucideIcons.share2,
            label: context.l10n.depositQrShare,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildSecondaryActionButton(
            icon: LucideIcons.download,
            label: context.l10n.depositQrSave,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ReceiveFlowSecondaryButton(
      onTap: onTap,
      icon: icon,
      label: label,
    );
  }
}
