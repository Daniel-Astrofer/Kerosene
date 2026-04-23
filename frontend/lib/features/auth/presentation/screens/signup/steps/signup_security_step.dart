import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupSecurityStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const SignupSecurityStep({super.key, required this.onNext});

  @override
  ConsumerState<SignupSecurityStep> createState() => _SignupSecurityStepState();
}

class _SignupSecurityStepState extends ConsumerState<SignupSecurityStep> {
  late SeedSecurityOption _selectedOption;
  late int _totalShares;
  late int _threshold;
  late int _multisigThreshold;

  @override
  void initState() {
    super.initState();
    final flowState = ref.read(signupFlowProvider);
    _selectedOption = flowState.seedSecurityOption;
    _totalShares = flowState.slip39TotalShares;
    _threshold = flowState.slip39Threshold;
    _multisigThreshold = flowState.multisigThreshold;
  }

  void _handleContinue() {
    final notifier = ref.read(signupFlowProvider.notifier);
    notifier.setSeedSecurityOption(_selectedOption);
    if (_selectedOption == SeedSecurityOption.slip39) {
      notifier.setSlip39Config(_totalShares, _threshold);
    } else if (_selectedOption == SeedSecurityOption.multisig2fa) {
      notifier.setMultisigThreshold(_multisigThreshold);
    }
    widget.onNext();
  }

  void _setSlip39Config({int? totalShares, int? threshold}) {
    final nextTotal = totalShares ?? _totalShares;
    final nextThreshold = threshold ?? _threshold;

    setState(() {
      _totalShares = nextTotal.clamp(2, 8);
      _threshold = nextThreshold.clamp(2, _totalShares);
    });
  }

