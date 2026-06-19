import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

const Color _signupInk = AppColors.hexFF000000;
const Color _signupSurface = AppColors.hexFF0A0A0A;
const Color _signupPanel = AppColors.hexFF111111;
const Color _signupField = AppColors.hexFF1A1A1A;
const Color _signupBorder = AppColors.hexFF333333;
const Color _signupBorderSoft = AppColors.hexFF27272A;
const Color _signupMuted = AppColors.hexFFA1A1AA;
const Color _signupDim = AppColors.hexFF71717A;
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
                                _SignupTopBar(
                                  step: _step,
                                  totalSteps: 6,
                                  onBack: _handleBack,
                                ),
                                if (_inlineFeedbackMessage != null) ...[
                                  const SizedBox(height: 18),
                                  AuthMotionShake(
                                    triggerKey: _inlineFeedbackPulseKey,
                                    child: _SignupInlineFeedback(
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
    return _SignupStepColumn(
      title: _signupCreateAccountTitle(context),
      subtitle: _signupUsernameSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.username,
          child: _SignupTextField(
            controller: _usernameController,
            label: context.tr.authSignupUsernameLabel,
            hintText: _signupUsernameHint(context),
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
        _SignupRuleRow(
          passed: _username.length >= 3,
          text: context.tr.authSignupUsernameRuleMin,
        ),
        _SignupRuleRow(
          passed: _username.isNotEmpty &&
              RegExp(r'^[a-z0-9_]+$').hasMatch(_username),
          text: _signupUsernameCharsetRule(context),
        ),
        _SignupRuleRow(
          passed: _usernameController.text ==
              _usernameController.text.toLowerCase(),
          text: context.tr.authSignupUsernameRuleLowercase,
        ),
        const SizedBox(height: 68),
        _SignupPrimaryButton(
          text: context.tr.continueButton,
          onPressed: _continueFromUsername,
        ),
      ],
    );
  }

  Widget _buildPassphraseStep() {
    return _SignupStepColumn(
      title: _signupPassphraseTitle(context),
      subtitle: _signupPassphraseSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.passphrase,
          child: _SignupTextField(
            controller: _passwordController,
            label: _signupPassphraseLabel(context),
            hintText: _signupPassphraseHint(context),
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
        _SignupRuleRow(
          passed: _passwordHasMin,
          text: context.tr.authSignupPassphraseRuleMin,
        ),
        _SignupRuleRow(
          passed: _passwordHasUpper,
          text: context.tr.authSignupPassphraseRuleUppercase,
        ),
        _SignupRuleRow(
          passed: _passwordHasLower,
          text: context.tr.authSignupPassphraseRuleLowercase,
        ),
        _SignupRuleRow(
          passed: _passwordHasNumber,
          text: context.tr.authSignupPassphraseRuleNumber,
        ),
        _SignupRuleRow(
          passed: _passwordHasSymbol,
          text: context.tr.authSignupPassphraseRuleSymbol,
        ),
        const SizedBox(height: 54),
        _SignupPrimaryButton(
          text: _signupProceedAction(context),
          onPressed: _continueFromPassword,
          borderRadius: 16,
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(bool isLoading) {
    return _SignupStepColumn(
      title: _signupConfirmTitle(context),
      subtitle: _signupConfirmSubtitle(context),
      children: [
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.confirmation,
          child: _SignupTextField(
            controller: _confirmPasswordController,
            label: context.tr.authSignupConfirmPassphraseLabel,
            hintText: _signupConfirmHint(context),
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
          child: _SignupRiskAcknowledgement(
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
        _SignupPrimaryButton(
          text: _signupFinishCreateAccountAction(context),
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
          _signupCreatingAlmostReadyTitle(context),
          textAlign: TextAlign.center,
          style: _SignupTypography.title(),
        ),
        const SizedBox(height: 12),
        Text(
          _signupCreatingAlmostReadySubtitle(context),
          textAlign: TextAlign.center,
          style: _SignupTypography.subtitle(),
        ),
        const SizedBox(height: 70),
        const _SignupSpinner(size: 64, strokeWidth: 4),
        const SizedBox(height: 26),
        Text(
          _signupCreatingSecurityProgress(context),
          textAlign: TextAlign.center,
          style: _SignupTypography.bodySmall(color: _signupMuted),
        ),
      ],
    );
  }

  Widget _buildTotpStep(bool isLoading) {
    return _SignupStepColumn(
      title: _signupTotpTitle(context),
      subtitle: _signupTotpSubtitle(context),
      children: [
        _NumberedInstruction(
          number: 1,
          text: context.tr.authSignupTotpScanInstruction,
        ),
        const SizedBox(height: 18),
        Center(
          child: _TotpQrBox(data: _qrCodeUri, size: 160),
        ),
        const SizedBox(height: 26),
        _NumberedInstruction(
          number: 2,
          text: _signupTotpCodeInstruction(context),
        ),
        const SizedBox(height: 14),
        AuthMotionShake(
          triggerKey: _inlineFeedbackPulseKey,
          enabled: _inlineFeedbackTarget == _SignupErrorTarget.totp,
          child: _TotpDigitBoxes(
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
          _signupRecoveryCodesTitle(context),
          style: _SignupTypography.sectionTitle(),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.authSignupRecoveryCodesBody,
          style: _SignupTypography.bodySmall(),
        ),
        const SizedBox(height: 14),
        _RecoveryCodesCopyButton(
          codes: _backupCodes,
          onCopied: _showRecoveryCodesCopied,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _SignupPrimaryButton(
                text: _signupSkipAction(context),
                outlined: true,
                onPressed: isLoading ? null : _skipTotp,
                borderRadius: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SignupPrimaryButton(
                text: _signupConfirmAction(context),
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
    return _SignupStepColumn(
      title: _signupPasskeyTitle(context),
      subtitle: _signupPasskeySubtitle(context),
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
        _SignupBullet(
          text: context.tr.authSignupPasskeyBiometricBullet,
          icon: KeroseneIcons.biometric,
        ),
        _SignupBullet(
          text: context.tr.authSignupPasskeyPasswordBullet,
          icon: KeroseneIcons.security,
        ),
        _SignupBullet(
          text: context.tr.authSignupPasskeyDeviceBullet,
          icon: KeroseneIcons.security,
        ),
        const SizedBox(height: 46),
        _SignupPrimaryButton(
          text: _signupAuthorizeDeviceAction(context),
          isLoading: isLoading,
          onPressed: isLoading ? null : _registerPasskey,
          borderRadius: 12,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return _SignupSuccessScene(
      appTitle: context.tr.appTitle,
      title: context.tr.authSignupSuccessTitle,
      subtitle: _signupSuccessBody(context),
      actionLabel: _signupStartAction(context),
      onContinue: _startAppAfterSuccess,
    );
  }

  void _showRecoveryCodesCopied() {
    final codes = _backupCodes.where((code) => code.trim().isNotEmpty).toList();
    if (codes.isEmpty) {
      _showInlineFeedback(
        title: _signupRecoveryCodesUnavailableTitle(context),
        message: _signupRecoveryCodesUnavailableMessage(context),
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
          content: Text(_signupRecoveryCodesCopiedMessage(context)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _signupField,
        ),
      );
  }
}

String _signupCreateAccountTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Create account',
    'es' => 'Crear cuenta',
    _ => 'Criar conta',
  };
}

String _signupUsernameSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'Please choose a username.\nIt will be your unique identity\nin Kerosene.',
    'es' =>
      'Por favor, elige un nombre de usuario.\nSerá tu identificación exclusiva\nen Kerosene.',
    _ =>
      'Por favor, escolha um nome de usuário.\nEle será sua identificação exclusiva\nna Kerosene.',
  };
}

String _signupUsernameHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter your username',
    'es' => 'Ingresa tu nombre de usuario',
    _ => 'Digite seu nome de usuário',
  };
}

String _signupUsernameCharsetRule(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Only lowercase letters, numbers, or underscore',
    'es' => 'Solo letras minúsculas, números o underscore',
    _ => 'Apenas letras minúsculas, números ou underscore',
  };
}

String _signupPassphraseTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Create a strong password',
    'es' => 'Crea una contraseña fuerte',
    _ => 'Crie uma senha forte',
  };
}

String _signupPassphraseSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'It protects your account and assets with maximum security. Nobody at Kerosene has access to your key.',
    'es' =>
      'Protege tu cuenta y tus activos con máxima seguridad. Nadie en Kerosene tiene acceso a tu clave.',
    _ =>
      'Ela protege sua conta e seus ativos com a máxima segurança. Ninguém da Kerosene tem acesso à sua chave.',
  };
}

String _signupPassphraseLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Your passphrase',
    'es' => 'Tu passphrase',
    _ => 'Sua Passphrase',
  };
}

String _signupPassphraseHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter your chosen password',
    'es' => 'Ingresa la contraseña elegida',
    _ => 'Insira sua senha escolhida',
  };
}

String _signupProceedAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Proceed',
    'es' => 'Continuar',
    _ => 'Prosseguir',
  };
}

