// Kerosene Storybook — Authentication Screen Stories
// Contains all auth-related screens: welcome, login, signup, passkey, TOTP, etc.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/auth/presentation/screens/welcome_screen.dart';
import 'package:teste/features/auth/presentation/screens/login_screen.dart';
import 'package:teste/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'package:teste/features/auth/presentation/screens/totp_screen.dart';
import 'package:teste/features/auth/presentation/screens/biometric_auth_screen.dart';
import 'package:teste/features/auth/presentation/screens/unknown_device_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_requirements_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_security_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_username_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_seed_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_verification_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_totp_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_hardware_step.dart';

/// Mock username for stories that require auth context.
const _mockUsername = 'satoshi_storybook';
const _mockPassphrase =
    'abandon ability able about above absent absorb abstract absurd abuse access accident';
const _mockSessionId = 'mock_session_123';

/// Returns all authentication-related stories for the Storybook catalog.
List<Story> authStories() {
  return [
    // ─── Onboarding ─────────────────────────────────────
    Story(
      name: 'Auth/Welcome Screen',
      description:
          'Initial landing screen with logo animation and CTA buttons.',
      builder: (context) => const WelcomeScreen(),
    ),

    // ─── Login Flow ─────────────────────────────────────
    Story(
      name: 'Auth/Login',
      description: 'Single login screen with passkey and passphrase access.',
      builder: (context) => const LoginScreen(),
    ),
    Story(
      name: 'Auth/Login — Passkey Verification',
      description: 'Passkey biometric challenge screen.',
      builder: (context) => const PasskeyVerificationScreen(
        username: _mockUsername,
      ),
    ),
    Story(
      name: 'Auth/Login — TOTP Challenge',
      description: '6-digit TOTP code entry for 2FA.',
      builder: (context) => TotpScreen(
        username: _mockUsername,
        passphrase: _mockPassphrase,
        isSetup: false,
      ),
    ),

    // ─── TOTP Management ────────────────────────────────
    Story(
      name: 'Auth/TOTP Screen',
      description: 'Unified TOTP screen for both setup and login.',
      builder: (context) {
        final isSetup = context.knobs.boolean(
          label: 'Setup Mode',
          initial: true,
        );
        return TotpScreen(
          username: _mockUsername,
          passphrase: _mockPassphrase,
          isSetup: isSetup,
          totpSecret: 'JBSWY3DPEHPK3PXP',
          qrCodeUri:
              'otpauth://totp/Kerosene:storybook?secret=JBSWY3DPEHPK3PXP&issuer=Kerosene',
        );
      },
    ),

    // ─── Security ───────────────────────────────────────
    Story(
      name: 'Auth/Biometric Auth',
      description: 'Biometric authentication prompt (fingerprint/face).',
      builder: (context) => const BiometricAuthScreen(),
    ),
    Story(
      name: 'Auth/Unknown Device',
      description: 'Alert screen when login from unrecognized device.',
      builder: (context) => const UnknownDeviceScreen(
        username: _mockUsername,
        passphrase: _mockPassphrase,
      ),
    ),

    // ─── Signup Flow (Integrated) ────────────────────────
    Story(
      name: 'Auth/Signup — Main Flow',
      description: 'Top-level signup orchestrator screen (9 steps).',
      builder: (context) => const SignupFlowScreen(),
    ),

    // ─── Signup Steps (Individual Previews) ──────────────
    Story(
      name: 'Auth/Signup/Steps — 1. Requirements',
      builder: (context) => SignupRequirementsStep(onNext: () {}),
    ),
    Story(
      name: 'Auth/Signup/Steps — 2. Security Option',
      builder: (context) => SignupSecurityStep(onNext: () {}),
    ),
    Story(
      name: 'Auth/Signup/Steps — 3. Username',
      builder: (context) => SignupUsernameStep(
        initialUsername: '',
        onNext: (u) {},
      ),
    ),
    Story(
      name: 'Auth/Signup/Steps — 4. Seed Phrase',
      builder: (context) => SignupSeedStep(onNext: (s) {}),
    ),
    Story(
      name: 'Auth/Signup/Steps — 5. Seed Verification',
      builder: (context) => SignupVerificationStep(
        mnemonic: _mockPassphrase,
        onNext: () {},
      ),
    ),
    Story(
      name: 'Auth/Signup/Steps — 7. TOTP Setup',
      builder: (context) => SignupTotpStep(
        username: _mockUsername,
        passphrase: _mockPassphrase,
        totpSecret: 'JBSWY3DPEHPK3PXP',
        qrCodeUri: 'otpauth://totp/Kerosene:storybook?secret=JBSWY3DPEHPK3PXP',
        onVerified: () {},
      ),
    ),
    Story(
      name: 'Auth/Signup/Steps — 8. Hardware Register',
      builder: (context) => SignupHardwareStep(
        sessionId: _mockSessionId,
        onVerified: () {},
      ),
    ),
  ];
}
