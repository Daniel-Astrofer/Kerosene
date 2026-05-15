import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/login_passphrase_screen.dart';
import 'package:teste/features/auth/presentation/screens/login_username_screen.dart';
import 'package:teste/features/auth/presentation/screens/passkey_verification_screen.dart';
import 'package:teste/features/auth/presentation/screens/totp_screen.dart';
import 'package:teste/l10n/app_localizations.dart';
import '../../helpers/test_auth_controller.dart';

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
            () => TestAuthController(
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
    testWidgets('login username screen remains centered on narrow screens', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const LoginUsernameScreen(),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'LoginUsernameScreen @ $size',
        );
      }
    });

    testWidgets(
        'login passphrase screen avoids overflow in portrait and landscape', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape]) {
        await pumpResponsiveScreen(
          tester,
          size: size,
          child: const LoginPassphraseScreen(username: 'astroferas'),
        );
        expectNoLayoutExceptions(
          tester,
          label: 'LoginPassphraseScreen @ $size',
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
