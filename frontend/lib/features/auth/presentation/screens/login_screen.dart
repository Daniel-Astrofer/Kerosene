import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/auth/presentation/widgets/auth_motion.dart';
import 'package:kerosene/features/home/presentation/screens/home_screen.dart';
import 'passkey_verification_screen.dart';
import 'login_screen_components.dart';

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

    final colors = AuthColors.of(context);

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
                            LoginTopBar(
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            if (_inlineErrorMessage != null) ...[
                              const SizedBox(height: 18),
                              AuthMotionShake(
                                triggerKey: _errorPulseKey,
                                child: LoginInlineFeedback(
                                  title: _inlineErrorTitle ??
                                      context.tr.authFlowInterruptedTitle,
                                  message: _inlineErrorMessage!,
                                  icon: KeroseneIcons.error,
                                ),
                              ),
                            ],
                            SizedBox(height: responsive.isTinyPhone ? 24 : 34),
                            LoginTitleBlock(
                              title: context.tr.loginTitle,
                              subtitle: context.tr.loginSubtitle,
                            ),
                            if (_hasPendingTotp) ...[
                              const SizedBox(height: 26),
                              AuthMotionShake(
                                triggerKey: _errorPulseKey,
                                enabled: _inlineErrorTarget ==
                                    _LoginErrorTarget.totp,
                                child: LoginTotpPanel(
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
                              child: LoginTextField(
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
                              child: LoginTextField(
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
                            LoginPrimaryButton(
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
                            LoginSignupLink(
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
