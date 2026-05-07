import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/features/auth/presentation/widgets/modern_auth_text_field.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/l10n/l10n_extension.dart';

import 'emergency_recovery_screen.dart';
import 'totp_screen.dart';

class LoginPassphraseScreen extends ConsumerStatefulWidget {
  final String username;

  const LoginPassphraseScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<LoginPassphraseScreen> createState() =>
      _LoginPassphraseScreenState();
}

class _LoginPassphraseScreenState extends ConsumerState<LoginPassphraseScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text.trim().isEmpty) {
      showCustomErrorDialog(
        context,
        'Digite a senha da conta.',
        onRetry: () {},
        onGoBack: () => Navigator.of(context).maybePop(),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).login(
          username: widget.username.trim(),
          password: _passwordController.text,
        );
  }

  void _openRecovery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyRecoveryScreen(
          initialUsername: widget.username.trim(),
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
              username: widget.username.trim(),
              passphrase: _passwordController.text,
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
            _submit();
          },
          onGoBack: () {
            ref.read(authControllerProvider.notifier).clearError();
            Navigator.of(context).maybePop();
          },
        );
      }
    });

    return AuthEntryScaffold(
      eyebrow: context.l10n.authPrivateAccessEyebrow.toUpperCase(),
      title: context.l10n.authAccountPasswordTitle,
      subtitle: '@${widget.username.trim()}',
      onBack: () => Navigator.of(context).maybePop(),
      child: AuthEntryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernAuthTextField(
              controller: _passwordController,
              label: context.l10n.password,
              hint: context.l10n.authAccountPasswordHint,
              icon: LucideIcons.lock,
              isPassword: _obscurePassword,
              autofocus: true,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => isLoading ? null : _submit(),
              suffixIcon: IconButton(
                onPressed: isLoading
                    ? null
                    : () {
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
              icon: isLoading ? LucideIcons.loader2 : LucideIcons.shieldCheck,
              title: isLoading
                  ? context.l10n.authCredentialSendingTitle
                  : context.l10n.authCredentialTitle,
              body: isLoading
                  ? context.l10n.authCredentialSendingBody
                  : context.l10n.authCredentialBody,
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthEntryButton(
              text: context.l10n.authSignInAction.toUpperCase(),
              isLoading: isLoading,
              icon: LucideIcons.arrowRight,
              onPressed: isLoading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthEntryButton(
              text: context.l10n.authEmergencyRecoveryAction.toUpperCase(),
              outlined: true,
              onPressed: isLoading ? null : _openRecovery,
            ),
          ],
        ),
      ),
    );
  }
}
