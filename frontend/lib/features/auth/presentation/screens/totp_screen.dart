import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/widgets/auth_action_illustration.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/l10n/l10n_extension.dart';

enum _TotpSceneState {
  review,
  verifying,
  success,
  issue,
}

class _TotpIssueData {
  final AuthActionIllustrationMode illustrationMode;
  final Color accentColor;
  final String title;
  final String message;
  final bool clearCode;

  const _TotpIssueData({
    required this.illustrationMode,
    required this.accentColor,
    required this.title,
    required this.message,
    this.clearCode = false,
  });
}

class TotpScreen extends ConsumerStatefulWidget {
  final String username;
  final String passphrase;
  final bool isSetup;
  final String? totpSecret;
  final String? qrCodeUri;
  final String? preAuthToken;

  const TotpScreen({
    super.key,
    required this.username,
    required this.passphrase,
    required this.isSetup,
    this.totpSecret,
    this.qrCodeUri,
    this.preAuthToken,
  });

  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  _TotpSceneState _sceneState = _TotpSceneState.review;
  _TotpIssueData? _issue;
  int _errorPulseKey = 0;
  bool _didScheduleNavigation = false;

  bool get _isSetupMode => widget.isSetup;
  String get _currentCode => _codeController.text.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  String _t({
    required String pt,
    required String en,
    required String es,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'pt' => pt,
      'es' => es,
      _ => en,
    };
  }

  void _handleCodeChanged(String code) {
    if (!mounted) {
      return;
    }

    if (_issue == null && _sceneState != _TotpSceneState.issue) {
      return;
    }

    setState(() {
      _issue = null;
      _sceneState = _TotpSceneState.review;
      _didScheduleNavigation = false;
    });
  }

