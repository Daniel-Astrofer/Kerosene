import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/core/providers/shader_provider.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/home/presentation/widgets/animated_balance_display.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/balance_settings_provider.dart';
import 'package:teste/features/wallet/presentation/widgets/wallet_credit_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const compactPortrait = Size(320, 640);
  const compactLandscape = Size(568, 320);
  const largePortrait = Size(430, 932);

  final wallet = Wallet(
    id: 'wallet-001',
    name: 'Vault Prime',
    address: 'bc1qv4ult9n3w2k7x8r6m5t4p2s0y7z6x5c4v3b2n1',
    balance: 9876543210.12345678,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.nativeSegwit,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  Future<ProviderContainer> pumpHarness(
    WidgetTester tester, {
    required Size size,
  }) async {
    SharedPreferences.setMockInitialValues(const {
      'balance_hidden': false,
      'balance_decimals': 8,
    });

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        metalShaderProvider.overrideWith(
          (ref) async =>
              throw UnsupportedError('Shader disabled in widget test'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: _HomeBalanceHarness(wallet: wallet),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    return container;
  }

  List<Object> takeAllExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    Object? exception;

    while ((exception = tester.takeException()) != null) {
      exceptions.add(exception!);
    }

    return exceptions;
  }

  void expectNoLayoutExceptions(
    WidgetTester tester, {
    required String label,
  }) {
    final exceptions = takeAllExceptions(tester);
    expect(
      exceptions,
      isEmpty,
      reason: '$label produced layout exceptions: $exceptions',
    );
  }

  Future<void> disposeHarness(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  group('Home balance responsiveness', () {
    testWidgets('global balance and wallet card stay stable with long values', (
      tester,
    ) async {
      for (final size in [compactPortrait, compactLandscape, largePortrait]) {
        await pumpHarness(tester, size: size);
        expectNoLayoutExceptions(
          tester,
          label: 'Home balance harness @ $size',
        );
        await disposeHarness(tester);
      }
    });

    testWidgets('hide balances and decimal changes do not break the layout', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        size: compactPortrait,
      );

      final notifier = container.read(balanceSettingsProvider.notifier);
      notifier.toggleVisibility();
      notifier.setDecimalPlaces(2);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(container.read(balanceSettingsProvider).isHidden, isTrue);
      expect(container.read(balanceSettingsProvider).decimalPlaces, 2);
      expect(find.text('BTC ••••••••'), findsOneWidget);
      expectNoLayoutExceptions(
        tester,
        label: 'Home balance harness after settings change',
      );
      await disposeHarness(tester);
    });

    testWidgets('decimal precision cycles through 8, 4 and 2 only', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        size: compactPortrait,
      );

      final notifier = container.read(balanceSettingsProvider.notifier);

      notifier.cycleDecimals();
      await tester.pump();
      expect(container.read(balanceSettingsProvider).decimalPlaces, 4);

      notifier.cycleDecimals();
      await tester.pump();
      expect(container.read(balanceSettingsProvider).decimalPlaces, 2);

      notifier.cycleDecimals();
      await tester.pump();
      expect(container.read(balanceSettingsProvider).decimalPlaces, 8);

      expectNoLayoutExceptions(
        tester,
        label: 'Home balance harness after decimal cycling',
      );
      await tester.pump(const Duration(seconds: 2));
      await disposeHarness(tester);
    });

    testWidgets('tapping the decimal area triggers the precision callback', (
      tester,
    ) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFF02050C),
            body: Center(
              child: AnimatedBalanceDisplay(
                balance: 1234.5678,
                prefix: 'BTC ',
                decimalPlaces: 4,
                locale: 'pt_BR',
                onDecimalTap: () => tapCount++,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AnimatedBalanceDisplay),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tapCount, 1);
      expectNoLayoutExceptions(
        tester,
        label: 'Animated balance decimal tap target',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

class _HomeBalanceHarness extends ConsumerWidget {
  final Wallet wallet;

  const _HomeBalanceHarness({
    required this.wallet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balanceSettings = ref.watch(balanceSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF02050C),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedBalanceDisplay(
                      balance: wallet.balance,
                      prefix: 'BTC ',
                      decimalPlaces: balanceSettings.decimalPlaces,
                      isHidden: balanceSettings.isHidden,
                      decimalScaleFactor: 0.65,
                      separatorScaleFactor: 0.65,
                      style: theme.textTheme.displayLarge!.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      balanceSettings.isHidden
                          ? 'BTC ••••••••'
                          : 'US\$ 999,999,999,999,999.99',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.52),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 303,
                      height: 191,
                      child: WalletCreditCard(
                        wallet: wallet,
                        colorIndex: 0,
                        isSelected: true,
                        showDetails: true,
                        onLongPress: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
