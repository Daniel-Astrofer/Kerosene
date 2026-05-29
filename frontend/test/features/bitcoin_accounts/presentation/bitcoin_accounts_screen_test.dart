// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';

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
          transactionHistoryProvider.overrideWith((ref) async => const []),
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
    expect(find.text('Bitcoin Advanced'), findsOneWidget);
    expect(find.text('UTXOs monitorados'), findsOneWidget);
    expect(find.text('PSBT workflows'), findsOneWidget);
    expect(find.text('Relatórios fiscais'), findsOneWidget);
    expect(find.text('Exportar JSON'), findsOneWidget);
  });

  testWidgets('shows receive requests empty state', (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      const _FakeBitcoinAccountsService([_internalAccount]),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pedidos de recebimento'), findsOneWidget);
    expect(find.text('Nenhum pedido ativo.'), findsOneWidget);
  });

  testWidgets('shows receive requests error and retry state', (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService(
        const [_internalAccount],
        requestError: Exception('request failure'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pedidos de recebimento'), findsOneWidget);
    expect(find.text('Não foi possível carregar pedidos.'), findsOneWidget);
    expect(find.text('Tentar Novamente'), findsOneWidget);
  });

  testWidgets('shows loaded receive requests', (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService(
        const [_internalAccount],
        requests: [
          ReceivingRequestView(
            id: 'request-1',
            accountId: 'internal-1',
            address: 'bc1qreceive0000000000000000000000000000000000',
            bip21:
                'bitcoin:bc1qreceive0000000000000000000000000000000000?amount=0.00050000',
            status: 'ACTIVE',
            amountSats: 50000,
            expiry: '2026-05-29T00:00:00Z',
            oneTime: true,
            createdAt: DateTime(2026, 5, 28),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pedidos de recebimento'), findsOneWidget);
    expect(find.text('0.00050000 BTC'), findsOneWidget);
  });
}

const _internalAccount = BitcoinAccount(
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
);

Future<void> _pumpBitcoinAccounts(
  WidgetTester tester,
  _FakeBitcoinAccountsService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bitcoinAccountsServiceProvider.overrideWithValue(service),
        transactionHistoryProvider.overrideWith((ref) async => const []),
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
}

class _FakeBitcoinAccountsService implements BitcoinAccountsService {
  final List<BitcoinAccount> accounts;
  final List<ReceivingRequestView> requests;
  final List<ColdWalletUtxoView> utxos;
  final List<PsbtWorkflowView> psbts;
  final List<TaxEventView> taxEvents;
  final Exception? requestError;

  const _FakeBitcoinAccountsService(
    this.accounts, {
    this.requests = const [],
    this.utxos = const [
      ColdWalletUtxoView(
        id: 'utxo-1',
        txidRef: 'abcdef12...34567890',
        vout: 0,
        amountSats: 250000,
        confirmations: 6,
        status: 'UNSPENT',
      ),
    ],
    this.psbts = const [
      PsbtWorkflowView(
        id: 'psbt-1',
        coldWalletId: 'cold-1',
        unsignedPsbt: 'cHNidP8BAHECAAAAA',
        status: 'WAITING_EXTERNAL_SIGNATURE',
        destinationAddress: 'bc1qrecipient000000000000000000000000000000',
        amountSats: 100000,
        estimatedFeeSats: 400,
        expiresAt: '2026-05-29T00:00:00Z',
        createdAt: '2026-05-28T00:00:00Z',
      ),
    ],
    this.taxEvents = const [
      TaxEventView(
        id: 'tax-1',
        eventType: 'DEPOSIT_INTERNAL',
        asset: 'BTC',
        quantitySats: 100000,
        classification: 'USER_CLASSIFICATION_PENDING',
        sourceRef: 'abcdef12...34567890',
        createdAt: '2026-05-28T00:00:00Z',
      ),
    ],
    this.requestError,
  });

  @override
  Future<List<BitcoinAccount>> listAccounts() async => accounts;

  @override
  Future<List<ReceivingRequestView>> listReceiveRequestsForAccount(
    String accountId,
  ) async {
    final error = requestError;
    if (error != null) {
      throw error;
    }
    return requests.where((request) => request.accountId == accountId).toList();
  }

  @override
  Future<List<ColdWalletUtxoView>> listColdWalletUtxos(
    String coldWalletId,
  ) async =>
      utxos;

  @override
  Future<List<PsbtWorkflowView>> listColdWalletPsbt(String coldWalletId) async {
    return psbts
        .where((workflow) => workflow.coldWalletId == coldWalletId)
        .toList();
  }

  @override
  Future<List<TaxEventView>> listTaxEvents() async => taxEvents;

  @override
  Future<PsbtWorkflowView> createColdWalletPsbt({
    required String coldWalletId,
    required String destinationAddress,
    required int amountSats,
    int? feeRate,
    List<String> selectedUtxoIds = const [],
  }) async {
    return PsbtWorkflowView(
      id: 'created-psbt',
      coldWalletId: coldWalletId,
      unsignedPsbt: 'cHNidP8BAHECAAAAA',
      status: 'WAITING_EXTERNAL_SIGNATURE',
      destinationAddress: destinationAddress,
      amountSats: amountSats,
      estimatedFeeSats: feeRate ?? 0,
      expiresAt: '2026-05-29T00:00:00Z',
      createdAt: '2026-05-28T00:00:00Z',
    );
  }

  @override
  Future<PsbtWorkflowView> getPsbtWorkflow(String workflowId) async {
    return psbts.firstWhere((workflow) => workflow.id == workflowId);
  }

  @override
  Future<PsbtWorkflowView> submitSignedPsbt({
    required String workflowId,
    required String signedPsbt,
    required bool broadcast,
  }) {
    return getPsbtWorkflow(workflowId);
  }

  @override
  Future<TaxEventsExportView> exportTaxEvents({required String format}) async {
    return TaxEventsExportView(
      format: format,
      filename: 'kerosene-tax-events.$format',
      educationalNotice: 'Temporary report.',
      events: taxEvents,
    );
  }

  @override
  Future<TaxEventView> classifyTaxEvent({
    required String eventId,
    required String classification,
  }) async {
    return taxEvents.firstWhere(
      (event) => event.id == eventId,
      orElse: () => TaxEventView(
        id: eventId,
        eventType: '',
        asset: 'BTC',
        quantitySats: 0,
        classification: classification,
        sourceRef: '',
        createdAt: '',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