  List<_SecurityChoice> _choices(BuildContext context) {
    return [
      _SecurityChoice(
        option: SeedSecurityOption.standard,
        title: AppCopy.signupSecurityStandardTitle.resolve(context),
        badge: AppCopy.signupSecurityStandardBadge.resolve(context),
        badgeColor: Theme.of(context).colorScheme.secondary,
        icon: LucideIcons.shield,
        description: AppCopy.signupSecurityStandardDescription.resolve(context),
        bullets: [
          AppCopy.signupSecurityStandardBulletStore.resolve(context),
          AppCopy.signupSecurityStandardBulletFit.resolve(context),
          AppCopy.signupSecurityStandardBulletFriction.resolve(context),
        ],
      ),
      _SecurityChoice(
        option: SeedSecurityOption.slip39,
        title: AppCopy.signupSecuritySlip39Title.resolve(context),
        badge: AppCopy.signupSecuritySlip39Badge.resolve(context),
        badgeColor: AppColors.warning,
        icon: LucideIcons.layoutGrid,
        description: AppCopy.signupSecuritySlip39Description.resolve(context),
        bullets: [
          AppCopy.signupSecuritySlip39BulletStorage.resolve(context),
          AppCopy.signupSecuritySlip39BulletQuorum.resolve(context),
          AppCopy.signupSecuritySlip39BulletDiscipline.resolve(context),
        ],
      ),
      _SecurityChoice(
        option: SeedSecurityOption.multisig2fa,
        title: AppCopy.signupSecurityMultisigTitle.resolve(context),
        badge: AppCopy.signupSecurityMultisigBadge.resolve(context),
        badgeColor: Theme.of(context).colorScheme.primary,
        icon: LucideIcons.keyRound,
        description: AppCopy.signupSecurityMultisigDescription.resolve(context),
        bullets: [
          AppCopy.signupSecurityMultisigBulletAdvanced.resolve(context),
          AppCopy.signupSecurityMultisigBulletRigor.resolve(context),
          AppCopy.signupSecurityMultisigBulletBeginners.resolve(context),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final choices = _choices(context);
    final selected =
        choices.firstWhere((item) => item.option == _selectedOption);

    return SignupStepLayout(
      eyebrow: AppCopy.signupSecurityEyebrow.resolve(context),
      title: AppCopy.signupSecurityTitle.resolve(context),
      subtitle: AppCopy.signupSecuritySubtitle.resolve(context),
      icon: LucideIcons.shield,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupSecurityHighlightLabel.resolve(context),
      highlightValue: selected.title,
      highlightHint: _selectedOption == SeedSecurityOption.slip39
          ? context.l10n.seedSlip39Summary(_threshold, _totalShares)
          : _selectedOption == SeedSecurityOption.multisig2fa
              ? AppCopy.signupSecurityMultisigHighlightHint(
                  context,
                  threshold: _multisigThreshold,
                )
              : selected.description,
      chips: [
        AppCopy.signupSecurityChipFriction.resolve(context),
        AppCopy.signupSecurityChipGuidedBackup.resolve(context),
        selected.badge,
      ],
      children: [
        ...choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SecurityOptionCard(
              choice: choice,
              isSelected: choice.option == _selectedOption,
              onTap: () => setState(() => _selectedOption = choice.option),
            ),
          ),
        ),
        if (_selectedOption == SeedSecurityOption.slip39) ...[
          const SizedBox(height: AppSpacing.sm),
          SignupPanel(
            tone: SignupSurfaceTone.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.seedSlip39ConfigTitle,
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppCopy.signupSecuritySlip39ConfigIntro.resolve(context),
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _ConfigCounter(
                  title: context.l10n.seedSlip39TotalShares,
                  subtitle: AppCopy.signupSecuritySlip39TotalSharesHint.resolve(
                    context,
                  ),
                  value: _totalShares,
                  onDecrement: () => _setSlip39Config(
                    totalShares: _totalShares - 1,
                    threshold: _threshold > _totalShares - 1
                        ? _totalShares - 1
                        : _threshold,
                  ),
                  onIncrement: () => _setSlip39Config(
                    totalShares: _totalShares + 1,
                  ),
                ),
                const SizedBox(height: 12),
                _ConfigCounter(
                  title: context.l10n.seedSlip39Threshold,
                  subtitle: AppCopy.signupSecuritySlip39ThresholdHint.resolve(
                    context,
                  ),
                  value: _threshold,
                  onDecrement: () => _setSlip39Config(
                    threshold: _threshold - 1,
                  ),
                  onIncrement: () => _setSlip39Config(
                    threshold: _threshold + 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.seedSlip39Summary(_threshold, _totalShares),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_selectedOption == SeedSecurityOption.multisig2fa) ...[
          const SizedBox(height: AppSpacing.sm),
          SignupPanel(
            tone: SignupSurfaceTone.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppCopy.signupSecurityMultisigConfigTitle.resolve(context),
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppCopy.signupSecurityMultisigConfigBody.resolve(context),
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                _ConfigCounter(
                  title: AppCopy.signupSecurityMultisigRequiredFactors.resolve(
                    context,
                  ),
                  subtitle: AppCopy.signupSecurityMultisigRequiredFactorsHint
                      .resolve(context),
                  value: _multisigThreshold,
                  onDecrement: () => setState(
                    () => _multisigThreshold =
                        (_multisigThreshold - 1).clamp(2, 3),
                  ),
                  onIncrement: () => setState(
                    () => _multisigThreshold =
                        (_multisigThreshold + 1).clamp(2, 3),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppCopy.signupSecurityMultisigSummary(
                    context,
                    threshold: _multisigThreshold,
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: selected.icon,
          title: AppCopy.signupSecurityNextScreenTitle.resolve(context),
          message: _selectedOption == SeedSecurityOption.slip39
              ? AppCopy.signupSecurityNextScreenSlip39.resolve(context)
              : _selectedOption == SeedSecurityOption.multisig2fa
                  ? AppCopy.signupSecurityNextScreenMultisig.resolve(context)
                  : AppCopy.signupSecurityNextScreenStandard.resolve(context),
          tone: _selectedOption == SeedSecurityOption.slip39
              ? SignupSurfaceTone.warning
              : SignupSurfaceTone.primary,
        ),
      ],
      footer: SignupPrimaryFooter(
        text: context.l10n.seedSecurityContinue,
        onPressed: _handleContinue,
        icon: LucideIcons.arrowRight,
      ),
    );
  }
}

class _SecurityChoice {
  final SeedSecurityOption option;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final List<String> bullets;

  const _SecurityChoice({
    required this.option,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.bullets,
  });
}

class _SecurityOptionCard extends StatelessWidget {
  final _SecurityChoice choice;
  final bool isSelected;
  final VoidCallback onTap;

  const _SecurityOptionCard({
    required this.choice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? choice.badgeColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? choice.badgeColor.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedGlyphIcon(
                      icon: choice.icon,
                      color: choice.badgeColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                choice.title,
                                style: AppTypography.h3.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              AnimatedGlyphIcon(
                                icon: LucideIcons.checkCircle2,
                                size: 18,
                                color: choice.badgeColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: choice.badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: choice.badgeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            choice.badge,
                            style: AppTypography.caption.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                choice.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              ...choice.bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          color: choice.badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bullet,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigCounter extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ConfigCounter({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _CounterButton(
            icon: LucideIcons.minus,
            onTap: onDecrement,
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          _CounterButton(
            icon: LucideIcons.plus,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: AnimatedGlyphIcon(
          icon: icon,
          size: 16,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
