import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/presentation/widgets/kerosene_logo.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/l10n/l10n_extension.dart';

import 'emergency_recovery_screen.dart';
import 'passkey_verification_screen.dart';
import 'totp_screen.dart';

const Color _loginInk = Color(0xFF020405);
const Color _loginPanel = Color(0xD70B1013);
const Color _loginPanelRaised = Color(0xE512171C);
const Color _loginLine = Color(0x1FFFFFFF);
const Color _loginMuted = Color(0xFFA6A8A4);

class LoginUsernameScreen extends ConsumerStatefulWidget {
  const LoginUsernameScreen({super.key});

  @override
  ConsumerState<LoginUsernameScreen> createState() =>
      _LoginUsernameScreenState();
}

class _LoginUsernameScreenState extends ConsumerState<LoginUsernameScreen> {
  final _usernameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _passphraseFocusNode = FocusNode();
  bool _obscurePassphrase = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passphraseController.dispose();
    _passphraseFocusNode.dispose();
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

  void _normalizeUsername(String value) {
    final sanitized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final normalized =
        sanitized.length > 24 ? sanitized.substring(0, 24) : sanitized;
    if (normalized != value) {
      _usernameController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {});
  }

  String? _validatedUsername() {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      AppNotice.showError(
        context,
        title: context.l10n.username,
        message: context.l10n.authUsernameRequiredMessage,
      );
      return null;
    }
    return username;
  }

  void _handlePasskeyContinue() {
    final username = _validatedUsername();
    if (username == null) {
      return;
    }

    ref.read(authControllerProvider.notifier).clearError();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasskeyVerificationScreen(username: username),
      ),
    );
  }

  void _submitPassphrase() {
    final username = _validatedUsername();
    if (username == null) {
      return;
    }

    if (_passphraseController.text.trim().isEmpty) {
      showCustomErrorDialog(
        context,
        _copy(
          context: context,
          pt: 'Digite sua passphrase.',
          en: 'Enter your passphrase.',
          es: 'Ingresa tu passphrase.',
        ),
        onRetry: () {},
        onGoBack: () => Navigator.of(context).maybePop(),
      );
      return;
    }

    ref.read(authControllerProvider.notifier)
      ..clearError()
      ..login(
        username: username,
        password: _passphraseController.text,
      );
  }

  void _openRecovery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyRecoveryScreen(
          initialUsername: _usernameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        HomeScreen.skipNextAuth = true;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
        return;
      }

      if (next is AuthRequiresLoginTotp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TotpScreen(
              username: _usernameController.text.trim(),
              passphrase: _passphraseController.text,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
        return;
      }

      if (next is AuthError) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.toString()),
          onRetry: () {
            ref.read(authControllerProvider.notifier).clearError();
            _submitPassphrase();
          },
          onGoBack: () {
            ref.read(authControllerProvider.notifier).clearError();
            Navigator.of(context).maybePop();
          },
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _LoginBackdrop(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AutofillGroup(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 560,
                            minHeight: constraints.maxHeight > 52
                                ? constraints.maxHeight - 52
                                : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _LoginBrand(),
                              const SizedBox(height: 78),
                              _LoginTitleBlock(
                                title: _copy(
                                  context: context,
                                  pt: 'Entrar',
                                  en: 'Sign in',
                                  es: 'Entrar',
                                ),
                                subtitle: _copy(
                                  context: context,
                                  pt: 'Acesse sua conta com segurança neste dispositivo.',
                                  en: 'Access your account securely on this device.',
                                  es: 'Accede a tu cuenta con seguridad en este dispositivo.',
                                ),
                              ),
                              const SizedBox(height: 28),
                              _LoginInputField(
                                controller: _usernameController,
                                label: _copy(
                                  context: context,
                                  pt: 'Nome de usuário',
                                  en: 'Username',
                                  es: 'Nombre de usuario',
                                ),
                                hint: 'lucas_01',
                                icon: LucideIcons.user,
                                enabled: !isLoading,
                                autofocus: true,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                onChanged: _normalizeUsername,
                                onSubmitted: (_) {
                                  _passphraseFocusNode.requestFocus();
                                },
                              ),
                              const SizedBox(height: 20),
                              _PasskeyPanel(
                                isLoading: isLoading,
                                onPressed:
                                    isLoading ? null : _handlePasskeyContinue,
                                title: _copy(
                                  context: context,
                                  pt: 'Entrar com passkey',
                                  en: 'Sign in with passkey',
                                  es: 'Entrar con passkey',
                                ),
                                subtitle: _copy(
                                  context: context,
                                  pt: 'Use a credencial segura deste dispositivo.',
                                  en: 'Use this device secure credential.',
                                  es: 'Usa la credencial segura de este dispositivo.',
                                ),
                                buttonLabel: _copy(
                                  context: context,
                                  pt: 'Continuar com passkey',
                                  en: 'Continue with passkey',
                                  es: 'Continuar con passkey',
                                ),
                              ),
                              const SizedBox(height: 30),
                              _LoginDivider(
                                label: _copy(
                                  context: context,
                                  pt: 'ou',
                                  en: 'or',
                                  es: 'o',
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                _copy(
                                  context: context,
                                  pt: 'Se a passkey não estiver disponível, confirme sua passphrase.',
                                  en: 'If the passkey is not available, confirm your passphrase.',
                                  es: 'Si la passkey no está disponible, confirma tu passphrase.',
                                ),
                                style: AppTypography.bodyLarge.copyWith(
                                  color: _loginMuted,
                                  fontSize: 18,
                                  height: 1.36,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _LoginInputField(
                                controller: _passphraseController,
                                focusNode: _passphraseFocusNode,
                                label: context.l10n.authSignupPassphraseLabel,
                                hint: '••••••••••••••••',
                                icon: _obscurePassphrase
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                enabled: !isLoading,
                                obscureText: _obscurePassphrase,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) {
                                  if (!isLoading) {
                                    _submitPassphrase();
                                  }
                                },
                                onIconPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassphrase =
                                              !_obscurePassphrase;
                                        });
                                      },
                              ),
                              const SizedBox(height: 22),
                              _DarkLoginButton(
                                label: _copy(
                                  context: context,
                                  pt: 'Entrar com passphrase',
                                  en: 'Sign in with passphrase',
                                  es: 'Entrar con passphrase',
                                ),
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _submitPassphrase,
                              ),
                              const SizedBox(height: 26),
                              _LoginInfoCard(
                                onTap: isLoading ? null : _openRecovery,
                                text: _copy(
                                  context: context,
                                  pt: 'Falha na passkey? Use sua passphrase para concluir o acesso.',
                                  en: 'Passkey failed? Use your passphrase to finish access.',
                                  es: '¿Falló la passkey? Usa tu passphrase para completar el acceso.',
                                ),
                              ),
                              const SizedBox(height: 36),
                              _LoginDeviceNote(
                                text: _copy(
                                  context: context,
                                  pt: 'Este dispositivo pode ser registrado como passkey confiável.',
                                  en: 'This device can be registered as a trusted passkey.',
                                  es: 'Este dispositivo puede registrarse como passkey confiable.',
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
          ],
        ),
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF06090B),
            Color(0xFF020405),
            Color(0xFF010202),
          ],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.55),
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _LoginMistPainter())),
        ],
      ),
    );
  }
}

