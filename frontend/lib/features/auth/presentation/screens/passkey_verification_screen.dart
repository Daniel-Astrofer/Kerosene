import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/l10n/l10n_extension.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/presentation/widgets/auth_motion.dart';
import 'package:teste/features/security/domain/entities/passkey_action_required.dart';

import '../../controller/auth_controller.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';

const Color _authBlack = Color(0xFF000000);
const Color _authWhite = Color(0xFFFFFFFF);
const Color _authMuted = Color(0xFFA3A3A3);
const Color _authSurface = Color(0xFF141313);
const Color _authSurfaceRaised = Color(0xFF1C1C1E);
const Color _authBorder = Color(0xFF2A2A2A);
const Color _authErrorText = Color(0xFFF4C7C7);
const Color _authSuccess = Color(0xFF4ADE80);

enum _PasskeyPhase { connecting, sending, prompt, totp, success, issue }

class _IssueInfo {
  final IconData icon;
  final String title;
  final String message;
  final bool allowRetry;
  final bool allowTotpFallback;

  const _IssueInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.allowRetry = true,
    this.allowTotpFallback = true,
  });
}

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
  _IssueInfo? _issue;
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
      duration: const Duration(milliseconds: 5000),
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

    final step1 = await _waitForScene(const Duration(milliseconds: 900));
    if (!step1 || !mounted) {
      _isRunningSequence = false;
      return;
    }

    setState(() => _phase = _PasskeyPhase.sending);

    final step2 = await _waitForScene(const Duration(milliseconds: 760));
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

  _IssueInfo _issueFromError(AuthError error) {
    final actionRequired = PasskeyActionRequired.fromDynamic(error.data);
    final translated = ErrorTranslator.translate(
      context.tr,
      error.toString(),
    );
    final code = error.errorCode ?? '';

    if (code == 'USER_NOT_FOUND' ||
        code == 'ERR_AUTH_USER_NOT_FOUND' ||
        error.statusCode == 404) {
      return _IssueInfo(
        icon: LucideIcons.userX,
        title: AppCopy.passkeyVerificationUserNotFound.resolve(context),
        message: translated,
        allowRetry: false,
        allowTotpFallback: false,
      );
    }

    if (code == 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS' ||
        code == 'ERR_AUTH_PASSKEY_NOT_REGISTERED' ||
        code == 'ERR_AUTH_PASSKEY_CORRUPTED_KEY_MATERIAL') {
      return _IssueInfo(
        icon: LucideIcons.keyRound,
        title: AppCopy.passkeyVerificationNoLocal.resolve(context),
        message: translated,
      );
    }

    if (code == 'ERR_AUTH_PASSKEY_AUTH_CANCELLED') {
      return _IssueInfo(
        icon: LucideIcons.ban,
        title: AppCopy.passkeyVerificationCancelled.resolve(context),
        message: translated,
      );
    }

    if (code == 'CHALLENGE_EXPIRED') {
      return _IssueInfo(
        icon: LucideIcons.timerOff,
        title: AppCopy.passkeyVerificationChallengeExpired.resolve(context),
        message: translated,
      );
    }

    if (code == 'AUTH_FAILED' ||
        code == 'INVALID_SIGNATURE' ||
        code == 'AUTH_012' ||
        code == 'AUTH_015' ||
        code == 'VERIFY_ERROR' ||
        code == 'MISSING_CREDENTIAL_ID') {
      return _IssueInfo(
        icon: LucideIcons.shieldOff,
        title: AppCopy.passkeyVerificationRejected.resolve(context),
        message: translated,
        allowRetry: actionRequired?.canRetryAssertion ?? true,
        allowTotpFallback: actionRequired?.totpFallbackAvailable ?? true,
      );
    }

    if (code == 'AUTH_014' || code == 'AUTH_016' || code == 'AUTH_017') {
      return _IssueInfo(
        icon: LucideIcons.link2Off,
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

    return _IssueInfo(
      icon: LucideIcons.alertTriangle,
      title: AppCopy.passkeyVerificationFailed.resolve(context),
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
        return AppCopy.passkeyVerificationBodyPreparing.resolve(context);
      case _PasskeyPhase.sending:
        return AppCopy.passkeyVerificationBodySending.resolve(context);
      case _PasskeyPhase.prompt:
        return _copy(
          pt: 'Toque no sensor para continuar',
          en: 'Touch the sensor to continue',
          es: 'Toca el sensor para continuar',
        );
      case _PasskeyPhase.success:
        return AppCopy.passkeyVerificationBodySuccess.resolve(context);
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
        await Future<void>.delayed(const Duration(milliseconds: 1000));
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
          await Future<void>.delayed(const Duration(milliseconds: 250));
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
                    child: _TopBackButton(
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
        return _PasskeyIssueView(
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
        return _TotpFallbackView(
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
        return _PasskeyAuthView(
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

class _TopBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TopBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onPressed,
          icon: const Icon(LucideIcons.arrowLeft, size: 24),
          color: _authWhite.withValues(alpha: 0.84),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PasskeyAuthView extends StatelessWidget {
  final Animation<double> animation;
  final String title;
  final String subtitle;
  final bool isShort;
  final bool isSuccess;

  const _PasskeyAuthView({
    required this.animation,
    required this.title,
    required this.subtitle,
    required this.isShort,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final sensorSize = responsive.isTinyPhone
        ? 196.0
        : isShort
            ? 156.0
            : 256.0;
    final iconSize = sensorSize * 0.42;
    final titleSize = responsive.isTinyPhone
        ? 34.0
        : isShort
            ? 32.0
            : 42.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SensorVisualizer(
            animation: animation,
            size: sensorSize,
            iconSize: iconSize,
            isSuccess: isSuccess,
          ),
          SizedBox(height: isShort ? AppSpacing.lg : 46),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
              color: _authWhite,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.08,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authMuted,
              fontSize: responsive.isTinyPhone ? 14 : 16,
              fontWeight: FontWeight.w300,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorVisualizer extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final double iconSize;
  final bool isSuccess;

  const _SensorVisualizer({
    required this.animation,
    required this.size,
    required this.iconSize,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final waveA = math.sin(animation.value * math.pi * 2);
          final waveB = math.sin((animation.value * math.pi * 2) + math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(
                size: size,
                scale: 0.92 + waveB * 0.08,
                opacity: 0.30 + waveB.abs() * 0.18,
                inset: 0,
              ),
              _PulseRing(
                size: size,
                scale: 0.88 + waveA * 0.10,
                opacity: 0.42 + waveA.abs() * 0.22,
                inset: size * 0.07,
              ),
              Container(
                width: size * 0.64,
                height: size * 0.64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _authSurface.withValues(alpha: 0.74),
                  border: Border.all(
                    color: _authWhite.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  isSuccess ? LucideIcons.shieldCheck : LucideIcons.fingerprint,
                  size: iconSize,
                  color: isSuccess ? _authSuccess : _authWhite,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double size;
  final double scale;
  final double opacity;
  final double inset;

  const _PulseRing({
    required this.size,
    required this.scale,
    required this.opacity,
    required this.inset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size - inset * 2,
        height: size - inset * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _authWhite.withValues(alpha: opacity.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}

class _PasskeyIssueView extends StatelessWidget {
  final _IssueInfo? issue;
  final bool isShort;
  final bool canRetry;
  final bool canUseTotp;
  final VoidCallback? onRetry;
  final VoidCallback? onUseTotp;
  final VoidCallback? onBackToPassword;
  final String Function({
    required String pt,
    required String en,
    required String es,
  }) copy;

  const _PasskeyIssueView({
    required this.issue,
    required this.isShort,
    required this.canRetry,
    required this.canUseTotp,
    required this.onRetry,
    required this.onUseTotp,
    required this.onBackToPassword,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final titleSize = responsive.isTinyPhone
        ? 32.0
        : isShort
            ? 30.0
            : 38.0;
    final message = issue?.message ??
        copy(
          pt: 'Biometria não reconhecida. Tente novamente ou use outro método.',
          en: 'Biometrics were not recognized. Try again or use another method.',
          es: 'Biometría no reconocida. Intenta de nuevo o usa otro método.',
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ErrorGlyph(size: isShort ? 92 : 120, icon: issue?.icon),
          SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xl),
          Text(
            copy(
              pt: 'Falha na Autenticação',
              en: 'Authentication Failed',
              es: 'Falló la Autenticación',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
              color: _authWhite.withValues(alpha: 0.96),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.12,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authErrorText,
              fontSize: responsive.isTinyPhone ? 14 : 15,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: isShort ? AppSpacing.xl : 58),
          if (canRetry)
            _ActionButton(
              text: copy(
                pt: 'Tentar novamente',
                en: 'Try again',
                es: 'Intentar de nuevo',
              ).toUpperCase(),
              onPressed: onRetry,
            ),
          if (canRetry) const SizedBox(height: AppSpacing.md),
          if (canUseTotp)
            _ActionButton(
              text: copy(
                pt: 'Usar TOTP',
                en: 'Use TOTP',
                es: 'Usar TOTP',
              ).toUpperCase(),
              onPressed: onUseTotp,
              secondary: true,
            )
          else
            _ActionButton(
              text: copy(
                pt: 'Voltar para senha',
                en: 'Back to password',
                es: 'Volver a contraseña',
              ).toUpperCase(),
              onPressed: onBackToPassword,
              secondary: true,
            ),
        ],
      ),
    );
  }
}

class _ErrorGlyph extends StatelessWidget {
  final double size;
  final IconData? icon;

  const _ErrorGlyph({
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _authSurface,
              border: Border.all(color: _authErrorText.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: _authErrorText.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon ?? LucideIcons.fingerprint,
              color: _authErrorText,
              size: size * 0.46,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: _authErrorText,
                shape: BoxShape.circle,
                border: Border.all(color: _authBlack, width: 2),
              ),
              child: Icon(
                LucideIcons.alertCircle,
                size: size * 0.16,
                color: _authBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotpFallbackView extends StatelessWidget {
  final String code;
  final bool hasError;
  final String? errorMessage;
  final int errorPulseKey;
  final bool isLoading;
  final bool isShort;
  final KeroseneResponsiveMetrics responsive;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final String Function({
    required String pt,
    required String en,
    required String es,
  }) copy;

  const _TotpFallbackView({
    required this.code,
    required this.hasError,
    required this.errorMessage,
    required this.errorPulseKey,
    required this.isLoading,
    required this.isShort,
    required this.responsive,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = responsive.isTinyPhone
        ? 34.0
        : isShort
            ? 31.0
            : 40.0;
    final keypadGap = isShort ? AppSpacing.xs : AppSpacing.md;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copy(
              pt: 'Código de Segurança',
              en: 'Security Code',
              es: 'Código de Seguridad',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
              color: _authWhite,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            copy(
              pt: 'Insira o código de 6 dígitos do seu app autenticador',
              en: 'Enter the 6-digit code from your authenticator app',
              es: 'Ingresa el código de 6 dígitos de tu app autenticadora',
            ),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: _authMuted,
              fontSize: responsive.isTinyPhone ? 14 : 16,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: isShort ? AppSpacing.lg : 48),
          AuthMotionShake(
            triggerKey: errorPulseKey,
            enabled: hasError,
            child: _PinDots(codeLength: code.length, hasError: hasError),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: _authErrorText,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ],
          SizedBox(height: isShort ? AppSpacing.lg : 46),
          _TotpKeypad(
            isShort: isShort,
            gap: keypadGap,
            onDigit: isLoading ? null : onDigit,
            onDelete: isLoading ? null : onDelete,
          ),
          SizedBox(height: isShort ? AppSpacing.lg : AppSpacing.xl),
          _ActionButton(
            text: copy(
              pt: 'Confirmar',
              en: 'Confirm',
              es: 'Confirmar',
            ),
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int codeLength;
  final bool hasError;

  const _PinDots({
    required this.codeLength,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < codeLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? _authWhite
                : hasError
                    ? _authErrorText.withValues(alpha: 0.12)
                    : _authSurface,
            border: Border.all(
              color: filled
                  ? _authWhite
                  : hasError
                      ? _authErrorText
                      : _authBorder,
            ),
          ),
        );
      }),
    );
  }
}

class _TotpKeypad extends StatelessWidget {
  final bool isShort;
  final double gap;
  final ValueChanged<String>? onDigit;
  final VoidCallback? onDelete;

  const _TotpKeypad({
    required this.isShort,
    required this.gap,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _KeypadRow(values: const ['1', '2', '3'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        _KeypadRow(values: const ['4', '5', '6'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        _KeypadRow(values: const ['7', '8', '9'], gap: gap, onDigit: onDigit),
        SizedBox(height: gap),
        Row(
          children: [
            const Expanded(child: SizedBox(height: 58)),
            SizedBox(width: gap),
            Expanded(
              child: _KeypadButton(
                value: '0',
                isShort: isShort,
                onPressed: onDigit == null ? null : () => onDigit?.call('0'),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _KeypadButton(
                icon: LucideIcons.delete,
                isShort: isShort,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadRow extends StatelessWidget {
  final List<String> values;
  final double gap;
  final ValueChanged<String>? onDigit;

  const _KeypadRow({
    required this.values,
    required this.gap,
    required this.onDigit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          Expanded(
            child: _KeypadButton(
              value: values[index],
              onPressed:
                  onDigit == null ? null : () => onDigit?.call(values[index]),
            ),
          ),
          if (index != values.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? value;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isShort;

  const _KeypadButton({
    this.value,
    this.icon,
    this.onPressed,
    this.isShort = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthMotionPressScale(
      enabled: onPressed != null,
      child: SizedBox(
        height: isShort ? 46 : 64,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: _authMuted, size: 22)
                  : Text(
                      value ?? '',
                      style: GoogleFonts.ibmPlexSerif(
                        color: _authWhite,
                        fontSize: isShort ? 25 : 29,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool isLoading;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.secondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background = secondary ? _authSurfaceRaised : _authWhite;
    final foreground = secondary ? _authWhite : _authBlack;

    return AuthMotionPressScale(
      enabled: !disabled,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed?.call();
                  },
            child: Ink(
              decoration: BoxDecoration(
                color:
                    disabled ? background.withValues(alpha: 0.42) : background,
                border: Border.all(
                  color: secondary ? _authSurfaceRaised : Colors.transparent,
                ),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.buttonText.copyWith(
                          color: disabled
                              ? foreground.withValues(alpha: 0.7)
                              : foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
