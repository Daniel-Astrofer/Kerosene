import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';

class SignupRequirementsStep extends ConsumerWidget {
  final VoidCallback onNext;

  const SignupRequirementsStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {



    return SignupStepLayout(
      eyebrow: AppCopy.signupRequirementsEyebrow.resolve(context),
      title: AppCopy.signupRequirementsTitle.resolve(context),
      subtitle: AppCopy.signupRequirementsSubtitle.resolve(context),
      icon: LucideIcons.shieldCheck,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupRequirementsHighlightLabel.resolve(context),
      chips: [
        AppCopy.signupRequirementsChip2fa.resolve(context),
        AppCopy.signupRequirementsChipPasskey.resolve(context),
        AppCopy.signupRequirementsChipConfirmations.resolve(context),
      ],
      children: [
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.signupRequirementsPanelTitle.resolve(context),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SignupBulletLine(
                icon: LucideIcons.clock3,
                title: AppCopy.signupRequirementsTimeTitle.resolve(context),
                subtitle: AppCopy.signupRequirementsTimeBody.resolve(context),
                tone: SignupSurfaceTone.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              SignupBulletLine(
                icon: LucideIcons.smartphone,
                title: AppCopy.signupRequirementsAuthenticatorTitle.resolve(
                  context,
                ),
                subtitle: AppCopy.signupRequirementsAuthenticatorBody.resolve(
                  context,
                ),
                tone: SignupSurfaceTone.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              SignupBulletLine(
                icon: LucideIcons.penTool,
                title: AppCopy.signupRequirementsBackupTitle.resolve(context),
                subtitle: AppCopy.signupRequirementsBackupBody.resolve(context),
                tone: SignupSurfaceTone.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: LucideIcons.lock,
          title: AppCopy.signupRequirementsNoticeTitle.resolve(context),
          message: AppCopy.signupRequirementsNoticeBody.resolve(context),
          tone: SignupSurfaceTone.warning,
        ),
      ],
      footer: SignupPrimaryFooter(
        text: AppCopy.signupRequirementsCta.resolve(context),
        onPressed: onNext,
        caption: AppCopy.signupRequirementsCaption.resolve(context),
        icon: LucideIcons.arrowRight,
      ),
    );
  }
}
