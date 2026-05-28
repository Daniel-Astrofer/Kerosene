import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/controller/auth_providers.dart';
import 'package:teste/features/auth/presentation/widgets/auth_motion.dart';
import 'package:teste/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/core/l10n/l10n_extension.dart';

import 'passkey_verification_screen.dart';

const Color _loginInk = Color(0xFF000000);
const Color _loginSurface = Color(0xFF0A0A0A);
const Color _loginField = Color(0xFF1A1A1A);
const Color _loginBorder = Color(0xFF333333);
const Color _loginBorderSoft = Color(0xFF27272A);
const Color _loginMuted = Color(0xFFA1A1AA);
const Color _loginDim = Color(0xFF71717A);
const Color _loginText = Color(0xFFFFFFFF);

enum _LoginErrorTarget { username, password, totp, general }

class LoginScreen extends ConsumerStatefulWidget {
  final String? username;
  final bool focusPassword;

  const LoginScreen({
    super.key,
    this.username,
    this.focusPassword = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _totpFocusNode = FocusNode();

  bool _obscurePassword = true;
  String? _pendingTotpUsername;
  String? _pendingTotpPassword;
  String? _pendingTotpPreAuthToken;
  String? _inlineErrorTitle;
  String? _inlineErrorMessage;
  _LoginErrorTarget? _inlineErrorTarget;
  int _errorPulseKey = 0;
  bool _isSubmittingCredentials = false;

  @override
  void initState() {
    super.initState();
    final username = widget.username?.trim();
    if (username != null && username.isNotEmpty) {
      _usernameController.text = _normalizedUsername(username);
    }
    if (widget.focusPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _passwordFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    _passwordFocusNode.dispose();
    _totpFocusNode.dispose();
    super.dispose();
  }

  String _copy({
    required BuildContext context,
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

  String _normalizedUsername(String value) {
    final sanitized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return sanitized.length > 24 ? sanitized.substring(0, 24) : sanitized;
  }

  void _normalizeUsername(String value) {
    final normalized = _normalizedUsername(value);
    if (normalized != value) {
      _usernameController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    _clearInlineError();
  }

  String? _validatedUsername() {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      _showInlineError(
        title: context.tr.username,
        message: context.tr.authUsernameRequiredMessage,
        target: _LoginErrorTarget.username,
      );
      return null;
    }
    return username;
  }

  void _showInlineError({
    required String title,
    required String message,
    _LoginErrorTarget target = _LoginErrorTarget.general,
  }) {
    HapticFeedback.lightImpact();
    setState(() {
      _inlineErrorTitle = title;
      _inlineErrorMessage = message;
      _inlineErrorTarget = target;
      _errorPulseKey += 1;
    });
  }

  void _clearInlineError() {
    if (_inlineErrorTitle == null && _inlineErrorMessage == null) {
      return;
    }
    setState(() {
      _inlineErrorTitle = null;
      _inlineErrorMessage = null;
      _inlineErrorTarget = null;
    });
  }

  Future<void> _continueToDeviceKey() async {
    final username = _validatedUsername();
    if (username == null) {
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showInlineError(
        title: context.tr.authAccountPasswordLabel,
        message: _copy(
          context: context,
          pt: 'Digite sua senha.',
          en: 'Enter your password.',
          es: 'Ingresa tu contraseña.',
        ),
        target: _LoginErrorTarget.password,
      );
      return;
    }

    setState(() => _isSubmittingCredentials = true);
    try {
      final loginResult = await ref.read(authRemoteDataSourceProvider).login(
            username: username,
            passphrase: _passwordController.text,
          );
      if (!mounted) {
        return;
      }

      _openDeviceKeyVerification(
        username,
        fallbackPassphrase: _passwordController.text,
        fallbackPreAuthToken: loginResult.requiresTotp ? loginResult.jwt : null,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInlineError(
        title: context.tr.authFlowInterruptedTitle,
        message: ErrorTranslator.translate(context.tr, error.toString()),
        target: _LoginErrorTarget.password,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCredentials = false);
      }
    }
  }

  void _openDeviceKeyVerification(
    String username, {
    String? fallbackPassphrase,
    String? fallbackPreAuthToken,
  }) {
    TextInput.finishAutofillContext();
    ref.read(authControllerProvider.notifier).clearError();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasskeyVerificationScreen(
          username: username,
          fallbackPassphrase: fallbackPassphrase,
          fallbackPreAuthToken: fallbackPreAuthToken,
        ),
      ),
    );
  }

  bool get _hasPendingTotp =>
      _pendingTotpUsername != null && _pendingTotpPassword != null;

  void _openInlineTotpChallenge(AuthRequiresLoginTotp challenge) {
    setState(() {
      _pendingTotpUsername = challenge.username;
      _pendingTotpPassword = challenge.passphrase;
      _pendingTotpPreAuthToken = challenge.preAuthToken;
      _inlineErrorTitle = null;
      _inlineErrorMessage = null;
      _inlineErrorTarget = null;
      _totpController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _totpFocusNode.requestFocus();
      }
    });
  }

  Future<void> _submitInlineTotp([String? value]) async {
    final code = (value ?? _totpController.text).replaceAll(RegExp(r'\D'), '');
    final username = _pendingTotpUsername;
    final password = _pendingTotpPassword;
    final preAuthToken = _pendingTotpPreAuthToken;
    if (username == null || password == null || preAuthToken == null) {
      return;
    }

    if (code.length != 6) {
      _showInlineError(
        title: context.tr.totpCodeLabel,
        message: _copy(
          context: context,
          pt: 'Informe o código de 6 dígitos.',
          en: 'Enter the 6-digit code.',
          es: 'Ingresa el código de 6 dígitos.',
        ),
        target: _LoginErrorTarget.totp,
      );
      return;
    }

    setState(() => _isSubmittingCredentials = true);
    try {
      await ref.read(authRemoteDataSourceProvider).verifyLoginTotp(
            username: username,
            totpCode: code,
            preAuthToken: preAuthToken,
          );
      if (!mounted) {
        return;
      }
      _openDeviceKeyVerification(username);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showInlineError(
        title: context.tr.authFlowInterruptedTitle,
        message: ErrorTranslator.translate(context.tr, error.toString()),
        target: _LoginErrorTarget.totp,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCredentials = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading || _isSubmittingCredentials;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent == false) {
        return;
      }

      if (next is AuthAuthenticated) {
        HomeScreen.skipNextAuth = true;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
        return;
      }

      if (next is AuthRequiresLoginTotp) {
        _openInlineTotpChallenge(next);
        return;
      }

      if (next is AuthError) {
        _showInlineError(
          title: context.tr.authFlowInterruptedTitle,
          message: ErrorTranslator.translate(context.tr, next.toString()),
          target: _hasPendingTotp
              ? _LoginErrorTarget.totp
              : _LoginErrorTarget.password,
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _loginInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _loginInk,
        resizeToAvoidBottomInset: true,
        body: ColoredBox(
          color: _loginInk,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final responsive = context.responsive;
                final horizontalPadding = responsive.isTinyPhone ? 20.0 : 24.0;
                final maxWidth = responsive.isCompact ? 390.0 : 430.0;
                final topSpacing = responsive.isTinyPhone ? 10.0 : 16.0;
                final bottomPadding =
                    28 + MediaQuery.viewInsetsOf(context).bottom;

                return AutofillGroup(
                  child: SingleChildScrollView(
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
                        child: AuthMotionStagger(
                          children: [
                            _LoginTopBar(
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            if (_inlineErrorMessage != null) ...[
                              const SizedBox(height: 18),
                              AuthMotionShake(
                                triggerKey: _errorPulseKey,
                                child: _LoginInlineFeedback(
                                  title: _inlineErrorTitle ??
                                      context.tr.authFlowInterruptedTitle,
                                  message: _inlineErrorMessage!,
                                  icon: LucideIcons.alertTriangle,
                                ),
                              ),
                            ],
                            SizedBox(height: responsive.isTinyPhone ? 24 : 34),
                            _LoginTitleBlock(
                              title: _copy(
                                context: context,
                                pt: 'Entrar',
                                en: 'Sign in',
                                es: 'Entrar',
                              ),
                              subtitle: _copy(
                                context: context,
                                pt: 'Informe usuário e senha. A chave do dispositivo será confirmada em seguida.',
                                en: 'Enter your username and password. Device key confirmation follows.',
                                es: 'Ingresa usuario y contraseña. Luego se confirma la llave del dispositivo.',
                              ),
                            ),
                            if (_hasPendingTotp) ...[
                              const SizedBox(height: 26),
                              AuthMotionShake(
                                triggerKey: _errorPulseKey,
                                enabled: _inlineErrorTarget ==
                                    _LoginErrorTarget.totp,
                                child: _LoginTotpPanel(
                                  controller: _totpController,
                                  focusNode: _totpFocusNode,
                                  isLoading: isLoading,
                                  hasError: _inlineErrorTarget ==
                                      _LoginErrorTarget.totp,
                                  errorPulseKey: _errorPulseKey,
                                  onCompleted: _submitInlineTotp,
                                  onSubmit: () => _submitInlineTotp(),
                                  title: _copy(
                                    context: context,
                                    pt: 'Confirme o código',
                                    en: 'Confirm the code',
                                    es: 'Confirma el código',
                                  ),
                                  subtitle: _copy(
                                    context: context,
                                    pt: 'Digite o código do seu autenticador para concluir o acesso.',
                                    en: 'Enter your authenticator code to finish signing in.',
                                    es: 'Ingresa el código de tu autenticador para terminar el acceso.',
                                  ),
                                  buttonLabel: _copy(
                                    context: context,
                                    pt: 'Confirmar acesso',
                                    en: 'Confirm access',
                                    es: 'Confirmar acceso',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 34),
                            AuthMotionShake(
                              triggerKey: _errorPulseKey,
                              enabled: _inlineErrorTarget ==
                                  _LoginErrorTarget.username,
                              child: _LoginTextField(
                                controller: _usernameController,
                                label: _copy(
                                  context: context,
                                  pt: 'Nome de usuário',
                                  en: 'Username',
                                  es: 'Nombre de usuario',
                                ),
                                enabled: !isLoading,
                                autofocus: !widget.focusPassword,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                prefixIcon: const Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: _loginMuted,
                                ),
                                suffixIcon: _usernameController.text.isNotEmpty
                                    ? Icon(
                                        LucideIcons.checkCircle2,
                                        size: 18,
                                        color:
                                            _loginText.withValues(alpha: 0.86),
                                      )
                                    : null,
                                onChanged: (value) {
                                  _normalizeUsername(value);
                                  setState(() {});
                                },
                                onSubmitted: (_) {
                                  _passwordFocusNode.requestFocus();
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthMotionShake(
                              triggerKey: _errorPulseKey,
                              enabled: _inlineErrorTarget ==
                                  _LoginErrorTarget.password,
                              child: _LoginTextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                label: context.tr.authAccountPasswordLabel,
                                hintText: '••••••••••••••••',
                                enabled: !isLoading,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                prefixIcon: const Icon(
                                  LucideIcons.lock,
                                  size: 18,
                                  color: _loginMuted,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                  icon: Icon(
                                    _obscurePassword
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    size: 18,
                                    color: _loginMuted,
                                  ),
                                ),
                                onChanged: (_) => _clearInlineError(),
                                onSubmitted: (_) {
                                  if (!isLoading) {
                                    _continueToDeviceKey();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            _LoginPrimaryButton(
                              text: _copy(
                                context: context,
                                pt: 'Continuar',
                                en: 'Continue',
                                es: 'Continuar',
                              ),
                              isLoading: isLoading,
                              onPressed:
                                  isLoading ? null : _continueToDeviceKey,
                              borderRadius: 16,
                            ),
                            const SizedBox(height: 26),
                            _LoginSignupLink(
                              onTap: isLoading
                                  ? null
                                  : () =>
                                      Navigator.pushNamed(context, '/signup'),
                              lead: _copy(
                                context: context,
                                pt: 'Novo por aqui?',
                                en: 'New here?',
                                es: '¿Nuevo por aquí?',
                              ),
                              action: _copy(
                                context: context,
                                pt: 'Criar conta',
                                en: 'Create account',
                                es: 'Crear cuenta',
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
          ),
        ),
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _LoginTopBar({required this.onBack});

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
              color: _loginText.withValues(alpha: 0.86),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: _loginText.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoginTitleBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _LoginTypography.title()),
        const SizedBox(height: 10),
        Text(subtitle, style: _LoginTypography.subtitle()),
      ],
    );
  }
}

class _LoginInlineFeedback extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _LoginInlineFeedback({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _loginText.withValues(alpha: 0.82)),
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
                  style: _LoginTypography.label().copyWith(
                    color: _loginText,
                    fontSize: 14,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _LoginTypography.bodySmall().copyWith(height: 1.34),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hintText;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.focusNode,
    this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _loginBorder),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _LoginTypography.label()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: _loginText,
          style: _LoginTypography.field().copyWith(
            color: enabled ? _loginText : _loginText.withValues(alpha: 0.48),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _loginField,
            hintText: hintText,
            hintStyle: _LoginTypography.field().copyWith(
              color: _loginDim,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            enabledBorder: border,
            disabledBorder: border.copyWith(
              borderSide:
                  BorderSide(color: _loginBorder.withValues(alpha: 0.72)),
            ),
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: _loginText.withValues(alpha: 0.45)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginTotpPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasError;
  final int errorPulseKey;
  final ValueChanged<String> onCompleted;
  final VoidCallback onSubmit;
  final String title;
  final String subtitle;
  final String buttonLabel;

  const _LoginTotpPanel({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasError,
    required this.errorPulseKey,
    required this.onCompleted,
    required this.onSubmit,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _loginText.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _loginText.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  LucideIcons.keyRound,
                  color: _loginText,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _LoginTypography.sectionTitle()),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: _LoginTypography.bodySmall(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TotpInputContainer(
            controller: controller,
            focusNode: focusNode,
            enabled: !isLoading,
            hasError: hasError,
            errorPulseKey: errorPulseKey,
            onCompleted: onCompleted,
          ),
          const SizedBox(height: 18),
          _LoginPrimaryButton(
            text: buttonLabel,
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;

  const _LoginPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background =
        disabled ? _loginText.withValues(alpha: 0.42) : _loginText;
    const foreground = _loginInk;

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
              side: BorderSide.none,
            ),
            textStyle: _LoginTypography.button(color: foreground),
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
              : Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}

class _LoginSignupLink extends StatelessWidget {
  final VoidCallback? onTap;
  final String lead;
  final String action;

  const _LoginSignupLink({
    required this.onTap,
    required this.lead,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text.rich(
              TextSpan(
                text: '$lead ',
                style: _LoginTypography.bodySmall(),
                children: [
                  TextSpan(
                    text: action,
                    style: _LoginTypography.bodySmall(
                      color: _loginText,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _LoginPanel({
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
        color: _loginSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _loginBorderSoft),
      ),
      child: child,
    );
  }
}

class _LoginTypography {
  const _LoginTypography._();

  static TextStyle title() {
    return GoogleFonts.ebGaramond(
      color: _loginText,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle subtitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _loginMuted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle label() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _loginText,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );
  }

  static TextStyle field() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _loginText,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmall({Color color = _loginMuted}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle() {
    return const TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: _loginText,
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
}
