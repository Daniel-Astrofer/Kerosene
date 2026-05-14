import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/kerosene_header.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'steps/signup_username_step.dart';
import 'steps/signup_seed_step.dart';
import 'steps/signup_verification_step.dart';
import 'steps/signup_security_step.dart';
import 'steps/signup_payment_step.dart'; // This is the Forge step
import 'steps/signup_requirements_step.dart';
import 'steps/signup_totp_step.dart';
import 'steps/signup_final_payment_step.dart';
import 'steps/signup_hardware_step.dart';
import '../totp_screen.dart';

/// Coordinator for the 9-step consolidated sequential signup flow.
class SignupFlowScreen extends ConsumerStatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  ConsumerState<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends ConsumerState<SignupFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // State retained across steps
  String _username = '';
  String _mnemonic = '';
  String _totpSecret = '';
  String _qrCodeUri = '';
  List<String> _backupCodes = [];
  String _sessionId = '';

  void _nextStep() {
    if (_currentStep < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthState to auto-advance during Forge and TOTP
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthRequiresTotpSetup) {
        setState(() {
          _totpSecret = next.totpSecret;
          _qrCodeUri = next.qrCodeUri;
          _backupCodes = next.backupCodes;
        });
        if (_currentStep == 5) _nextStep(); // Advance from Forge to TOTP
      } else if (next is AuthTotpVerified) {
        setState(() {
          _sessionId = next.sessionId;
        });
        if (_currentStep == 6) {
          _nextStep(); // Advance from TOTP to Hardware Register
        }
      } else if (next is AuthHardwareVerified) {
        if (_currentStep == 7) {
          _nextStep(); // Advance from Hardware to Final Payment
        }
      } else if (next is AuthRequiresLoginTotp) {
        // Mock payment was confirmed and auto-login triggered a TOTP requirement
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TotpScreen(
              username: _username,
              passphrase: _mnemonic,
              isSetup: false,
              preAuthToken: next.preAuthToken,
            ),
          ),
        );
      } else if (next is AuthAuthenticated) {
        // Final success - go to home
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home_loading', (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            KeroseneHeader(
              title: _currentStep >= 5 ? 'FINALIZAR' : 'CRIAR CONTA',
              onBackPressed: _prevStep,
            ),

            // Progress Indicator (9 segments)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: List.generate(9, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: index < 8 ? 4 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Step Views
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Enforce validation
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  SignupRequirementsStep(onNext: _nextStep),
                  SignupSecurityStep(onNext: _nextStep),
                  SignupUsernameStep(
                    initialUsername: _username,
                    onNext: (username) {
                      setState(() => _username = username);
                      _nextStep();
                    },
                  ),
                  SignupSeedStep(
                    onNext: (mnemonic) {
                      setState(() => _mnemonic = mnemonic);
                      _nextStep();
                    },
                  ),
                  SignupVerificationStep(
                    mnemonic: _mnemonic,
                    onNext: _nextStep,
                  ),
                  SignupPaymentStep(
                    // This widget is the "Forge" step
                    username: _username,
                    mnemonic: _mnemonic,
                  ),
                  SignupTotpStep(
                    username: _username,
                    passphrase: _mnemonic,
                    totpSecret: _totpSecret,
                    qrCodeUri: _qrCodeUri,
                    backupCodes: _backupCodes,
                    onVerified: () {
                      // Handled by ref.listen
                    },
                  ),
                  SignupHardwareStep(
                    sessionId: _sessionId,
                    onVerified: () {
                      // Handled by ref.listen
                    },
                  ),
                  SignupFinalPaymentStep(
                    sessionId: _sessionId,
                    username: _username,
                    password: _mnemonic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
