import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/features/security/domain/entities/passkey_action_required.dart';
import 'package:teste/l10n/l10n_extension.dart';

import '../../controller/auth_controller.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_passphrase_screen.dart';
import 'totp_screen.dart';

enum _PasskeyPhase { connecting, sending, prompt, success, issue }

class _IssueInfo {
  final IconData icon;
  final String title;
  final String message;
  final bool allowRetry;
  final bool allowManualFallback;

  const _IssueInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.allowRetry = true,
    this.allowManualFallback = true,
  });
}

class PasskeyVerificationScreen extends ConsumerStatefulWidget {
  final String username;

  const PasskeyVerificationScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<PasskeyVerificationScreen> createState() =>
      _PasskeyVerificationScreenState();
}

class _PasskeyVerificationScreenState
    extends ConsumerState<PasskeyVerificationScreen> {
  _PasskeyPhase _phase = _PasskeyPhase.connecting;
  _IssueInfo? _issue;
  bool _isRunningSequence = false;
  Timer? _sequenceTimer;
  Completer<bool>? _sequenceCompleter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPasskeySequence();
    });
  }

  Future<void> _startPasskeySequence() async {
    if (_isRunningSequence) return;

    _isRunningSequence = true;
    ref.read(authControllerProvider.notifier).clearError();

    if (mounted) {
      setState(() {
        _issue = null;
        _phase = _PasskeyPhase.connecting;
      });
    }

    final step1 = await _waitForScene(const Duration(milliseconds: 1100));
    if (!step1 || !mounted) {
      _isRunningSequence = false;
      return;
    }

    setState(() => _phase = _PasskeyPhase.sending);

    final step2 = await _waitForScene(const Duration(milliseconds: 1000));
    if (!step2 || !mounted) {
      _isRunningSequence = false;
      return;
    }

    setState(() => _phase = _PasskeyPhase.prompt);

    _isRunningSequence = false;
    unawaited(
      ref.read(authControllerProvider.notifier).loginWithPasskey(
            widget.username.trim(),
          ),
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
        builder: (context) => LoginPassphraseScreen(
          username: widget.username.trim(),
        ),
      ),
    );
  }

  String _copy({
    required String pt,
    required String en,
    required String es,
  }) {
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
      context.l10n,
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
        allowManualFallback: false,
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
        allowManualFallback: actionRequired?.totpFallbackAvailable ?? true,
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
        allowManualFallback: actionRequired?.totpFallbackAvailable ?? true,
      );
    }

    return _IssueInfo(
      icon: LucideIcons.alertTriangle,
      title: AppCopy.passkeyVerificationFailed.resolve(context),
      message: translated,
    );
  }

  int _activeStepIndex() {
    switch (_phase) {
      case _PasskeyPhase.connecting:
        return 0;
      case _PasskeyPhase.sending:
        return 1;
      case _PasskeyPhase.prompt:
      case _PasskeyPhase.success:
      case _PasskeyPhase.issue:
        return 2;
    }
  }

  String _phaseLabel() {
    if (_issue != null) return _issue!.title;

    switch (_phase) {
      case _PasskeyPhase.connecting:
        return AppCopy.passkeyVerificationHeadlinePreparing.resolve(context);
      case _PasskeyPhase.sending:
        return AppCopy.passkeyVerificationHeadlineSending.resolve(context);
      case _PasskeyPhase.prompt:
        return AppCopy.passkeyVerificationHeadlineDevice.resolve(context);
      case _PasskeyPhase.success:
        return AppCopy.passkeyVerificationHeadlineSuccess.resolve(context);
      case _PasskeyPhase.issue:
        return _issue?.title ?? '';
    }
  }

  String _phaseBody() {
    if (_issue != null) return _issue!.message;

    switch (_phase) {
      case _PasskeyPhase.connecting:
        return AppCopy.passkeyVerificationBodyPreparing.resolve(context);
      case _PasskeyPhase.sending:
        return AppCopy.passkeyVerificationBodySending.resolve(context);
      case _PasskeyPhase.prompt:
        return AppCopy.passkeyVerificationBodyDevice.resolve(context);
      case _PasskeyPhase.success:
        return AppCopy.passkeyVerificationBodySuccess.resolve(context);
      case _PasskeyPhase.issue:
        return _issue?.message ?? '';
    }
  }

  IconData _phaseIcon() {
    if (_issue != null) return _issue!.icon;

    switch (_phase) {
      case _PasskeyPhase.connecting:
        return LucideIcons.radio;
      case _PasskeyPhase.sending:
        return LucideIcons.send;
      case _PasskeyPhase.prompt:
        return LucideIcons.fingerprint;
      case _PasskeyPhase.success:
        return LucideIcons.shieldCheck;
      case _PasskeyPhase.issue:
        return _issue?.icon ?? LucideIcons.alertTriangle;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      final navigator = Navigator.of(context);

      if (next is AuthAuthenticated) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        if (mounted) {
          setState(() {
            _issue = null;
            _phase = _PasskeyPhase.success;
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!context.mounted) {
          return;
        }
        HomeScreen.skipNextAuth = true;
        navigator.pushNamedAndRemoveUntil('/home_loading', (route) => false);
      } else if (next is AuthRequiresLoginTotp) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        if (mounted) {
          setState(() {
            _issue = null;
            _phase = _PasskeyPhase.success;
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (!context.mounted) {
          return;
        }
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => TotpScreen(
              username: next.username,
              passphrase: next.passphrase,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthError) {
        _cancelSequenceWait();
        _isRunningSequence = false;
        if (mounted) {
          setState(() {
            _issue = _issueFromError(next);
            _phase = _PasskeyPhase.issue;
          });
        }
      }
    });

    final isIssue = _phase == _PasskeyPhase.issue;
    final isSuccess = _phase == _PasskeyPhase.success;

    return AuthEntryScaffold(
      eyebrow: AppCopy.passkeyVerificationScreenTitle.resolve(context),
      title: _phaseLabel(),
      subtitle: _phaseBody(),
      onBack: () => Navigator.pop(context),
      trailing: [
        _PasskeyUserChip(username: widget.username.trim()),
      ],
      child: AuthEntryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasskeyStatusBlock(
              icon: _phaseIcon(),
              stepIndex: _activeStepIndex(),
              isSuccess: isSuccess,
              isIssue: isIssue,
            ),
            if (isIssue && _issue != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AuthEntryNote(
                icon: _issue!.icon,
                title: _issue!.title,
                body: _issue!.message,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (isIssue && _issue != null && _issue!.allowRetry)
              AuthEntryButton(
                text: AppCopy.passkeyVerificationRetry
                    .resolve(context)
                    .toUpperCase(),
                icon: LucideIcons.refreshCw,
                onPressed: _startPasskeySequence,
              ),
            if (isIssue && _issue != null && _issue!.allowRetry)
              const SizedBox(height: AppSpacing.sm),
            if (isIssue && _issue != null && _issue!.allowManualFallback)
              AuthEntryButton(
                text: AppCopy.passkeyVerificationUsePassphrase
                    .resolve(context)
                    .toUpperCase(),
                outlined: true,
                onPressed: _goToManualLogin,
              ),
            if (!isIssue) ...[
              AuthEntryButton(
                text: AppCopy.passkeyVerificationUsePassphrase
                    .resolve(context)
                    .toUpperCase(),
                outlined: true,
                onPressed: _goToManualLogin,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppCopy.passkeyVerificationFallbackHint.resolve(context),
                style: AppTypography.bodySmall.copyWith(
                  color: authEntryFaint,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelSequenceWait();
    super.dispose();
  }
}

class _PasskeyUserChip extends StatelessWidget {
  final String username;
  const _PasskeyUserChip({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: authEntrySurface,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        '@$username',
        style: AppTypography.caption.copyWith(
          fontFamily: 'JetBrainsMono',
          color: authEntryMuted,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PasskeyStatusBlock extends StatelessWidget {
  final IconData icon;
  final int stepIndex;
  final bool isSuccess;
  final bool isIssue;

  const _PasskeyStatusBlock({
    required this.icon,
    required this.stepIndex,
    required this.isSuccess,
    required this.isIssue,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['CONECTANDO', 'TRANSFERINDO', 'VERIFICANDO'];

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: authEntrySurfaceRaised,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 24,
              color: isSuccess
                  ? const Color(0xFF4ADE80)
                  : isIssue
                      ? const Color(0xFFF59E0B)
                      : authEntryText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: List.generate(3, (index) {
            final isActive = index <= stepIndex;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isSuccess
                                ? const Color(0xFF4ADE80)
                                : isIssue
                                    ? const Color(0xFFF59E0B)
                                    : authEntryText)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepLabels[index],
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: isActive ? authEntryMuted : authEntryFaint,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
