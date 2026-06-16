import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/presentation/widgets/recent_transaction_destinations_section.dart';
import 'package:kerosene/core/providers/recent_transaction_destinations_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prioritizes saved labels and localizes fallback kinds',
      (tester) async {
    final now = DateTime(2026, 1, 1);
    final labeledDestination = RecentTransactionDestination(
      address: 'bc1qhardwarevault000000000000000000000000000',
      label: 'Hardware vault',
      kind: RecentTransactionDestinationKind.onChain,
      lastUsedAt: now,
    );
    final internalDestination = RecentTransactionDestination(
      address: 'wallet-alice',
      kind: RecentTransactionDestinationKind.internal,
      lastUsedAt: now.subtract(const Duration(minutes: 1)),
    );
    RecentTransactionDestination? selectedDestination;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: RecentTransactionDestinationsSection(
              title: 'Recent',
              destinations: [labeledDestination, internalDestination],
              onSelect: (destination) => selectedDestination = destination,
            ),
          ),
        ),
      ),
    );

    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('Hardware vault'), findsOneWidget);
    expect(
      find.text('bc1qhardwarevault000000000000000000000000000'),
      findsOneWidget,
    );
    expect(find.text('wallet-alice'), findsOneWidget);
    expect(find.text('Internal transfer'), findsOneWidget);

    await tester.tap(find.text('Hardware vault'));
    await tester.pump();

    expect(selectedDestination, same(labeledDestination));
  });

  testWidgets('can request removal without selecting the destination',
      (tester) async {
    final destination = RecentTransactionDestination(
      address: 'bc1qhardwarevault000000000000000000000000000',
      label: 'Hardware vault',
      kind: RecentTransactionDestinationKind.onChain,
      lastUsedAt: DateTime(2026, 1, 1),
    );
    RecentTransactionDestination? selectedDestination;
    RecentTransactionDestination? removedDestination;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: RecentTransactionDestinationsSection(
              title: 'Recent',
              destinations: [destination],
              onSelect: (value) => selectedDestination = value,
              onRemove: (value) => removedDestination = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Delete'));
    await tester.pump();

    expect(selectedDestination, isNull);
    expect(removedDestination, same(destination));
  });

  testWidgets('can request clearing all destinations without selecting one',
      (tester) async {
    final destination = RecentTransactionDestination(
      address: 'lnbc1invoice000000000000000000000000000',
      label: 'Lightning vendor',
      kind: RecentTransactionDestinationKind.lightning,
      lastUsedAt: DateTime(2026, 1, 1),
    );
    RecentTransactionDestination? selectedDestination;
    var clearAllRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: RecentTransactionDestinationsSection(
              title: 'Recent lightning',
              destinations: [destination],
              onSelect: (value) => selectedDestination = value,
              onClearAll: () => clearAllRequested = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear all'));
    await tester.pump();

    expect(selectedDestination, isNull);
    expect(clearAllRequested, isTrue);
  });
}
