import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupHardwareStep extends ConsumerWidget {
  final String sessionId;
  final VoidCallback onVerified;

  const SignupHardwareStep({
    super.key,
    required this.sessionId,
    required this.onVerified,
  });

  void _handleRegister(WidgetRef ref) {
    ref
        .read(authControllerProvider.notifier)
        .registerPasskeyOnboarding(sessionId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthHardwareVerified) {
        onVerified();
      } else if (next is AuthError) {
        if (next.errorCode == 'SESSION_NOT_FOUND') {
          showCustomErrorDialog(
            context,
            context.l10n.authSignupSessionExpiredMessage,
            title: context.l10n.authSessionInterruptedTitle,
            onGoBack: () {
              ref.read(authControllerProvider.notifier).clearError();
              Navigator.of(context).pop();
            },
          );
          return;
        }

        if (next.errorCode == 'ERR_VAULT_NOT_READY') {
          showCustomErrorDialog(
            context,
            context.l10n.authSecurityPreparingMessage,
            title: context.l10n.authSecurityPreparingTitle,
            onRetry: () {
              ref.read(authControllerProvider.notifier).clearError();
              _handleRegister(ref);
            },
          );
          return;
        }

        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.toString()),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            _handleRegister(ref);
          },
        );
      }
    });

    return SignupStepLayout(
      eyebrow: AppCopy.signupHardwareEyebrow.resolve(context),
      title: AppCopy.signupHardwareTitle.resolve(context),
      subtitle: AppCopy.signupHardwareSubtitle.resolve(context),
      icon: LucideIcons.fingerprint,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupHardwareHighlightLabel.resolve(context),
      highlightValue: AppCopy.signupHardwareHighlightValue.resolve(context),
      highlightHint: AppCopy.signupHardwareHighlightHint.resolve(context),
      chips: [
        AppCopy.signupHardwareChipBiometric.resolve(context),
        AppCopy.signupHardwareChipDeviceLock.resolve(context),
        AppCopy.signupHardwareChipSaferAccess.resolve(context),
      ],
      footer: SignupPrimaryFooter(
        text: AppCopy.signupHardwareCta.resolve(context),
        isLoading: isLoading,
        onPressed: () => _handleRegister(ref),
        icon: LucideIcons.fingerprint,
      ),
      children: [
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BenefitLine(
                icon: LucideIcons.shieldCheck,
                text: AppCopy.signupHardwareBenefitExposure.resolve(context),
              ),
              const SizedBox(height: 14),
              _BenefitLine(
                icon: LucideIcons.smartphone,
                text: AppCopy.signupHardwareBenefitBinding.resolve(context),
              ),
              const SizedBox(height: 14),
              _BenefitLine(
                icon: LucideIcons.lock,
                text: AppCopy.signupHardwareBenefitLock.resolve(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: LucideIcons.badgeCheck,
          title: AppCopy.signupHardwareNoticeTitle.resolve(context),
          message: AppCopy.signupHardwareNoticeBody.resolve(context),
          tone: SignupSurfaceTone.primary,
        ),
      ],
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedGlyphIcon(
          icon: icon,
          size: 18,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}
