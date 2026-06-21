import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/features/home/presentation/screens/startup_connection_loading_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.isTorEnabled = false;
  });

  tearDown(() {
    AppConfig.isTorEnabled = false;
  });

  Future<void> pumpStartupScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartupConnectionLoadingScreen(
          childAfterWarmup: Text('warmup-child-ready'),
        ),
      ),
    );
  }

  testWidgets('keeps child hidden while Tor is not ready', (tester) async {
    await pumpStartupScreen(tester);

    await tester.pump(const Duration(seconds: 14));

    expect(find.text('warmup-child-ready'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows child after Tor reaches ready state', (tester) async {
    await pumpStartupScreen(tester);

    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('warmup-child-ready'), findsNothing);

    AppConfig.isTorEnabled = true;
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('warmup-child-ready'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
