import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/storybook/storybook_mocks.dart';
import 'package:kerosene/storybook/stories/receive_stories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('receive request stories render every documented state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final scenario in ReceiveRequestStoryScenario.values) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionHistoryProvider.overrideWith(
              (ref) async => mockTransactions,
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ReceiveRequestsScenarioPreview(scenario: scenario),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.label} should render without widget exceptions.',
      );
      expect(find.byType(ReceiveRequestsScenarioPreview), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
