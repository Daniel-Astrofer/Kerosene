import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:kerosene/features/auth/presentation/widgets/totp_input_container.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'passkey_verification_screen.dart';

class _AuthColors {
  final bool isLight;
  final Color background;
  final Color surface;
  final Color field;
  final Color border;
  final Color borderSoft;
  final Color text;
  final Color muted;
  final Color dim;
  final Color success;
  final Color errorText;

  const _AuthColors({
    required this.isLight,
    required this.background,
    required this.surface,
    required this.field,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.muted,
    required this.dim,
    required this.success,
    required this.errorText,
  });

  factory _AuthColors.of(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) {
      return const _AuthColors(
        isLight: true,
        background: AppColors.hexFFF7F7F5,
        surface: AppColors.hexFFFFFFFF,
        field: AppColors.hexFFF0F1EE,
        border: AppColors.hexFFDDE0D8,
        borderSoft: AppColors.hexFFE2E4DE,
        text: AppColors.hexFF181A17,
        muted: AppColors.hexFF62675F,
        dim: AppColors.hexFF8B9087,
        success: AppColors.hexFF16A34A,
        errorText: AppColors.hexFFDC2626,
      );
    }
    return const _AuthColors(
      isLight: false,
      background: AppColors.hexFF000000,
      surface: AppColors.hexFF0A0A0A,
      field: AppColors.hexFF1A1A1A,
      border: AppColors.hexFF333333,
      borderSoft: AppColors.hexFF27272A,
      text: AppColors.hexFFFFFFFF,
      muted: AppColors.hexFFA1A1AA,
      dim: AppColors.hexFF71717A,
      success: AppColors.hexFF4ADE80,
      errorText: AppColors.hexFFF4C7C7,
    );
  }

  BorderRadius get radiusMedium =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(12);
  BorderRadius get radiusButton =>
      isLight ? BorderRadius.circular(16) : BorderRadius.circular(999);
}

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
        message: context.tr.loginPasswordRequired,
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
        message: context.tr.loginTotpRequired,
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

    final colors = _AuthColors.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            colors.isLight ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness:
            colors.isLight ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
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
                                  icon: KeroseneIcons.error,
                                ),
                              ),
                            ],
                            SizedBox(height: responsive.isTinyPhone ? 24 : 34),
                            _LoginTitleBlock(
                              title: context.tr.loginTitle,
                              subtitle: context.tr.loginSubtitle,
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
                                  title: context.tr.loginConfirmCodeTitle,
                                  subtitle: context.tr.loginConfirmCodeSubtitle,
                                  buttonLabel:
                                      context.tr.loginConfirmAccessButton,
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
                                label: context.tr.loginUsernameLabel,
                                enabled: !isLoading,
                                autofocus: !widget.focusPassword,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                prefixIcon: Icon(
                                  KeroseneIcons.user,
                                  size: 18,
                                  color: colors.muted,
                                ),
                                suffixIcon: _usernameController.text.isNotEmpty
                                    ? Icon(
                                        KeroseneIcons.success,
                                        size: 18,
                                        color:
                                            colors.text.withValues(alpha: 0.86),
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
                                prefixIcon: Icon(
                                  KeroseneIcons.lock,
                                  size: 18,
                                  color: colors.muted,
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
                                        ? KeroseneIcons.eye
                                        : KeroseneIcons.eyeOff,
                                    size: 18,
                                    color: colors.muted,
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
                              text: context.tr.loginContinueButton,
                              isLoading: isLoading,
                              onPressed:
                                  isLoading ? null : _continueToDeviceKey,
                              borderRadius: 16,
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pushNamed(
                                        context,
                                        '/recovery/emergency',
                                      ),
                              child: Text(
                                context.tr.loginLostAccessButton,
                              ),
                            ),
                            const SizedBox(height: 26),
                            _LoginSignupLink(
                              onTap: isLoading
                                  ? null
                                  : () =>
                                      Navigator.pushNamed(context, '/signup'),
                              lead: context.tr.loginNewHere,
                              action: context.tr.loginCreateAccount,
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
    final colors = _AuthColors.of(context);
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
              color: colors.text.withValues(alpha: 0.86),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: colors.text.withValues(alpha: 0.86),
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
    final colors = _AuthColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _LoginTypography.title(colors)),
        const SizedBox(height: 10),
        Text(subtitle, style: _LoginTypography.subtitle(colors)),
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
    final colors = _AuthColors.of(context);
    return _LoginPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.text.withValues(alpha: 0.82)),
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
                  style: _LoginTypography.label(colors).copyWith(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style:
                      _LoginTypography.bodySmall(colors).copyWith(height: 1.34),
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
    final colors = _AuthColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _LoginTypography.label(colors)),
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
          cursorColor: colors.text,
          style: _LoginTypography.field(colors).copyWith(
            color: enabled ? colors.text : colors.text.withValues(alpha: 0.48),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.field,
            hintText: hintText,
            hintStyle: _LoginTypography.field(colors).copyWith(
              color: colors.dim,
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
                  BorderSide(color: colors.border.withValues(alpha: 0.72)),
            ),
            focusedBorder: border.copyWith(
              borderSide:
                  BorderSide(color: colors.text.withValues(alpha: 0.45)),
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
    final colors = _AuthColors.of(context);
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
                  color: colors.text.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.text.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(
                  KeroseneIcons.passkey,
                  color: colors.text,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _LoginTypography.sectionTitle(colors)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: _LoginTypography.bodySmall(colors),
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
    final colors = _AuthColors.of(context);
    final disabled = onPressed == null || isLoading;
    final background =
        disabled ? colors.text.withValues(alpha: 0.42) : colors.text;
    final foreground = colors.background;

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
            textStyle: _LoginTypography.button(colors, color: foreground),
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
    final colors = _AuthColors.of(context);
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
                style: _LoginTypography.bodySmall(colors),
                children: [
                  TextSpan(
                    text: action,
                    style: _LoginTypography.bodySmall(
                      colors,
                      color: colors.text,
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
    final colors = _AuthColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.borderSoft),
      ),
      child: child,
    );
  }
}

class _LoginTypography {
  const _LoginTypography._();

  static TextStyle title(_AuthColors colors) {
    return AppTypography.newsreader(
      color: colors.text,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: 0,
    );
  }

  static TextStyle subtitle(_AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.muted,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    );
  }

  static TextStyle label(_AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
    );
  }

  static TextStyle field(_AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle bodySmall(_AuthColors colors, {Color? color}) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: color ?? colors.muted,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle(_AuthColors colors) {
    return TextStyle(
      fontFamily: AppTypography.fontFamily,
      color: colors.text,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    );
  }

  static TextStyle button(_AuthColors colors, {required Color color}) {
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
