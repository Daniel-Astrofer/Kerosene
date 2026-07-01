import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/design_system/icons.dart';

import 'package:kerosene/features/movement/widgets/transaction_amount_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders editable BTC value with decimal keypad', (tester) async {
    final taps = <String>[];

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        title: 'Transaction amount',
        direction: TransactionAmountDirection.send,
        rail: 'Bitcoin',
        sourceParty: const TransactionPartyData(
          prefix: 'From',
          title: 'Main wallet',
          subtitle: 'bc1qsource0000000000000000000000000000000000',
          icon: KeroseneIcons.wallet,
        ),
        destinationParty: const TransactionPartyData(
          prefix: 'To',
          title: 'Recipient',
          subtitle: 'bc1qdest000000000000000000000000000000000000',
          icon: KeroseneIcons.send,
        ),
        amountLabel: '0.001',
        unitLabel: 'BTC',
        fiatReference: '~ R\$ 320,00',
        ctaLabel: 'Continue',
        onKeyTap: taps.add,
      ),
    );

    expect(find.text('0.001'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('~ R\$ 320,00'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-keypad-1')), findsOneWidget);
    expect(find.text(','), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transaction-keypad-1')));

    expect(taps, ['1']);
  });

  testWidgets('fiat reference can trigger currency switching', (tester) async {
    var switched = false;

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        amountLabel: '0,001',
        unitLabel: 'BTC',
        fiatReference: '≈ R\$ 320,00',
        onFiatReferenceTap: () => switched = true,
      ),
    );

    await tester.tap(find.text('≈ R\$ 320,00'));

    expect(switched, isTrue);
  });

  testWidgets('renders selected network connector between parties', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      const TransactionAmountSurface(
        rail: 'Pagamento',
        connectionLabel: 'Lightning',
        sourceParty: TransactionPartyData(
          prefix: 'De',
          title: 'Carteira principal',
          subtitle: 'wallet-1',
        ),
        destinationParty: TransactionPartyData(
          prefix: 'Para',
          title: 'Invoice Lightning',
          subtitle: 'lnbc...',
        ),
        amountLabel: '0.001',
        unitLabel: 'BTC',
      ),
    );

    expect(find.textContaining('Carteira principal'), findsOneWidget);
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.textContaining('Invoice Lightning'), findsOneWidget);
  });

  testWidgets('renders locked read-only value without keypad', (tester) async {
    await _pumpSurface(
      tester,
      const TransactionAmountSurface(
        title: 'Invoice',
        editable: false,
        amountLabel: '0.02000000',
        unitLabel: 'BTC',
        fiatReference: '~ R\$ 6.400,00',
        ctaLabel: 'Pay',
      ),
    );

    expect(find.text('0.02000000'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-keypad-1')), findsNothing);
    expect(find.byKey(const ValueKey('transaction-keypad-.')), findsNothing);
  });

  testWidgets('renders integer sats mode without decimal key for PSBT', (
    tester,
  ) async {
    final taps = <String>[];

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        title: 'Create PSBT',
        direction: TransactionAmountDirection.send,
        amountLabel: '125000',
        unitLabel: 'sats',
        keypadConfig: TransactionKeypadConfig(
          mode: TransactionKeypadMode.integer,
          onKeyTap: taps.add,
        ),
      ),
    );

    expect(find.text('125000'), findsOneWidget);
    expect(find.text('sats'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-keypad-.')), findsNothing);
    expect(find.byKey(const ValueKey('transaction-keypad-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transaction-keypad-0')));

    expect(taps, ['0']);
  });

  testWidgets('backspace key exposes localized tooltip and emits delete value',
      (
    tester,
  ) async {
    final taps = <String>[];

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        amountLabel: '0.004',
        unitLabel: 'BTC',
        onKeyTap: taps.add,
      ),
    );

    final tooltip = MaterialLocalizations.of(
      tester.element(find.byType(TransactionAmountSurface)),
    ).deleteButtonTooltip;

    await tester.longPress(find.byKey(const ValueKey('transaction-keypad-←')));
    await tester.pumpAndSettle();

    expect(find.text(tooltip), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transaction-keypad-←')));

    expect(taps, ['←']);
  });

  testWidgets('updates loading detail rows to final values', (tester) async {
    await _pumpSurface(
      tester,
      const TransactionAmountSurface(
        amountLabel: '0.004',
        unitLabel: 'BTC',
        details: [
          TransactionDetailRowData(
            label: 'Network fee',
            value: '',
            loading: true,
          ),
        ],
        loadingRows: 1,
      ),
    );

    expect(find.text('Network fee'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-row-value-loading')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-detail-loading-0')),
        findsOneWidget);

    await _pumpSurface(
      tester,
      const TransactionAmountSurface(
        amountLabel: '0.004',
        unitLabel: 'BTC',
        details: [
          TransactionDetailRowData(
            label: 'Network fee',
            value: '0.00001234 BTC',
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0.00001234 BTC'), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-row-value-loading')),
        findsNothing);
  });

  testWidgets('long addresses and labels do not overflow on narrow screens', (
    tester,
  ) async {
    await _pumpSurface(
      tester,
      const TransactionAmountSurface(
        title: 'Very long localized title for a transaction amount surface',
        rail: 'Bitcoin on-chain with a very long network label',
        maxWidth: 320,
        sourceParty: TransactionPartyData(
          prefix: 'Receiving in',
          title: 'Wallet with a very long user configured name',
          subtitle:
              'bc1qverylongaddress000000000000000000000000000000000000000000',
          icon: KeroseneIcons.wallet,
        ),
        destinationParty: TransactionPartyData(
          prefix: 'Invoice',
          title: 'Lightning invoice with long memo',
          subtitle:
              'lnbc2500u1pverylonginvoice000000000000000000000000000000000000',
          icon: KeroseneIcons.lightning,
        ),
        amountLabel: '123456789.12345678',
        unitLabel: 'BTC',
        fiatReference: '~ R\$ 999.999.999,99',
        detailRows: [
          TransactionDetailRowData(
            label: 'Extremely long detail label that should stay constrained',
            value:
                'Extremely long final value that should truncate visually without overflowing',
          ),
        ],
        ctaLabel: 'Continue',
      ),
      size: const Size(320, 740),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('CTA switches between disabled and enabled states', (
    tester,
  ) async {
    var continued = false;

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        amountLabel: '0',
        unitLabel: 'BTC',
        ctaLabel: 'Continue',
        ctaEnabled: false,
        onContinue: () => continued = true,
      ),
    );

    final disabledButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('transaction-amount-surface-cta')),
    );
    disabledButton.onPressed?.call();
    expect(continued, isFalse);

    await _pumpSurface(
      tester,
      TransactionAmountSurface(
        amountLabel: '0.01',
        unitLabel: 'BTC',
        ctaLabel: 'Continue',
        ctaEnabled: true,
        onContinue: () => continued = true,
      ),
    );

    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('transaction-amount-surface-cta')),
    );
    enabledButton.onPressed?.call();
    expect(continued, isTrue);
  });
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: child),
        ),
      ),
    ),
  );
}
