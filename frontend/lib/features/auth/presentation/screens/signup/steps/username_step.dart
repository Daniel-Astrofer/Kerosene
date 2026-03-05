import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../core/presentation/widgets/animated_loading_button.dart';
import '../../../providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/l10n/app_localizations.dart';

class UsernameStep extends ConsumerStatefulWidget {
  const UsernameStep({super.key});

  @override
  ConsumerState<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends ConsumerState<UsernameStep> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitAndGeneratePayment() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      ref.read(signupFlowProvider.notifier).setUsername(username);

      final flowState = ref.read(signupFlowProvider);

      // Map domain enum to API string
      String accountSecurity = 'STANDARD';
      if (flowState.seedSecurityOption == SeedSecurityOption.multisig2fa) {
        accountSecurity = 'MULTISIG_2FA';
      } else if (flowState.seedSecurityOption == SeedSecurityOption.slip39) {
        accountSecurity = 'SLIP39';
      }

      // Trigger actual signup API call
      // This will handle PoW challenge internally and set AuthProvider state
      await ref
          .read(authProvider.notifier)
          .signup(
            username: username,
            password: flowState.passphrase ?? '',
            accountSecurity: accountSecurity,
          );

      // The SignupFlowScreen listens to authProvider and will advance
      // to the next step (TOTP) when the API returns.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(signupFlowProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 64,
              color: CyberTheme.neonCyan,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.usernameTitle,
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.usernameSubtitle,
              style: CyberTheme.label(
                size: 14,
                color: CyberTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextFormField(
              controller: _usernameController,
              enabled: !isLoading,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
              ],
              style: const TextStyle(
                color: CyberTheme.textPrimary,
                fontSize: 15,
              ),
              decoration:
                  CyberTheme.cyberInput(
                    label: l10n.usernameFieldLabel,
                    hint: l10n.usernameHintChars,
                    icon: Icons.alternate_email_rounded,
                  ).copyWith(
                    helperText: l10n.usernameHelperLength,
                    helperStyle: const TextStyle(
                      color: CyberTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.required;
                if (value.length < 3) return l10n.usernameErrorMin;
                if (value.length > 15) return l10n.usernameErrorMax;
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                  return l10n.usernameErrorInvalidChars;
                }
                return null;
              },
            ),
            const SizedBox(height: 64),
            AnimatedLoadingButton(
              onPressed: isLoading ? null : _submitAndGeneratePayment,
              text: l10n
                  .paymentTitle, // Or usernameContinue which is "Reserve Handle & Continue"
              loadingTexts: [
                l10n.usernameLoadingPow,
                l10n.usernameLoadingKeys,
                l10n.usernameLoadingInvoice,
                l10n.usernameLoadingNetwork,
              ],
              baseColor: CyberTheme.neonCyan,
            ),
          ],
        ),
      ),
    );
  }
}
