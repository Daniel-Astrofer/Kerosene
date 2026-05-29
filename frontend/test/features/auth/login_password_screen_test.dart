import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/presentation/screens/login_screen.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('manual login screen uses account password copy without BIP39 UI',
      (tester) async {
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
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(username: 'alice', focusPassword: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Senha da conta'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.textContaining('passphrase'), findsNothing);
    expect(find.textContaining('Passphrase'), findsNothing);
    expect(find.textContaining('18 palavras'), findsNothing);
    expect(find.textContaining('SLIP-39'), findsNothing);
  });
}
