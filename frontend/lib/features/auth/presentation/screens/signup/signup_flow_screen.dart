import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/kerosene_header.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/models/signup_seed_material.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'widgets/signup_animated_backdrop.dart';
import 'widgets/signup_step_ui.dart';
import 'steps/signup_username_step.dart';
import 'steps/signup_seed_step.dart';
import 'steps/signup_verification_step.dart';
import 'steps/signup_security_step.dart';
import 'steps/signup_payment_step.dart'; // This is the Forge step
import 'steps/signup_pow_step.dart';
import 'steps/signup_requirements_step.dart';
import 'steps/signup_totp_step.dart';
import 'steps/signup_final_payment_step.dart';
import 'steps/signup_hardware_step.dart';
import '../totp_screen.dart';

/// Coordinator for the 9-step consolidated sequential signup flow.
class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
  final PageController _pageController = PageController();
  final ValueNotifier<double> _overviewCollapseProgress =
      ValueNotifier<double>(0);
  static const int _totalSteps = 10;
  int _currentStep = 0;
  late final ProviderSubscription<AuthState> _authStateSubscription;

  // State retained across steps
  String _username = '';
  SignupSeedMaterial? _seedMaterial;
  String _totpSecret = '';
  String _qrCodeUri = '';
  List<String> _backupCodes = [];
  String _sessionId = '';
  String _accountSecurity = 'STANDARD';
  int _powRunId = 0;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = ref.listenManual<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }

        if (next is AuthRequiresTotpSetup) {
          setState(() {
            _totpSecret = next.totpSecret;
            _qrCodeUri = next.qrCodeUri;
            _backupCodes = next.backupCodes;
          });
          if (_currentStep == 6) {
            _nextStep();
          }
        } else if (next is AuthTotpVerified) {
          setState(() {
            _sessionId = next.sessionId;
          });
          if (_currentStep == 7) {
            _nextStep();
          }
        } else if (next is AuthHardwareVerified) {
          if (_currentStep == 8) {
            _nextStep();
          }
        } else if (next is AuthRequiresLoginTotp) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TotpScreen(
                username: _username,
                passphrase: _mnemonic,
                isSetup: false,
                preAuthToken: next.preAuthToken,
              ),
            ),
          );
        } else if (next is AuthAuthenticated) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home_loading', (route) => false);
        }
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription.close();
    _overviewCollapseProgress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _mnemonic => _seedMaterial?.primaryMnemonic ?? '';

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    final authState = ref.read(authControllerProvider);
    if (_currentStep == 6 && authState is AuthLoading) {
      return;
    }
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  _PhaseInfo _phaseForStep(int step) {
    return _PhaseInfo(
      title: AppCopy.signupFlowPhaseTitle(context, step: step),
      subtitle: AppCopy.signupFlowPhaseSubtitle(context, step: step),
    );
  }

  _StepInfo _stepInfo(int step, SeedSecurityOption seedSecurityOption) {
    return _StepInfo(
      title: AppCopy.signupFlowStepTitle(
        context,
        step: step,
        securityOption: seedSecurityOption.name,
      ),
      description: AppCopy.signupFlowStepDescription(
        context,
        step: step,
        securityOption: seedSecurityOption.name,
      ),
    );
  }

  String _securityLabel(SeedSecurityOption option) {
    return AppCopy.signupFlowSecurityLabel(
      context,
      option: option.name,
    );
  }

  String _heroHighlightLabel(AuthState authState) {
    return AppCopy.signupFlowHeroHighlightLabel(
      context,
      hasPaymentRequired: authState is AuthPaymentRequired,
      currentStep: _currentStep,
      hasUsername: _username.isNotEmpty,
    );
  }

  String _heroHighlightValue(AuthState authState) {
    return AppCopy.signupFlowHeroHighlightValue(
      context,
      hasPaymentRequired: authState is AuthPaymentRequired,
      paymentAmountBtc: authState is AuthPaymentRequired
          ? authState.amountBtc.toStringAsFixed(8)
          : null,
      currentStep: _currentStep,
      username: _username,
    );
  }

  String _heroHighlightHint(AuthState authState) {
    return AppCopy.signupFlowHeroHighlightHint(
      context,
      hasPaymentRequired: authState is AuthPaymentRequired,
      currentStep: _currentStep,
      hasUsername: _username.isNotEmpty,
    );
  }

  List<String> _contextChips(
    SeedSecurityOption option,
    AuthState authState,
  ) {
    final chips = <String>[
      AppCopy.signupFlowGuidedStepsChip.resolve(context),
      _securityLabel(option),
    ];

    if (_username.isNotEmpty) {
      chips.add('@$_username');
    }
    if (_currentStep >= 7) {
      chips.add(AppCopy.signupFlowRequired2faChip.resolve(context));
    }
    if (_currentStep >= 8) {
      chips.add(AppCopy.signupFlowDevicePasskeyChip.resolve(context));
    }
    if (authState is AuthPaymentRequired) {
      chips.add(AppCopy.signupFlowThreeConfirmationsChip.resolve(context));
    }

    return chips.take(4).toList();
  }

  double _overviewCollapseStart(Size viewport) {
    if (viewport.height < 700) {
      return 2;
    }
    if (viewport.width < 420) {
      return 4;
    }
    return 8;
  }

  double _overviewCollapseDistance(Size viewport) {
    if (viewport.height < 700) {
      return 56;
    }
    if (viewport.width < 420) {
      return 74;
    }
    return 96;
  }

  double _segmentProgress(
    double progress, {
    required double begin,
    required double end,
    Curve curve = Curves.linear,
  }) {
    if (progress <= begin) {
      return 0;
    }
    if (progress >= end) {
      return 1;
    }
    final normalized = (progress - begin) / (end - begin);
    return curve.transform(normalized);
  }

  bool _handleStepScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final viewport = MediaQuery.sizeOf(context);
    final traveled = notification.metrics.pixels -
        notification.metrics.minScrollExtent -
        _overviewCollapseStart(viewport);
    final nextProgress = (traveled / _overviewCollapseDistance(viewport))
        .clamp(0.0, 1.0)
        .toDouble();

    if ((nextProgress - _overviewCollapseProgress.value).abs() < 0.008) {
      return false;
    }

    _overviewCollapseProgress.value = nextProgress;

    return false;
  }

  Widget _buildStepPage(int index, Widget child) {
    return TickerMode(
      enabled: (index - _currentStep).abs() <= 1,
      child: RepaintBoundary(child: child),
    );
  }

  Widget _buildPhaseRail(double collapseProgress) {
    return Row(
      children: [
        Expanded(
            child: _PhasePill(
          label: AppCopy.signupFlowPhasePreparation.resolve(context),
          isActive: _currentStep <= 2,
          isComplete: _currentStep > 2,
          compactness: collapseProgress,
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _PhasePill(
          label: AppCopy.signupFlowPhaseProtection.resolve(context),
          isActive: _currentStep >= 3 && _currentStep <= 8,
          isComplete: _currentStep > 8,
          compactness: collapseProgress,
        )),
        const SizedBox(width: 8),
        Expanded(
            child: _PhasePill(
          label: AppCopy.signupFlowPhaseActivation.resolve(context),
          isActive: _currentStep >= 9,
          isComplete: false,
          compactness: collapseProgress,
        )),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double collapseProgress) {
    final spacing = lerpDouble(4, 3, collapseProgress)!;
    final height = lerpDouble(4, 3, collapseProgress)!;

    return Row(
      children: List.generate(
        _totalSteps,
        (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(
                right: index < _totalSteps - 1 ? spacing : 0,
              ),
              height: height,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary.withValues(
                          alpha: 0.15,
                        ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    _PhaseInfo phase,
    _StepInfo stepInfo,
    SignupFlowState flowState,
    AuthState authState,
    double collapseProgress,
  ) {
    final descriptionVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.08,
          end: 0.56,
          curve: Curves.easeInCubic,
        );
    final highlightVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.18,
          end: 0.86,
          curve: Curves.easeInOutCubic,
        );
    final highlightLabelVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.04,
          end: 0.42,
          curve: Curves.easeInCubic,
        );
    final highlightHintVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.0,
          end: 0.32,
          curve: Curves.easeInCubic,
        );
    final chipsVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.26,
          end: 0.9,
          curve: Curves.easeInCubic,
        );
    final phaseSubtitleVisibility = 1 -
        _segmentProgress(
          collapseProgress,
          begin: 0.45,
          end: 1.0,
          curve: Curves.easeInCubic,
        );
    final cardPadding = EdgeInsets.symmetric(
      horizontal: lerpDouble(AppSpacing.lg, AppSpacing.md, collapseProgress)!,
      vertical: lerpDouble(AppSpacing.lg, AppSpacing.md, collapseProgress)!,
    );
    final titleFontSize = lerpDouble(22, 18, collapseProgress)!;
    final titleGap = lerpDouble(AppSpacing.sm, 10, collapseProgress)!;
    final titleBottomGap = lerpDouble(6, 4, collapseProgress)!;
    final highlightValueFontSize = lerpDouble(28, 22, collapseProgress)!;

    return SignupGlassSurface(
      key: ValueKey(
        'overview_${_currentStep}_${flowState.seedSecurityOption.name}_${_username}_${authState.runtimeType}',
      ),
      padding: cardPadding,
      borderRadius: BorderRadius.circular(20),
      fillColor: Colors.black.withValues(alpha: 0.12),
      borderColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
      blurSigma: 10,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppCopy.signupFlowStepProgress(
                    context,
                    current: _currentStep + 1,
                    total: _totalSteps,
                  ),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SignupTag(
                label: phase.title,
                tone: SignupSurfaceTone.primary,
              ),
            ],
          ),
          SizedBox(height: titleGap),
          Text(
            stepInfo.title,
            maxLines: collapseProgress > 0.72 ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                  height: lerpDouble(1.14, 1.08, collapseProgress),
                ),
          ),
          _ProgressiveCollapse(
            visibility: descriptionVisibility,
            verticalOffset: 12,
            child: Padding(
              padding: EdgeInsets.only(top: titleBottomGap),
              child: Text(
                stepInfo.description,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ),
          _ProgressiveCollapse(
            visibility: highlightVisibility,
            verticalOffset: 14,
            child: Padding(
              padding: EdgeInsets.only(
                top:
                    lerpDouble(AppSpacing.lg, AppSpacing.sm, collapseProgress)!,
              ),
              child: SignupGlassSurface(
                padding: EdgeInsets.symmetric(
                  horizontal: lerpDouble(AppSpacing.md, 14, collapseProgress)!,
                  vertical: lerpDouble(AppSpacing.md, 12, collapseProgress)!,
                ),
                borderRadius: BorderRadius.circular(18),
                fillColor: Colors.black.withValues(alpha: 0.14),
                borderColor: Colors.white.withValues(alpha: 0.08),
                blurSigma: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressiveCollapse(
                      visibility: highlightLabelVisibility,
                      verticalOffset: 8,
                      child: Text(
                        _heroHighlightLabel(authState).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (highlightLabelVisibility > 0.04)
                      SizedBox(
                        height: lerpDouble(
                          0.0,
                          4.0,
                          highlightLabelVisibility.clamp(0.0, 1.0).toDouble(),
                        )!,
                      ),
                    Text(
                      _heroHighlightValue(authState),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: highlightValueFontSize,
                            height: lerpDouble(1.12, 1.02, collapseProgress),
                          ),
                    ),
                    _ProgressiveCollapse(
                      visibility: highlightHintVisibility,
                      verticalOffset: 8,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _heroHighlightHint(authState),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _ProgressiveCollapse(
            visibility: chipsVisibility,
            verticalOffset: 12,
            child: Padding(
              padding: EdgeInsets.only(
                top: lerpDouble(AppSpacing.md, 10, collapseProgress)!,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _contextChips(
                  flowState.seedSecurityOption,
                  authState,
                )
                    .map(
                      (chip) => SignupTag(
                        label: chip,
                        tone: SignupSurfaceTone.neutral,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          SizedBox(
              height:
                  lerpDouble(AppSpacing.md, AppSpacing.sm, collapseProgress)!),
          _buildProgressBar(context, collapseProgress),
          _ProgressiveCollapse(
            visibility: phaseSubtitleVisibility,
            verticalOffset: 10,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                phase.subtitle,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(signupFlowProvider);
    final authState = ref.watch(authControllerProvider);
    final phase = _phaseForStep(_currentStep);
    final stepInfo = _stepInfo(_currentStep, flowState.seedSecurityOption);
    final viewport = MediaQuery.sizeOf(context);
    final forceCollapsedOverview =
        viewport.height < 600 || viewport.width < 340;
    final contentHorizontalPadding =
        viewport.width < 360 ? AppSpacing.md : AppSpacing.lg;
    final contentBottomPadding =
        viewport.height < 720 ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SignupAnimatedBackdrop(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SignupGlassSurface(
              borderRadius: BorderRadius.circular(32),
              fillColor:
                  AppColors.onboardingBackgroundMid.withValues(alpha: 0.74),
              borderColor: Colors.white.withValues(alpha: 0.08),
              blurSigma: 16,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.onboardingBackgroundTop.withValues(alpha: 0.84),
                  AppColors.onboardingBackgroundMid.withValues(alpha: 0.78),
                  AppColors.onboardingBackgroundBottom.withValues(alpha: 0.88),
                ],
              ),
              child: Column(
                children: [
                  KeroseneHeader(
                    title: AppCopy.signupFlowCreateAccount.resolve(context),
                    onBackPressed: _prevStep,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        contentHorizontalPadding,
                        AppSpacing.sm,
                        contentHorizontalPadding,
                        contentBottomPadding,
                      ),
                      child: Column(
                        children: [
                          ValueListenableBuilder<double>(
                            valueListenable: _overviewCollapseProgress,
                            builder: (context, rawCollapseProgress, _) {
                              final collapseProgress = forceCollapsedOverview
                                  ? 1.0
                                  : rawCollapseProgress;

                              return SignupGlassSurface(
                                borderRadius: BorderRadius.circular(24),
                                fillColor: Colors.black.withValues(alpha: 0.14),
                                borderColor:
                                    Colors.white.withValues(alpha: 0.08),
                                blurSigma: 12,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.05),
                                    Colors.white.withValues(alpha: 0.04),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    lerpDouble(
                                      AppSpacing.lg,
                                      AppSpacing.md,
                                      collapseProgress,
                                    )!,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildPhaseRail(collapseProgress),
                                      SizedBox(
                                        height: lerpDouble(
                                          14,
                                          AppSpacing.sm,
                                          collapseProgress,
                                        )!,
                                      ),
                                      _buildOverviewCard(
                                        context,
                                        phase,
                                        stepInfo,
                                        flowState,
                                        authState,
                                        collapseProgress,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: _handleStepScrollNotification,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) => setState(() {
                                  _currentStep = index;
                                  _overviewCollapseProgress.value = 0;
                                }),
                                children: [
                                  _buildStepPage(
                                    0,
                                    SignupRequirementsStep(onNext: _nextStep),
                                  ),
                                  _buildStepPage(
                                    1,
                                    SignupSecurityStep(onNext: _nextStep),
                                  ),
                                  _buildStepPage(
                                    2,
                                    SignupUsernameStep(
                                      initialUsername: _username,
                                      onNext: (username) {
                                        setState(() => _username = username);
                                        _nextStep();
                                      },
                                    ),
                                  ),
                                  _buildStepPage(
                                    3,
                                    SignupSeedStep(
                                      seedSecurityOption:
                                          flowState.seedSecurityOption,
                                      slip39Threshold:
                                          flowState.slip39Threshold,
                                      slip39TotalShares:
                                          flowState.slip39TotalShares,
                                      onNext: (seedMaterial) {
                                        setState(
                                            () => _seedMaterial = seedMaterial);
                                        _nextStep();
                                      },
                                    ),
                                  ),
                                  _buildStepPage(
                                    4,
                                    SignupVerificationStep(
                                      seedMaterial: _seedMaterial,
                                      onNext: _nextStep,
                                    ),
                                  ),
                                  _buildStepPage(
                                    5,
                                    SignupPaymentStep(
                                      username: _username,
                                      mnemonic: _mnemonic,
                                      onStartPow: (accountSecurity) {
                                        setState(() {
                                          _accountSecurity = accountSecurity;
                                          _powRunId += 1;
                                        });
                                        _nextStep();
                                      },
                                    ),
                                  ),
                                  _buildStepPage(
                                    6,
                                    SignupPowStep(
                                      username: _username,
                                      mnemonic: _mnemonic,
                                      accountSecurity: _accountSecurity,
                                      runId: _powRunId,
                                    ),
                                  ),
                                  _buildStepPage(
                                    7,
                                    SignupTotpStep(
                                      username: _username,
                                      passphrase: _mnemonic,
                                      totpSecret: _totpSecret,
                                      qrCodeUri: _qrCodeUri,
                                      backupCodes: _backupCodes,
                                      onVerified: () {},
                                    ),
                                  ),
                                  _buildStepPage(
                                    8,
                                    SignupHardwareStep(
                                      sessionId: _sessionId,
                                      onVerified: () {},
                                    ),
                                  ),
                                  _buildStepPage(
                                    9,
                                    SignupFinalPaymentStep(
                                      sessionId: _sessionId,
                                      username: _username,
                                      password: _mnemonic,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseInfo {
  final String title;
  final String subtitle;

  const _PhaseInfo({
    required this.title,
    required this.subtitle,
  });
}

class _StepInfo {
  final String title;
  final String description;

  const _StepInfo({
    required this.title,
    required this.description,
  });
}

class _PhasePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isComplete;
  final double compactness;

  const _PhasePill({
    required this.label,
    required this.isActive,
    required this.isComplete,
    this.compactness = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive || isComplete
        ? Theme.of(context).colorScheme.secondary
        : Colors.white.withValues(alpha: 0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        vertical: lerpDouble(10, 7, compactness)!,
      ),
      decoration: BoxDecoration(
        color: (isActive || isComplete)
            ? color.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isActive || isComplete)
              ? color.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: isActive || isComplete
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
                fontSize: lerpDouble(11, 10, compactness),
              ),
        ),
      ),
    );
  }
}

class _ProgressiveCollapse extends StatelessWidget {
  final double visibility;
  final double verticalOffset;
  final Widget child;

  const _ProgressiveCollapse({
    required this.visibility,
    required this.child,
    this.verticalOffset = 10,
  });

  @override
  Widget build(BuildContext context) {
    final clampedVisibility = visibility.clamp(0.0, 1.0).toDouble();
    if (clampedVisibility <= 0) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: clampedVisibility,
        child: Opacity(
          opacity: clampedVisibility,
          child: Transform.translate(
            offset: Offset(0, (1 - clampedVisibility) * verticalOffset),
            child: child,
          ),
        ),
      ),
    );
  }
}
