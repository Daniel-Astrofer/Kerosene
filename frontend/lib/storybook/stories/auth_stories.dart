// Kerosene Storybook — Authentication Screen Stories
// Contains auth screens that are still part of the app flows.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/auth/presentation/screens/welcome_screen.dart';
import 'package:teste/features/auth/presentation/screens/login_screen.dart';
import 'package:teste/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_flow_screen.dart';

/// Mock username for stories that require auth context.
const _mockUsername = 'satoshi_storybook';

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
      description: 'Login screen with password entry before device key check.',
      builder: (context) => const LoginScreen(),
    ),
    Story(
      name: 'Auth/Login — Passkey Verification',
      description: 'Passkey biometric challenge screen.',
      builder: (context) => const PasskeyVerificationScreen(
        username: _mockUsername,
      ),
    ),

    // ─── Signup Flow (Integrated) ────────────────────────
    Story(
      name: 'Auth/Signup — Main Flow',
      description: 'Real signup flow used by the app route /signup.',
      builder: (context) => const SignupFlowScreen(),
    ),
  ];
}
