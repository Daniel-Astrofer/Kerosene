import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_flow_screen.dart';
import 'package:teste/l10n/app_localizations.dart';
import 'package:teste/storybook/storybook_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup screen starts with strong-password account flow only',
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
          home: const SignupFlowScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Conta e credenciais'), findsOneWidget);
    expect(
      find.textContaining(
        'Se você perder a senha sem os códigos de recuperação',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Escolha seu identificador público'),
      findsOneWidget,
    );
    expect(find.textContaining('18 palavras'), findsNothing);
    expect(find.textContaining('frase secreta'), findsNothing);
  });
}
