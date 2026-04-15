import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/btc_quote_badge.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:teste/features/notifications/presentation/widgets/session_notification_sidebar.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_activity_details_sheet.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_status_badge.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/balance_websocket_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/home/presentation/widgets/animated_balance_display.dart';

class DepositsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const DepositsScreen({
    super.key,
    this.showPrimaryNavigation = false,
  });

  @override
  ConsumerState<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends ConsumerState<DepositsScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _linksSectionKey = GlobalKey();
  final GlobalKey _historySectionKey = GlobalKey();
  final AppPrimaryNavigationController _navBarController =
      AppPrimaryNavigationController();

  int _page = 0;
  int _size = 25;

  @override
  void dispose() {
    _scrollController.dispose();
    _navBarController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    _navBarController.triggerRefreshAnimation();
    ref.invalidate(depositAddressProvider);
    ref.invalidate(paymentLinksProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(pagedTransactionHistoryProvider);

    await Future.wait([
      ref.read(paymentLinksProvider.future),
      ref.read(
        pagedTransactionHistoryProvider((page: _page, size: _size)).future,
      ),
    ]);
  }

  Future<void> _copyValue(String value, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: value));
    await HapticFeedback.selectionClick();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;
    if (sectionContext == null) {
      return;
    }

    await HapticFeedback.selectionClick();
    await Scrollable.ensureVisible(
      sectionContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Wallet? _resolveActiveWallet(WalletState state) {
    if (state is! WalletLoaded || state.wallets.isEmpty) {
      return null;
    }
    return state.selectedWallet ?? state.wallets.first;
  }

  String? _resolveDepositAddress({
    required Wallet? wallet,
    required AsyncValue<String> remoteAddress,
  }) {
    final remote = remoteAddress.asData?.value.trim();
    if (remote != null && remote.isNotEmpty) {
      return remote;
    }

    final fallback = wallet?.address.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1180;
    final isCompact = screenWidth < 860;
    final pageHorizontalPadding = isCompact ? 16.0 : 20.0;
    final pageTopPadding = isCompact ? 10.0 : 12.0;
    final pageBottomPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : (isWide ? 28.0 : 108.0);

    final linksAsync = ref.watch(paymentLinksProvider);
    final historyAsync = ref.watch(
      pagedTransactionHistoryProvider((page: _page, size: _size)),
    );
    final wsAsync = ref.watch(balanceWebSocketServiceProvider);
    final walletState = ref.watch(walletProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final balanceVisible = ref.watch(balanceVisibilityProvider);
    final totalBalanceBtc = ref.watch(totalBalanceBtcProvider);
    final sidebarOpen = ref.watch(notificationSidebarProvider);
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final notificationCount = notifications.length;
    final activeWallet = _resolveActiveWallet(walletState);
    final depositAddressAsync = ref.watch(depositAddressProvider);
    final depositAddress = _resolveDepositAddress(
      wallet: activeWallet,
      remoteAddress: depositAddressAsync,
    );
    final isRealtimeActive = wsAsync.asData?.value?.isConnected ?? false;
    final primaryBalanceValue = MoneyDisplay.convertFromBtcAmount(
      btcAmount: totalBalanceBtc,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final secondaryCurrency = MoneyDisplay.fallbackFiatFor(selectedCurrency);
    final secondaryBalanceLabel = selectedCurrency == Currency.btc
        ? MoneyDisplay.format(
            amount: MoneyDisplay.convertFromBtcAmount(
              btcAmount: totalBalanceBtc,
              currency: secondaryCurrency,
              btcUsd: btcUsd,
              btcEur: btcEur,
              btcBrl: btcBrl,
            ),
            currency: secondaryCurrency,
          )
        : MoneyDisplay.format(
            amount: totalBalanceBtc,
            currency: Currency.btc,
          );
    final quoteLabel = selectedCurrency == Currency.btc
        ? null
        : MoneyDisplay.formatQuoteValue(
            currency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          );

    final links = linksAsync.asData?.value ?? const <PaymentLink>[];
    final sortedLinks = [...links]..sort((a, b) {
        final rankCompare = _paymentLinkPriority(a).compareTo(
          _paymentLinkPriority(b),
        );
        if (rankCompare != 0) {
          return rankCompare;
        }
        return (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      });
    final pendingLinks = sortedLinks
        .where((link) => link.isPending || link.isVerifyingOnboarding)
        .toList();
    final expiredLinks = sortedLinks.where(_isLinkExpired).length;

    final historyRows = [
      ...(historyAsync.asData?.value ?? const <Transaction>[])
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final pendingTransactions = historyRows
        .where(
          (tx) =>
              tx.status == TransactionStatus.pending ||
              tx.status == TransactionStatus.confirming,
        )
        .toList();
    final incomeTransactions = historyRows
        .where(
          (tx) =>
              tx.type == TransactionType.deposit ||
              tx.type == TransactionType.receive,
        )
        .length;
    final hasBalance = totalBalanceBtc > 0;

    final primaryAction = _resolvePrimaryAction(
      context: context,
      depositAddress: depositAddress,
      hasBalance: hasBalance,
      pendingLinks: pendingLinks,
      pendingTransactions: pendingTransactions,
    );

    final attentionCards = _buildAttentionCards(
      depositAddress: depositAddress,
      hasBalance: hasBalance,
      pendingLinks: pendingLinks,
      expiredLinks: expiredLinks,
      pendingTransactions: pendingTransactions,
      notificationCount: notificationCount,
      isWide: isWide,
    );

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: Stack(
        children: [
          const _MonitoringBackdrop(),
          Row(
            children: [
              Expanded(
                child: SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.85),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pageHorizontalPadding,
                            pageTopPadding,
                            pageHorizontalPadding,
                            pageBottomPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildHeader(
                                context,
                                isWide: isWide,
                                notificationCount: notificationCount,
                              ),
                              SizedBox(height: isCompact ? 16 : 20),
                              RepaintBoundary(
                                child: _MonitoringHeroCard(
                                  walletName: activeWallet?.name,
                                  walletSecurity: activeWallet?.accountSecurity,
                                  walletCardType: activeWallet?.cardType,
                                  depositFeeRate: activeWallet?.depositFeeRate,
                                  balanceVisible: balanceVisible,
                                  selectedCurrency: selectedCurrency,
                                  primaryBalanceValue: primaryBalanceValue,
                                  secondaryBalanceLabel: secondaryBalanceLabel,
                                  quoteLabel: quoteLabel,
                                  realtimeActive: isRealtimeActive,
                                  pendingLinksCount: pendingLinks.length,
                                  pendingTransactionsCount:
                                      pendingTransactions.length,
                                  notificationCount: notificationCount,
                                  headline: _heroHeadline(
                                    hasBalance: hasBalance,
                                    pendingLinksCount: pendingLinks.length,
                                    pendingTransactionsCount:
                                        pendingTransactions.length,
                                    notificationCount: notificationCount,
                                  ),
                                  supportingText: _heroSupportingText(
                                    depositAddress: depositAddress,
                                    hasBalance: hasBalance,
                                    pendingLinksCount: pendingLinks.length,
                                    pendingTransactionsCount:
                                        pendingTransactions.length,
                                    isRealtimeActive: isRealtimeActive,
                                  ),
                                  onToggleBalance: () async {
                                    await HapticFeedback.selectionClick();
                                    ref
                                        .read(
                                          balanceVisibilityProvider.notifier,
                                        )
                                        .toggle();
                                  },
                                  onPrimaryAction: primaryAction.onTap,
                                  primaryActionLabel: primaryAction.label,
                                  primaryActionIcon: primaryAction.icon,
                                  onSecondaryAction: () {
                                    if (pendingLinks.isNotEmpty) {
                                      _scrollToSection(_linksSectionKey);
                                      return;
                                    }
                                    _scrollToSection(_historySectionKey);
                                  },
                                  secondaryActionLabel: pendingLinks.isNotEmpty
                                      ? 'Ver cobranças'
                                      : 'Ver movimentações',
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 20),
                              if (attentionCards.isNotEmpty) ...[
                                _SectionHeader(
                                  title: 'O que fazer agora',
                                  subtitle:
                                      'A tela se adapta ao seu momento para reduzir passos e leitura desnecessária.',
                                ),
                                SizedBox(height: isCompact ? 12 : 14),
                                RepaintBoundary(
                                  child: _AttentionGrid(cards: attentionCards),
                                ),
                                SizedBox(height: isCompact ? 20 : 24),
                              ],
                              Container(
                                key: _linksSectionKey,
                                child: _SectionHeader(
                                  title: 'Links de pagamento e vouchers',
                                  subtitle:
                                      'Os links criados no receber por QR aparecem aqui com o status real da API, como pendente, pago, expirado ou concluído.',
                                ),
                              ),
                              SizedBox(height: isCompact ? 12 : 14),
                              RepaintBoundary(
                                child: _buildPaymentLinksSection(
                                    linksAsync, sortedLinks),
                              ),
                              SizedBox(height: isCompact ? 20 : 24),
                              Container(
                                key: _historySectionKey,
                                child: _SectionHeader(
                                  title: 'Movimentações',
                                  subtitle:
                                      'Histórico real do ledger com paginação. No celular, a leitura fica em cartões; em telas largas, você vê a tabela completa.',
                                ),
                              ),
                              SizedBox(height: isCompact ? 12 : 14),
                              RepaintBoundary(
                                child: _buildHistorySection(
                                  historyAsync: historyAsync,
                                  rows: historyRows,
                                  isCompact: isCompact,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RepaintBoundary(
                                child: _buildPaginationControls(
                                  historyAsync: historyAsync,
                                  rows: historyRows,
                                ),
                              ),
                              if (incomeTransactions > 0) ...[
                                const SizedBox(height: 16),
                                _FriendlyInfoCard(
                                  icon: Icons.savings_rounded,
                                  accent: FinancialStatusBadge.successColor,
                                  title: 'Você está no controle',
                                  message:
                                      '$incomeTransactions movimentação${incomeTransactions == 1 ? '' : 'ões'} de entrada já apareceram nesta página. O acompanhamento continua em tempo real enquanto a conexão estiver ativa.',
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isWide) const SessionNotificationSidebar(),
            ],
          ),
          if (!isWide && sidebarOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    ref.read(notificationSidebarProvider.notifier).close(),
                child: Container(color: Colors.black.withValues(alpha: 0.42)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SessionNotificationSidebar(
                showCloseButton: true,
                onClose: () =>
                    ref.read(notificationSidebarProvider.notifier).close(),
              ),
            ),
          ],
          if (widget.showPrimaryNavigation)
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.history,
              controller: _navBarController,
            )
          else if (!isWide)
            _MobileActionDock(
              onRefresh: _refreshData,
              onNotifications: () async {
                await HapticFeedback.selectionClick();
                ref.read(notificationSidebarProvider.notifier).toggle();
              },
              notificationCount: notificationCount,
            ),
        ],
      ),
    );
  }

  _HeroAction _resolvePrimaryAction({
    required BuildContext context,
    required String? depositAddress,
    required bool hasBalance,
    required List<PaymentLink> pendingLinks,
    required List<Transaction> pendingTransactions,
  }) {
    if (!hasBalance && depositAddress != null) {
      return _HeroAction(
        label: 'Copiar endereço',
        icon: Icons.copy_rounded,
        onTap: () => _copyValue(
          depositAddress,
          'Endereço da conta copiado para receber BTC.',
        ),
      );
    }

    if (pendingLinks.isNotEmpty) {
      return _HeroAction(
        label: 'Abrir cobrança',
        icon: Icons.qr_code_2_rounded,
        onTap: () async {
          await HapticFeedback.selectionClick();
          if (!mounted) {
            return;
          }
          await FinancialActivityDetailsSheet.show(
            context,
            paymentLink: pendingLinks.first,
          );
        },
      );
    }

    if (pendingTransactions.isNotEmpty) {
      return _HeroAction(
        label: 'Ver andamento',
        icon: Icons.route_rounded,
        onTap: () async {
          await HapticFeedback.selectionClick();
          if (!mounted) {
            return;
          }
          await FinancialActivityDetailsSheet.show(
            context,
            transaction: pendingTransactions.first,
          );
        },
      );
    }

    return _HeroAction(
      label: 'Atualizar agora',
      icon: Icons.refresh_rounded,
      onTap: _refreshData,
    );
  }

  List<_AttentionCardData> _buildAttentionCards({
    required String? depositAddress,
    required bool hasBalance,
    required List<PaymentLink> pendingLinks,
    required int expiredLinks,
    required List<Transaction> pendingTransactions,
    required int notificationCount,
    required bool isWide,
  }) {
    final cards = <_AttentionCardData>[];

    if (!hasBalance && depositAddress != null) {
      cards.add(
        _AttentionCardData(
          icon: Icons.south_west_rounded,
          accent: FinancialStatusBadge.successColor,
          title: 'Pronto para receber',
          message:
              'Sua conta ainda está sem saldo. Copie o endereço e compartilhe só quando precisar receber.',
          ctaLabel: 'Copiar endereço',
          onTap: () => _copyValue(
            depositAddress,
            'Endereço da conta copiado para receber BTC.',
          ),
        ),
      );
    }

    if (pendingLinks.isNotEmpty) {
      cards.add(
        _AttentionCardData(
          icon: Icons.schedule_send_rounded,
          accent: FinancialStatusBadge.pendingColor,
          title: 'Cobranças aguardando',
          message:
              '${pendingLinks.length} item${pendingLinks.length == 1 ? '' : 's'} ainda ${pendingLinks.length == 1 ? 'precisa' : 'precisam'} de pagamento ou conferência.',
          ctaLabel: 'Ver pendências',
          onTap: () => _scrollToSection(_linksSectionKey),
        ),
      );
    }

    if (pendingTransactions.isNotEmpty) {
      cards.add(
        _AttentionCardData(
          icon: Icons.sync_rounded,
          accent: FinancialStatusBadge.infoColor,
          title: 'Movimentações em andamento',
          message:
              '${pendingTransactions.length} transa${pendingTransactions.length == 1 ? 'ção' : 'ções'} ainda está${pendingTransactions.length == 1 ? '' : 'o'} em processamento.',
          ctaLabel: 'Ver andamento',
          onTap: () => _scrollToSection(_historySectionKey),
        ),
      );
    }

    if (expiredLinks > 0) {
      cards.add(
        _AttentionCardData(
          icon: Icons.lock_clock_rounded,
          accent: FinancialStatusBadge.errorColor,
          title: 'Itens expirados',
          message:
              '$expiredLinks link${expiredLinks == 1 ? '' : 's'} já não aceita${expiredLinks == 1 ? '' : 'm'} novos pagamentos.',
          ctaLabel: 'Revisar',
          onTap: () => _scrollToSection(_linksSectionKey),
        ),
      );
    }

    if (!isWide && notificationCount > 0) {
      cards.add(
        _AttentionCardData(
          icon: Icons.notifications_active_rounded,
          accent: FinancialStatusBadge.successColor,
          title: 'Atualizações recentes',
          message:
              '$notificationCount alerta${notificationCount == 1 ? '' : 's'} chegou${notificationCount == 1 ? '' : 'ram'} nesta sessão.',
          ctaLabel: 'Abrir alertas',
          onTap: () async {
            await HapticFeedback.selectionClick();
            ref.read(notificationSidebarProvider.notifier).open();
          },
        ),
      );
    }

    if (cards.isEmpty) {
      cards.add(
        _AttentionCardData(
          icon: Icons.verified_user_rounded,
          accent: FinancialStatusBadge.successColor,
          title: 'Tudo em ordem',
          message:
              'Saldo, cobranças e movimentações estão sob controle. Se algo mudar, o alerta aparece automaticamente.',
          ctaLabel: 'Atualizar',
          onTap: _refreshData,
        ),
      );
    }

    return cards;
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isWide,
    required int notificationCount,
  }) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: widget.showPrimaryNavigation
              ? () => AppPrimaryNavigationBar.backOrHome(context)
              : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            padding: EdgeInsets.all(isCompact ? 10 : 12),
          ),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu dinheiro',
                style: (isCompact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saldo, cobranças e movimentações em uma única tela.',
                style: (isCompact
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (isWide)
          _TopStatusPill(
            icon: Icons.lock_rounded,
            label: 'Monitoramento seguro',
            accent: Colors.white,
          )
        else
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () async {
                  await HapticFeedback.selectionClick();
                  ref.read(notificationSidebarProvider.notifier).toggle();
                },
                icon: const Icon(Icons.notifications_active_outlined),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FinancialStatusBadge.errorColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentLinksSection(
    AsyncValue<List<PaymentLink>> linksAsync,
    List<PaymentLink> links,
  ) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    return linksAsync.when(
      loading: () => const _LoadingCard(
        message: 'Buscando cobranças e vouchers...',
      ),
      error: (error, _) => _ErrorCard(message: error.toString()),
      data: (_) {
        if (links.isEmpty) {
          return const _EmptyCard(
            title: 'Nenhuma cobrança recente',
            message:
                'Quando um voucher de onboarding ou um link de pagamento for criado, ele aparece aqui para acompanhamento rápido.',
          );
        }

        return Column(
          children: links.take(4).map((link) {
            final status = FinancialStatusBadge.paymentLink(link.status);
            final accent = status.color;
            final title = link.isOnboardingVoucher
                ? 'Voucher de onboarding'
                : 'Cobrança por link';
            final helper = _paymentLinkHelperText(link);
            final dueLabel = link.expiresAt != null && !_isLinkExpired(link)
                ? 'Expira ${_relativeTime(link.expiresAt!)}'
                : link.createdAt != null
                    ? _relativeTime(link.createdAt!)
                    : 'Atualizado agora';
            final amountLabel = MoneyDisplay.formatAmountFromBtc(
              btcAmount: link.amountBtc,
              currency: selectedCurrency,
              btcUsd: btcUsd,
              btcEur: btcEur,
              btcBrl: btcBrl,
            );

            return Padding(
              padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
              child: InkWell(
                onTap: () => FinancialActivityDetailsSheet.show(
                  context,
                  paymentLink: link,
                ),
                borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding: EdgeInsets.all(isCompact ? 16 : 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.11),
                        const Color(0xFF0E1722),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                    border: Border.all(color: accent.withValues(alpha: 0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: isCompact ? 14 : 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: isCompact ? 16 : 18,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  helper,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontSize: isCompact ? 13 : null,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FinancialStatusBadge(meta: status, compact: true),
                        ],
                      ),
                      SizedBox(height: isCompact ? 14 : 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          amountLabel,
                          key: ValueKey(
                            '${link.id}_${link.amountBtc}_${selectedCurrency.code}',
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                fontSize: isCompact ? 22 : 24,
                              ),
                        ),
                      ),
                      if (selectedCurrency != Currency.btc) ...[
                        const SizedBox(height: 6),
                        Text(
                          MoneyDisplay.format(
                            amount: link.amountBtc,
                            currency: Currency.btc,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                      SizedBox(height: isCompact ? 12 : 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricPill(
                            label: 'Para receber',
                            value: _shorten(link.depositAddress),
                            accent: Colors.white,
                          ),
                          _MetricPill(
                            label: 'Momento',
                            value: dueLabel,
                            accent: accent,
                          ),
                          if (link.createdAt != null)
                            _MetricPill(
                              label: 'Criado em',
                              value: _dateFormat.format(link.createdAt!),
                              accent: Colors.white70,
                            ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 12 : 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _copyValue(
                                link.depositAddress,
                                'Endereço de depósito copiado.',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                minimumSize:
                                    Size.fromHeight(isCompact ? 44 : 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isCompact ? 14 : 16,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copiar endereço'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => FinancialActivityDetailsSheet.show(
                              context,
                              paymentLink: link,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              minimumSize: Size(104, isCompact ? 44 : 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 14 : 16,
                                ),
                              ),
                            ),
                            child: const Text('Detalhes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHistorySection({
    required AsyncValue<List<Transaction>> historyAsync,
    required List<Transaction> rows,
    required bool isCompact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C141E),
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: isCompact ? 18 : 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: historyAsync.when(
        loading: () => const _LoadingCard(
          message: 'Atualizando movimentações do ledger...',
          dense: true,
        ),
        error: (error, _) => _ErrorCard(message: error.toString()),
        data: (_) {
          if (rows.isEmpty) {
            return const _EmptyCard(
              title: 'Sem movimentações nesta página',
              message:
                  'Ajuste a paginação ou aguarde novas entradas. Quando algo chegar, esta lista atualiza automaticamente.',
            );
          }

          if (isCompact) {
            return Column(
              children: rows.map((tx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    transaction: tx,
                    onTap: () => FinancialActivityDetailsSheet.show(
                      context,
                      transaction: tx,
                    ),
                  ),
                );
              }).toList(),
            );
          }

          // Avoid LayoutBuilder inside SliverChildListDelegate (causes
          // _RenderLayoutBuilder is not a subtype of RenderSliver crash).
          // Use a SingleChildScrollView that fills its parent naturally.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HistoryHeaderRow(),
                  const Divider(color: Colors.white12, height: 22),
                  ...rows.map(
                    (tx) => _HistoryTableRow(
                      transaction: tx,
                      onTap: () => FinancialActivityDetailsSheet.show(
                        context,
                        transaction: tx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls({
    required AsyncValue<List<Transaction>> historyAsync,
    required List<Transaction> rows,
  }) {
    final canGoNext = historyAsync.isLoading ? false : rows.length >= _size;

    // Avoid LayoutBuilder inside SliverChildListDelegate context.
    // Use MediaQuery.sizeOf for the responsive breakpoint instead.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 720;

    final info = Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          label: 'Página atual',
          value: '${_page + 1}',
          accent: Colors.white,
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _size,
            dropdownColor: const Color(0xFF111A24),
            borderRadius: BorderRadius.circular(16),
            items: const [10, 25, 50].map((size) {
              return DropdownMenuItem<int>(
                value: size,
                child: Text('$size por página'),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) {
                return;
              }
              await HapticFeedback.selectionClick();
              setState(() {
                _size = value;
                _page = 0;
              });
            },
          ),
        ),
        Text(
          'Consulta atual: /ledger/history?page=$_page&size=$_size',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
              ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _page == 0 || historyAsync.isLoading
              ? null
              : () async {
                  await HapticFeedback.selectionClick();
                  setState(() => _page -= 1);
                },
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Anterior'),
        ),
        FilledButton.icon(
          onPressed: !canGoNext
              ? null
              : () async {
                  await HapticFeedback.selectionClick();
                  setState(() => _page += 1);
                },
          style: FilledButton.styleFrom(
            backgroundColor: FinancialStatusBadge.successColor,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Próxima'),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B141D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 14),
                actions,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  static String _heroHeadline({
    required bool hasBalance,
    required int pendingLinksCount,
    required int pendingTransactionsCount,
    required int notificationCount,
  }) {
    if (!hasBalance) {
      return 'Conta pronta para receber';
    }
    if (pendingLinksCount > 0) {
      return 'Há dinheiro esperando por você';
    }
    if (pendingTransactionsCount > 0) {
      return 'Tudo visível enquanto processa';
    }
    if (notificationCount > 0) {
      return 'Atualizações chegaram agora';
    }
    return 'Tudo sob controle';
  }

  static String _heroSupportingText({
    required String? depositAddress,
    required bool hasBalance,
    required int pendingLinksCount,
    required int pendingTransactionsCount,
    required bool isRealtimeActive,
  }) {
    if (!hasBalance && depositAddress != null) {
      return 'Sua carteira está pronta para receber. Copie o endereço quando precisar e acompanhe o saldo daqui.';
    }
    if (pendingLinksCount > 0) {
      return 'Você tem $pendingLinksCount cobrança${pendingLinksCount == 1 ? '' : 's'} aguardando pagamento ou conferência.';
    }
    if (pendingTransactionsCount > 0) {
      return 'Há $pendingTransactionsCount movimentação${pendingTransactionsCount == 1 ? '' : 'ões'} em andamento. O status muda automaticamente.';
    }
    if (isRealtimeActive) {
      return 'O acompanhamento em tempo real está ativo. Se algo mudar, você vê primeiro por aqui.';
    }
    return 'Você continua vendo o histórico mesmo sem tempo real ativo. Use atualizar para buscar o estado mais recente.';
  }

  static int _paymentLinkPriority(PaymentLink link) {
    if (link.isPending) {
      return 0;
    }
    if (link.isVerifyingOnboarding) {
      return 1;
    }
    if (link.isPaid || link.isCompleted) {
      return 2;
    }
    if (_isLinkExpired(link)) {
      return 3;
    }
    return 4;
  }

  static bool _isLinkExpired(PaymentLink link) {
    return link.status == 'expired' || link.isExpired;
  }

  static String _paymentLinkHelperText(PaymentLink link) {
    if (link.isOnboardingVoucher &&
        (link.isPending || link.isVerifyingOnboarding)) {
      return 'Use este voucher para concluir o onboarding sem precisar navegar por várias telas.';
    }
    if (link.isPaid || link.isCompleted) {
      return 'Pagamento recebido. Você pode abrir os detalhes para conferir o identificador e o horário.';
    }
    if (_isLinkExpired(link)) {
      return 'Este link expirou e não aceita novos pagamentos.';
    }
    return 'Compartilhe o endereço de depósito e acompanhe o status sem sair desta tela.';
  }

  static String _relativeTime(DateTime date) {
    final localDate = date.toLocal();
    final difference = DateTime.now().difference(localDate);
    if (difference.isNegative) {
      final future = localDate.difference(DateTime.now());
      if (future.inMinutes < 1) {
        return 'em instantes';
      }
      if (future.inHours < 1) {
        return 'em ${future.inMinutes} min';
      }
      if (future.inDays < 1) {
        return 'em ${future.inHours} h';
      }
      return 'em ${future.inDays} d';
    }
    if (difference.inMinutes < 1) {
      return 'agora';
    }
    if (difference.inHours < 1) {
      return 'há ${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return 'há ${difference.inHours} h';
    }
    return 'há ${difference.inDays} d';
  }

  static String _shorten(String value) {
    if (value.length <= 18) {
      return value;
    }
    return '${value.substring(0, 10)}...${value.substring(value.length - 6)}';
  }
}

class _MonitoringBackdrop extends StatelessWidget {
  const _MonitoringBackdrop();

  @override
  Widget build(BuildContext context) {
    return const AmbientSideGlowBackdrop.authenticated();
  }
}

class _MonitoringHeroCard extends StatelessWidget {
  final String? walletName;
  final String? walletSecurity;
  final WalletCardType? walletCardType;
  final double? depositFeeRate;
  final bool balanceVisible;
  final Currency selectedCurrency;
  final double primaryBalanceValue;
  final String secondaryBalanceLabel;
  final String? quoteLabel;
  final bool realtimeActive;
  final int pendingLinksCount;
  final int pendingTransactionsCount;
  final int notificationCount;
  final String headline;
  final String supportingText;
  final VoidCallback onToggleBalance;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onSecondaryAction;
  final String secondaryActionLabel;

  const _MonitoringHeroCard({
    required this.walletName,
    required this.walletSecurity,
    required this.walletCardType,
    required this.depositFeeRate,
    required this.balanceVisible,
    required this.selectedCurrency,
    required this.primaryBalanceValue,
    required this.secondaryBalanceLabel,
    required this.quoteLabel,
    required this.realtimeActive,
    required this.pendingLinksCount,
    required this.pendingTransactionsCount,
    required this.notificationCount,
    required this.headline,
    required this.supportingText,
    required this.onToggleBalance,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onSecondaryAction,
    required this.secondaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final theme = Theme.of(context);
    final balanceStyle = (isCompact
                ? theme.textTheme.headlineSmall
                : theme.textTheme.headlineMedium)
            ?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: isCompact ? 28 : 34,
          height: 0.96,
          letterSpacing: isCompact ? -0.5 : -0.8,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 28 : 34,
          fontWeight: FontWeight.w700,
          height: 0.96,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1D2A), Color(0xFF0A1520)],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 28 : 32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: isCompact ? 22 : 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TopStatusPill(
                icon: realtimeActive
                    ? Icons.bolt_rounded
                    : Icons.cloud_off_rounded,
                label: realtimeActive
                    ? 'Tempo real ativo'
                    : 'Tempo real indisponível',
                accent: realtimeActive
                    ? FinancialStatusBadge.successColor
                    : FinancialStatusBadge.errorColor,
              ),
              _TopStatusPill(
                icon: Icons.lock_rounded,
                label: walletSecurity ?? 'STANDARD',
                accent: Colors.white,
              ),
              if (walletName != null && walletName!.trim().isNotEmpty)
                _TopStatusPill(
                  icon: Icons.account_balance_wallet_rounded,
                  label: walletName!,
                  accent: Colors.white,
                ),
              if (walletCardType != null)
                _TopStatusPill(
                  icon: Icons.percent_rounded,
                  label:
                      '${walletCardType!.label} • depósito ${WalletCardType.formatRate(depositFeeRate ?? walletCardType!.defaultFeeRate)}',
                  accent: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          SizedBox(height: isCompact ? 18 : 22),
          Text(
            'Saldo monitorado',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: isCompact ? 10 : 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedBalanceDisplay(
                      balance: primaryBalanceValue,
                      prefix:
                          '${MoneyDisplay.tickerSymbolFor(selectedCurrency)} ',
                      decimalPlaces: MoneyDisplay.decimalsFor(selectedCurrency),
                      locale: MoneyDisplay.localeFor(selectedCurrency),
                      enableFlash: true,
                      isHidden: !balanceVisible,
                      digitWidthFactor: isCompact ? 0.7 : 0.66,
                      characterSpacing: isCompact ? 1.0 : 0.8,
                      decimalScaleFactor: isCompact ? 0.58 : 0.62,
                      separatorScaleFactor: 0.74,
                      style: balanceStyle,
                      animateInitialValue: false,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              IconButton(
                onPressed: onToggleBalance,
                icon: Icon(
                  balanceVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  padding: EdgeInsets.all(isCompact ? 10 : 12),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              balanceVisible
                  ? secondaryBalanceLabel
                  : 'Toque no olho para mostrar o valor',
              key: ValueKey(
                'secondary_$balanceVisible\_$selectedCurrency\_$secondaryBalanceLabel',
              ),
              style: (isCompact
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                color: Colors.white.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 14 : null,
              ),
            ),
          ),
          if (quoteLabel != null) ...[
            const SizedBox(height: 10),
            BtcQuoteBadge(value: quoteLabel!, compact: isCompact),
          ],
          SizedBox(height: isCompact ? 18 : 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey('$headline|$supportingText'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: (isCompact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 22 : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  supportingText,
                  style: (isCompact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: isCompact ? 14 : null,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 16 : 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                height: isCompact ? 46 : 50,
                child: FilledButton.icon(
                  onPressed: onPrimaryAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancialStatusBadge.successColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 20,
                    ),
                  ),
                  icon: Icon(primaryActionIcon),
                  label: Text(primaryActionLabel),
                ),
              ),
              SizedBox(
                height: isCompact ? 46 : 50,
                child: OutlinedButton.icon(
                  onPressed: onSecondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 20,
                    ),
                  ),
                  icon: const Icon(Icons.swipe_right_alt_rounded),
                  label: Text(secondaryActionLabel),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(
                label: 'Cobranças aguardando',
                value: '$pendingLinksCount',
                accent: FinancialStatusBadge.pendingColor,
              ),
              _HeroMetric(
                label: 'Em andamento',
                value: '$pendingTransactionsCount',
                accent: FinancialStatusBadge.infoColor,
              ),
              _HeroMetric(
                label: 'Alertas da sessão',
                value: '$notificationCount',
                accent: FinancialStatusBadge.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Container(
      constraints: BoxConstraints(minWidth: isCompact ? 104 : 120),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 11.5 : null,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: (isCompact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: isCompact ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _TopStatusPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 14 : 16, color: accent),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 11.5 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (isCompact
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleLarge)
              ?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 18 : null,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 6),
        Text(
          subtitle,
          style: (isCompact
                  ? Theme.of(context).textTheme.bodySmall
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AttentionGrid extends StatelessWidget {
  final List<_AttentionCardData> cards;

  const _AttentionGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) {
        return SizedBox(
          width: 320,
          child: _AttentionCard(data: card),
        );
      }).toList(),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final _AttentionCardData data;

  const _AttentionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1620),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
            ),
            child:
                Icon(data.icon, color: data.accent, size: isCompact ? 20 : 24),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 16 : null,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            data.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: isCompact ? 13 : null,
                  height: 1.4,
                ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          TextButton.icon(
            onPressed: data.onTap,
            style: TextButton.styleFrom(
              foregroundColor: data.accent,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(data.ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.46),
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 10 : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 13 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? accent;

  const _InlineInfoChip({
    required this.icon,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final resolvedAccent = accent ?? Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: resolvedAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedAccent.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 14, color: resolvedAccent),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: resolvedAccent.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 10.5 : null,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _HistoryCell(width: 150, text: 'Tipo'),
        _HistoryCell(width: 140, text: 'Status'),
        _HistoryCell(width: 160, text: 'Valor'),
        _HistoryCell(width: 240, text: 'Quem participou'),
        _HistoryCell(width: 180, text: 'Data'),
      ],
    );
  }
}

class _HistoryTableRow extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _HistoryTableRow({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = FinancialStatusBadge.transaction(transaction.status);
    final isCredit = transaction.type == TransactionType.receive ||
        transaction.type == TransactionType.deposit;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountColor = isCredit
        ? FinancialStatusBadge.successColor
        : transaction.type == TransactionType.withdrawal
            ? FinancialStatusBadge.errorColor
            : FinancialStatusBadge.pendingColor;
    final counterparty =
        (isCredit ? transaction.fromAddress : transaction.toAddress).trim();
    final amountLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: transaction.amountBTC,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      signed: true,
    );
    final rowGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(const Color(0xFF101823), amountColor, 0.18)!,
        Colors.black,
        const Color(0xFF111A24),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: rowGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: amountColor.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            _HistoryValueCell(
              width: 150,
              child: Text(
                _historyTypeLabel(transaction),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            _HistoryValueCell(
              width: 140,
              child: FinancialStatusBadge(meta: status, compact: true),
            ),
            _HistoryValueCell(
              width: 160,
              child: Text(
                amountLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _HistoryValueCell(
              width: 240,
              child: Text(
                counterparty.isEmpty ? 'Não informado' : counterparty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
              ),
            ),
            _HistoryValueCell(
              width: 180,
              child: Text(
                _DepositsScreenState._dateFormat.format(transaction.timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = FinancialStatusBadge.transaction(transaction.status);
    final isCompact = MediaQuery.sizeOf(context).width < 860;
    final isCredit = transaction.type == TransactionType.receive ||
        transaction.type == TransactionType.deposit;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountColor = isCredit
        ? FinancialStatusBadge.successColor
        : transaction.type == TransactionType.withdrawal
            ? FinancialStatusBadge.errorColor
            : FinancialStatusBadge.pendingColor;
    final counterparty =
        (isCredit ? transaction.fromAddress : transaction.toAddress).trim();
    final amountLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: transaction.amountBTC,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
      signed: true,
    );
    final cardGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(const Color(0xFF101823), amountColor, 0.18)!,
        Colors.black,
        const Color(0xFF111A24),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 14 : 16),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
          border: Border.all(color: amountColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isCompact ? 38 : 42,
                  height: isCompact ? 38 : 42,
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                    border: Border.all(
                      color: amountColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    _historyTypeIcon(transaction),
                    color: amountColor,
                    size: isCompact ? 18 : 20,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _historyTypeLabel(transaction),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 16 : null,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        counterparty.isEmpty
                            ? 'Origem ou destino não informado'
                            : _DepositsScreenState._shorten(counterparty),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.56),
                              fontSize: isCompact ? 12 : null,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isCompact ? 132 : 156),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          amountLabel,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: amountColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 18 : 20,
                                    height: 1,
                                  ),
                        ),
                      ),
                      if (selectedCurrency != Currency.btc) ...[
                        const SizedBox(height: 4),
                        Text(
                          MoneyDisplay.format(
                            amount: transaction.amountBTC,
                            currency: Currency.btc,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.44),
                                    fontWeight: FontWeight.w600,
                                    fontSize: isCompact ? 11 : null,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FinancialStatusBadge(meta: status, compact: true),
                _InlineInfoChip(
                  icon: Icons.schedule_rounded,
                  value: _DepositsScreenState._dateFormat
                      .format(transaction.timestamp),
                ),
                if (transaction.status == TransactionStatus.confirming)
                  _InlineInfoChip(
                    icon: Icons.shield_outlined,
                    value: '${transaction.confirmations}/6 confirmações',
                    accent: FinancialStatusBadge.pendingColor,
                  ),
                if (transaction.feeSatoshis > 0)
                  _InlineInfoChip(
                    icon: Icons.toll_rounded,
                    value: 'Taxa ${MoneyDisplay.formatAmountFromBtc(
                      btcAmount: transaction.feeBTC,
                      currency: selectedCurrency,
                      btcUsd: btcUsd,
                      btcEur: btcEur,
                      btcBrl: btcBrl,
                    )}',
                    accent: Colors.white70,
                  ),
                const _InlineInfoChip(
                  icon: Icons.chevron_right_rounded,
                  value: 'Detalhes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  final double width;
  final String text;

  const _HistoryCell({
    required this.width,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.46),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _HistoryValueCell extends StatelessWidget {
  final double width;
  final Widget child;

  const _HistoryValueCell({
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;
  final bool dense;

  const _LoadingCard({
    required this.message,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 18 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1622),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FinancialStatusBadge.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: FinancialStatusBadge.errorColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Não deu para atualizar agora',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: FinancialStatusBadge.errorColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1622),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _FriendlyInfoCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  const _FriendlyInfoCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
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

class _MobileActionDock extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;
  final int notificationCount;

  const _MobileActionDock({
    required this.onRefresh,
    required this.onNotifications,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C141D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRefresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: FinancialStatusBadge.successColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNotifications,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_active_outlined),
                      if (notificationCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: FinancialStatusBadge.errorColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('Alertas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _AttentionCardData {
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback onTap;

  const _AttentionCardData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onTap,
  });
}

String _historyTypeLabel(Transaction tx) {
  switch (tx.type) {
    case TransactionType.deposit:
      return 'Depósito';
    case TransactionType.withdrawal:
      return 'Saque';
    case TransactionType.send:
      return 'Saída';
    case TransactionType.receive:
      return 'Entrada';
    case TransactionType.swap:
      return 'Swap';
    case TransactionType.fee:
      return 'Taxa';
  }
}

IconData _historyTypeIcon(Transaction tx) {
  switch (tx.type) {
    case TransactionType.deposit:
    case TransactionType.receive:
      return Icons.south_west_rounded;
    case TransactionType.withdrawal:
    case TransactionType.send:
      return Icons.north_east_rounded;
    case TransactionType.swap:
      return Icons.swap_horiz_rounded;
    case TransactionType.fee:
      return Icons.toll_rounded;
  }
}
