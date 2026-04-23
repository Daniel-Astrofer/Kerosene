import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';

/// Signup Step 5: Finalization / Payment
class SignupPaymentStep extends ConsumerWidget {
  final String username;
  final String mnemonic;
  final ValueChanged<String> onStartPow;

  const SignupPaymentStep({
    super.key,
    required this.username,
    required this.mnemonic,
    required this.onStartPow,
  });

  void _startPowResolution(WidgetRef ref) {
    final flowState = ref.read(signupFlowProvider);
    onStartPow(_mapAccountSecurity(flowState.seedSecurityOption));
  }

  String _mapAccountSecurity(SeedSecurityOption option) {
    switch (option) {
      case SeedSecurityOption.slip39:
        return 'SHAMIR';
      case SeedSecurityOption.multisig2fa:
        return 'MULTISIG_2FA';
      case SeedSecurityOption.standard:
        return 'STANDARD';
    }
  }

  String _securityLabel(BuildContext context, SeedSecurityOption option) {
    switch (option) {
      case SeedSecurityOption.slip39:
        return AppCopy.signupSecuritySlip39Title.resolve(context);
      case SeedSecurityOption.multisig2fa:
        return AppCopy.signupPaymentSecurityLabelMultisig.resolve(context);
      case SeedSecurityOption.standard:
        return AppCopy.signupPaymentSecurityLabelStandard.resolve(context);
    }
  }

  String _securitySummary(BuildContext context, SeedSecurityOption option) {
    switch (option) {
      case SeedSecurityOption.slip39:
        return AppCopy.signupPaymentSecuritySummarySlip39.resolve(context);
      case SeedSecurityOption.multisig2fa:
        return AppCopy.signupPaymentSecuritySummaryMultisig.resolve(context);
      case SeedSecurityOption.standard:
        return AppCopy.signupPaymentSecuritySummaryStandard.resolve(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(signupFlowProvider);

    return SignupStepLayout(
      eyebrow: AppCopy.signupPaymentEyebrow.resolve(context),
      title: AppCopy.signupPaymentTitle.resolve(context),
      subtitle: AppCopy.signupPaymentSubtitle.resolve(context),
      icon: LucideIcons.shield,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupPaymentHighlightLabel.resolve(context),
      highlightValue: _securityLabel(context, flowState.seedSecurityOption),
      highlightHint: _securitySummary(context, flowState.seedSecurityOption),
      chips: [
        AppCopy.signupPaymentChip2fa.resolve(context),
        AppCopy.signupPaymentChipPasskey.resolve(context),
        AppCopy.signupPaymentChipActivation.resolve(context),
      ],
      children: [
        SignupPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewCard(
                context: context,
                icon: LucideIcons.user,
                label:
                    AppCopy.signupPaymentReviewUsernameLabel.resolve(context),
                value: '@$username',
                subtitle:
                    AppCopy.signupPaymentReviewUsernameHint.resolve(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildReviewCard(
                context: context,
                icon: LucideIcons.shieldCheck,
                label:
                    AppCopy.signupPaymentReviewProtectionLabel.resolve(context),
                value: _securityLabel(context, flowState.seedSecurityOption),
                subtitle:
                    _securitySummary(context, flowState.seedSecurityOption),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.signupPaymentSectionTitle.resolve(context),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SignupBulletLine(
                icon: LucideIcons.cpu,
                title: AppCopy.signupPaymentStepPrepareTitle.resolve(context),
                subtitle: AppCopy.signupPaymentStepPrepareBody.resolve(context),
                tone: SignupSurfaceTone.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              SignupBulletLine(
                icon: LucideIcons.qrCode,
                title: AppCopy.signupPaymentStepTotpTitle.resolve(context),
                subtitle: AppCopy.signupPaymentStepTotpBody.resolve(context),
                tone: SignupSurfaceTone.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              SignupBulletLine(
                icon: LucideIcons.fingerprint,
                title: AppCopy.signupPaymentStepPasskeyTitle.resolve(context),
                subtitle: AppCopy.signupPaymentStepPasskeyBody.resolve(context),
                tone: SignupSurfaceTone.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: LucideIcons.lock,
          title: AppCopy.signupPaymentNoticeTitle.resolve(context),
          message: AppCopy.signupPaymentNoticeBody.resolve(context),
          tone: SignupSurfaceTone.primary,
        ),
      ],
      footer: SignupPrimaryFooter(
        text: AppCopy.signupPaymentCta.resolve(context),
        onPressed: () => _startPowResolution(ref),
        icon: LucideIcons.arrowRight,
      ),
    );
  }

  Widget _buildReviewCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedGlyphIcon(
              icon: icon,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
