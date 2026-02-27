import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/core/presentation/widgets/animated_loading_button.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

class PasskeyStep extends ConsumerStatefulWidget {
  const PasskeyStep({super.key});

  @override
  ConsumerState<PasskeyStep> createState() => _PasskeyStepState();
}

class _PasskeyStepState extends ConsumerState<PasskeyStep> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authMessage = '';

  Future<void> _createPasskey() async {
    try {
      final repo = ref.read(authProvider.notifier).authRepository;
      final flowNotifier = ref.read(signupFlowProvider.notifier);
      final sessionId = ref.read(signupFlowProvider).sessionId;

      if (sessionId == null) {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'Session not found. Please restart the process.';
        });
        return;
      }

      // 1. Check Biometrics
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isAuthenticating = false;
          _authMessage = 'No biometric hardware available on this device.';
        });
        return;
      }

      // 2. Start Passkey Registration with Backend
      final startResult = await repo.registerPasskeyOnboardingStart(sessionId);

      await startResult.fold(
        (failure) async {
          setState(() {
            _isAuthenticating = false;
            _authMessage = 'Error starting registration: ${failure.message}';
          });
        },
        (optionsJson) async {
          // 3. Authenticate with Device
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Create a Passkey to secure your Kerosene wallet',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );

          if (didAuthenticate) {
            // 4. Finish Passkey Registration with Backend
            // (In a real WebAuthn flow, we'd pass the credential result.
            // For now, we simulate with a placeholder as the local_auth doesn't return full WebAuthn data)
            final finishResult = await repo.registerPasskeyOnboardingFinish(
              sessionId,
              '{"placeholder": "credential_data"}',
            );

            await finishResult.fold(
              (failure) async {
                setState(() {
                  _isAuthenticating = false;
                  _authMessage =
                      'Error finishing registration: ${failure.message}';
                });
              },
              (_) async {
                // Success! Fetch payment link before moving on
                await flowNotifier.fetchPaymentLink(repo);
                flowNotifier.nextStep();
              },
            );
          } else {
            setState(() {
              _isAuthenticating = false;
              _authMessage = 'Authentication cancelled or failed.';
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authMessage = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.fingerprint_rounded,
            size: 80,
            color: CyberTheme.neonPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'Create Device Passkey',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bind your device\'s biometrics (Face ID/Touch ID) to this account for seamless and secure future logins without a password.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          if (_authMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                _authMessage,
                style: const TextStyle(
                  color: CyberTheme.neonAmber,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          AnimatedLoadingButton(
            onPressed: _isAuthenticating ? null : _createPasskey,
            text: 'Register Device Biometrics',
            loadingTexts: const [
              'Initializing Biometrics...',
              'Securing Device...',
              'Registering Passkey...',
            ],
            baseColor: CyberTheme.neonPurple,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              // Option to skip passkey creation
              final repo = ref.read(authProvider.notifier).authRepository;
              final flowNotifier = ref.read(signupFlowProvider.notifier);
              await flowNotifier.fetchPaymentLink(repo);
              flowNotifier.nextStep();
            },
            style: TextButton.styleFrom(
              foregroundColor: CyberTheme.textSecondary,
            ),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
