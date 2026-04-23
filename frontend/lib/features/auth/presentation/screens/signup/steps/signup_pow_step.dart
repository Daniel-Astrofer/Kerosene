import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupPowStep extends ConsumerStatefulWidget {
  final String username;
  final String mnemonic;
  final String accountSecurity;
  final int runId;

  const SignupPowStep({
    super.key,
    required this.username,
    required this.mnemonic,
    required this.accountSecurity,
    required this.runId,
  });

  @override
  ConsumerState<SignupPowStep> createState() => _SignupPowStepState();
}

enum _PowPhaseKey { request, solve, provision }

class _SignupPowStepState extends ConsumerState<SignupPowStep> {
  static const List<_PowPhase> _phases = [
    _PowPhase(
      key: _PowPhaseKey.request,
      icon: LucideIcons.keyRound,
    ),
    _PowPhase(
      key: _PowPhaseKey.solve,
      icon: LucideIcons.cpu,
    ),
    _PowPhase(
      key: _PowPhaseKey.provision,
      icon: LucideIcons.shieldCheck,
    ),
  ];

  Timer? _phaseTimer;
  int _phaseIndex = 0;
  int _lastStartedRunId = 0;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _maybeStartRun(widget.runId);
  }

  @override
  void didUpdateWidget(covariant SignupPowStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runId != widget.runId) {
      _maybeStartRun(widget.runId);
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _maybeStartRun(int runId) {
    if (runId <= 0 || runId == _lastStartedRunId) {
      return;
    }

    _lastStartedRunId = runId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startSignup();
    });
  }

  void _startSignup() {
    final flowState = ref.read(signupFlowProvider);
    _phaseTimer?.cancel();
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {
      _phaseIndex = 0;
    });

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_phaseIndex >= _phases.length - 1) {
        timer.cancel();
        return;
      }

      setState(() {
        _phaseIndex += 1;
      });
    });

    ref.read(authControllerProvider.notifier).signup(
          username: widget.username,
          password: widget.mnemonic,
          accountSecurity: widget.accountSecurity,
          shamirTotalShares:
              flowState.seedSecurityOption == SeedSecurityOption.slip39
                  ? flowState.slip39TotalShares
                  : null,
          shamirThreshold:
              flowState.seedSecurityOption == SeedSecurityOption.slip39
                  ? flowState.slip39Threshold
                  : null,
          multisigThreshold:
              flowState.seedSecurityOption == SeedSecurityOption.multisig2fa
                  ? flowState.multisigThreshold
                  : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthRequiresTotpSetup) {
        _phaseTimer?.cancel();
        if (mounted) {
          setState(() {
            _phaseIndex = _phases.length - 1;
          });
        }
        return;
      }

      if (next is! AuthError || _dialogOpen) {
        return;
      }

      _phaseTimer?.cancel();
      _dialogOpen = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _dialogOpen = false;
          return;
        }

        showCustomErrorDialog(
          context,
          next.message,
          title: AppCopy.signupPowErrorTitle.resolve(context),
          onRetry: () {
            _dialogOpen = false;
            _startSignup();
          },
          onGoBack: () {
            _dialogOpen = false;
            ref.read(authControllerProvider.notifier).clearError();
          },
        );
      });
    });

    final phase = _phases[_phaseIndex.clamp(0, _phases.length - 1)];

    return SignupStepLayout(
      eyebrow: AppCopy.signupPowEyebrow.resolve(context),
      title: context.l10n.usernameLoadingPow,
      subtitle: AppCopy.signupPowSubtitle.resolve(context),
      icon: LucideIcons.cpu,
      tone: SignupSurfaceTone.primary,
      highlightLabel: AppCopy.signupPowHighlightLabel.resolve(context),
      highlightValue: _localizedPhaseTitle(context, phase.key),
      highlightHint: _localizedPhaseBody(context, phase.key),
      chips: [
        AppCopy.signupPowChipAutomatic.resolve(context),
        AppCopy.signupPowChipKeepOpen.resolve(context),
        AppCopy.signupPowChipAutoAdvance.resolve(context),
      ],
      children: [
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _PowStatusPanel(
                  phaseIndex: _phaseIndex,
                  phaseCount: _phases.length,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AnimatedGlyphIcon(
                    icon: phase.icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _localizedPhaseTitle(context, phase.key),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                  _StatusChip(isLoading: isLoading),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(_phases.length, (index) {
                final item = _phases[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _phases.length - 1 ? 0 : AppSpacing.md,
                  ),
                  child: _PhaseRow(
                    title: _localizedPhaseTitle(context, item.key),
                    subtitle: _localizedPhaseBody(context, item.key),
                    icon: item.icon,
                    isDone: index < _phaseIndex,
                    isCurrent: index == _phaseIndex,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: isLoading ? LucideIcons.loader : LucideIcons.badgeCheck,
          title: AppCopy.signupPowNoticeTitle.resolve(context),
          message: isLoading
              ? AppCopy.signupPowNoticeLoading.resolve(context)
              : AppCopy.signupPowNoticeReady.resolve(context),
          tone: SignupSurfaceTone.primary,
        ),
      ],
    );
  }

  String _localizedPhaseTitle(BuildContext context, _PowPhaseKey key) {
    switch (key) {
      case _PowPhaseKey.request:
        return AppCopy.signupPowPhaseRequestTitle.resolve(context);
      case _PowPhaseKey.solve:
        return AppCopy.signupPowPhaseSolveTitle.resolve(context);
      case _PowPhaseKey.provision:
        return AppCopy.signupPowPhaseProvisionTitle.resolve(context);
    }
  }

  String _localizedPhaseBody(BuildContext context, _PowPhaseKey key) {
    switch (key) {
      case _PowPhaseKey.request:
        return AppCopy.signupPowPhaseRequestBody.resolve(context);
      case _PowPhaseKey.solve:
        return AppCopy.signupPowPhaseSolveBody.resolve(context);
      case _PowPhaseKey.provision:
        return AppCopy.signupPowPhaseProvisionBody.resolve(context);
    }
  }
}

class _PowStatusPanel extends StatelessWidget {
  final int phaseIndex;
  final int phaseCount;
  final bool isLoading;

  const _PowStatusPanel({
    required this.phaseIndex,
    required this.phaseCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final completion = isLoading
        ? math.min(0.92, (phaseIndex + 0.35) / math.max(1, phaseCount))
        : 1.0;
    final accent = Color.lerp(
      Theme.of(context).colorScheme.secondary,
      AppColors.success,
      completion * 0.45,
    )!;

    return SizedBox(
      width: 296,
      child: _PowActivityPanel(
        accent: accent,
        completion: completion,
        phaseIndex: phaseIndex,
        phaseCount: phaseCount,
        isLoading: isLoading,
      ),
    );
  }
}

class _PowActivityPanel extends StatelessWidget {
  final Color accent;
  final double completion;
  final int phaseIndex;
  final int phaseCount;
  final bool isLoading;

  const _PowActivityPanel({
    required this.accent,
    required this.completion,
    required this.phaseIndex,
    required this.phaseCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final statusColor = isLoading ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PowActivityDot(accent: accent, isLoading: isLoading),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppCopy.signupPowDeviceTitle.resolve(context),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppCopy.signupPowDeviceSubtitle.resolve(context),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  isLoading
                      ? AppCopy.signupPowStatusInProgress.resolve(context)
                      : AppCopy.signupPowStatusCompleted.resolve(context),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isLoading
                ? AppCopy.signupPowNoticeLoading.resolve(context)
                : AppCopy.signupPowNoticeReady.resolve(context),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: secondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          _PowProgressTrack(
            completion: completion,
            accent: accent,
          ),
          const SizedBox(height: 16),
          _PowStageMeter(
            completion: completion,
            phaseIndex: phaseIndex,
            phaseCount: phaseCount,
            accent: accent,
          ),
          const SizedBox(height: 16),
          _PowSignalRow(
            phaseIndex: phaseIndex,
            phaseCount: phaseCount,
            accent: accent,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _PowActivityDot extends StatelessWidget {
  final Color accent;
  final bool isLoading;

  const _PowActivityDot({
    required this.accent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLoading ? accent : AppColors.success;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _PowProgressTrack extends StatelessWidget {
  final double completion;
  final Color accent;

  const _PowProgressTrack({
    required this.completion,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          widthFactor: completion.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: accent.withValues(alpha: 0.88),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowStageMeter extends StatelessWidget {
  final double completion;
  final int phaseIndex;
  final int phaseCount;
  final Color accent;

  const _PowStageMeter({
    required this.completion,
    required this.phaseIndex,
    required this.phaseCount,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${phaseIndex + 1}/$phaseCount',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '${(completion * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: secondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(phaseCount, (index) {
              final isComplete = index < phaseIndex;
              final isCurrent = index == phaseIndex;
              final color = isComplete || isCurrent
                  ? accent.withValues(alpha: isCurrent ? 0.88 : 0.58)
                  : Colors.white.withValues(alpha: 0.10);

              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: index == phaseCount - 1 ? 0 : 8),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: color,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PowSignalRow extends StatelessWidget {
  final int phaseIndex;
  final int phaseCount;
  final Color accent;
  final bool isLoading;

  const _PowSignalRow({
    required this.phaseIndex,
    required this.phaseCount,
    required this.accent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Text(
            isLoading
                ? AppCopy.signupPowPhaseSolveTitle.resolve(context)
                : AppCopy.signupPowStatusCompleted.resolve(context),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(phaseCount, (index) {
              final isComplete = index < phaseIndex || !isLoading;
              final isCurrent = index == phaseIndex && isLoading;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isCurrent ? 18 : 10,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isComplete || isCurrent
                      ? accent.withValues(alpha: isCurrent ? 0.92 : 0.58)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;

  const _PhaseRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDone
        ? AppColors.success
        : isCurrent
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isCurrent ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Center(
            child: AnimatedGlyphIcon(
              icon: isDone ? LucideIcons.check : icon,
              size: 16,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: isCurrent || isDone
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isCurrent || isDone
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isLoading;

  const _StatusChip({
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLoading ? AppColors.warning : AppColors.success;
    final label = isLoading
        ? AppCopy.signupPowStatusInProgress.resolve(context)
        : AppCopy.signupPowStatusCompleted.resolve(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PowPhase {
  final _PowPhaseKey key;
  final IconData icon;

  const _PowPhase({
    required this.key,
    required this.icon,
  });
}
