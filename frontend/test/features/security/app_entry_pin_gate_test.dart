import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/security/presentation/widgets/app_entry_pin_gate.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/balance_websocket_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the requested PIN setup and unlock copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _AuthenticatedAuthController(),
          ),
          appPinStatusProvider.overrideWith((ref) async {
            return const AppPinStatus(
              configured: false,
              minPinLength: 4,
              maxPinLength: 8,
            );
          }),
          balanceWebSocketServiceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppEntryPinGate(
            child: Text('home ready'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Crie um PIN para acessar a conta'), findsOneWidget);

    await tester.tap(find.text('Toque para digitar'));
    await tester.pumpAndSettle();

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Confirme o PIN'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _AuthenticatedAuthController(),
          ),
          appPinStatusProvider.overrideWith((ref) async {
            return const AppPinStatus(
              enabled: true,
              configured: true,
              minPinLength: 4,
              maxPinLength: 8,
            );
          }),
          balanceWebSocketServiceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppEntryPinGate(
            child: Text('home ready'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Digite o PIN para acessar sua conta'), findsOneWidget);
  });

  testWidgets('retries a transient PIN status failure before showing the app',
      (tester) async {
    var statusLoadCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _AuthenticatedAuthController(),
          ),
          appPinStatusProvider.overrideWith((ref) async {
            statusLoadCount += 1;
            if (statusLoadCount == 1) {
              throw Exception('PIN status temporarily unavailable');
            }
            return const AppPinStatus(configured: true);
          }),
          appEntryPinUnlockedProvider.overrideWith(
            () => _UnlockedAppEntryPinNotifier(),
          ),
          balanceWebSocketServiceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: AppEntryPinGate(
            child: Text('home ready'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PIN indisponível'), findsNothing);
    expect(find.text('home ready'), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(statusLoadCount, 2);
    expect(find.text('PIN indisponível'), findsNothing);
    expect(find.text('home ready'), findsOneWidget);
  });
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(_testUser);
}

class _UnlockedAppEntryPinNotifier extends AppEntryPinUnlockNotifier {
  @override
  bool build() => true;
}

final _testUser = User(
  id: 'user-1',
  username: 'satoshi',
  createdAt: DateTime(2026, 1, 1),
);
