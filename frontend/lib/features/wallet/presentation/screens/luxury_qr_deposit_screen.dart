import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';

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
      title: 'Receber BTC',
      subtitle: 'Visual simplificado para QR de depósito.',
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
              label: 'Definir valor',
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
            'Escaneie para receber Bitcoin',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Envie apenas Bitcoin (BTC) para este endereço.\nO envio de outros ativos resultará em perda permanente.',
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
          const ReceiveFlowSectionLabel('Seu endereço BTC'),
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
                label: 'Copiar',
                icon: LucideIcons.copy,
                fullWidth: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: address));
                  SnackbarHelper.showSuccess('Endereço copiado!');
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
            label: 'Compartilhar',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildSecondaryActionButton(
            icon: LucideIcons.download,
            label: 'Salvar QR',
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
