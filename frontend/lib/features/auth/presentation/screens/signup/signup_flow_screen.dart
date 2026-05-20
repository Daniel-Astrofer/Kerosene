import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/widgets/auth_motion.dart';
import 'package:teste/l10n/l10n_extension.dart';

const Color _signupInk = Color(0xFF000000);
const Color _signupSurface = Color(0xFF0A0A0A);
const Color _signupPanel = Color(0xFF111111);
const Color _signupField = Color(0xFF1A1A1A);
const Color _signupBorder = Color(0xFF333333);
const Color _signupBorderSoft = Color(0xFF27272A);
const Color _signupMuted = Color(0xFFA1A1AA);
const Color _signupDim = Color(0xFF71717A);
const Color _signupText = Color(0xFFFFFFFF);

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
  Timer? _redirectTimer;

  int _step = 0;
  bool _isForward = true;
  bool _acceptedPasswordRisk = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _creationCompleted = false;
  bool _successRedirectScheduled = false;
  String _sessionId = '';
  String _totpSecret = '';
  String _qrCodeUri = '';
  List<String> _backupCodes = const [];
  String? _inlineFeedbackTitle;
  String? _inlineFeedbackMessage;
  IconData _inlineFeedbackIcon = LucideIcons.alertTriangle;
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
    _redirectTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  String get _username => _usernameController.text.trim();
  String get _password => _passwordController.text;
  String get _totpCode => _totpController.text.replaceAll(RegExp(r'\D'), '');
  String get _totpCountdownHint => '25';

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
      _creationCompleted = true;
      setState(() {});
      _totpTransitionTimer?.cancel();
      _totpTransitionTimer = Timer(const Duration(milliseconds: 850), () {
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
      _scheduleSuccessRedirect();
      return;
    }

    if (next is AuthError) {
      _totpTransitionTimer?.cancel();
      _creationCompleted = false;
      if (_step == 3) {
        _goToStep(2);
      }
      _showInlineFeedback(
        title: context.tr.authFlowInterruptedTitle,
        message: ErrorTranslator.translate(context.tr, next.toString()),
        target: _SignupErrorTarget.general,
      );
    }
  }

  void _scheduleSuccessRedirect() {
    if (_successRedirectScheduled) {
      return;
    }
    _successRedirectScheduled = true;
    _redirectTimer?.cancel();
    _redirectTimer = Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home_loading',
        (route) => false,
      );
    });
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
    IconData icon = LucideIcons.alertTriangle,
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

    _creationCompleted = false;
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
        icon: LucideIcons.info,
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
                          ? LucideIcons.checkCircle2
                          : LucideIcons.alertCircle,
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
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
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
                _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
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
        const SizedBox(height: 26),
        SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.shield,
                size: 74,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  LucideIcons.lock,
                  size: 30,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _signupCreatingTitle(context),
          textAlign: TextAlign.center,
          style: _SignupTypography.title(),
        ),
        const SizedBox(height: 8),
        Text(
          _signupCreatingSubtitle(context),
          textAlign: TextAlign.center,
          style: _SignupTypography.subtitle(),
        ),
        const SizedBox(height: 28),
        _SignupPanel(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          child: Column(
            children: [
              _SignupProcessingRow(
                icon: LucideIcons.badgeCheck,
                text: _signupCreatingSecureConnection(context),
                status: _creationCompleted
                    ? _SignupProcessingStatus.done
                    : _SignupProcessingStatus.done,
              ),
              _SignupProcessingRow(
                icon: LucideIcons.terminal,
                text: _signupCreatingHumanCheck(context),
                status: _creationCompleted
                    ? _SignupProcessingStatus.done
                    : _SignupProcessingStatus.loading,
              ),
              _SignupProcessingRow(
                icon: LucideIcons.server,
                text: _signupCreatingProfile(context),
                status: _creationCompleted
                    ? _SignupProcessingStatus.done
                    : _SignupProcessingStatus.pending,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SignupPanel(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.lock,
                  color: _signupMuted,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _signupCreatingSecurityNote(context),
                  style: _SignupTypography.bodySmall(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotpStep(bool isLoading) {
    return _SignupStepColumn(
      title: _signupTotpTitle(context),
      subtitle: _signupTotpSubtitle(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TotpQrBox(data: _qrCodeUri),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  _NumberedInstruction(
                    number: 1,
                    text: context.tr.authSignupTotpScanInstruction,
                  ),
                  const SizedBox(height: 12),
                  _NumberedInstruction(
                    number: 2,
                    text: context.tr.authSignupTotpCodeLabel,
                  ),
                  const SizedBox(height: 8),
                  AuthMotionShake(
                    triggerKey: _inlineFeedbackPulseKey,
                    enabled: _inlineFeedbackTarget == _SignupErrorTarget.totp,
                    child: _TotpCodeField(
                      controller: _totpController,
                      countdownText: _totpCountdownHint,
                      onChanged: (_) {
                        _clearInlineFeedback();
                        setState(() {});
                      },
                      onSubmitted: (_) => isLoading ? null : _verifyTotp(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
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
        _RecoveryCodeGrid(codes: _backupCodes),
        const SizedBox(height: 22),
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
              LucideIcons.userCheck,
              size: 48,
              color: _signupText,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SignupBullet(
          text: context.tr.authSignupPasskeyBiometricBullet,
          icon: LucideIcons.fingerprint,
        ),
        _SignupBullet(
          text: context.tr.authSignupPasskeyPasswordBullet,
          icon: LucideIcons.shieldCheck,
        ),
        _SignupBullet(
          text: context.tr.authSignupPasskeyDeviceBullet,
          icon: LucideIcons.shieldCheck,
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
      preparingSubtitle: context.tr.authSignupSuccessPreparingSubtitle,
      redirectSubtitle: context.tr.authSignupSuccessSubtitle,
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

String _signupCreatingTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Creating your account.',
    'es' => 'Creando tu cuenta.',
    _ => 'Criando sua conta.',
  };
}

String _signupCreatingSubtitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Please wait a moment.',
    'es' => 'Por favor, espera un momento.',
    _ => 'Por gentileza, aguarde um instante.',
  };
}

String _signupCreatingSecureConnection(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Establishing secure connection',
    'es' => 'Estableciendo conexión segura',
    _ => 'Estabelecendo conexão segura',
  };
}

String _signupCreatingHumanCheck(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Verifying that you are human.',
    'es' => 'Verificando que eres humano.',
    _ => 'Verificando se você é humano.',
  };
}

String _signupCreatingProfile(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Completing profile setup',
    'es' => 'Concluyendo configuración del perfil',
    _ => 'Concluindo configuração do perfil',
  };
}

String _signupCreatingSecurityNote(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' =>
      'Our advanced security protocols preserve the integrity of your experience.',
    'es' =>
      'Nuestros protocolos avanzados de seguridad garantizan la integridad de tu experiencia.',
    _ =>
      'Nossos protocolos avançados de segurança garantem a integridade da sua experiência.',
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

class _SignupTypography {
  const _SignupTypography._();

  static TextStyle title() {
    return GoogleFonts.ebGaramond(
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
    return GoogleFonts.ebGaramond(
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

  static TextStyle percent() {
    return const TextStyle(
      fontFamily: AppTypography.spaceGroteskVariableFamily,
      color: _signupText,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1,
      letterSpacing: 0,
    );
  }
}

class _SignupSuccessScene extends StatefulWidget {
  final String appTitle;
  final String title;
  final String preparingSubtitle;
  final String redirectSubtitle;

  const _SignupSuccessScene({
    required this.appTitle,
    required this.title,
    required this.preparingSubtitle,
    required this.redirectSubtitle,
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
        final progress = _easeInOut(_interval(_controller.value, 0, 1));
        final badgeProgress = AuthMotion.reduce(context)
            ? 1.0
            : _easeInOut(_interval(_controller.value, 0, 0.32));
        final showRedirect = _controller.value >= 0.72;

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
                          Opacity(
                            opacity: badgeProgress,
                            child: Transform.scale(
                              scale: 0.92 + (0.08 * badgeProgress),
                              child: Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _signupText,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  color: _signupText,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            _withTrailingPeriod(widget.title),
                            textAlign: TextAlign.center,
                            style: _SignupTypography.successTitle(),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: Text(
                              showRedirect
                                  ? widget.redirectSubtitle
                                  : widget.preparingSubtitle,
                              key: ValueKey<bool>(showRedirect),
                              textAlign: TextAlign.center,
                              style: _SignupTypography.successSubtitle(),
                            ),
                          ),
                          const SizedBox(height: 44),
                          SizedBox(
                            width: 210,
                            child: _SignupSuccessProgress(
                              progress: progress,
                              showPercent: false,
                            ),
                          ),
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
    return Curves.easeInOutCubic.transform(value.clamp(0.0, 1.0));
  }

  static String _withTrailingPeriod(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('.')) {
      return trimmed;
    }
    return '$trimmed.';
  }
}

class _SignupSuccessProgress extends StatelessWidget {
  final double progress;
  final bool showPercent;

  const _SignupSuccessProgress({
    required this.progress,
    required this.showPercent,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round().clamp(0, 100);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 10,
            child: CustomPaint(
              painter: _SignupSuccessProgressPainter(progress: progress),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: showPercent
              ? Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    '$percent%',
                    style: _SignupTypography.percent(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SignupSuccessProgressPainter extends CustomPainter {
  final double progress;

  const _SignupSuccessProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final start = Offset(0, centerY);
    final end = Offset(size.width, centerY);
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, trackPaint);

    final progressEnd = Offset(size.width * progress.clamp(0, 1), centerY);
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawLine(start, progressEnd, glowPaint);

    final progressPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.98)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, progressEnd, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _SignupSuccessProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
              icon: const Icon(LucideIcons.arrowLeft, size: 24),
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
                      curve: Curves.easeOutCubic,
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
            passed ? LucideIcons.checkCircle2 : LucideIcons.circle,
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
                ? const Icon(LucideIcons.check, size: 13, color: _signupInk)
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

enum _SignupProcessingStatus { done, loading, pending }

class _SignupProcessingRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final _SignupProcessingStatus status;

  const _SignupProcessingRow({
    required this.icon,
    required this.text,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = switch (status) {
      _SignupProcessingStatus.done => const Icon(
          LucideIcons.checkCircle2,
          color: _signupText,
          size: 20,
        ),
      _SignupProcessingStatus.loading => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _signupText,
          ),
        ),
      _SignupProcessingStatus.pending => Icon(
          LucideIcons.circle,
          color: Colors.white.withValues(alpha: 0.35),
          size: 20,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _signupMuted, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: _SignupTypography.bodySmall(color: _signupText),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _TotpQrBox extends StatelessWidget {
  final String data;

  const _TotpQrBox({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _signupText,
        borderRadius: BorderRadius.circular(12),
      ),
      child: data.isEmpty
          ? const Center(
              child: Icon(LucideIcons.qrCode, color: _signupInk, size: 42),
            )
          : QrImageView(data: data, version: QrVersions.auto),
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

class _TotpCodeField extends StatelessWidget {
  final TextEditingController controller;
  final String countdownText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TotpCodeField({
    required this.controller,
    required this.countdownText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _signupBorderSoft),
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: _signupText,
      style: AppTypography.bodyMedium.copyWith(
        fontFamily: AppTypography.spaceGroteskVariableFamily,
        color: _signupText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        hintText: '123 456',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: _signupDim,
          letterSpacing: 1.6,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            countdownText,
            style: _SignupTypography.bodySmall(color: _signupMuted).copyWith(
              color: _signupMuted,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
        ),
      ),
    );
  }
}

class _RecoveryCodeGrid extends StatelessWidget {
  final List<String> codes;

  const _RecoveryCodeGrid({required this.codes});

  @override
  Widget build(BuildContext context) {
    final visibleCodes = codes.isEmpty
        ? const <String>[
            'VZ38 - 7RVK - K9N0',
            'PY05 - 2LTM - R15X',
            'V42T - 828M - K6JP',
            'Y9NF - 3D7S - L8QW',
          ]
        : codes.take(4).toList(growable: false);

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.75,
      children: [
        for (final code in visibleCodes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: _signupField,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _signupBorderSoft),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: AppTypography.technicalMono(
                color: _signupMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
      ],
    );
  }
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