  void _focusCodeInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _codeFocusNode.requestFocus();
      }
    });
  }

  void _presentIssue(_TotpIssueData issue) {
    if (issue.clearCode) {
      _codeController.clear();
    }

    HapticFeedback.heavyImpact();
    _focusCodeInput();

    if (!mounted) {
      return;
    }

    setState(() {
      _issue = issue;
      _sceneState = _TotpSceneState.issue;
      _didScheduleNavigation = false;
      _errorPulseKey += 1;
    });
  }

  _TotpIssueData _missingDigitsIssue() {
    return _TotpIssueData(
      illustrationMode: AuthActionIllustrationMode.warning,
      accentColor: AppColors.warning,
      title: _t(
        pt: 'Digite os 6 digitos',
        en: 'Enter all 6 digits',
        es: 'Ingresa los 6 digitos',
      ),
      message: context.l10n.totpEnter6Digits,
    );
  }

  _TotpIssueData _issueFromError(AuthError error) {
    final translated = ErrorTranslator.translate(
      context.l10n,
      error.toString(),
    );
    final code = error.errorCode ?? '';

    if (code == 'ERR_AUTH_INCORRECT_TOTP') {
      return _TotpIssueData(
        illustrationMode: AuthActionIllustrationMode.keyRejected,
        accentColor: Theme.of(context).colorScheme.error,
        title: _t(
          pt: 'Codigo incorreto',
          en: 'Incorrect code',
          es: 'Codigo incorrecto',
        ),
        message: translated,
        clearCode: true,
      );
    }

    if (code == 'ERR_AUTH_TOTP_TIMEOUT' || code == 'CHALLENGE_EXPIRED') {
      return _TotpIssueData(
        illustrationMode: AuthActionIllustrationMode.sessionExpired,
        accentColor: AppColors.warning,
        title: _t(
          pt: 'Codigo expirado',
          en: 'Expired code',
          es: 'Codigo expirado',
        ),
        message: translated,
        clearCode: true,
      );
    }

    if (code == 'ERR_AUTH_USER_NOT_FOUND' || code == 'USER_NOT_FOUND') {
      return _TotpIssueData(
        illustrationMode: AuthActionIllustrationMode.userMissing,
        accentColor: Theme.of(context).colorScheme.error,
        title: _t(
          pt: 'Usuario nao encontrado',
          en: 'User not found',
          es: 'Usuario no encontrado',
        ),
        message: translated,
      );
    }

    return _TotpIssueData(
      illustrationMode: AuthActionIllustrationMode.warning,
      accentColor: AppColors.warning,
      title: _t(
        pt: 'Nao foi possivel validar',
        en: 'Could not verify the code',
        es: 'No fue posible validar el codigo',
      ),
      message: translated,
    );
  }

  void _submitCurrentCode() {
    final authState = ref.read(authControllerProvider);
    if (authState is AuthLoading) {
      return;
    }

    if (_currentCode.length != 6) {
      _presentIssue(_missingDigitsIssue());
      return;
    }

    HapticFeedback.lightImpact();
    ref.read(authControllerProvider.notifier).clearError();

    setState(() {
      _issue = null;
      _sceneState = _TotpSceneState.verifying;
    });

    if (_isSetupMode) {
      ref.read(authControllerProvider.notifier).verifyTotp(
            username: widget.username,
            passphrase: widget.passphrase,
            totpSecret: widget.totpSecret ?? '',
            totpCode: _currentCode,
          );
      return;
    }

    ref.read(authControllerProvider.notifier).verifyLoginTotp(
          username: widget.username,
          passphrase: widget.passphrase,
          totpCode: _currentCode,
          preAuthToken: widget.preAuthToken,
        );
  }

  Future<void> _handleSuccess(AuthState next) async {
    if (!mounted) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _issue = null;
      _sceneState = _TotpSceneState.success;
    });

    if (_didScheduleNavigation) {
      return;
    }
    _didScheduleNavigation = true;

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    if (next is AuthAuthenticated) {
      HomeScreen.skipNextAuth = true;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home_loading', (route) => false);
      return;
    }

    if (next is AuthTotpVerified) {
      await Navigator.of(context).maybePop(next);
    }
  }

  AuthActionIllustrationMode _illustrationMode() {
    if (_issue != null) {
      return _issue!.illustrationMode;
    }

    switch (_sceneState) {
      case _TotpSceneState.review:
        return _isSetupMode
            ? AuthActionIllustrationMode.recoveryCodes
            : AuthActionIllustrationMode.connectingServer;
      case _TotpSceneState.verifying:
        return AuthActionIllustrationMode.keyTransfer;
      case _TotpSceneState.success:
        return AuthActionIllustrationMode.shieldSuccess;
      case _TotpSceneState.issue:
        return _issue?.illustrationMode ?? AuthActionIllustrationMode.warning;
    }
  }

  Color _baseAccentColor(BuildContext context) {
    return _isSetupMode
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
  }

  Color _accentColor(BuildContext context) {
    if (_sceneState == _TotpSceneState.success) {
      return AppColors.success;
    }
    if (_issue != null) {
      return _issue!.accentColor;
    }
    return _baseAccentColor(context);
  }

  int _activeStepIndex() {
    switch (_sceneState) {
      case _TotpSceneState.review:
      case _TotpSceneState.issue:
        return 0;
      case _TotpSceneState.verifying:
        return 1;
      case _TotpSceneState.success:
        return 2;
    }
  }

  String _headline() {
    if (_issue != null) {
      return _issue!.title;
    }

    switch (_sceneState) {
      case _TotpSceneState.review:
        return _isSetupMode
            ? context.l10n.totpSetupTitle
            : _t(
                pt: 'Confirme seu autenticador',
                en: 'Confirm your authenticator',
                es: 'Confirma tu autenticador',
              );
      case _TotpSceneState.verifying:
        return context.l10n.totpVerifying;
      case _TotpSceneState.success:
        return _t(
          pt: 'Codigo confirmado',
          en: 'Code confirmed',
          es: 'Codigo confirmado',
        );
      case _TotpSceneState.issue:
        return _issue?.title ?? '';
    }
  }

  String _body() {
    if (_issue != null) {
      return _issue!.message;
    }

    switch (_sceneState) {
      case _TotpSceneState.review:
        if (_isSetupMode) {
          return context.l10n.totpSetupSubtitle;
        }
        return _t(
          pt: 'Abra o autenticador, confira o codigo atual e conclua a verificacao do login com 6 digitos.',
          en: 'Open your authenticator app, check the current code, and complete sign-in verification with 6 digits.',
          es: 'Abre tu aplicacion autenticadora, revisa el codigo actual y completa la verificacion del acceso con 6 digitos.',
        );
      case _TotpSceneState.verifying:
        return _isSetupMode
            ? context.l10n.totpAuthenticating
            : context.l10n.totpEstablishingSession;
      case _TotpSceneState.success:
        return _isSetupMode
            ? _t(
                pt: 'O autenticador foi validado. A proxima etapa pode continuar agora.',
                en: 'The authenticator was validated. The next step can continue now.',
                es: 'El autenticador fue validado. El siguiente paso ya puede continuar.',
              )
            : _t(
                pt: 'O codigo foi aceito. Sua sessao esta sendo liberada agora.',
                en: 'The code was accepted. Your session is being opened now.',
                es: 'El codigo fue aceptado. Tu sesion se esta abriendo ahora.',
              );
      case _TotpSceneState.issue:
        return _issue?.message ?? '';
    }
  }

  String _primaryButtonText() {
    if (_sceneState == _TotpSceneState.verifying) {
      return context.l10n.totpVerifying;
    }
    return _isSetupMode
        ? context.l10n.totpVerifyButton
        : context.l10n.totpVerifyContinue;
  }

  Widget _buildSetupArtifacts(BuildContext context, Color accentColor) {
    if (!_isSetupMode) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.18),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: widget.qrCodeUri != null && widget.qrCodeUri!.isNotEmpty
                  ? QrImageView(
                      data: widget.qrCodeUri!,
                      version: QrVersions.auto,
                      size: 176,
                    )
                  : Icon(
                      LucideIcons.qrCode,
                      size: 120,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(
                  pt: 'SEGREDO TOTP',
                  en: 'TOTP SECRET',
                  es: 'SECRETO TOTP',
                ),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.totpSecret ?? '•••• •••• •••• ••••',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontFamily: 'IBM Plex Mono',
                            letterSpacing: 1.3,
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportPanel(BuildContext context, Color accentColor) {
    final message = _issue?.message ??
        (_isSetupMode
            ? context.l10n.totpHint
            : context.l10n.unknownDeviceHelper);
    final panelColor = _issue != null
        ? accentColor.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.04);
    final borderColor = _issue != null
        ? accentColor.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.08);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey<String>('support-${_issue?.title ?? "helper"}'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final pagePadding = isCompact ? AppSpacing.md : AppSpacing.lg;
    final cardPadding = isCompact ? AppSpacing.lg : AppSpacing.xl;
    final accentColor = _accentColor(context);

    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next is AuthLoading) {
        if (mounted) {
          setState(() {
            _issue = null;
            _sceneState = _TotpSceneState.verifying;
          });
        }
      } else if (next is AuthAuthenticated || next is AuthTotpVerified) {
        await _handleSuccess(next);
      } else if (next is AuthError) {
        _presentIssue(_issueFromError(next));
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: AmbientSideGlowBackdrop(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    AppSpacing.md,
                    pagePadding,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _isSetupMode
                              ? context.l10n.totpSetupTitle
                              : context.l10n.totpTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        AppSpacing.sm,
                        pagePadding,
                        AppSpacing.xl,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          padding: EdgeInsets.all(cardPadding),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _InlineChip(
                                    label: '@${widget.username.trim()}',
                                  ),
                                  _InlineChip(
                                    label: _isSetupMode
                                        ? _t(
                                            pt: 'Configurar autenticador',
                                            en: 'Authenticator setup',
                                            es: 'Configurar autenticador',
                                          )
                                        : _t(
                                            pt: 'Checkpoint TOTP',
                                            en: 'TOTP checkpoint',
                                            es: 'Checkpoint TOTP',
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            accentColor.withValues(alpha: 0.16),
                                        blurRadius: 34,
                                        spreadRadius: -10,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: AuthActionIllustration(
                                      key: ValueKey<String>(
                                        'totp-illustration-$_sceneState-${_issue?.title}',
                                      ),
                                      mode: _illustrationMode(),
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: Text(
                                  _headline(),
                                  key:
                                      ValueKey<String>('headline-$_sceneState'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                child: Text(
                                  _body(),
                                  key: ValueKey<String>('body-$_sceneState'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        height: 1.55,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _buildSetupArtifacts(context, accentColor),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                context.l10n.totpEnter6Digits.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TotpInputContainer(
                                controller: _codeController,
                                focusNode: _codeFocusNode,
                                onChanged: _handleCodeChanged,
                                onCompleted: (_) => _submitCurrentCode(),
                                hasError: _issue != null,
                                enabled: !isLoading,
                                accentColor: accentColor,
                                errorPulseKey: _errorPulseKey,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: List.generate(3, (index) {
                                  final isActive = index <= _activeStepIndex();
                                  return Expanded(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      height: 4,
                                      margin: EdgeInsets.only(
                                        right: index == 2 ? 0 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? accentColor
                                            : Colors.white
                                                .withValues(alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildSupportPanel(context, accentColor),
                              const SizedBox(height: AppSpacing.lg),
                              BouncingButton(
                                text: _primaryButtonText(),
                                isLoading: isLoading,
                                onPressed: isLoading
                                    ? null
                                    : () => _submitCurrentCode(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _InlineChip extends StatelessWidget {
  final String label;

  const _InlineChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
