import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/security/domain/entities/passkey_action_required.dart';

import '../../controller/auth_controller.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';
import 'passkey_verification_components.dart';

const Color _authBlack = AppColors.hexFF000000;

enum _PasskeyPhase { connecting, sending, prompt, totp, success, issue }

class PasskeyVerificationScreen extends ConsumerStatefulWidget {
  final String username;
  final String? fallbackPassphrase;
  final String? fallbackPreAuthToken;

  const PasskeyVerificationScreen({
    super.key,
    required this.username,
    this.fallbackPassphrase,
    this.fallbackPreAuthToken,
  });

  @override
  ConsumerState<PasskeyVerificationScreen> createState() =>
      _PasskeyVerificationScreenState();
}

class _PasskeyVerificationScreenState
    extends ConsumerState<PasskeyVerificationScreen>
    with TickerProviderStateMixin {
  _PasskeyPhase _phase = _PasskeyPhase.connecting;
  final _totpController = TextEditingController();
  late final AnimationController _pulseController;
  PasskeyIssueInfo? _issue;
  bool _isRunningSequence = false;
  bool _isSubmittingTotp = false;
  bool _totpHasError = false;
  String? _totpErrorMessage;
  Timer? _sequenceTimer;
  Completer<bool>? _sequenceCompleter;
  int _transparentChallengeRenewals = 0;
  int _issuePulseKey = 0;
  String? _pendingTotpUsername;
  String? _pendingTotpPassphrase;
  String? _pendingTotpPreAuthToken;
  static const int _maxTransparentChallengeRenewals = 2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.passkeyPulse,
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPasskeySequence();
    });
  }

  bool get _canUseTotpFallback {
    return widget.fallbackPreAuthToken?.trim().isNotEmpty == true;
  }

  Future<void> _startPasskeySequence({
    bool resetChallengeRenewals = true,
  }) async {
    if (_isRunningSequence) return;

    _isRunningSequence = true;
    if (resetChallengeRenewals) {
      _transparentChallengeRenewals = 0;
    }
    ref.read(authControllerProvider.notifier).clearError();

    if (mounted) {
      setState(() {
        _issue = null;
        _totpHasError = false;
        _phase = _PasskeyPhase.connecting;
      });
    }

    final step1 = await _waitForScene(KeroseneMotion.passkeyScene);
    if (!step1 || !mounted) {
      _isRunningSequence = false;
      return;
    }

    setState(() => _phase = _PasskeyPhase.sending);

    final step2 = await _waitForScene(KeroseneMotion.passkeySceneCompact);
    if (!step2 || !mounted) {
      _isRunningSequence = false;
      return;
    }

    setState(() => _phase = _PasskeyPhase.prompt);

    _isRunningSequence = false;
    unawaited(
      ref
          .read(authControllerProvider.notifier)
          .loginWithPasskey(widget.username.trim()),
    );
  }

  Future<bool> _waitForScene(Duration duration) {
    _cancelSequenceWait();
    final completer = Completer<bool>();
    _sequenceCompleter = completer;
    _sequenceTimer = Timer(duration, () {
      _sequenceTimer = null;
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  void _openInlineTotpChallenge(AuthRequiresLoginTotp challenge) {
    setState(() {
      _issue = null;
      _phase = _PasskeyPhase.totp;
      _pendingTotpUsername = challenge.username;
      _pendingTotpPassphrase = challenge.passphrase;
      _pendingTotpPreAuthToken = challenge.preAuthToken;
      _totpHasError = false;
      _totpErrorMessage = null;
      _totpController.clear();
    });
  }

  void _openTotpFallback() {
    final token = widget.fallbackPreAuthToken?.trim();
    if (token == null || token.isEmpty) {
      _goToManualLogin();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _issue = null;
      _phase = _PasskeyPhase.totp;
      _pendingTotpUsername = widget.username.trim();
      _pendingTotpPassphrase = widget.fallbackPassphrase ?? '';
      _pendingTotpPreAuthToken = token;
      _totpHasError = false;
      _totpErrorMessage = null;
      _totpController.clear();
    });
  }

  void _appendTotpDigit(String digit) {
    if (_isSubmittingTotp) return;
    final current = _totpController.text;
    if (current.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _totpHasError = false;
      _totpErrorMessage = null;
      _totpController.text = '$current$digit';
    });
  }

  void _deleteTotpDigit() {
    if (_isSubmittingTotp) return;
    final current = _totpController.text;
    if (current.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _totpHasError = false;
      _totpErrorMessage = null;
      _totpController.text = current.substring(0, current.length - 1);
    });
  }

  void _submitInlineTotp() {
    final code = _totpController.text.replaceAll(RegExp(r'\D'), '');
    final username = _pendingTotpUsername;
    final passphrase = _pendingTotpPassphrase;
    final preAuthToken = _pendingTotpPreAuthToken;
    if (username == null ||
        passphrase == null ||
        preAuthToken == null ||
        code.length != 6) {
      HapticFeedback.lightImpact();
      setState(() {
        _totpHasError = true;
        _totpErrorMessage = _copy(
          pt: 'Informe os 6 dígitos.',
          en: 'Enter all 6 digits.',
          es: 'Ingresa los 6 dígitos.',
        );
        _issuePulseKey += 1;
      });
      return;
    }

    setState(() {
      _isSubmittingTotp = true;
      _totpHasError = false;
      _totpErrorMessage = null;
    });
    ref.read(authControllerProvider.notifier).verifyLoginTotp(
          username: username,
          passphrase: passphrase,
          totpCode: code,
          preAuthToken: preAuthToken,
        );
  }

  void _cancelSequenceWait() {
    _sequenceTimer?.cancel();
    _sequenceTimer = null;
    if (_sequenceCompleter != null && !_sequenceCompleter!.isCompleted) {
      _sequenceCompleter!.complete(false);
    }
    _sequenceCompleter = null;
  }

  Future<void> _goToManualLogin() async {
    ref.read(authControllerProvider.notifier).clearError();
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          username: widget.username.trim(),
          focusPassword: true,
        ),
      ),
    );
  }

  String _copy({required String pt, required String en, required String es}) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  PasskeyIssueInfo _issueFromError(AuthError error) {
    final actionRequired = PasskeyActionRequired.fromDynamic(error.data);
    final translated = ErrorTranslator.translate(
      context.tr,
      error.toString(),
    );
    final code = error.errorCode ?? '';

    if (code == 'USER_NOT_FOUND' ||
        code == 'ERR_AUTH_USER_NOT_FOUND' ||
        error.statusCode == 404) {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.userUnavailable,
        title: context.tr.passkeyVerificationUserNotFound,
        message: translated,
        allowRetry: false,
        allowTotpFallback: false,
      );
    }

    if (code == 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS' ||
        code == 'ERR_AUTH_PASSKEY_NOT_REGISTERED' ||
        code == 'ERR_AUTH_PASSKEY_CORRUPTED_KEY_MATERIAL') {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.passkey,
        title: context.tr.passkeyVerificationNoLocal,
        message: translated,
      );
    }

    if (code == 'ERR_AUTH_PASSKEY_AUTH_CANCELLED') {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.accessDenied,
        title: context.tr.passkeyVerificationCancelled,
        message: translated,
      );
    }

    if (code == 'CHALLENGE_EXPIRED') {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.timerOff,
        title: context.tr.passkeyVerificationChallengeExpired,
        message: translated,
      );
    }

    if (code == 'AUTH_FAILED' ||
        code == 'INVALID_SIGNATURE' ||
        code == 'AUTH_012' ||
        code == 'AUTH_015' ||
        code == 'VERIFY_ERROR' ||
        code == 'MISSING_CREDENTIAL_ID') {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.shieldOff,
        title: context.tr.passkeyVerificationRejected,
        message: translated,
        allowRetry: actionRequired?.canRetryAssertion ?? true,
        allowTotpFallback: actionRequired?.totpFallbackAvailable ?? true,
      );
    }

    if (code == 'AUTH_014' || code == 'AUTH_016' || code == 'AUTH_017') {
      return PasskeyIssueInfo(
        icon: KeroseneIcons.linkUnavailable,
        title: _copy(
          pt: 'Vincule uma nova passkey',
          en: 'Link a new passkey',
          es: 'Vincula una nueva passkey',
        ),
        message: translated,
        allowRetry: false,
        allowTotpFallback: actionRequired?.totpFallbackAvailable ?? true,
      );
    }

    return PasskeyIssueInfo(
      icon: KeroseneIcons.error,
      title: context.tr.passkeyVerificationFailed,
      message: translated,
    );
  }

  bool _isChallengeExpired(AuthError error) {
    final code = error.errorCode ?? '';
    return code == 'CHALLENGE_EXPIRED' || code == 'AUTH_012';
  }

  String _authTitle() {
    if (_phase == _PasskeyPhase.success) {
      return _copy(
        pt: 'Acesso aprovado',
        en: 'Access approved',
        es: 'Acceso aprobado',
      );
    }
    return _copy(
      pt: 'Autenticação',
      en: 'Authentication',
      es: 'Autenticación',
    );
  }

  String _authSubtitle() {
    switch (_phase) {
      case _PasskeyPhase.connecting:
        return context.tr.passkeyVerificationBodyPreparing;
      case _PasskeyPhase.sending:
        return context.tr.passkeyVerificationBodySending;
      case _PasskeyPhase.prompt:
        return _copy(
          pt: 'Toque no sensor para continuar',
          en: 'Touch the sensor to continue',
          es: 'Toca el sensor para continuar',
        );
      case _PasskeyPhase.success:
        return context.tr.passkeyVerificationBodySuccess;
      case _PasskeyPhase.totp:
      case _PasskeyPhase.issue:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading || _isSubmittingTotp;

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (ModalRoute.of(context)?.isCurrent == false) {
        return;
      }

      final navigator = Navigator.of(context);

      if (next is AuthAuthenticated) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        _isSubmittingTotp = false;
        HapticFeedback.lightImpact();
        if (mounted) {
          setState(() {
            _issue = null;
            _phase = _PasskeyPhase.success;
          });
        }
        await Future<void>.delayed(KeroseneMotion.calm);
        if (!context.mounted) {
          return;
        }
        HomeScreen.skipNextAuth = true;
        navigator.pushNamedAndRemoveUntil('/home_loading', (route) => false);
      } else if (next is AuthRequiresLoginTotp) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        _isSubmittingTotp = false;
        HapticFeedback.lightImpact();
        if (mounted) {
          _openInlineTotpChallenge(next);
        }
      } else if (next is AuthError) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        _isSubmittingTotp = false;
        if (_isChallengeExpired(next) &&
            _transparentChallengeRenewals < _maxTransparentChallengeRenewals) {
          _transparentChallengeRenewals++;
          if (mounted) {
            setState(() {
              _issue = null;
              _phase = _PasskeyPhase.connecting;
            });
          }
          await Future<void>.delayed(KeroseneMotion.medium);
          if (mounted) {
            unawaited(_startPasskeySequence(resetChallengeRenewals: false));
          }
          return;
        }
        if (_phase == _PasskeyPhase.totp) {
          if (mounted) {
            HapticFeedback.lightImpact();
            setState(() {
              _totpHasError = true;
              _totpErrorMessage = ErrorTranslator.translate(
                context.tr,
                next.toString(),
              );
              _issuePulseKey += 1;
            });
          }
          return;
        }
        if (mounted) {
          HapticFeedback.lightImpact();
          setState(() {
            _issue = _issueFromError(next);
            _phase = _PasskeyPhase.issue;
            _totpHasError = false;
            _issuePulseKey += 1;
          });
        }
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _authBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _authBlack,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final responsive = context.responsive;
              final horizontalPadding =
                  responsive.isTinyPhone ? AppSpacing.base : AppSpacing.lg;
              final isShort = constraints.maxHeight < 560;
              final topInset = isShort ? 54.0 : 72.0;
              final bottomInset = isShort ? AppSpacing.md : AppSpacing.xl;

              return Stack(
                children: [
                  Positioned(
                    top: 4,
                    left: horizontalPadding - 8,
                    child: TopBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topInset,
                        horizontalPadding,
                        bottomInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            constraints.maxHeight - topInset - bottomInset,
                          ),
                        ),
                        child: Center(
                          child: _buildPhaseContent(
                            isLoading: isLoading,
                            isShort: isShort,
                            responsive: responsive,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent({
    required bool isLoading,
    required bool isShort,
    required KeroseneResponsiveMetrics responsive,
  }) {
    switch (_phase) {
      case _PasskeyPhase.issue:
        return PasskeyIssueView(
          issue: _issue,
          isShort: isShort,
          canRetry: _issue?.allowRetry == true,
          canUseTotp: _issue?.allowTotpFallback == true && _canUseTotpFallback,
          onRetry: isLoading ? null : _startPasskeySequence,
          onUseTotp: isLoading ? null : _openTotpFallback,
          onBackToPassword: isLoading ? null : _goToManualLogin,
          copy: _copy,
        );
      case _PasskeyPhase.totp:
        return TotpFallbackView(
          code: _totpController.text,
          hasError: _totpHasError,
          errorMessage: _totpErrorMessage,
          errorPulseKey: _issuePulseKey,
          isLoading: isLoading,
          isShort: isShort,
          responsive: responsive,
          onDigit: _appendTotpDigit,
          onDelete: _deleteTotpDigit,
          onSubmit: _submitInlineTotp,
          copy: _copy,
        );
      case _PasskeyPhase.connecting:
      case _PasskeyPhase.sending:
      case _PasskeyPhase.prompt:
      case _PasskeyPhase.success:
        return PasskeyAuthView(
          animation: _pulseController,
          title: _authTitle(),
          subtitle: _authSubtitle(),
          isShort: isShort,
          isSuccess: _phase == _PasskeyPhase.success,
        );
    }
  }

  @override
  void dispose() {
    _cancelSequenceWait();
    _pulseController.dispose();
    _totpController.dispose();
    super.dispose();
  }
}
