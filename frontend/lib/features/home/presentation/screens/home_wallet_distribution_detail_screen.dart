import 'home_screen_dependencies.dart';
import 'home_screen.dart';
import 'home_screen_surface.dart';

class HomeWalletDistributionDetailScreen extends ConsumerStatefulWidget {
  final Wallet initialWallet;

  const HomeWalletDistributionDetailScreen({
    super.key,
    required this.initialWallet,
  });

  @override
  ConsumerState<HomeWalletDistributionDetailScreen> createState() =>
      _HomeWalletDistributionDetailScreenState();
}

class _HomeWalletDistributionDetailScreenState
    extends ConsumerState<HomeWalletDistributionDetailScreen> {
  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    ref.invalidate(transactionHistoryProvider);
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(transactionHistoryProvider.future),
    ]);
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final wallet = _resolveFreshWallet(walletState);
    final historyAsync = ref.watch(transactionHistoryProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final now = DateTime.now();
    final bottomPadding =
        MediaQuery.viewPaddingOf(context).bottom + homeSize(34);

    return Scaffold(
      backgroundColor: homeBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsive.isCompact ? 430 : 520,
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                BitcoinRefreshIndicator(onRefresh: _refreshData),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      homeSize(20),
                      homeSize(18),
                      homeSize(20),
                      0,
                    ),
                    child: _WalletDetailTopBar(onBack: _handleBack),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      homeSize(20),
                      homeSize(18),
                      homeSize(20),
                      0,
                    ),
                    child: _WalletDetailHeader(
                      wallet: wallet,
                      selectedCurrency: selectedCurrency,
                      btcUsd: btcUsd,
                      btcEur: btcEur,
                      btcBrl: btcBrl,
                    ),
                  ),
                ),
                historyAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        homeSize(20),
                        homeSize(18),
                        homeSize(20),
                        bottomPadding,
                      ),
                      child: const _WalletDetailLoadingPanel(),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        homeSize(20),
                        homeSize(18),
                        homeSize(20),
                        bottomPadding,
                      ),
                      child: _WalletDetailMessage(
                        icon: KeroseneIcons.warning,
                        title: _walletDetailCopy(
                          context,
                          pt: 'Não foi possível carregar as movimentações.',
                          en: 'Could not load movements.',
                          es: 'No fue posible cargar los movimientos.',
                        ),
                        message: error.toString(),
                      ),
                    ),
                  ),
                  data: (transactions) {
                    final walletTransactions = _transactionsForWallet(
                      wallet,
                      transactions,
                    );
                    final monthTransactions = _transactionsForMonth(
                      walletTransactions,
                      now,
                    );
                    final summary = _WalletMonthSummary.fromTransactions(
                      monthTransactions,
                      month: now,
                    );

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        homeSize(20),
                        homeSize(18),
                        homeSize(20),
                        bottomPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          _WalletMonthlySummaryPanel(
                            month: now,
                            summary: summary,
                            selectedCurrency: selectedCurrency,
                            btcUsd: btcUsd,
                            btcEur: btcEur,
                            btcBrl: btcBrl,
                          ),
                          SizedBox(height: homeSize(14)),
                          _WalletMonthlyChartPanel(summary: summary),
                          SizedBox(height: homeSize(18)),
                          _WalletMovementList(
                            transactions: monthTransactions,
                            selectedCurrency: selectedCurrency,
                            btcUsd: btcUsd,
                            btcEur: btcEur,
                            btcBrl: btcBrl,
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Wallet _resolveFreshWallet(WalletState walletState) {
    if (walletState is WalletLoaded) {
      for (final wallet in walletState.wallets) {
        if (wallet.id == widget.initialWallet.id) {
          return wallet;
        }
      }
    }
    return widget.initialWallet;
  }
}

class _WalletDetailTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _WalletDetailTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WalletRoundButton(icon: KeroseneIcons.back, onPressed: onBack),
        const Spacer(),
        Text(
          _walletDetailCopy(
            context,
            pt: 'Detalhes da carteira',
            en: 'Wallet details',
            es: 'Detalles de la billetera',
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: homeMutedTextColor,
                fontSize: homeFontSize(12),
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _WalletRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _WalletRoundButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: homeSize(42),
      height: homeSize(42),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: homeSize(20)),
        style: IconButton.styleFrom(
          backgroundColor: homeCardColor,
          shape: const CircleBorder(),
          side: BorderSide(color: homePanelBorderColor),
        ),
      ),
    );
  }
}

