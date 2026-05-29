import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/presentation/screens/login_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:kerosene/features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

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
    testWidgets('real signup flow stays stable in compact sizes', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const SignupFlowScreen(),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'SignupFlowScreen @ $size',
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

    testWidgets('login password step avoids overflow in portrait and landscape',
        (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const LoginScreen(
            username: 'astroferas',
            focusPassword: true,
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
  });
}
