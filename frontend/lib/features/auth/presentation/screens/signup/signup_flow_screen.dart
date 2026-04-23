import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/features/auth/presentation/widgets/modern_auth_text_field.dart';

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
          title: 'Fluxo interrompido',
          message: next.message,
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

  String? _usernameError(String value) {
    final username = value.trim();
    if (username.length < 3) {
      return 'Use pelo menos 3 caracteres.';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Use apenas letras minúsculas, números e underline.';
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
    final error = _usernameError(_username);
    if (error != null) {
      AppNotice.showError(
        context,
        title: 'Username inválido',
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
        title: 'Senha fraca',
        message:
            'Use pelo menos 12 caracteres com maiúscula, minúscula, número e símbolo.',
      );
      return;
    }
    _goToStep(2);
  }

  void _submitSignup() {
    final usernameError = _usernameError(_username);
    if (usernameError != null) {
      _goToStep(0);
      AppNotice.showError(
        context,
        title: 'Username inválido',
        message: usernameError,
      );
      return;
    }

    if (!_passwordLooksStrong) {
      _goToStep(1);
      AppNotice.showError(
        context,
        title: 'Senha fraca',
        message:
            'Use pelo menos 12 caracteres com maiúscula, minúscula, número e símbolo.',
      );
      return;
    }

    if (_confirmPasswordController.text != _password) {
      AppNotice.showError(
        context,
        title: 'Confirmação inválida',
        message: 'A confirmação de senha não corresponde.',
      );
      return;
    }

    if (!_acceptedPasswordRisk) {
      AppNotice.showError(
        context,
        title: 'Confirmação necessária',
        message: 'Confirme que entende o risco de perder a senha da conta.',
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
      eyebrow: 'CONTA',
      title: 'Criar conta',
      subtitle: 'Insira as credenciais para a criação da conta na plataforma.',
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
          _buildStepMeta(),
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

  Widget _buildStepMeta() {
    final label = switch (_step) {
      0 => '01/03',
      1 => '02/03',
      2 => '03/03',
      3 => 'PASSKEY',
      _ => 'CADASTRO',
    };
    final title = switch (_step) {
      0 => 'Nome de usuário',
      1 => 'Senha',
      2 => 'Confirmação',
      3 => 'Criação',
      _ => 'Cadastro',
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
            title: 'Conta e credenciais',
            body:
                'Primeiro, escolha o identificador público da sua conta. A senha será pedida na próxima etapa.',
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _usernameController,
            label: 'Nome de usuário',
            hint: 'Insira Um Nome',
            icon: LucideIcons.user,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onChanged: _normalizeUsername,
            onFieldSubmitted: (_) => _continueFromUsername(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AuthEntryNote(
            icon: LucideIcons.shield,
            title: 'Custódia',
            body:
                'Perder a senha pode significar perder a conta se não possuir o backup dos códigos.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthEntryButton(
            text: 'CONTINUAR',
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
          const _StepTitle(
            title: 'Senha forte',
            body:
                'Use uma senha longa e única.',
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _passwordController,
            label: 'Senha',
            hint: '+12 caracteres',
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
            title: _passwordLooksStrong ? 'Pronta' : 'Regra mínima',
            body: '+12 caracteres com maiúscula, minúscula, número e símbolo.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AuthEntryButton(
                  text: 'VOLTAR',
                  outlined: true,
                  onPressed: () => _goToStep(0),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AuthEntryButton(
                  text: 'PRONTO',
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
          const _StepTitle(
            title: 'Confirmar senha',
            body:
                'Repita a senha e confirme que entende o risco operacional desta credencial.',
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernAuthTextField(
            controller: _confirmPasswordController,
            label: 'TERMINAR',
            hint: 'Senha',
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
                  text: 'VOLTAR',
                  outlined: true,
                  onPressed: isLoading ? null : () => _goToStep(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AuthEntryButton(
                  text: 'CRIAR',
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
                'Entendo que perder a senha pode significar perder a conta.',
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
          const _StepTitle(
            title: 'Registrar passkey',
            body:
                'O cadastro segue direto para a passkey. A etapa TOTP não aparece neste fluxo.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const AuthEntryNote(
            icon: LucideIcons.fingerprint,
            title: 'Dispositivo',
            body:
                'A passkey vincula a conta a este dispositivo e conclui o cadastro.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthEntryButton(
            text: 'REGISTRAR PASSKEY',
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