String _signupConfirmTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm your password',
    'es' => 'Confirma tu contraseña',
    _ => 'Confirme sua senha',
  };
}

String _signupConfirmSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Please enter your passphrase again to continue.',
    'es' => 'Por favor, ingresa tu passphrase nuevamente para continuar.',
    _ => 'Por gentileza, insira sua passphrase novamente para prosseguir.',
  };
}

String _signupConfirmHint(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm your passphrase',
    'es' => 'Confirma tu passphrase',
    _ => 'Confirme sua passphrase',
  };
}

String _signupFinishCreateAccountAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Finish account creation',
    'es' => 'Finalizar creación de cuenta',
    _ => 'Finalizar criação da conta',
  };
}

String _signupCreatingAlmostReadyTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Almost ready',
    'es' => 'Casi listo',
    _ => 'Quase pronto',
  };
}

String _signupCreatingAlmostReadySubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'We are configuring the final details with maximum security.',
    'es' => 'Estamos configurando los últimos detalles con máxima seguridad.',
    _ => 'Estamos configurando os últimos detalhes com segurança máxima.',
  };
}

String _signupCreatingSecurityProgress(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Securing your account...',
    'es' => 'Protegiendo tu cuenta...',
    _ => 'Garantindo a segurança da sua conta...',
  };
}

