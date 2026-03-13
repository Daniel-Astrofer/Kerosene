import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/state/auth_state.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_payment_screen.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/theme/cyber_theme.dart';
import '../login_totp_screen.dart';

class SignupPasskeyScreen extends ConsumerWidget {
  const SignupPasskeyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(signupFlowProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    // Listener for state transitions
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthHardwareChallengeReceived) {
        // We handle the challenge automatically in AuthNotifier now
        // so we don't need to do anything here unless we want specialized UI.
      } else if (next is AuthHardwareVerified) {
        // Success! Now get the payment link
        ref
            .read(authProvider.notifier)
            .getOnboardingLink(flowState.sessionId ?? '');
      } else if (next is AuthPaymentRequired) {
        // Navigate to payment screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignupPaymentScreen()),
          (route) => false,
        );
      } else if (next is AuthRequiresLoginTotp) {
        // Redirecionamento após ativação mock ou real que requer login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginTotpScreen(
              username: next.username,
              passphrase: next.passphrase,
              preAuthToken: next.preAuthToken,
            ),
          ),
          (route) => false,
        );
      } else if (next is AuthAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          next.message,
          onRetry: () {
            ref.read(authProvider.notifier).clearError();
          },
          onGoBack: () {
            ref.read(authProvider.notifier).clearError();
            Navigator.pop(context);
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: CyberTheme.bgDeep,
      body: Container(
        decoration: BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: Column(
          children: [
            // Top Progress Bar
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Container(
                    height: 2,
                    color: const Color(0xFF2962FF), // Deep blue
                  ),
                ),
              ],
            ),

            // App Bar equivalent
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 8.0,
                  bottom: 8.0,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Glowing fingerprint icon
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF0C162C,
                          ), // Very dark blue base for the circle
                          border: Border.all(
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2962FF,
                              ).withValues(alpha: 0.15),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Two outer concentric dashed/dotted rings
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF2962FF,
                                  ).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF2962FF,
                                  ).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Core Icon
                            const Icon(
                              Icons.security_rounded, // Changed from fingerprint
                              size: 72,
                              color: Color(0xFF2962FF),
                            ),
                            // Small decorative star top right
                            const Positioned(
                              top: 25,
                              right: 35,
                              child: Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF2962FF),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    const Text(
                      'VERIFICAÇÃO DE\nCHAVE SOBERANA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 6.0,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // "Pronto para escanear" dot and text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2962FF),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2962FF),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PRONTO PARA ESCANEAR',
                          style: TextStyle(
                            color: Color(0xFF3D7CFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Continuous Button at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2962FF),
                      Color(0xFF1E3A8A),
                    ], // Blue gradient
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2962FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: isLoading
                        ? null
                        : () {
                          final sessionId = flowState.sessionId;
                          if (sessionId != null) {
                            ref
                                .read(authProvider.notifier)
                                .registerHardwareStart(sessionId);
                          }
                          },
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'AUTENTICAR AGORA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
