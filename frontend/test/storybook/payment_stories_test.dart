import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/storybook/stories/payment_stories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('payment intent stories render every storybook scenario',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final scenario in PaymentIntentStoryScenario.values) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PaymentIntentScenarioPreview(scenario: scenario),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.label} should render without widget exceptions.',
      );
      expect(find.byType(PaymentIntentScenarioPreview), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
