import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/login_screen.dart';
import 'package:teste/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/steps/signup_pow_step.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';
import 'package:teste/features/auth/presentation/screens/totp_screen.dart';
import 'package:teste/l10n/app_localizations.dart';
import 'package:teste/storybook/storybook_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compactPortrait = Size(320, 640);
  const compactLandscape = Size(568, 320);

  Future<void> pumpResponsiveScreen(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => MockAuthController(
              initialOverride: const AuthUnauthenticated(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;

    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }

    return exceptions;
  }

  void expectNoLayoutExceptions(
    WidgetTester tester, {
    required String label,
  }) {
    final exceptions = takeAllExceptions(tester);
    expect(
      exceptions,
      isEmpty,
      reason: '$label produced layout exceptions: $exceptions',
    );
  }

  group('Auth responsive layouts', () {
    testWidgets('signup shared step layout stays stable in compact sizes', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: Scaffold(
            body: SignupStepLayout(
              eyebrow: 'Create account',
              title: 'Prepare your secure access',
              subtitle: 'Review the final security details before continuing.',
              icon: LucideIcons.shield,
              tone: SignupSurfaceTone.primary,
              highlightLabel: 'Selected mode',
              highlightValue: 'Standard backup',
              highlightHint: 'Balanced for daily use across device sizes.',
              chips: const [
                'Guided backup',
                'Prepare secure access',
                '2FA required',
              ],
              footer: SignupPrimaryFooter(
                text: 'Continue and prepare the account',
                onPressed: () {},
                icon: LucideIcons.arrowRight,
              ),
              children: [
                SignupPanel(
                  child: Text(
                    'Final check before the secure credential setup starts.',
                    style: AppTheme.darkTheme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'SignupStepLayout @ $size',
        );
      }
    });

    testWidgets('signup pow step stays stable in compact sizes', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const SignupPowStep(
            username: 'astroferas',
            mnemonic: 'alpha beta gamma delta',
            accountSecurity: 'STANDARD',
            runId: 0,
          ),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'SignupPowStep @ $size',
        );
      }
    });

    testWidgets('login screen remains centered on narrow screens', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const LoginScreen(),
        );
        expect(find.text('lucas_01'), findsNothing);
        expect(find.text('KEROSENE'), findsNothing);
        expectNoLayoutExceptions(
          tester,
          label: 'LoginScreen @ $size',
        );
      }
    });

    testWidgets(
        'login passphrase fallback avoids overflow in portrait and landscape', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const LoginScreen(
            username: 'astroferas',
            focusPassphrase: true,
          ),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'LoginScreen fallback @ $size',
        );
      }
    });

    testWidgets('passkey verification screen stays aligned in compact sizes', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const PasskeyVerificationScreen(username: 'astroferas'),
        );
        expect(find.text('@astroferas'), findsNothing);
        expectNoLayoutExceptions(
          tester,
          label: 'PasskeyVerificationScreen @ $size',
        );
      }
    });

    testWidgets('totp screen remains stable in compact portrait and landscape',
        (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const TotpScreen(
            username: 'astroferas',
            passphrase: 'alpha beta gamma',
            isSetup: false,
            preAuthToken: 'token',
          ),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'TotpScreen @ $size',
        );
      }
    });
  });
}
