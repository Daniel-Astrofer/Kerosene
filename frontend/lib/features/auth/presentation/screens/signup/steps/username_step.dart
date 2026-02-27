import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../core/presentation/widgets/animated_loading_button.dart';
import '../../../providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';

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
              'Choose Username',
              style: CyberTheme.heading(size: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This is your public identity on Kerosene. It must be unique.',
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
                    label: 'Enter username',
                    hint: 'a-z, 0-9 and _',
                    icon: Icons.alternate_email_rounded,
                  ).copyWith(
                    helperText: 'Must be between 3 and 15 characters',
                    helperStyle: const TextStyle(
                      color: CyberTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 3) return 'Min 3 chars';
                if (value.length > 15) return 'Max 15 chars';
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                  return 'Invalid characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 64),
            AnimatedLoadingButton(
              onPressed: isLoading ? null : _submitAndGeneratePayment,
              text: 'Generate Payment Invoice',
              loadingTexts: const [
                'Calculating Proof of Work...',
                'Securing Keys...',
                'Generating Invoice...',
                'Connecting to Network...',
              ],
              baseColor: CyberTheme.neonCyan,
            ),
          ],
        ),
      ),
    );
  }
}