String _signupTotpTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Protect your account even more (optional)',
    'es' => 'Eleva la seguridad de tu cuenta (opcional)',
    _ => 'Eleve a segurança de sua conta (opcional)',
  };
}

String _signupTotpSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'We recommend enabling two-factor authentication for an extra protection layer.',
    'es' =>
      'Recomendamos activar la autenticación de dos factores para una capa superior de protección.',
    _ =>
      'Recomendamos a ativação da autenticação de dois fatores para uma camada superior de proteção.',
  };
}

String _signupRecoveryCodesTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Recovery codes',
    'es' => 'Códigos de recuperación',
    _ => 'Códigos de Recuperação',
  };
}

String _signupTotpCodeInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter the 6-digit code',
    'es' => 'Ingresa el código de 6 dígitos',
    _ => 'Insira o código de 6 dígitos',
  };
}

String _signupRecoveryCodesCopiedMessage(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Recovery codes copied.',
    'es' => 'Códigos de recuperación copiados.',
    _ => 'Códigos de recuperação copiados.',
  };
}

String _signupRecoveryCodesUnavailableTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Codes unavailable',
    'es' => 'Códigos no disponibles',
    _ => 'Códigos indisponíveis',
  };
}

String _signupRecoveryCodesUnavailableMessage(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Wait for account creation to finish and try again.',
    'es' =>
      'Espera a que termine la creación de la cuenta e inténtalo otra vez.',
    _ => 'Aguarde a criação da conta terminar e tente novamente.',
  };
}

String _signupSkipAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Skip',
    'es' => 'Saltar',
    _ => 'Pular',
  };
}

String _signupConfirmAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm',
    'es' => 'Confirmar',
    _ => 'Confirmar',
  };
}

String _signupPasskeyTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Authorize this device.',
    'es' => 'Autoriza este dispositivo.',
    _ => 'Autorize este dispositivo.',
  };
}

String _signupPasskeySubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'Registration is essential to ensure exclusive and protected access to your account.',
    'es' =>
      'El registro es esencial para asegurar acceso exclusivo y protegido a tu cuenta.',
    _ =>
      'O registro é essencial para assegurar um acesso exclusivo e protegido à sua conta.',
  };
}

String _signupAuthorizeDeviceAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Authorize device',
    'es' => 'Autorizar dispositivo',
    _ => 'Autorizar dispositivo',
  };
}

String _signupSuccessBody(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'You are now a Kerosene user. You can start moving funds.',
    'es' => 'Ahora eres usuario de Kerosene. Ya puedes realizar movimientos.',
    _ => 'Agora você é um usuário da Kerosene. Já pode realizar movimentações.',
  };
}

String _signupStartAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Start',
    'es' => 'Comenzar',
    _ => 'Começar',
  };
}

class _SignupTypography {
  const _SignupTypography._();

  static TextStyle title() {
    return AppTypography.newsreader(
      color: _signupText,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle subtitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupMuted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle label() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );
  }

