import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/presentation/widgets/auth_entry_ui.dart';
import 'package:teste/features/auth/presentation/widgets/modern_auth_text_field.dart';
import 'package:teste/l10n/l10n_extension.dart';

import 'emergency_recovery_screen.dart';
import 'passkey_verification_screen.dart';

class LoginUsernameScreen extends ConsumerStatefulWidget {
  const LoginUsernameScreen({super.key});

  @override
  ConsumerState<LoginUsernameScreen> createState() =>
      _LoginUsernameScreenState();
}

class _LoginUsernameScreenState extends ConsumerState<LoginUsernameScreen> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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

  void _handleContinue() {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      AppNotice.showError(
        context,
        title: context.l10n.username,
        message: 'Informe o username da conta.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasskeyVerificationScreen(
          username: username,
        ),
      ),
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
    return AuthEntryScaffold(
      eyebrow: 'ACESSAR CONTA',
      title: context.l10n.welcomeBack,
      subtitle:
          'Primeiro informe seu nome de usuário',
      onBack: () => Navigator.of(context).maybePop(),
      child: AuthEntryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernAuthTextField(
              controller: _usernameController,
              label: context.l10n.username,
              hint: 'Nome de usuário',
              icon: LucideIcons.user,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onChanged: _normalizeUsername,
              onFieldSubmitted: (_) => _handleContinue(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AuthEntryNote(
              icon: LucideIcons.fingerprint,
              title: 'Aviso',
              body:
                  'A Kerosene tenta a passkey local primeiro.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthEntryButton(
              text: context.l10n.continueButton.toUpperCase(),
              icon: LucideIcons.arrowRight,
              onPressed: _handleContinue,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthEntryButton(
              text: context.l10n.forgotPassword.toUpperCase(),
              outlined: true,
              onPressed: _openRecovery,
            ),
          ],
        ),
      ),
    );
  }
}
