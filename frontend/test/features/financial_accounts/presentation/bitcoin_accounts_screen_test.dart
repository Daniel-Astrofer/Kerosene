// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/auth/domain/entities/user.dart';
import 'package:kerosene/core/theme/app_theme.dart';
import 'package:kerosene/features/financial_accounts/data/bitcoin_accounts_service.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_screen.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/core/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'separates Kerosene card balance from cold wallet watched balance',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          sessionStorageScopeProvider.overrideWithValue('test-user'),
          authControllerProvider.overrideWith(() => _AuthTestController()),
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

    expect(find.text('STATUS DA CARTEIRA'), findsOneWidget);
    expect(find.text('ENDEREÇO DE RECEBIMENTO'), findsOneWidget);
    expect(find.text('NOME DA CARTEIRA'), findsOneWidget);
    expect(find.text('UTXOS MONITORADOS'), findsNothing);

    await _tapExpansion(tester, 'STATUS DA CARTEIRA');

    expect(find.text('Internal BTC Card'), findsWidgets);
    expect(find.text('0.00131000 BTC'), findsOneWidget);

    await tester.drag(find.byType(PageView).first, const Offset(-360, 0));
    await tester.pumpAndSettle();

    expect(find.text('Cold Wallet'), findsWidgets);
    expect(find.text('UTXOS MONITORADOS'), findsOneWidget);
    expect(find.text('PSBT WORKFLOWS'), findsOneWidget);

    await _tapExpansion(tester, 'STATUS DA CARTEIRA');

    expect(find.text('Arquivar acompanhamento'), findsOneWidget);
    expect(find.text('0.00250000 BTC'), findsWidgets);

    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pumpAndSettle();
    await _tapExpansion(tester, 'UTXOS MONITORADOS');

    expect(find.text('Disponível para PSBT'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await _tapExpansion(tester, 'PSBT WORKFLOWS');

    expect(find.text('Copiar unsigned'), findsOneWidget);
    expect(find.text('Bitcoin Advanced'), findsNothing);
    expect(find.text('Relatórios fiscais'), findsNothing);
    expect(find.text('Exportar JSON'), findsNothing);
  });

  testWidgets('uses dedicated empty bitcoin accounts layout', (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService([]),
    );

    await tester.pumpAndSettle();

    expect(find.text('Contas Bitcoin'), findsOneWidget);
    expect(find.text('Nenhuma conta Bitcoin ainda'), findsOneWidget);
    expect(find.text('Novo cartão Kerosene'), findsOneWidget);
    expect(find.text('Criar Cold Wallet'), findsOneWidget);
    expect(find.text('Carteira interna'), findsNothing);
  });

  testWidgets('opens full-screen custody selector for new wallets',
      (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService([]),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo cartão Kerosene'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Carteira'), findsOneWidget);
    expect(find.text('Carteira Interna'), findsOneWidget);
    expect(find.text('Custodial On-chain'), findsOneWidget);
    expect(find.text('Kerosene Watch-Only'), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('allows custodial on-chain creation when internal wallet exists',
      (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService(const [_internalAccount]),
    );

    await tester.pumpAndSettle();

    expect(find.text('Novo cartão Kerosene'), findsOneWidget);

    await tester.tap(find.text('Novo cartão Kerosene'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Carteira'), findsOneWidget);
    expect(find.text('Custodial On-chain'), findsOneWidget);
    expect(
        find.text('As carteiras disponíveis já foram criadas.'), findsNothing);
  });

  testWidgets('hides custody creation options that already exist',
      (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService(
        const [
          _internalAccount,
          BitcoinAccount(
            id: 'custodial-1',
            type: 'INTERNAL_CARD',
            custody: 'CUSTODIAL_ONCHAIN',
            status: 'ACTIVE',
            label: 'Reserva on-chain',
            riskTier: 'BRONZE',
            cardId: 'card-2',
            balanceAvailableSats: 50000,
          ),
          BitcoinAccount(
            id: 'watch-1',
            type: 'WATCH_ONLY_COLD_WALLET',
            custody: 'WATCH_ONLY',
            status: 'ACTIVE',
            label: 'Cold 1',
            riskTier: 'WATCH_ONLY',
            coldWalletId: 'cold-1',
          ),
          BitcoinAccount(
            id: 'watch-2',
            type: 'WATCH_ONLY_COLD_WALLET',
            custody: 'WATCH_ONLY',
            status: 'ACTIVE',
            label: 'Cold 2',
            riskTier: 'WATCH_ONLY',
            coldWalletId: 'cold-2',
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Novo cartão Kerosene'), findsNothing);
    expect(find.text('Cold Wallet'), findsNothing);
    expect(find.byType(CreateWalletActionChip), findsNothing);
  });

  testWidgets('requires name and custody before creating wallet',
      (tester) async {
    final service = _FakeBitcoinAccountsService([]);
    await _pumpBitcoinAccounts(tester, service);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo cartão Kerosene'));
    await tester.pumpAndSettle();

    expect(service.createWalletCalls, 0);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(service.createWalletCalls, 0);

    await tester.tap(find.text('Carteira Interna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Como essa carteira deve se chamar?'), findsOneWidget);
    expect(service.createWalletCalls, 0);

    await tester.tap(find.text('Criar carteira'));
    await tester.pumpAndSettle();

    expect(service.createWalletCalls, 0);

    await tester.enterText(find.byType(TextField), 'Reserva familiar');
    await tester.tap(find.text('Criar carteira'));
    await tester.pumpAndSettle();

    expect(service.createWalletCalls, 1);
    expect(service.lastCreatedLabel, 'Reserva familiar');
    expect(service.lastCreatedCustody, BitcoinAccountCustody.internal);
    expect(find.text('Reserva familiar'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('keeps created wallet visible when post-create refresh is stale',
      (tester) async {
    final service = _FakeBitcoinAccountsService(
      const [],
      failListAfterCreate: true,
    );
    await _pumpBitcoinAccounts(tester, service);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo cartão Kerosene'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carteira Interna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Reserva familiar');
    await tester.tap(find.text('Criar carteira'));
    await tester.pumpAndSettle();

    expect(service.createWalletCalls, 1);
    expect(find.text('Reserva familiar'), findsWidgets);
    expect(find.text('Não foi possível criar o cartão'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows receive requests empty state', (tester) async {
    await _pumpBitcoinAccounts(
      tester,
      _FakeBitcoinAccountsService([_internalAccount]),
    );

    await tester.pumpAndSettle();

    expect(find.text('ENDEREÇO DE RECEBIMENTO'), findsOneWidget);

    await _tapExpansion(tester, 'ENDEREÇO DE RECEBIMENTO');
    await tester.pumpAndSettle();

    expect(find.text('Não informado'), findsWidgets);
    expect(find.text('Pronta'), findsWidgets);
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

    expect(find.text('ENDEREÇO DE RECEBIMENTO'), findsOneWidget);

    await _tapExpansion(tester, 'ENDEREÇO DE RECEBIMENTO');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A Kerosene não conseguiu atualizar os pedidos de recebimento desta conta.',
      ),
      findsOneWidget,
    );
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

    expect(find.text('ENDEREÇO DE RECEBIMENTO'), findsOneWidget);
    expect(
      find.text('bc1qreceive0000000000000000000000000000000000'),
      findsWidgets,
    );

    await _tapExpansion(tester, 'ENDEREÇO DE RECEBIMENTO');
    await tester.pumpAndSettle();

    expect(find.text('0.00050000 BTC'), findsOneWidget);
    expect(
      find.text('bc1qreceive0000000000000000000000000000000000'),
      findsWidgets,
    );
  });

  testWidgets('exposes focused card management actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeBitcoinAccountsService(
      [_internalAccount],
      requests: [
        ReceivingRequestView(
          id: 'request-1',
          accountId: 'internal-1',
          address: 'bc1qreceive0000000000000000000000000000000000',
          bip21: 'bitcoin:bc1qreceive0000000000000000000000000000000000',
          status: 'ACTIVE',
          amountSats: null,
          expiry: '',
          oneTime: false,
          createdAt: DateTime(2026, 5, 28),
        ),
      ],
    );
    await _pumpBitcoinAccounts(tester, service);
    await tester.pumpAndSettle();

    await _tapExpansion(tester, 'ENDEREÇO DE RECEBIMENTO');
    await tester.pumpAndSettle();
    expect(find.text('Rotacionar endereço'), findsOneWidget);
    await tester.tap(find.text('Rotacionar endereço'));
    await tester.pumpAndSettle();
    expect(service.rotateAddressCalls, 1);
    expect(
      find.text('bc1qrotated0000000000000000000000000000000000'),
      findsWidgets,
    );

    await _tapExpansion(tester, 'NOME DA CARTEIRA');
    await tester.pumpAndSettle();
    expect(find.text('Trocar nome'), findsOneWidget);
    await tester.tap(find.text('Trocar nome'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Reserva privada');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(service.renameWalletCalls, 1);
    expect(service.lastRenamedLabel, 'Reserva privada');

    await _tapExpansion(tester, 'STATUS DA CARTEIRA');
    await tester.pumpAndSettle();
    expect(find.text('Bloquear carteira'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR'));
    await tester.pumpAndSettle();
    expect(service.archiveWalletCalls, 1);
    expect(service.lastArchivedAccountId, 'internal-1');
    await tester.pump(const Duration(seconds: 3));
  });
}

Future<void> _tapExpansion(WidgetTester tester, String title) async {
  final header = find.ancestor(
    of: find.text(title),
    matching: find.byType(InkWell),
  );
  await tester.ensureVisible(header.first);
  await tester.pumpAndSettle();
  final rect = tester.getRect(header.first);
  await tester.tapAt(Offset(rect.left + 28, rect.top + 28));
  await tester.pumpAndSettle();
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
        authControllerProvider.overrideWith(() => _AuthTestController()),
        sessionStorageScopeProvider.overrideWithValue('test-user'),
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

class _AuthTestController extends AuthController {
  @override
  AuthState build() => AuthAuthenticated(
        User(
          id: 'user-1',
          username: 'Satoshi Nakamoto',
          createdAt: DateTime(2026, 1, 1),
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
  final bool failListAfterCreate;
  int createWalletCalls = 0;
  int rotateAddressCalls = 0;
  int renameWalletCalls = 0;
  int archiveWalletCalls = 0;
  String? lastCreatedLabel;
  BitcoinAccountCustody? lastCreatedCustody;
  String? lastRenamedAccountId;
  String? lastRenamedLabel;
  String? lastArchivedAccountId;

  _FakeBitcoinAccountsService(
    List<BitcoinAccount> accounts, {
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
    this.failListAfterCreate = false,
  }) : accounts = List<BitcoinAccount>.of(accounts);

  @override
  Future<List<BitcoinAccount>> listAccounts() async {
    if (failListAfterCreate && createWalletCalls > 0) {
      throw Exception('stale list after create');
    }
    return accounts;
  }

  @override
  Future<BitcoinAccount> createWallet({
    required String label,
    required BitcoinAccountCustody custody,
  }) async {
    createWalletCalls += 1;
    lastCreatedLabel = label;
    lastCreatedCustody = custody;
    final created = BitcoinAccount(
      id: 'created-$createWalletCalls',
      type: custody == BitcoinAccountCustody.watchOnly
          ? 'WATCH_ONLY_COLD_WALLET'
          : 'INTERNAL_CARD',
      custody: switch (custody) {
        BitcoinAccountCustody.watchOnly => 'WATCH_ONLY',
        BitcoinAccountCustody.custodialOnchain => 'CUSTODIAL_ONCHAIN',
        BitcoinAccountCustody.internal => 'KEROSENE_CUSTODIAL',
      },
      status: 'ACTIVE',
      label: label,
      riskTier: 'BRONZE',
      cardId: 'created-card',
    );
    accounts.insert(0, created);
    return created;
  }

  @override
  Future<BitcoinAccount> createInternalCard({required String label}) {
    return createWallet(
      label: label,
      custody: BitcoinAccountCustody.internal,
    );
  }

  @override
  Future<ReceivingRequestView> rotateReceiveAddress(String accountId) async {
    rotateAddressCalls += 1;
    return ReceivingRequestView.fromKfeActiveAddress(
      accountId: accountId,
      address: 'bc1qrotated0000000000000000000000000000000000',
      createdAt: DateTime(2026, 5, 29),
    );
  }

  @override
  Future<BitcoinAccount> renameWallet({
    required String accountId,
    required String label,
  }) async {
    renameWalletCalls += 1;
    lastRenamedAccountId = accountId;
    lastRenamedLabel = label;
    return _accountWith(
      accounts.firstWhere((account) => account.id == accountId),
      label: label,
    );
  }

  @override
  Future<BitcoinAccount> archiveWallet(String accountId) async {
    archiveWalletCalls += 1;
    lastArchivedAccountId = accountId;
    return _accountWith(
      accounts.firstWhere((account) => account.id == accountId),
      status: 'ARCHIVED',
    );
  }

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

  BitcoinAccount _accountWith(
    BitcoinAccount account, {
    String? label,
    String? status,
  }) {
    return BitcoinAccount(
      id: account.id,
      type: account.type,
      custody: account.custody,
      status: status ?? account.status,
      label: label ?? account.label,
      walletTypeDescription: account.walletTypeDescription,
      riskTier: account.riskTier,
      cardId: account.cardId,
      coldWalletId: account.coldWalletId,
      balanceAvailableSats: account.balanceAvailableSats,
      balancePendingSats: account.balancePendingSats,
      balanceLockedSats: account.balanceLockedSats,
      balanceAutoHoldSats: account.balanceAutoHoldSats,
      observedBalanceSats: account.observedBalanceSats,
      xpubFingerprint: account.xpubFingerprint,
      derivationPath: account.derivationPath,
      scriptPolicy: account.scriptPolicy,
    );
  }
}
