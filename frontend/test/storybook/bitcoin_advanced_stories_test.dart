import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_screens/cold_wallet_creation_screen.dart';
import 'package:kerosene/storybook/stories/bitcoin_advanced_stories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bitcoin advanced stories include cold wallet creation flow', () {
    final storyNames = bitcoinAdvancedStories().map((story) => story.name);

    expect(storyNames, contains('Bitcoin/Cold Wallet/Create Flow'));
    expect(storyNames, contains('Bitcoin/Cards Surface'));
  });

  testWidgets('cards surface story renders card tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BitcoinCardsSurfaceStoryPreview(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    expect(find.byType(BitcoinAccountsScreen), findsOneWidget);
    expect(find.text('Cartão Kerosene'), findsWidgets);
    expect(find.text('STATUS DA CARTEIRA'), findsOneWidget);
    expect(find.text('ENDEREÇO DE RECEBIMENTO'), findsOneWidget);
    expect(find.text('Criar carteira'), findsOneWidget);
  });

  testWidgets('cold wallet creation story renders the first flow screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ColdWalletCreationStoryPreview(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    expect(find.byType(ColdWalletCreationScreen), findsOneWidget);
    expect(find.text('Nível de segurança'), findsWidgets);
    expect(find.text('Gerar palavras'), findsOneWidget);
  });
}