  static TextStyle field() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmall({Color color = _signupMuted}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle bodyMedium({Color color = _signupText}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupText,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle button({required Color color}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: 0,
    );
  }

  static TextStyle successTitle() {
    return AppTypography.newsreader(
      color: _signupText,
      fontSize: 31,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle successSubtitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _signupMuted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }
}

class _SignupSuccessScene extends StatefulWidget {
  final String appTitle;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onContinue;

  const _SignupSuccessScene({
    required this.appTitle,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onContinue,
  });

  @override
  State<_SignupSuccessScene> createState() => _SignupSuccessSceneState();
}

class _SignupSuccessSceneState extends State<_SignupSuccessScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AuthMotion.ceremonial,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthMotion.reduce(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final badgeProgress = AuthMotion.reduce(context)
            ? 1.0
            : _easeInOut(_interval(_controller.value, 0, 0.32));
        final headingProgress =
            _easeInOut(_interval(_controller.value, 0.18, 0.62));
        final bodyProgress =
            _easeInOut(_interval(_controller.value, 0.32, 0.82));
        final buttonProgress =
            _easeInOut(_interval(_controller.value, 0.56, 1));

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  context.responsive.isTinyPhone ? 24.0 : 32.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Semantics(
                      label: widget.appTitle,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          Opacity(
                            opacity: badgeProgress,
                            child: Transform.scale(
                              scale: 0.92 + (0.08 * badgeProgress),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _signupPanel,
                                  border: Border.all(color: _signupBorderSoft),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.hexFF63FEA7
                                          .withValues(alpha: 0.15),
                                      blurRadius: 60,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.hexFF63FEA7
                                            .withValues(alpha: 0.10),
                                      ),
                                    ),
                                    const Icon(
                                      KeroseneIcons.success,
                                      color: AppColors.hexFF63FEA7,
                                      size: 52,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Opacity(
                            opacity: headingProgress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - headingProgress)),
                              child: Text(
                                _withSuccessBang(widget.title),
                                textAlign: TextAlign.center,
                                style: _SignupTypography.successTitle(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: bodyProgress,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - bodyProgress)),
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                style: _SignupTypography.successSubtitle(),
                              ),
                            ),
                          ),
                          const Spacer(flex: 3),
                          Opacity(
                            opacity: buttonProgress,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - buttonProgress)),
                              child: _SignupPrimaryButton(
                                text: widget.actionLabel,
                                onPressed: widget.onContinue,
                                borderRadius: 999,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static double _interval(double value, double start, double end) {
    if (value <= start) {
      return 0;
    }
    if (value >= end) {
      return 1;
    }
    return (value - start) / (end - start);
  }

  static double _easeInOut(double value) {
    return KeroseneMotion.standard.transform(value.clamp(0.0, 1.0));
  }

  static String _withSuccessBang(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('!')) {
      return trimmed;
    }
    return '$trimmed!';
  }
}

class _SignupTopBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback onBack;

  const _SignupTopBar({
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(KeroseneIcons.back, size: 24),
              color: _signupText.withValues(alpha: 0.86),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < totalSteps; index++) ...[
                if (index > 0) const SizedBox(width: 7),
                SizedBox(
                  width: 30,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AuthMotion.step,
                      curve: KeroseneMotion.standard,
                      width: index == step ? 30 : (index < step ? 18 : 8),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: index <= step
                            ? _signupText.withValues(
                                alpha: index == step ? 1 : 0.58,
                              )
                            : Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SignupStepColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SignupStepColumn({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionStagger(
      children: [
        Text(
          title,
          style: _SignupTypography.title(),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: _SignupTypography.subtitle(),
        ),
        const SizedBox(height: 34),
        ...children,
      ],
    );
  }
}

class _SignupInlineFeedback extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _SignupInlineFeedback({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _SignupPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _SignupTypography.label().copyWith(
                    color: _signupText,
                    fontSize: 14,
                    height: 1.16,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _SignupTypography.bodySmall().copyWith(
                    color: _signupMuted,
                    height: 1.34,
                    decoration: TextDecoration.none,
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

class _SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _SignupTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _signupBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _SignupTypography.label(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: _signupText,
          style: _SignupTypography.field(),
          decoration: InputDecoration(
            filled: true,
            fillColor: _signupField,
            hintText: hintText,
            hintStyle: _SignupTypography.field().copyWith(
              color: _signupDim,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupRuleRow extends StatelessWidget {
  final bool passed;
  final String text;

  const _SignupRuleRow({required this.passed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? KeroseneIcons.success : KeroseneIcons.circle,
            size: 18,
            color: passed
                ? _signupText.withValues(alpha: 0.82)
                : _signupDim.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: _SignupTypography.bodySmall(
                color:
                    passed ? _signupText.withValues(alpha: 0.82) : _signupMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupRiskAcknowledgement extends StatelessWidget {
  final bool checked;
  final String text;
  final VoidCallback onTap;

  const _SignupRiskAcknowledgement({
    required this.checked,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: checked ? _signupText : Colors.transparent,
              border: Border.all(color: checked ? _signupText : _signupDim),
            ),
            child: checked
                ? const Icon(KeroseneIcons.check, size: 13, color: _signupInk)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: _SignupTypography.bodySmall(color: _signupMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final double borderRadius;

  const _SignupPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background = outlined
        ? Colors.white.withValues(alpha: disabled ? 0.02 : 0.03)
        : disabled
            ? Colors.white.withValues(alpha: 0.42)
            : _signupText;
    final foreground = outlined ? _signupText : _signupInk;

    return AuthMotionPressScale(
      enabled: !disabled,
      child: SizedBox(
        height: 54,
        child: FilledButton(
          onPressed: disabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed?.call();
                },
          style: FilledButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: foreground,
            disabledForegroundColor: foreground.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: outlined
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.16))
                  : BorderSide.none,
            ),
            textStyle: _SignupTypography.button(color: foreground),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Text(text),
        ),
      ),
    );
  }
}

class _SignupPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _SignupPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _signupSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _signupBorderSoft),
      ),
      child: child,
    );
  }
}

class _SignupSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;

  const _SignupSpinner({
    required this.size,
    required this.strokeWidth,
  });

  @override
  State<_SignupSpinner> createState() => _SignupSpinnerState();
}

class _SignupSpinnerState extends State<_SignupSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.calm,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthMotion.reduce(context)) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          color: _signupText,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
      );
    }

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _SignupSpinnerPainter(strokeWidth: widget.strokeWidth),
        ),
      ),
    );
  }
}

