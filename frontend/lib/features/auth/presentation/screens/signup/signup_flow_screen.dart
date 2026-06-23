import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'signup_flow_components.dart';
import 'signup_flow_copy.dart';
import 'signup_success_scene.dart';

const Color _signupInk = AppColors.hexFF000000;
const Color _signupPanel = AppColors.hexFF111111;
const Color _signupField = AppColors.hexFF1A1A1A;
const Color _signupBorderSoft = AppColors.hexFF27272A;
const Color _signupMuted = AppColors.hexFFA1A1AA;
const Color _signupText = AppColors.hexFFFFFFFF;

enum _SignupErrorTarget {
  username,
  passphrase,
  confirmation,
  totp,
  risk,
  general
}

class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _totpController = TextEditingController();

  ProviderSubscription<AuthState>? _authSubscription;
  Timer? _totpTransitionTimer;

  int _step = 0;
  bool _isForward = true;
  bool _acceptedPasswordRisk = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _sessionId = '';
  String _totpSecret = '';
  String _qrCodeUri = '';
  List<String> _backupCodes = const [];
  String? _inlineFeedbackTitle;
  String? _inlineFeedbackMessage;
  IconData _inlineFeedbackIcon = KeroseneIcons.error;
  _SignupErrorTarget? _inlineFeedbackTarget;
  int _inlineFeedbackPulseKey = 0;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthState>(
      authControllerProvider,
      _handleAuthState,
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _totpTransitionTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  String get _username => _usernameController.text.trim();
  String get _password => _passwordController.text;
  String get _totpCode => _totpController.text.replaceAll(RegExp(r'\D'), '');

  bool get _usernameLooksValid =>
      _username.length >= 3 && RegExp(r'^[a-z0-9_]+$').hasMatch(_username);

  bool get _passwordHasMin => _password.length >= 12;
  bool get _passwordHasUpper => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _passwordHasLower => RegExp(r'[a-z]').hasMatch(_password);
  bool get _passwordHasNumber => RegExp(r'[0-9]').hasMatch(_password);
  bool get _passwordHasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_password);
  bool get _passwordLooksStrong =>
      _passwordHasMin &&
      _passwordHasUpper &&
      _passwordHasLower &&
      _passwordHasNumber &&
      _passwordHasSymbol;

  void _handleAuthState(AuthState? previous, AuthState next) {
    if (!mounted) {
      return;
    }

    if (next is AuthRequiresTotpSetup) {
      _sessionId = next.sessionId;
      _totpSecret = next.totpSecret;
      _qrCodeUri = next.qrCodeUri;
      _backupCodes = next.backupCodes;
      setState(() {});
      _totpTransitionTimer?.cancel();
      _totpTransitionTimer = Timer(KeroseneMotion.totpTransition, () {
        if (mounted && _step == 3) {
          _goToStep(4);
        }
      });
      return;
    }

    if (next is AuthTotpVerified) {
      _sessionId = next.sessionId;
      _goToStep(5);
      return;
    }

    if (next is AuthAuthenticated) {
      _goToStep(6);
      return;
    }

    if (next is AuthError) {
      _totpTransitionTimer?.cancel();
      final wasTotpOrPasskeyStep = _step == 4 || _step == 5;
      if (_step == 3 || wasTotpOrPasskeyStep) {
        _sessionId = '';
        _totpSecret = '';
        _qrCodeUri = '';
        _backupCodes = const [];
        _goToStep(wasTotpOrPasskeyStep ? 0 : 2);
      }
      _showInlineFeedback(
        title: context.tr.authFlowInterruptedTitle,
        message: ErrorTranslator.translate(context.tr, next.toString()),
        target: _SignupErrorTarget.general,
      );
    }
  }

  void _startAppAfterSuccess() {
    AppScreenFeedbackBus.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  String? _usernameError(BuildContext context, String value) {
    final username = value.trim();
    if (username.length < 3) {
      return context.tr.authUsernameMinError;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return context.tr.authUsernameCharsError;
    }
    return null;
  }

  void _normalizeUsername(String value) {
    final sanitized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final normalized = sanitized.substring(0, sanitized.length.clamp(0, 24));
    if (normalized != value) {
      _usernameController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {
      _inlineFeedbackTitle = null;
      _inlineFeedbackMessage = null;
      _inlineFeedbackTarget = null;
    });
  }

  void _goToStep(int nextStep) {
    if (nextStep == _step) {
      return;
    }
    setState(() {
      _isForward = nextStep > _step;
      _step = nextStep;
      _inlineFeedbackTitle = null;
      _inlineFeedbackMessage = null;
      _inlineFeedbackTarget = null;
    });
  }

  void _showInlineFeedback({
    required String title,
    required String message,
    IconData icon = KeroseneIcons.error,
    _SignupErrorTarget target = _SignupErrorTarget.general,
  }) {
    HapticFeedback.lightImpact();
    setState(() {
      _inlineFeedbackTitle = title;
      _inlineFeedbackMessage = message;
      _inlineFeedbackIcon = icon;
      _inlineFeedbackTarget = target;
      _inlineFeedbackPulseKey += 1;
    });
  }

  void _clearInlineFeedback() {
    if (_inlineFeedbackTitle == null && _inlineFeedbackMessage == null) {
      return;
    }
    setState(() {
      _inlineFeedbackTitle = null;
      _inlineFeedbackMessage = null;
      _inlineFeedbackTarget = null;
    });
  }

  void _handleBack() {
    if (_step == 0 || _step >= 6) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_step == 3) {
      ref.read(authControllerProvider.notifier).clearError();
      _totpTransitionTimer?.cancel();
      _goToStep(2);
      return;
    }
    _goToStep(_step - 1);
  }

  void _continueFromUsername() {
    final error = _usernameError(context, _username);
    if (error != null) {
      _showInlineFeedback(
        title: context.tr.authInvalidUsernameTitle,
        message: error,
        target: _SignupErrorTarget.username,
      );
      return;
    }
    _goToStep(1);
  }

  void _continueFromPassword() {
    if (!_passwordLooksStrong) {
      _showInlineFeedback(
        title: context.tr.authWeakPasswordTitle,
        message: context.tr.authPasswordStrengthMessage,
        target: _SignupErrorTarget.passphrase,
      );
      return;
    }
    _goToStep(2);
  }

  void _submitSignup() {
    final usernameError = _usernameError(context, _username);
    if (usernameError != null) {
      _goToStep(0);
      _showInlineFeedback(
        title: context.tr.authInvalidUsernameTitle,
        message: usernameError,
        target: _SignupErrorTarget.username,
      );
      return;
    }

    if (!_passwordLooksStrong) {
      _goToStep(1);
      _showInlineFeedback(
        title: context.tr.authWeakPasswordTitle,
        message: context.tr.authPasswordStrengthMessage,
        target: _SignupErrorTarget.passphrase,
      );
      return;
    }

    if (_confirmPasswordController.text != _password) {
      _showInlineFeedback(
        title: context.tr.authInvalidConfirmationTitle,
        message: context.tr.authPasswordMismatchMessage,
        target: _SignupErrorTarget.confirmation,
      );
      return;
    }

    if (!_acceptedPasswordRisk) {
      _showInlineFeedback(
        title: context.tr.authConfirmationRequiredTitle,
        message: context.tr.authPasswordRiskRequiredMessage,
        target: _SignupErrorTarget.risk,
      );
      return;
    }

    _goToStep(3);
    ref.read(authControllerProvider.notifier).signup(
          username: _username,
          password: _password,
        );
  }

  void _skipTotp() {
    ref.read(authControllerProvider.notifier).skipTotpSetup();
  }

  void _verifyTotp() {
    if (_totpCode.length != 6) {
      _showInlineFeedback(
        title: context.tr.authInvalidConfirmationTitle,
        message: context.tr.authSignupTotpCodeRequiredMessage,
        target: _SignupErrorTarget.totp,
      );
      return;
    }

    ref.read(authControllerProvider.notifier).verifyTotp(
          username: _username,
          passphrase: _password,
          totpSecret: _totpSecret,
          totpCode: _totpCode,
        );
  }

  void _registerPasskey() {
    if (_sessionId.isEmpty) {
      _showInlineFeedback(
        title: context.tr.authSecurityPreparingTitle,
        message: context.tr.authSecurityPreparingMessage,
        icon: KeroseneIcons.info,
        target: _SignupErrorTarget.general,
      );
      return;
    }
    ref.read(authControllerProvider.notifier).registerPasskeyOnboarding(
          _sessionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _signupInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _signupInk,
        resizeToAvoidBottomInset: true,
        body: ColoredBox(
          color: _signupInk,
          child: _step == 6
              ? _buildSuccessStep()
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final responsive = context.responsive;
                      final horizontalPadding =
                          responsive.isTinyPhone ? 20.0 : 24.0;
                      final maxWidth = responsive.isCompact ? 390.0 : 430.0;
                      final topSpacing = responsive.isTinyPhone ? 10.0 : 16.0;
                      final bottomPadding =
                          28 + MediaQuery.viewInsetsOf(context).bottom;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topSpacing,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxWidth,
                              minHeight: constraints.maxHeight -
                                  topSpacing -
                                  bottomPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SignupTopBar(
                                  step: _step,
                                  totalSteps: 6,
                                  onBack: _handleBack,
                                ),
                                if (_inlineFeedbackMessage != null) ...[
                                  const SizedBox(height: 18),
                                  AuthMotionShake(
                                    triggerKey: _inlineFeedbackPulseKey,
                                    child: SignupInlineFeedback(
                                      title: _inlineFeedbackTitle ??
                                          context.tr.authFlowInterruptedTitle,
                                      message: _inlineFeedbackMessage!,
                                      icon: _inlineFeedbackIcon,
                                    ),
                                  ),
                                ],
                                SizedBox(
                                  height: responsive.isTinyPhone ? 24 : 34,
                                ),
                                AuthDirectionalSwitcher(
                                  isForward: _isForward,
                                  child: KeyedSubtree(
                                    key: ValueKey(_step),
                                    child: _buildStepBody(isLoading),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepBody(bool isLoading) {
    return switch (_step) {
      0 => _buildUsernameStep(),
      1 => _buildPassphraseStep(),
      2 => _buildConfirmationStep(isLoading),
      3 => _buildCreatingStep(),
      4 => _buildTotpStep(isLoading),
      5 => _buildPasskeyStep(isLoading),
      6 => _buildSuccessStep(),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildUsernameStep() {
    return SignupStepColumn(
      title: signupCreateAccountTitle(context),
      subtitle: signupUsernameSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.username,
          child: SignupTextField(
            controller: _usernameController,
            label: context.tr.authSignupUsernameLabel,
            hintText: signupUsernameHint(context),
            autofocus: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            keyboardType: TextInputType.text,
            onChanged: _normalizeUsername,
            onSubmitted: (_) => _continueFromUsername(),
            suffixIcon: _usernameController.text.isNotEmpty
                ? AnimatedSwitcher(
                    duration: AuthMotion.entrance,
                    child: Icon(
                      _usernameLooksValid
                          ? KeroseneIcons.success
                          : KeroseneIcons.warning,
                      key: ValueKey<bool>(_usernameLooksValid),
                      size: 18,
                      color: _usernameLooksValid ? _signupText : _signupMuted,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        SignupRuleRow(
          passed: _username.length >= 3,
          text: context.tr.authSignupUsernameRuleMin,
        ),
        SignupRuleRow(
          passed: _username.isNotEmpty &&
              RegExp(r'^[a-z0-9_]+$').hasMatch(_username),
          text: signupUsernameCharsetRule(context),
        ),
        SignupRuleRow(
          passed: _usernameController.text ==
              _usernameController.text.toLowerCase(),
          text: context.tr.authSignupUsernameRuleLowercase,
        ),
        const SizedBox(height: 68),
        SignupPrimaryButton(
          text: context.tr.continueButton,
          onPressed: _continueFromUsername,
        ),
      ],
    );
  }

  Widget _buildPassphraseStep() {
    return SignupStepColumn(
      title: signupPassphraseTitle(context),
      subtitle: signupPassphraseSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.passphrase,
          child: SignupTextField(
            controller: _passwordController,
            label: signupPassphraseLabel(context),
            hintText: signupPassphraseHint(context),
            autofocus: true,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) {
              _clearInlineFeedback();
              setState(() {});
            },
            onSubmitted: (_) => _continueFromPassword(),
            suffixIcon: IconButton(
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
              icon: Icon(
                _obscurePassword ? KeroseneIcons.eye : KeroseneIcons.eyeOff,
                size: 18,
                color: _signupMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SignupRuleRow(
          passed: _passwordHasMin,
          text: context.tr.authSignupPassphraseRuleMin,
        ),
        SignupRuleRow(
          passed: _passwordHasUpper,
          text: context.tr.authSignupPassphraseRuleUppercase,
        ),
        SignupRuleRow(
          passed: _passwordHasLower,
          text: context.tr.authSignupPassphraseRuleLowercase,
        ),
        SignupRuleRow(
          passed: _passwordHasNumber,
          text: context.tr.authSignupPassphraseRuleNumber,
        ),
        SignupRuleRow(
          passed: _passwordHasSymbol,
          text: context.tr.authSignupPassphraseRuleSymbol,
        ),
        const SizedBox(height: 54),
        SignupPrimaryButton(
          text: signupProceedAction(context),
          onPressed: _continueFromPassword,
          borderRadius: 16,
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(bool isLoading) {
    return SignupStepColumn(
      title: signupConfirmTitle(context),
      subtitle: signupConfirmSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.confirmation,
          child: SignupTextField(
            controller: _confirmPasswordController,
            label: context.tr.authSignupConfirmPassphraseLabel,
            hintText: signupConfirmHint(context),
            autofocus: true,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) {
              _clearInlineFeedback();
              setState(() {});
            },
            onSubmitted: (_) => isLoading ? null : _submitSignup(),
            suffixIcon: IconButton(
              onPressed: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
              icon: Icon(
                _obscureConfirmPassword
                    ? KeroseneIcons.eye
                    : KeroseneIcons.eyeOff,
                size: 18,
                color: _signupMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.risk,
          child: SignupRiskAcknowledgement(
            checked: _acceptedPasswordRisk,
            text: context.tr.authSignupPassphraseRiskAcknowledgement,
            onTap: () => setState(() {
              _inlineFeedbackTitle = null;
              _inlineFeedbackMessage = null;
              _inlineFeedbackTarget = null;
              _acceptedPasswordRisk = !_acceptedPasswordRisk;
            }),
          ),
        ),
        const SizedBox(height: 66),
        SignupPrimaryButton(
          text: signupFinishCreateAccountAction(context),
          isLoading: isLoading,
          onPressed: isLoading ? null : _submitSignup,
        ),
      ],
    );
  }

  Widget _buildCreatingStep() {
    return AuthMotionStagger(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        SizedBox(
          width: 72,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                KeroseneIcons.shield,
                size: 82,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  KeroseneIcons.lock,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          signupCreatingAlmostReadyTitle(context),
          textAlign: TextAlign.center,
          style: SignupTypography.title(),
        ),
        const SizedBox(height: 12),
        Text(
          signupCreatingAlmostReadySubtitle(context),
          textAlign: TextAlign.center,
          style: SignupTypography.subtitle(),
        ),
        const SizedBox(height: 70),
        const SignupSpinner(size: 64, strokeWidth: 4),
        const SizedBox(height: 26),
        Text(
          signupCreatingSecurityProgress(context),
          textAlign: TextAlign.center,
          style: SignupTypography.bodySmall(color: _signupMuted),
        ),
      ],
    );
  }

  Widget _buildTotpStep(bool isLoading) {
    return SignupStepColumn(
      title: signupTotpTitle(context),
      subtitle: signupTotpSubtitle(context),
      children: [
        NumberedInstruction(
          number: 1,
          text: context.tr.authSignupTotpScanInstruction,
        ),
        const SizedBox(height: 18),
        Center(
          child: TotpQrBox(data: _qrCodeUri, size: 160),
        ),
        const SizedBox(height: 26),
        NumberedInstruction(
          number: 2,
          text: signupTotpCodeInstruction(context),
        ),
        const SizedBox(height: 14),
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.totp,
          child: TotpDigitBoxes(
            controller: _totpController,
            enabled: !isLoading,
            onChanged: (_) {
              _clearInlineFeedback();
              setState(() {});
            },
            onSubmitted: (_) => isLoading ? null : _verifyTotp(),
          ),
        ),
        const SizedBox(height: 34),
        Text(
          signupRecoveryCodesTitle(context),
          style: SignupTypography.sectionTitle(),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.authSignupRecoveryCodesBody,
          style: SignupTypography.bodySmall(),
        ),
        const SizedBox(height: 14),
        RecoveryCodesCopyButton(
          codes: _backupCodes,
          onCopied: _showRecoveryCodesCopied,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: SignupPrimaryButton(
                text: signupSkipAction(context),
                outlined: true,
                onPressed: isLoading ? null : _skipTotp,
                borderRadius: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SignupPrimaryButton(
                text: signupConfirmAction(context),
                isLoading: isLoading,
                onPressed: isLoading ? null : _verifyTotp,
                borderRadius: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasskeyStep(bool isLoading) {
    return SignupStepColumn(
      title: signupPasskeyTitle(context),
      subtitle: signupPasskeySubtitle(context),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _signupBorderSoft),
              color: _signupPanel,
            ),
            child: const Icon(
              KeroseneIcons.userCheck,
              size: 48,
              color: _signupText,
            ),
          ),
        ),
        const SizedBox(height: 28),
        SignupBullet(
          text: context.tr.authSignupPasskeyBiometricBullet,
          icon: KeroseneIcons.biometric,
        ),
        SignupBullet(
          text: context.tr.authSignupPasskeyPasswordBullet,
          icon: KeroseneIcons.security,
        ),
        SignupBullet(
          text: context.tr.authSignupPasskeyDeviceBullet,
          icon: KeroseneIcons.security,
        ),
        const SizedBox(height: 46),
        SignupPrimaryButton(
          text: signupAuthorizeDeviceAction(context),
          isLoading: isLoading,
          onPressed: isLoading ? null : _registerPasskey,
          borderRadius: 12,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return SignupSuccessScene(
      appTitle: context.tr.appTitle,
      title: context.tr.authSignupSuccessTitle,
      subtitle: signupSuccessBody(context),
      actionLabel: signupStartAction(context),
      onContinue: _startAppAfterSuccess,
    );
  }

  void _showRecoveryCodesCopied() {
    final codes = _backupCodes.where((code) => code.trim().isNotEmpty).toList();
    if (codes.isEmpty) {
      _showInlineFeedback(
        title: signupRecoveryCodesUnavailableTitle(context),
        message: signupRecoveryCodesUnavailableMessage(context),
        icon: KeroseneIcons.info,
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: codes.join('\n')));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(signupRecoveryCodesCopiedMessage(context)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _signupField,
        ),
      );
  }
}