class _LoginMistPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final smokePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.055),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.56, size.height * 0.44),
          radius: size.width * 0.64,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.44),
      size.width * 0.64,
      smokePaint,
    );

    final speckPaint = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (var index = 0; index < 18; index++) {
      canvas.drawCircle(
        Offset(
          size.width * ((index * 37) % 100) / 100,
          size.height * ((index * 53) % 100) / 100,
        ),
        0.8 + (index % 2),
        speckPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KeroseneLogo(size: 72, showText: false),
            const SizedBox(width: 24),
            Text(
              'KEROSENE',
              style: AppTypography.h2.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontFamily: AppTypography.fontFamily,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoginTitleBlock({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h1.copyWith(
            color: Colors.white,
            fontFamily: AppTypography.titleFontFamily,
            fontSize: 42,
            fontWeight: FontWeight.w300,
            height: 1.05,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: _loginMuted,
            fontSize: 20,
            height: 1.32,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _LoginInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onIconPressed;

  const _LoginInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.focusNode,
    this.autofocus = false,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginGlass(
      borderRadius: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 86),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      autofocus: autofocus,
                      obscureText: obscureText,
                      cursorColor: Colors.white,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      autofillHints: autofillHints,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      style: AppTypography.bodyLarge.copyWith(
                        color: enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.48),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Center(
                child: IconButton(
                  onPressed: onIconPressed,
                  icon: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.68),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasskeyPanel extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String title;
  final String subtitle;
  final String buttonLabel;

  const _PasskeyPanel({
    required this.isLoading,
    required this.onPressed,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginGlass(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.scanFace,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontFamily: AppTypography.titleFontFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          height: 1.08,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        subtitle,
                        style: AppTypography.bodyLarge.copyWith(
                          color: _loginMuted,
                          fontSize: 18,
                          height: 1.32,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _LightLoginButton(
              label: buttonLabel,
              isLoading: isLoading,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _LightLoginButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LightLoginButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginButtonBase(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      borderColor: Colors.transparent,
    );
  }
}

class _DarkLoginButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _DarkLoginButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginButtonBase(
      label: label,
      isLoading: isLoading,
      onPressed: onPressed,
      backgroundColor: _loginPanelRaised,
      foregroundColor: Colors.white,
      borderColor: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _LoginButtonBase extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _LoginButtonBase({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: disabled
                  ? backgroundColor.withValues(alpha: 0.54)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: foregroundColor,
                                strokeWidth: 2,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                style: AppTypography.buttonText.copyWith(
                                  color: foregroundColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    color: foregroundColor.withValues(alpha: 0.82),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  final String label;

  const _LoginDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child:
              Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: _loginMuted,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child:
              Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
        ),
      ],
    );
  }
}

class _LoginInfoCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _LoginInfoCard({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _LoginGlass(
      borderRadius: 14,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.045),
                  ),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    color: Colors.white.withValues(alpha: 0.72),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.bodyLarge.copyWith(
                      color: _loginMuted,
                      fontSize: 17,
                      height: 1.34,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginDeviceNote extends StatelessWidget {
  final String text;

  const _LoginDeviceNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.11)),
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(
              LucideIcons.lock,
              color: Colors.white.withValues(alpha: 0.62),
              size: 24,
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: _loginMuted,
                  fontSize: 15,
                  height: 1.32,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              LucideIcons.info,
              color: Colors.white.withValues(alpha: 0.62),
              size: 22,
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const _LoginGlass({
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _loginPanel,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _loginLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.035),
                blurRadius: 18,
                spreadRadius: -12,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
