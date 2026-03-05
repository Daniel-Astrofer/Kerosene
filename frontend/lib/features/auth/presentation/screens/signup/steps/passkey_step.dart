import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/core/presentation/widgets/animated_loading_button.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

class PasskeyStep extends ConsumerStatefulWidget {
  const PasskeyStep({super.key});

  @override
  ConsumerState<PasskeyStep> createState() => _PasskeyStepState();
}

class _PasskeyStepState extends ConsumerState<PasskeyStep>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authMessage = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _createPasskey() async {
    setState(() {
      _isAuthenticating = true;
      _authMessage = '';
    });

    try {
      final repo = ref.read(authProvider.notifier).authRepository;
      final flowNotifier = ref.read(signupFlowProvider.notifier);
      final sessionId = ref.read(signupFlowProvider).sessionId;

      if (sessionId == null) {
        setState(() {
          _isAuthenticating = false;
          _authMessage = context.l10n.passkeySessionNotFound;
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
          _authMessage = context.l10n.passkeyNoBiometrics;
        });
        return;
      }

      // 2. Start Passkey Registration with Backend
      final startResult = await repo.registerPasskeyOnboardingStart(sessionId);

      await startResult.fold(
        (failure) async {
          setState(() {
            _isAuthenticating = false;
            _authMessage = context.l10n.passkeyErrorStarting(failure.message);
          });
        },
        (optionsJson) async {
          // 3. Authenticate with Device
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: context.l10n.passkeyBiometricReason,
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );

          if (didAuthenticate) {
            // 4. Finish Passkey Registration with Backend
            final finishResult = await repo.registerPasskeyOnboardingFinish(
              sessionId,
              '{"placeholder": "credential_data", "originalOptions": $optionsJson}',
            );

            await finishResult.fold(
              (failure) async {
                setState(() {
                  _isAuthenticating = false;
                  _authMessage = context.l10n.passkeyErrorFinishing(
                    failure.message,
                  );
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
              _authMessage = context.l10n.passkeyAuthFailed;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authMessage = context.l10n.passkeyUnexpectedError(e.toString());
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
          _buildHexagonIcon(),
          const SizedBox(height: 32),
          Text(
            context.l10n.passkeyTitle.toUpperCase(),
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(),
          const SizedBox(height: 48),
          if (_authMessage.isNotEmpty) _buildErrorMessage(),
          AnimatedLoadingButton(
            onPressed: _isAuthenticating ? null : _createPasskey,
            text: context.l10n.passkeyRegisterButton,
            loadingTexts: [
              context.l10n.passkeyLoadingInitBiom,
              context.l10n.passkeyLoadingSecuring,
              context.l10n.passkeyLoadingRegistering,
            ],
            baseColor: CyberTheme.neonPurple,
          ),
          const SizedBox(height: 20),
          _buildSkipButton(),
        ],
      ),
    );
  }

  Widget _buildHexagonIcon() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CyberTheme.neonPurple.withValues(
                        alpha: 0.15 * _pulseController.value,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: CyberTheme.beveledDecoration(
              borderColor: CyberTheme.neonPurple.withValues(alpha: 0.5),
              fillColor: CyberTheme.bgCard,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 64,
              color: CyberTheme.neonPurple,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: CyberTheme.neonPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Text(
                context.l10n.passkeySubtitle,
                style: CyberTheme.monoData(
                  size: 13,
                  color: CyberTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoBadge(Icons.security_rounded, "E2EE"),
                  const SizedBox(width: 8),
                  _infoBadge(Icons.phonelink_lock_rounded, "SECURE ELEMENT"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CyberTheme.neonPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CyberTheme.neonPurple),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: CyberTheme.neonPurple,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberTheme.neonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CyberTheme.neonRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: CyberTheme.neonRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _authMessage,
              style: const TextStyle(color: CyberTheme.neonRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isAuthenticating
          ? null
          : () async {
              final repo = ref.read(authProvider.notifier).authRepository;
              final flowNotifier = ref.read(signupFlowProvider.notifier);
              await flowNotifier.fetchPaymentLink(repo);
              flowNotifier.nextStep();
            },
      style: TextButton.styleFrom(
        foregroundColor: CyberTheme.textMuted,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        context.l10n.passkeySkip.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
