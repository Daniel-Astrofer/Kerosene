import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/features/auth/presentation/widgets/modern_auth_text_field.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  bool _isForward = true;
  bool _acceptedPasswordRisk = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _skipTotpRequested = false;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      if (next is AuthRequiresTotpSetup) {
        _sessionId = next.sessionId;
        if (!_skipTotpRequested) {
          _skipTotpRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ref.read(authControllerProvider.notifier).skipTotpSetup();
          });
        }
        return;
      }

      if (next is AuthTotpVerified) {
        _skipTotpRequested = false;
        _sessionId = next.sessionId;
        _goToStep(3);
        return;
      }

      if (next is AuthAuthenticated) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
        return;
      }

      if (next is AuthError) {
        _skipTotpRequested = false;
        AppNotice.showError(
          context,
          title: context.l10n.authFlowInterruptedTitle,
          message: ErrorTranslator.translate(context.l10n, next.toString()),
        );
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _username => _usernameController.text.trim();
  String get _password => _passwordController.text;

  bool get _passwordLooksStrong {
    final password = _passwordController.text;
    return password.length >= 12 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  String? _usernameError(BuildContext context, String value) {
    final username = value.trim();
    if (username.length < 3) {
      return context.l10n.authUsernameMinError;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return context.l10n.authUsernameCharsError;
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
    setState(() {});
  }

  void _goToStep(int nextStep) {
    if (nextStep == _step) {
      return;
    }
    setState(() {
      _isForward = nextStep > _step;
      _step = nextStep;
    });
  }

  void _continueFromUsername() {
    final error = _usernameError(context, _username);
    if (error != null) {
      AppNotice.showError(
        context,
        title: context.l10n.authInvalidUsernameTitle,
        message: error,
      );
      return;
    }
    _goToStep(1);
  }

  void _continueFromPassword() {
    if (!_passwordLooksStrong) {
      AppNotice.showError(
        context,
        title: context.l10n.authWeakPasswordTitle,
        message: context.l10n.authPasswordStrengthMessage,
      );
      return;
    }
    _goToStep(2);
  }

  void _submitSignup() {
    final usernameError = _usernameError(context, _username);
    if (usernameError != null) {
      _goToStep(0);
      AppNotice.showError(
        context,
        title: context.l10n.authInvalidUsernameTitle,
        message: usernameError,
      );
      return;
    }

    if (!_passwordLooksStrong) {
      _goToStep(1);
      AppNotice.showError(
        context,
        title: context.l10n.authWeakPasswordTitle,
        message: context.l10n.authPasswordStrengthMessage,
      );
      return;
    }

    if (_confirmPasswordController.text != _password) {
      AppNotice.showError(
        context,
        title: context.l10n.authInvalidConfirmationTitle,
        message: context.l10n.authPasswordMismatchMessage,
      );
      return;
    }

    if (!_acceptedPasswordRisk) {
      AppNotice.showError(
        context,
        title: context.l10n.authConfirmationRequiredTitle,
        message: context.l10n.authPasswordRiskRequiredMessage,
      );
      return;
    }

    ref.read(authControllerProvider.notifier).signup(
          username: _username,
          password: _password,
        );
  }

  void _registerPasskey() {
    ref.read(authControllerProvider.notifier).registerPasskeyOnboarding(
          _sessionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return AuthEntryScaffold(
      eyebrow: context.l10n.authAccountEyebrow.toUpperCase(),
      title: context.l10n.authCreateAccountTitle,
      subtitle: context.l10n.authCreateAccountSubtitle,
      onBack: () {
        if (_step > 0 && _step < 3) {
          _goToStep(_step - 1);
          return;
        }
        Navigator.of(context).maybePop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepMeta(context),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey<int>(_step);
              final begin = isIncoming
                  ? Offset(_isForward ? 1 : -1, 0)
                  : Offset(_isForward ? -1 : 1, 0);
              final position = Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: position, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_step),
              child: _buildStepBody(context, authState, isLoading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepMeta(BuildContext context) {
    final label = switch (_step) {
      0 => '01/03',
      1 => '02/03',
      2 => '03/03',
      3 => context.l10n.authPasskeyStepLabel,
      _ => context.l10n.authSignupStepFallbackLabel,
    };
    final title = switch (_step) {
      0 => context.l10n.authSignupStepUsernameTitle,
      1 => context.l10n.authSignupStepPasswordTitle,
      2 => context.l10n.authSignupStepConfirmationTitle,
      3 => context.l10n.authSignupStepCreationTitle,
      _ => context.l10n.authSignupStepFallbackLabel,
    };

    return Text(
      '$label  /  $title'.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontFamily: AppTypography.numericFontFamily,
        color: authEntryFaint,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildStepBody(
    BuildContext context,
    AuthState authState,
    bool isLoading,
  ) {
    return switch (_step) {
      0 => _buildUsernameStep(),
      1 => _buildPasswordStep(),
      2 => _buildConfirmationStep(isLoading),
      3 => _buildPasskeyStep(isLoading),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildUsernameStep() {
    return AuthEntryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: context.l10n.authAccountCredentialsTitle,
            body: context.l10n.authAccountCredentialsBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _usernameController,
            label: context.l10n.authUsernameHint,
            hint: context.l10n.authUsernameHint,
            icon: LucideIcons.user,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onChanged: _normalizeUsername,
            onFieldSubmitted: (_) => _continueFromUsername(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthEntryNote(
            icon: LucideIcons.shield,
            title: context.l10n.authCustodyNoteTitle,
            body: context.l10n.authCustodyNoteBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthEntryButton(
            text: context.l10n.continueButton.toUpperCase(),
            icon: LucideIcons.arrowRight,
            onPressed: _continueFromUsername,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return AuthEntryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: context.l10n.authStrongPasswordTitle,
            body: context.l10n.authStrongPasswordBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _passwordController,
            label: context.l10n.password,
            hint: context.l10n.authPasswordLongHint,
            icon: LucideIcons.lock,
            isPassword: _obscurePassword,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _continueFromPassword(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                color: authEntryMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthEntryNote(
            icon: _passwordLooksStrong ? LucideIcons.check : LucideIcons.key,
            title: _passwordLooksStrong
                ? context.l10n.authPasswordReadyTitle
                : context.l10n.authPasswordMinimumTitle,
            body: context.l10n.authPasswordRuleBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AuthEntryButton(
                  text: context.l10n.authBackAction.toUpperCase(),
                  outlined: true,
                  onPressed: () => _goToStep(0),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AuthEntryButton(
                  text: context.l10n.authReadyAction.toUpperCase(),
                  icon: LucideIcons.arrowRight,
                  onPressed: _continueFromPassword,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(bool isLoading) {
    return AuthEntryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: context.l10n.authConfirmPasswordTitle,
            body: context.l10n.authConfirmPasswordBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _confirmPasswordController,
            label: context.l10n.authConfirmPasswordLabel,
            hint: context.l10n.password,
            icon: LucideIcons.badgeCheck,
            isPassword: _obscureConfirmPassword,
            autofocus: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => isLoading ? null : _submitSignup(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                color: authEntryMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildRiskAcknowledgement(),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AuthEntryButton(
                  text: context.l10n.authBackAction.toUpperCase(),
                  outlined: true,
                  onPressed: isLoading ? null : () => _goToStep(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AuthEntryButton(
                  text: context.l10n.authCreateAction.toUpperCase(),
                  isLoading: isLoading,
                  icon: LucideIcons.arrowRight,
                  onPressed: isLoading ? null : _submitSignup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAcknowledgement() {
    return InkWell(
      onTap: () {
        setState(() {
          _acceptedPasswordRisk = !_acceptedPasswordRisk;
        });
      },
      child: AuthEntryPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        raised: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _acceptedPasswordRisk
                  ? LucideIcons.checkCircle2
                  : LucideIcons.circle,
              color: _acceptedPasswordRisk ? authEntryText : authEntryMuted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.authPasswordRiskAcknowledgement,
                style: AppTypography.bodySmall.copyWith(
                  color: authEntryText,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasskeyStep(bool isLoading) {
    return AuthEntryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            title: context.l10n.authPasskeyRegisterTitle,
            body: context.l10n.authPasskeyRegisterBody,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthEntryNote(
            icon: LucideIcons.fingerprint,
            title: context.l10n.authDeviceTitle,
            body: context.l10n.authDeviceBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthEntryButton(
            text: context.l10n.authRegisterPasskeyAction.toUpperCase(),
            isLoading: isLoading,
            icon: LucideIcons.fingerprint,
            onPressed:
                isLoading || _sessionId.isEmpty ? null : _registerPasskey,
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String body;

  const _StepTitle({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h2.copyWith(
            fontFamily: 'HubotSansCondensed',
            color: authEntryText,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: AppTypography.bodySmall.copyWith(
            color: authEntryMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
