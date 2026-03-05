import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/cyber_theme.dart';
import '../../providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/state/auth_state.dart';
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import '../../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../../core/utils/error_translator.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../unknown_device_screen.dart';

import 'steps/fee_explanation_step.dart';
import 'steps/seed_security_selection_step.dart';
import 'steps/passphrase_step.dart';
import 'steps/totp_step.dart';
import 'steps/passkey_step.dart';
import 'steps/username_step.dart';
import 'steps/payment_step.dart';
import 'steps/confirmations_step.dart';

class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(signupFlowProvider);

    // Listen to global AuthState for wizard transitions
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthRequiresTotpSetup) {
        // API Signup was successful. Update wizard state and move to TOTP step.
        ref.read(signupFlowProvider.notifier).setTotpSecret(next.totpSecret);
        ref.read(signupFlowProvider.notifier).setQrCodeUri(next.qrCodeUri);
        ref.read(signupFlowProvider.notifier).goToStep(SignupStep.totp);
      } else if (next is AuthTotpVerified) {
        // TOTP verified. Update session and move to Passkey step.
        ref.read(signupFlowProvider.notifier).setSessionId(next.sessionId);
        ref.read(signupFlowProvider.notifier).goToStep(SignupStep.passkey);
      } else if (next is AuthRequiresLoginTotp) {
        // Post-signup login succeeded — now requires TOTP verification.
        // Pop out of signup and navigate to the TOTP verification screen.
        ref.read(signupFlowProvider.notifier).reset();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => UnknownDeviceScreen(
              username: next.username,
              passphrase: next.passphrase,
              rememberMe: false,
            ),
          ),
          (route) => route.isFirst,
        );
      } else if (next is AuthAuthenticated) {
        // Fully authenticated (e.g. backend auto-logged in after payment).
        ref.read(signupFlowProvider.notifier).reset();
        HomeScreen.skipNextAuth = true;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (next is AuthError) {
        ref.read(signupFlowProvider.notifier).setError(next.message);
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onGoBack: () {
            ref.read(authProvider.notifier).clearError();
            ref.read(signupFlowProvider.notifier).clearError();
            // Reset the entire flow to start over
            ref.read(signupFlowProvider.notifier).reset();
            // Navigate strictly back to login screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading:
            flowState.currentStep != SignupStep.feeExplanation &&
                flowState.currentStep != SignupStep.confirmations &&
                flowState.currentStep != SignupStep.payment
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: CyberTheme.textPrimary,
                ),
                onPressed: () {
                  ref.read(signupFlowProvider.notifier).previousStep();
                },
              )
            : flowState.currentStep == SignupStep.feeExplanation
            ? IconButton(
                icon: const Icon(Icons.close, color: CyberTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null, // No back button on payment and confirmations
        title: _StepIndicator(currentStep: flowState.currentStep),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              if (flowState.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CyberTheme.neonRed.withValues(alpha: 0.1),
                    border: Border.all(color: CyberTheme.neonRed),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flowState.error!,
                    style: const TextStyle(
                      color: CyberTheme.neonRed,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: _buildStepContent(flowState.currentStep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(SignupStep step) {
    switch (step) {
      case SignupStep.feeExplanation:
        return FeeExplanationStep(key: const ValueKey('feeExplanation'));
      case SignupStep.seedSecuritySelection:
        return SeedSecuritySelectionStep(
          key: const ValueKey('seedSecuritySelection'),
        );
      case SignupStep.passphrase:
        return PassphraseStep(key: const ValueKey('passphrase'));
      case SignupStep.totp:
        return TotpStep(key: const ValueKey('totp'));
      case SignupStep.passkey:
        return PasskeyStep(key: const ValueKey('passkey'));
      case SignupStep.username:
        return UsernameStep(key: const ValueKey('username'));
      case SignupStep.payment:
        return PaymentStep(key: const ValueKey('payment'));
      case SignupStep.confirmations:
        return ConfirmationsStep(key: const ValueKey('confirmations'));
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final SignupStep currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const totalSteps = 8;
    final activeStepIndex = currentStep.index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= activeStepIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: isActive ? 24 : 12,
          decoration: BoxDecoration(
            color: isActive ? CyberTheme.neonCyan : CyberTheme.border,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isActive
                ? CyberTheme.glow(CyberTheme.neonCyan, blur: 8)
                : [],
          ),
        );
      }),
    );
  }
}