class _SignupSpinnerPainter extends CustomPainter {
  final double strokeWidth;

  const _SignupSpinnerPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _signupText;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.57,
      4.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SignupSpinnerPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}

class _TotpQrBox extends StatelessWidget {
  final String data;
  final double size;

  const _TotpQrBox({
    required this.data,
    this.size = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size >= 150 ? 12 : 8),
      decoration: BoxDecoration(
        color: _signupText,
        borderRadius: BorderRadius.circular(12),
      ),
      child: data.isEmpty
          ? const Center(
              child: Icon(KeroseneIcons.qr, color: _signupInk, size: 42),
            )
          : QrImageView(data: data, version: QrVersions.auto),
    );
  }
}

class _TotpDigitBoxes extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TotpDigitBoxes({
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_TotpDigitBoxes> createState() => _TotpDigitBoxesState();
}

class _TotpDigitBoxesState extends State<_TotpDigitBoxes> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _TotpDigitBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _focus() {
    if (widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.replaceAll(RegExp(r'\D'), '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.01,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final digit = index < code.length ? code[index] : '';
              final active = _focusNode.hasFocus && index == code.length;
              return AnimatedContainer(
                duration: AuthMotion.step,
                curve: KeroseneMotion.standard,
                width: 48,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _signupField,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? _signupText.withValues(alpha: 0.72)
                        : _signupBorder,
                  ),
                ),
                child: Text(
                  digit,
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: AppTypography.numericFontFamily,
                    color: _signupText,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
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

class _NumberedInstruction extends StatelessWidget {
  final int number;
  final String text;

  const _NumberedInstruction({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _signupMuted),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: _SignupTypography.bodySmall(color: _signupText).copyWith(
              color: _signupText,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _SignupTypography.bodySmall(color: _signupMuted),
          ),
        ),
      ],
    );
  }
}

class _RecoveryCodesCopyButton extends StatelessWidget {
  final List<String> codes;
  final VoidCallback onCopied;

  const _RecoveryCodesCopyButton({
    required this.codes,
    required this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      enabled: true,
      child: OutlinedButton.icon(
        onPressed: onCopied,
        icon: const Icon(KeroseneIcons.copy, size: 20),
        label: Text(_signupCopyRecoveryCodesAction(context)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: _signupText,
          backgroundColor: _signupField,
          side: const BorderSide(color: _signupBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _SignupTypography.button(color: _signupText).copyWith(
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _signupCopyRecoveryCodesAction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Copy recovery codes',
    'es' => 'Copiar códigos de recuperación',
    _ => 'Copiar códigos de recuperação',
  };
}

class _SignupBullet extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SignupBullet({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: _signupDim, size: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: _SignupTypography.bodyMedium(color: _signupMuted),
            ),
          ),
        ],
      ),
    );
  }
}
