import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/snackbar_helper.dart';

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
                  const SizedBox(height: AppSpacing.lg),
                  if (amountBtc != null && amountBtc! > 0)
                    _buildAmountHeader().animate().fade().scale(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQrCard()
                      .animate(delay: 100.ms)
                      .fade()
                      .scale(curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSubtitles().animate(delay: 200.ms).fade(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAddressSection(context)
                      .animate(delay: 300.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActionRow(context)
                      .animate(delay: 400.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xxl),
                  if (amountBtc == null || amountBtc! <= 0)
                    CyberButton(
                      text: 'DEFINIR VALOR',
                      onTap: () => Navigator.pop(context),
                    ).animate(delay: 500.ms).fade().slideY(begin: 0.2, end: 0),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'RECEBER BTC',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAmountHeader() {
    return Column(
      children: [
        Text(
          amountBtc!.toStringAsFixed(8),
          style: AppTypography.h1
              .copyWith(fontSize: 48, fontFamily: 'JetBrainsMono'),
        ),
        Text(
          'BTC',
          style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
          ),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 200,
            eyeStyle:
                QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitles() {
    return Column(
      children: [
        Text(
          'Escaneie para receber Bitcoin',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Envie apenas Bitcoin (BTC) para este endereço.\nO envio de outros ativos resultará em perda permanente.',
          style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.4), height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEU ENDEREÇO BTC',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassContainer(
          padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.xs,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _shortAddress,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontFamily: 'JetBrainsMono', letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(ClipboardData(text: address));
                  SnackbarHelper.showSuccess('Endereço copiado!');
                },
                icon: Icon(LucideIcons.copy,
                    color: Theme.of(context).colorScheme.onPrimary, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: GlassContainer(
        height: 56,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style:
                  AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
