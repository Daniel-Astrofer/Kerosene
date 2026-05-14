import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teste/core/theme/app_theme.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:teste/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'separates Kerosene card balance from cold wallet watched balance',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bitcoinAccountsServiceProvider.overrideWithValue(
            _FakeBitcoinAccountsService(
              const [
                BitcoinAccount(
                  id: 'internal-1',
                  type: 'INTERNAL_CARD',
                  custody: 'KEROSENE_CUSTODIAL',
                  status: 'ACTIVE',
                  label: 'Internal BTC Card',
                  riskTier: 'BRONZE',
                  cardId: 'card-1',
                  balanceAvailableSats: 125000,
                  balancePendingSats: 3000,
                  balanceLockedSats: 2000,
                  balanceAutoHoldSats: 1000,
                ),
                BitcoinAccount(
                  id: 'watch-1',
                  type: 'WATCH_ONLY_COLD_WALLET',
                  custody: 'WATCH_ONLY',
                  status: 'ACTIVE',
                  label: 'Cold Wallet',
                  riskTier: 'WATCH_ONLY',
                  coldWalletId: 'cold-1',
                  observedBalanceSats: 250000,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BitcoinAccountsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Saldo disponível'), findsOneWidget);
    expect(find.text('Saldo acompanhado'), findsOneWidget);
    expect(find.text('Cartão Kerosene'), findsWidgets);
    expect(find.text('Somente leitura'), findsOneWidget);
    expect(find.textContaining('só acompanha'), findsOneWidget);
    expect(find.textContaining('Em análise'), findsOneWidget);
    expect(find.textContaining('PSBT'), findsNothing);
    expect(find.textContaining('UTXO'), findsNothing);
    expect(find.textContaining('Relatórios fiscais'), findsNothing);
  });
}

class _FakeBitcoinAccountsService implements BitcoinAccountsService {
  final List<BitcoinAccount> accounts;

  const _FakeBitcoinAccountsService(this.accounts);

  @override
  Future<List<BitcoinAccount>> listAccounts() async => accounts;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
