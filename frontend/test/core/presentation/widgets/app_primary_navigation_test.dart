import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/features/security/presentation/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }
    return exceptions;
  }

  Widget localizedApp({
    required Widget home,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: routes ?? const <String, WidgetBuilder>{},
      home: home,
    );
  }

  Widget navigationSurface(AppPrimaryDestination destination, String label) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Text(label)),
          AppPrimaryNavigationBar.overlay(currentDestination: destination),
        ],
      ),
    );
  }

  Offset closedButtonCenter(Size size) {
    return Offset(size.width / 2, size.height - 56);
  }

  testWidgets('expands centered without overflow on compact screens', (
    tester,
  ) async {
    for (final size in const [
      Size(300, 640),
      Size(320, 720),
      Size(360, 780),
      Size(430, 900),
    ]) {
      await setViewport(tester, size);
      await tester.pumpWidget(
        localizedApp(
          home: navigationSurface(AppPrimaryDestination.settings, 'settings'),
        ),
      );

      await tester.tapAt(closedButtonCenter(size));
      await tester.pumpAndSettle();

      final navSurface = tester.getRect(
        find.byKey(const ValueKey('appPrimaryNavigationSurface')),
      );
      expect(
        (navSurface.center.dx - size.width / 2).abs(),
        lessThanOrEqualTo(0.5),
        reason: 'Primary navigation must open from the horizontal center.',
      );
      expect(navSurface.left, greaterThanOrEqualTo(16));
      expect(navSurface.right, lessThanOrEqualTo(size.width - 16));

      for (final destination in AppPrimaryDestination.values) {
        final itemRect = tester.getRect(
          find.byKey(
            ValueKey('appPrimaryNavigationDestination-${destination.name}'),
          ),
        );
        expect(
          navSurface.contains(itemRect.topLeft) &&
              navSurface.contains(itemRect.bottomRight),
          isTrue,
          reason: '${destination.name} must stay inside the navigation bar.',
        );
      }

      for (final label in ['Início', 'Cartão', 'Histórico', 'Ajustes']) {
        final labelRect = tester.getRect(find.text(label));
        expect(
          navSurface.contains(labelRect.topLeft) &&
              navSurface.contains(labelRect.bottomRight),
          isTrue,
          reason: '$label must stay inside the navigation bar.',
        );
      }
      expect(
        takeAllExceptions(tester),
        isEmpty,
        reason: 'Primary navigation overflowed at $size.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('selecting a destination navigates after the close animation', (
    tester,
  ) async {
    const size = Size(430, 900);
    await setViewport(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppPrimaryDestination.home.routeName,
        routes: {
          AppPrimaryDestination.home.routeName: (_) => navigationSurface(
                AppPrimaryDestination.home,
                'home route',
              ),
          AppPrimaryDestination.card.routeName: (_) => navigationSurface(
                AppPrimaryDestination.card,
                'accounts route',
              ),
          AppPrimaryDestination.history.routeName: (_) => navigationSurface(
                AppPrimaryDestination.history,
                'history route',
              ),
          AppPrimaryDestination.settings.routeName: (_) => navigationSurface(
                AppPrimaryDestination.settings,
                'settings route',
              ),
        },
      ),
    );

    await tester.tapAt(closedButtonCenter(size));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('appPrimaryNavigationDestination-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('accounts route'), findsOneWidget);
    expect(takeAllExceptions(tester), isEmpty);
  });

  testWidgets('modal barrier fades out instead of disappearing on close', (
    tester,
  ) async {
    const size = Size(430, 900);
    await setViewport(tester, size);
    await tester.pumpWidget(
      localizedApp(
        home: navigationSurface(AppPrimaryDestination.home, 'home'),
      ),
    );

    Finder barrierBox() {
      return find.byWidgetPredicate((widget) {
        return widget is ColoredBox &&
            widget.color == Colors.black.withValues(alpha: 0.16);
      });
    }

    await tester.tapAt(closedButtonCenter(size));
    await tester.pumpAndSettle();

    expect(barrierBox(), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    expect(
      barrierBox(),
      findsOneWidget,
      reason: 'The modal barrier should remain mounted while opacity fades.',
    );

    await tester.pumpAndSettle();
    expect(takeAllExceptions(tester), isEmpty);
  });

  testWidgets('settings screen renders the primary navigation when requested', (
    tester,
  ) async {
    const size = Size(430, 900);
    await setViewport(tester, size);
    await tester.pumpWidget(
      const ProviderScope(
        child: _SettingsNavigationHarness(),
      ),
    );

    await tester.tapAt(closedButtonCenter(size));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(takeAllExceptions(tester), isEmpty);
  });
}

class _SettingsNavigationHarness extends StatelessWidget {
  const _SettingsNavigationHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(showPrimaryNavigation: true),
    );
  }
}
