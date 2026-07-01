import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/errors/failures.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/domain/repositories/security_repository.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/features/security/presentation/widgets/app_entry_pin_gate.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/balance_websocket_provider.dart';
import 'package:kerosene/features/security/presentation/widgets/pin_entry_scaffold.dart';

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

  testWidgets('hides the numeric pad and shows loading while verifying PIN',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _PendingPinSecurityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _AuthenticatedAuthController(),
          ),
          securityRepositoryProvider.overrideWithValue(repository),
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
    await tester.tap(find.text('Toque para digitar'));
    await tester.pumpAndSettle();

    expect(find.byType(PinNumericPad), findsOneWidget);

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.verifyCalls, 1);
    expect(repository.lastPin, '1234');
    expect(find.byType(PinNumericPad), findsNothing);
    expect(find.byType(TorLoadingDots), findsOneWidget);

    repository.completeVerify(
      const Left(
        AuthFailure(
          message: 'ERR_AUTH_APP_PIN_INVALID',
          errorCode: 'ERR_AUTH_APP_PIN_INVALID',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TorLoadingDots), findsNothing);
    expect(find.byType(PinNumericPad), findsOneWidget);
    expect(find.text('Digite o PIN para acessar sua conta'), findsOneWidget);
  });

  test('reloads app PIN status when the authenticated session changes',
      () async {
    final repository = _SequencedPinStatusSecurityRepository([
      const AppPinStatus(enabled: true, configured: true),
      const AppPinStatus(enabled: false, configured: false),
    ]);

    final container = ProviderContainer(
      overrides: [
        securityRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith(
          () => _SwitchableAuthController(_testUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    final first = await container.read(appPinStatusProvider.future);
    expect(first.configured, isTrue);

    (container.read(authControllerProvider.notifier)
            as _SwitchableAuthController)
        .setUser(
      User(
        id: 'user-2',
        username: 'hal',
        createdAt: DateTime(2026, 1, 2),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final second = await container.read(appPinStatusProvider.future);
    expect(second.configured, isFalse);
    expect(repository.statusCalls, 2);
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

class _SwitchableAuthController extends AuthController {
  final User initialUser;

  _SwitchableAuthController(this.initialUser);

  @override
  AuthState build() => AuthAuthenticated(initialUser);

  void setUser(User user) {
    state = AuthAuthenticated(user);
  }
}

class _PendingPinSecurityRepository implements SecurityRepository {
  final Completer<Either<Failure, AppPinStatus>> _verifyCompleter =
      Completer<Either<Failure, AppPinStatus>>();
  int verifyCalls = 0;
  String? lastPin;

  @override
  Future<Either<Failure, AppPinStatus>> verifyAppPin({
    required String pin,
  }) {
    verifyCalls += 1;
    lastPin = pin;
    return _verifyCompleter.future;
  }

  void completeVerify(Either<Failure, AppPinStatus> result) {
    _verifyCompleter.complete(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SequencedPinStatusSecurityRepository implements SecurityRepository {
  final List<AppPinStatus> statuses;
  int statusCalls = 0;

  _SequencedPinStatusSecurityRepository(this.statuses);

  @override
  Future<Either<Failure, AppPinStatus>> getAppPinStatus() async {
    final index = statusCalls.clamp(0, statuses.length - 1);
    statusCalls += 1;
    return Right(statuses[index]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _testUser = User(
  id: 'user-1',
  username: 'satoshi',
  createdAt: DateTime(2026, 1, 1),
);
