import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "₿ $amountDisplay",
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontFamily: 'JetBrainsMono',
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 48,
                          fontWeight: FontWeight.w200,
                        ),
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                  if (label != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(label!,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.5),
                                    letterSpacing: 2))
                        .animate(delay: 100.ms)
                        .fade(),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(AppSpacing.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: paymentUri,
                        version: QrVersions.auto,
                        size: MediaQuery.of(context).orientation ==
                                Orientation.landscape
                            ? 180
                            : 220,
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Theme.of(context)
                              .colorScheme
                              .surface, // QR Dark Color
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Theme.of(context)
                              .colorScheme
                              .surface, // QR Dark Color
                        ),
                      ),
                    ),
                  ).animate(delay: 200.ms).scale(curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    context.l10n.receiveScanToPay.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.4),
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                        ),
                  ).animate(delay: 400.ms).fade(),
                ],
              ),
            ),
            const Spacer(),
            _buildActions(context)
                .animate(delay: 600.ms)
                .fade()
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppSpacing.xl),
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
          const Spacer(),
          Text(
            context.l10n.receive.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _ActionIconButton(
              onTap: () {
                HapticFeedback.mediumImpact();
                Clipboard.setData(ClipboardData(text: paymentUri));
                SnackbarHelper.showSuccess(
                    "Copiado para a área de transferência");
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
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: Theme.of(context).colorScheme.onPrimary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
