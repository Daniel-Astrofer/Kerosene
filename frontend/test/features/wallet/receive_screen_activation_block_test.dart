import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/auth/controller/auth_providers.dart';
import 'package:teste/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/screens/receive_screen.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/app_localizations.dart';

class _StaticCurrencyNotifier extends CurrencyNotifier {
  final Currency value;

  _StaticCurrencyNotifier(this.value);

  @override
  Currency build() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const blockedStatus = ActivationStatusResult(
    activated: false,
    canReceiveInbound: false,
    requiresActivationDeposit: true,
    paymentLinkId: 'activation-1',
    amountBtc: 0,
    depositAddress: '',
    paymentStatus: 'pending',
    warningMessage:
        'Para receber fundos dentro da plataforma, deposite algum valor primeiro.',
  );

  final wallet = Wallet(
    id: 'wallet-1',
    name: 'Main Wallet',
    address: 'bc1qwallet0000000000000000000000000000',
    balance: 0.0,
    derivationPath: "m/84'/0'/0'/0/0",
    type: WalletType.segwit,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('receive screen blocks inbound until activation deposit is done',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activationStatusProvider.overrideWith((ref) async => blockedStatus),
          currencyProvider.overrideWith(
            () => _StaticCurrencyNotifier(Currency.btc),
          ),
          latestBtcPriceProvider.overrideWith((ref) => 65000.0),
          btcEurPriceProvider.overrideWith((ref) => 60000.0),
          btcBrlPriceProvider.overrideWith((ref) => 320000.0),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReceiveScreen(initialWallet: wallet),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Recebimento indisponível'), findsOneWidget);
    expect(find.textContaining('receber fundos'), findsOneWidget);
    expect(find.text('Depositar'), findsOneWidget);
    expect(find.textContaining('Depósito obrigatório'), findsNothing);
    expect(find.textContaining('bc1qactivation'), findsNothing);

    final button = tester.widget<ReceiveFlowPrimaryButton>(
      find.byType(ReceiveFlowPrimaryButton),
    );
    expect(button.onTap, isNull);
  });
}