class _WalletDetailHeader extends StatelessWidget {
  final Wallet wallet;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const _WalletDetailHeader({
    required this.wallet,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: wallet.balance,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final btcLabel = MoneyDisplay.format(
      amount: wallet.balance,
      currency: Currency.btc,
    );

    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(24)),
      padding: EdgeInsets.all(homeSize(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: homeSize(44),
                height: homeSize(44),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Icon(
                  wallet.isColdWallet
                      ? KeroseneIcons.shield
                      : KeroseneIcons.wallet,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: homeSize(20),
                ),
              ),
              SizedBox(width: homeSize(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.newsreader(
                        color: Colors.white,
                        fontSize: homeFontSize(28),
                        fontWeight: FontWeight.w400,
                        height: 1.02,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: homeSize(8)),
                    Wrap(
                      spacing: homeSize(8),
                      runSpacing: homeSize(8),
                      children: [
                        _WalletTag(label: wallet.custodyDisplayLabel),
                        _WalletTag(
                          label: wallet.isActive
                              ? _walletDetailCopy(
                                  context,
                                  pt: 'Ativa',
                                  en: 'Active',
                                  es: 'Activa',
                                )
                              : _walletDetailCopy(
                                  context,
                                  pt: 'Inativa',
                                  en: 'Inactive',
                                  es: 'Inactiva',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: homeSize(24)),
          Text(
            _walletDetailCopy(
              context,
              pt: 'Saldo atual',
              en: 'Current balance',
              es: 'Saldo actual',
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: homeMutedTextColor,
              fontSize: homeFontSize(11),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(6)),
          Text(
            balanceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: homeFontSize(24),
              fontWeight: FontWeight.w300,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: homeSize(5)),
          Text(
            btcLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: homeMutedTextColor,
              fontSize: homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTag extends StatelessWidget {
  final String label;

  const _WalletTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: homeSize(10), vertical: homeSize(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(homeSize(999)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: homeFontSize(10),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _WalletMonthlySummaryPanel extends StatelessWidget {
  final DateTime month;
  final _WalletMonthSummary summary;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const _WalletMonthlySummaryPanel({
    required this.month,
    required this.summary,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(20)),
      padding: EdgeInsets.all(homeSize(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthTitle(context, month),
            style: AppTypography.newsreader(
              color: Colors.white,
              fontSize: homeFontSize(22),
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(6)),
          Text(
            _walletDetailCopy(
              context,
              pt: 'Entradas, saídas e saldo líquido do mês.',
              en: 'Monthly inflows, outflows and net result.',
              es: 'Entradas, salidas y saldo neto del mes.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: homeMutedTextColor,
                  fontSize: homeFontSize(12),
                  fontWeight: FontWeight.w300,
                  height: 1.35,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: homeSize(16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < homeSize(320);
              final cards = [
                _WalletMetricCard(
                  label: _walletDetailCopy(
                    context,
                    pt: 'Entradas',
                    en: 'Inflow',
                    es: 'Entradas',
                  ),
                  value: _formatSats(
                    summary.incomingSats,
                    selectedCurrency,
                    btcUsd,
                    btcEur,
                    btcBrl,
                    signed: true,
                  ),
                ),
                _WalletMetricCard(
                  label: _walletDetailCopy(
                    context,
                    pt: 'Saídas',
                    en: 'Outflow',
                    es: 'Salidas',
                  ),
                  value: _formatSats(
                    -summary.outgoingSats,
                    selectedCurrency,
                    btcUsd,
                    btcEur,
                    btcBrl,
                    signed: true,
                  ),
                ),
                _WalletMetricCard(
                  label: _walletDetailCopy(
                    context,
                    pt: 'Saldo do mês',
                    en: 'Month net',
                    es: 'Saldo del mes',
                  ),
                  value: _formatSats(
                    summary.netSats,
                    selectedCurrency,
                    btcUsd,
                    btcEur,
                    btcBrl,
                    signed: true,
                  ),
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      if (index > 0) SizedBox(height: homeSize(10)),
                      cards[index],
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) SizedBox(width: homeSize(10)),
                    Expanded(child: cards[index]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WalletMetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _WalletMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(homeSize(12)),
      decoration: BoxDecoration(
        color: homeCardColor,
        borderRadius: BorderRadius.circular(homeSize(16)),
        border: Border.all(color: homePanelBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: homeMutedTextColor,
              fontSize: homeFontSize(10),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(8)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: homeFontSize(13),
              fontWeight: FontWeight.w300,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletMonthlyChartPanel extends StatelessWidget {
  final _WalletMonthSummary summary;

  const _WalletMonthlyChartPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(20)),
      padding: EdgeInsets.all(homeSize(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _walletDetailCopy(
                    context,
                    pt: 'Movimentação diária',
                    en: 'Daily movement',
                    es: 'Movimiento diario',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _ChartLegendDot(
                color: Colors.white,
                label: _walletDetailCopy(
                  context,
                  pt: 'Entrada',
                  en: 'In',
                  es: 'Entrada',
                ),
              ),
              SizedBox(width: homeSize(10)),
              _ChartLegendDot(
                color: Colors.white.withValues(alpha: 0.34),
                label: _walletDetailCopy(
                  context,
                  pt: 'Saída',
                  en: 'Out',
                  es: 'Salida',
                ),
              ),
            ],
          ),
          SizedBox(height: homeSize(18)),
          SizedBox(
            height: homeSize(150),
            width: double.infinity,
            child: CustomPaint(
              painter: _WalletMonthlyMovementPainter(days: summary.days),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: homeSize(7),
          height: homeSize(7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: homeSize(5)),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: homeMutedTextColor,
                fontSize: homeFontSize(10),
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _WalletMovementList extends StatelessWidget {
  final List<Transaction> transactions;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const _WalletMovementList({
    required this.transactions,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(20)),
      padding: EdgeInsets.all(homeSize(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _walletDetailCopy(
              context,
              pt: 'Movimentações do mês',
              en: 'Monthly movements',
              es: 'Movimientos del mes',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontSize: homeFontSize(14),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: homeSize(14)),
          if (transactions.isEmpty)
            _WalletDetailMessage(
              icon: KeroseneIcons.history,
              title: _walletDetailCopy(
                context,
                pt: 'Sem movimentações neste mês.',
                en: 'No movements this month.',
                es: 'Sin movimientos este mes.',
              ),
              message: _walletDetailCopy(
                context,
                pt: 'Quando esta carteira receber ou enviar fundos, o histórico aparece aqui.',
                en: 'When this wallet receives or sends funds, the history appears here.',
                es: 'Cuando esta billetera reciba o envíe fondos, el historial aparecerá aquí.',
              ),
            )
          else
            for (var index = 0; index < transactions.length; index++) ...[
              if (index > 0)
                Divider(color: homePanelBorderColor, height: homeSize(18)),
              _WalletMovementRow(
                transaction: transactions[index],
                selectedCurrency: selectedCurrency,
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
              ),
            ],
        ],
      ),
    );
  }
}

class _WalletMovementRow extends StatelessWidget {
  final Transaction transaction;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const _WalletMovementRow({
    required this.transaction,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signedSats = _signedSats(transaction);
    final title = transaction.isDebit
        ? _walletDetailCopy(
            context,
            pt: 'Saída',
            en: 'Outflow',
            es: 'Salida',
          )
        : _walletDetailCopy(
            context,
            pt: 'Entrada',
            en: 'Inflow',
            es: 'Entrada',
          );
    final description = _movementDescription(context, transaction);
    final amount = _formatSats(
      signedSats,
      selectedCurrency,
      btcUsd,
      btcEur,
      btcBrl,
      signed: true,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: homeSize(38),
          height: homeSize(38),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Icon(
            transaction.isDebit ? KeroseneIcons.send : KeroseneIcons.receive,
            color: Colors.white
                .withValues(alpha: transaction.isDebit ? 0.52 : 0.9),
            size: homeSize(17),
          ),
        ),
        SizedBox(width: homeSize(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: homeFontSize(13),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: homeSize(4)),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: homeMutedTextColor,
                  fontSize: homeFontSize(11),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: homeSize(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontSize: homeFontSize(12),
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: homeSize(4)),
            Text(
              _statusLabel(context, transaction.status),
              style: theme.textTheme.labelSmall?.copyWith(
                color: homeMutedTextColor,
                fontSize: homeFontSize(10),
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletDetailLoadingPanel extends StatelessWidget {
  const _WalletDetailLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return HomeGlassPanel(
      borderRadius: BorderRadius.circular(homeSize(20)),
      padding: EdgeInsets.all(homeSize(18)),
      child: Column(
        children: [
          HomeSkeletonBox(
            height: homeSize(22),
            borderRadius: BorderRadius.circular(homeSize(8)),
          ),
          SizedBox(height: homeSize(14)),
          HomeSkeletonBox(
            height: homeSize(130),
            borderRadius: BorderRadius.circular(homeSize(18)),
          ),
          SizedBox(height: homeSize(14)),
          HomeSkeletonBox(
            height: homeSize(72),
            borderRadius: BorderRadius.circular(homeSize(16)),
          ),
        ],
      ),
    );
  }
}

class _WalletDetailMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _WalletDetailMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(homeSize(16)),
      decoration: BoxDecoration(
        color: homeCardColor,
        borderRadius: BorderRadius.circular(homeSize(16)),
        border: Border.all(color: homePanelBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Colors.white.withValues(alpha: 0.72), size: homeSize(18)),
          SizedBox(width: homeSize(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: homeFontSize(13),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: homeSize(5)),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: homeMutedTextColor,
                    fontSize: homeFontSize(11),
                    fontWeight: FontWeight.w300,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletMonthSummary {
  final DateTime month;
  final List<_WalletDailyMovement> days;
  final int incomingSats;
  final int outgoingSats;

  const _WalletMonthSummary({
    required this.month,
    required this.days,
    required this.incomingSats,
    required this.outgoingSats,
  });

  int get netSats => incomingSats - outgoingSats;

  factory _WalletMonthSummary.fromTransactions(
    List<Transaction> transactions, {
    required DateTime month,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final incoming = List<int>.filled(daysInMonth, 0);
    final outgoing = List<int>.filled(daysInMonth, 0);

    for (final tx in transactions) {
      final dayIndex = tx.timestamp.toLocal().day - 1;
      if (dayIndex < 0 || dayIndex >= daysInMonth) continue;
      if (tx.isDebit) {
        outgoing[dayIndex] += _signedSats(tx).abs();
      } else {
        incoming[dayIndex] += _signedSats(tx).abs();
      }
    }

    return _WalletMonthSummary(
      month: DateTime(month.year, month.month),
      days: [
        for (var index = 0; index < daysInMonth; index++)
          _WalletDailyMovement(
            day: index + 1,
            incomingSats: incoming[index],
            outgoingSats: outgoing[index],
          ),
      ],
      incomingSats: incoming.fold(0, (sum, value) => sum + value),
      outgoingSats: outgoing.fold(0, (sum, value) => sum + value),
    );
  }
}

class _WalletDailyMovement {
  final int day;
  final int incomingSats;
  final int outgoingSats;

  const _WalletDailyMovement({
    required this.day,
    required this.incomingSats,
    required this.outgoingSats,
  });
}

class _WalletMonthlyMovementPainter extends CustomPainter {
  final List<_WalletDailyMovement> days;

  const _WalletMonthlyMovementPainter({required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = homePanelBorderColor
      ..strokeWidth = 1;
    final baseY = size.height - homeSize(18);
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), axisPaint);

    if (days.isEmpty) return;

    final maxSats = days.fold<int>(0, (current, day) {
      final localMax = max(day.incomingSats, day.outgoingSats);
      return max(current, localMax);
    });
    if (maxSats <= 0) return;

    final slotWidth = size.width / days.length;
    final barWidth = max(2.0, min(homeSize(6), slotWidth * 0.32));
    final chartHeight = baseY - homeSize(10);
    final incomingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final outgoingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;

    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      final centerX = slotWidth * index + slotWidth / 2;
      final incomingHeight = chartHeight * day.incomingSats / maxSats;
      final outgoingHeight = chartHeight * day.outgoingSats / maxSats;
      final radius = Radius.circular(barWidth);
      if (incomingHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              centerX - barWidth - 1,
              baseY - incomingHeight,
              barWidth,
              incomingHeight,
            ),
            radius,
          ),
          incomingPaint,
        );
      }
      if (outgoingHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              centerX + 1,
              baseY - outgoingHeight,
              barWidth,
              outgoingHeight,
            ),
            radius,
          ),
          outgoingPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WalletMonthlyMovementPainter oldDelegate) {
    return oldDelegate.days != days;
  }
}

List<Transaction> _transactionsForWallet(
  Wallet wallet,
  List<Transaction> transactions,
) {
  final walletTokens = _walletTokens(wallet);
  final rows = transactions.where((tx) {
    final explicitTokens = [
      tx.walletId,
      tx.sourceWalletId,
      tx.destinationWalletId,
    ].map(_normalizeToken).where((value) => value.isNotEmpty).toSet();
    if (explicitTokens.any(walletTokens.contains)) return true;

    final looseTokens = [
      tx.fromAddress,
      tx.toAddress,
      tx.externalReference,
      tx.description,
      tx.senderDisplayName,
      tx.receiverDisplayName,
    ].map(_normalizeToken).where((value) => value.isNotEmpty).toSet();
    return looseTokens.any(walletTokens.contains);
  }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return rows;
}

List<Transaction> _transactionsForMonth(
  List<Transaction> transactions,
  DateTime month,
) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return transactions.where((tx) {
    final timestamp = tx.timestamp.toLocal();
    return !timestamp.isBefore(start) && timestamp.isBefore(end);
  }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}

Set<String> _walletTokens(Wallet wallet) {
  return {
    wallet.id,
    wallet.name,
    wallet.address,
    wallet.cardMaskedNumber,
    wallet.cardNumberSuffix,
  }.map(_normalizeToken).where((value) => value.isNotEmpty).toSet();
}

String _normalizeToken(Object? value) {
  return (value ?? '')
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'^@+'), '');
}

int _signedSats(Transaction tx) {
  return tx.isDebit ? -tx.totalSatoshis.abs() : tx.amountSatoshis.abs();
}

String _formatSats(
  int signedSats,
  Currency currency,
  double? btcUsd,
  double? btcEur,
  double? btcBrl, {
  required bool signed,
}) {
  return MoneyDisplay.formatAmountFromBtc(
    btcAmount: signedSats / 100000000.0,
    currency: currency,
    btcUsd: btcUsd,
    btcEur: btcEur,
    btcBrl: btcBrl,
    signed: signed,
  );
}

String _movementDescription(BuildContext context, Transaction tx) {
  final date = tx.timestamp.toLocal();
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: true,
  );
  final base = '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} · $time';
  final rail = tx.isLightning
      ? 'Lightning'
      : tx.isInternal
          ? 'Kerosene'
          : 'On-chain';
  return '$base · $rail';
}

String _statusLabel(BuildContext context, TransactionStatus status) {
  return switch (status) {
    TransactionStatus.confirmed => context.tr.confirmed,
    TransactionStatus.confirming => context.tr.confirming,
    TransactionStatus.pending => context.tr.pending,
    TransactionStatus.failed => context.tr.failed,
  };
}

String _monthTitle(BuildContext context, DateTime date) {
  final names = switch (Localizations.localeOf(context).languageCode) {
    'en' => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ],
    'es' => const [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ],
    _ => const [
        'Janeiro',
        'Fevereiro',
        'Março',
        'Abril',
        'Maio',
        'Junho',
        'Julho',
        'Agosto',
        'Setembro',
        'Outubro',
        'Novembro',
        'Dezembro',
      ],
  };
  return '${names[date.month - 1]} ${date.year}';
}

String _walletDetailCopy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}
