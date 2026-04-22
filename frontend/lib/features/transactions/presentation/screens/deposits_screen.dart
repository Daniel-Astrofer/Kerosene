import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:teste/features/notifications/presentation/widgets/session_notification_sidebar.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/transactions/presentation/widgets/financial_activity_details_sheet.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/providers/balance_websocket_provider.dart';
import 'package:teste/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:teste/features/wallet/presentation/state/wallet_state.dart';

const Color _background = authenticatedSurfaceBackgroundColor;
const Color _surface = Color(0xFF0D0F11);
const Color _surfaceRaised = Color(0xFF111418);
const Color _surfacePressed = Color(0xFF15191E);
const Color _border = Color(0xFF262B31);
const Color _borderSoft = Color(0xFF1D2228);
const Color _textPrimary = Color(0xFFF2F4F5);
const Color _textSecondary = Color(0xFFA3ABB3);
const Color _textMuted = Color(0xFF6E7781);
const Color _iconMuted = Color(0xFF9099A3);

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
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _linksSectionKey = GlobalKey();
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

    AppNotice.showSuccess(context, message: successMessage);
  }

  Future<void> _scrollToLinks() async {
    final sectionContext = _linksSectionKey.currentContext;
    if (sectionContext == null) {
      return;
    }
    await HapticFeedback.selectionClick();
    await Scrollable.ensureVisible(
      sectionContext,
      alignment: 0.10,
      duration: const Duration(milliseconds: 240),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 1120;
    final isCompact = screenWidth < 760;
    final pageHorizontalPadding = isCompact ? 16.0 : 24.0;
    final pageTopPadding = isCompact ? 14.0 : 20.0;
    final pageBottomPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : (isCompact ? 112.0 : 32.0);

    final walletState = ref.watch(walletProvider);
    final activeWallet = _resolveActiveWallet(walletState);
    final depositAddressAsync = ref.watch(depositAddressProvider);
    final depositAddress = _resolveDepositAddress(
      wallet: activeWallet,
      remoteAddress: depositAddressAsync,
    );

    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final totalBalanceBtc = ref.watch(totalBalanceBtcProvider);
    final balanceVisible = ref.watch(balanceVisibilityProvider);
    final primaryBalance = MoneyDisplay.format(
      amount: MoneyDisplay.convertFromBtcAmount(
        btcAmount: totalBalanceBtc,
        currency: selectedCurrency,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      ),
      currency: selectedCurrency,
    );
    final secondaryBalance = selectedCurrency == Currency.btc
        ? MoneyDisplay.format(
            amount: MoneyDisplay.convertFromBtcAmount(
              btcAmount: totalBalanceBtc,
              currency: Currency.brl,
              btcUsd: btcUsd,
              btcEur: btcEur,
              btcBrl: btcBrl,
            ),
            currency: Currency.brl,
          )
        : MoneyDisplay.format(amount: totalBalanceBtc, currency: Currency.btc);

    final wsAsync = ref.watch(balanceWebSocketServiceProvider);
    final isRealtimeActive = wsAsync.asData?.value?.isConnected ?? false;
    final linksAsync = ref.watch(paymentLinksProvider);
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
    final openLinks = sortedLinks
        .where((link) => link.isPending || link.isVerifyingOnboarding)
        .toList();

    final historyAsync = ref.watch(
      pagedTransactionHistoryProvider((page: _page, size: _size)),
    );
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
    final sidebarOpen = ref.watch(notificationSidebarProvider);
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final notificationCount = notifications.length;

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const ColoredBox(color: _background),
          Row(
            children: [
              Expanded(
                child: SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: _textPrimary,
                    backgroundColor: _surfaceRaised,
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
                          sliver: SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 1040 : 720,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _StatementHeader(
                                      walletName: activeWallet?.name,
                                      notificationCount: notificationCount,
                                      showNotificationButton: !isWide,
                                      onBack: () => widget.showPrimaryNavigation
                                          ? AppPrimaryNavigationBar.backOrHome(
                                              context)
                                          : Navigator.maybePop(context),
                                      onRefresh: _refreshData,
                                      onNotifications: () async {
                                        await HapticFeedback.selectionClick();
                                        ref
                                            .read(
                                              notificationSidebarProvider
                                                  .notifier,
                                            )
                                            .toggle();
                                      },
                                    ),
                                    SizedBox(height: isCompact ? 16 : 20),
                                    _StatementOverview(
                                      balance: balanceVisible
                                          ? primaryBalance
                                          : '••••',
                                      secondaryBalance: balanceVisible
                                          ? secondaryBalance
                                          : 'Saldo oculto',
                                      balanceVisible: balanceVisible,
                                      transactionCount: historyRows.length,
                                      pendingCount: pendingTransactions.length,
                                      openLinkCount: openLinks.length,
                                      realtimeActive: isRealtimeActive,
                                      onToggleBalance: () async {
                                        await HapticFeedback.selectionClick();
                                        ref
                                            .read(
                                              balanceVisibilityProvider
                                                  .notifier,
                                            )
                                            .toggle();
                                      },
                                      onCopyAddress: depositAddress == null
                                          ? null
                                          : () => _copyValue(
                                                depositAddress,
                                                'Endereço copiado.',
                                              ),
                                      onOpenLinks: openLinks.isEmpty
                                          ? null
                                          : _scrollToLinks,
                                      onRefresh: _refreshData,
                                    ),
                                    if (openLinks.isNotEmpty ||
                                        linksAsync.isLoading) ...[
                                      SizedBox(height: isCompact ? 20 : 24),
                                      Container(
                                        key: _linksSectionKey,
                                        child: _OpenLinksSection(
                                          linksAsync: linksAsync,
                                          links: openLinks,
                                          selectedCurrency: selectedCurrency,
                                          btcUsd: btcUsd,
                                          btcEur: btcEur,
                                          btcBrl: btcBrl,
                                          onCopyAddress: (address) =>
                                              _copyValue(
                                            address,
                                            'Endereço copiado.',
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: isCompact ? 20 : 24),
                                    _SectionTitle(
                                      icon: LucideIcons.receipt,
                                      title: 'Movimentações',
                                      trailing: 'Página ${_page + 1}',
                                    ),
                                    const SizedBox(height: 10),
                                    _HistorySection(
                                      historyAsync: historyAsync,
                                      rows: historyRows,
                                      isCompact: isCompact,
                                    ),
                                    const SizedBox(height: 12),
                                    _PaginationControls(
                                      page: _page,
                                      size: _size,
                                      isLoading: historyAsync.isLoading,
                                      canGoNext: !historyAsync.isLoading &&
                                          historyRows.length >= _size,
                                      onPrevious: _page == 0
                                          ? null
                                          : () async {
                                              await HapticFeedback
                                                  .selectionClick();
                                              setState(() => _page -= 1);
                                            },
                                      onNext: !historyAsync.isLoading &&
                                              historyRows.length >= _size
                                          ? () async {
                                              await HapticFeedback
                                                  .selectionClick();
                                              setState(() => _page += 1);
                                            }
                                          : null,
                                      onSizeChanged: (value) async {
                                        await HapticFeedback.selectionClick();
                                        setState(() {
                                          _size = value;
                                          _page = 0;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.46)),
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

  static String shorten(String value, {int head = 10, int tail = 6}) {
    final normalized = value.trim();
    if (normalized.length <= head + tail + 3) {
      return normalized;
    }
    return '${normalized.substring(0, head)}...${normalized.substring(normalized.length - tail)}';
  }
}

class _StatementHeader extends StatelessWidget {
  final String? walletName;
  final int notificationCount;
  final bool showNotificationButton;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onNotifications;

  const _StatementHeader({
    required this.walletName,
    required this.notificationCount,
    required this.showNotificationButton,
    required this.onBack,
    required this.onRefresh,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      color: _textPrimary,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      height: 1.0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _IconButtonShell(
          tooltip: 'Voltar',
          icon: LucideIcons.arrowLeft,
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Extrato', style: titleStyle),
              const SizedBox(height: 5),
              Text(
                walletName == null || walletName!.trim().isEmpty
                    ? 'Ledger da conta'
                    : walletName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        _IconButtonShell(
          tooltip: 'Atualizar',
          icon: LucideIcons.refreshCw,
          onPressed: onRefresh,
        ),
        if (showNotificationButton) ...[
          const SizedBox(width: 8),
          _NotificationButton(
            count: notificationCount,
            onPressed: onNotifications,
          ),
        ],
      ],
    );
  }
}

class _StatementOverview extends StatelessWidget {
  final String balance;
  final String secondaryBalance;
  final bool balanceVisible;
  final int transactionCount;
  final int pendingCount;
  final int openLinkCount;
  final bool realtimeActive;
  final VoidCallback onToggleBalance;
  final VoidCallback? onCopyAddress;
  final VoidCallback? onOpenLinks;
  final VoidCallback onRefresh;

  const _StatementOverview({
    required this.balance,
    required this.secondaryBalance,
    required this.balanceVisible,
    required this.transactionCount,
    required this.pendingCount,
    required this.openLinkCount,
    required this.realtimeActive,
    required this.onToggleBalance,
    required this.onCopyAddress,
    required this.onOpenLinks,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 14 : 16,
              isCompact ? 14 : 16,
              isCompact ? 12 : 14,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _textMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balance,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: _textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            height: 1.0,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        secondaryBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _IconButtonShell(
                  tooltip: balanceVisible ? 'Ocultar saldo' : 'Mostrar saldo',
                  icon: balanceVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  onPressed: onToggleBalance,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderSoft),
          Padding(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OverviewMetric(
                  icon: LucideIcons.receipt,
                  label: 'Itens',
                  value: '$transactionCount',
                ),
                _OverviewMetric(
                  icon: LucideIcons.clock3,
                  label: 'Pendentes',
                  value: '$pendingCount',
                ),
                _OverviewMetric(
                  icon: LucideIcons.link2,
                  label: 'Cobranças',
                  value: '$openLinkCount',
                ),
                _OverviewMetric(
                  icon:
                      realtimeActive ? LucideIcons.radio : LucideIcons.cloudOff,
                  label: 'Rede',
                  value: realtimeActive ? 'Ativa' : 'Manual',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderSoft),
          Padding(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MonoActionButton(
                  icon: LucideIcons.copy,
                  label: 'Copiar endereço',
                  onPressed: onCopyAddress,
                ),
                _MonoActionButton(
                  icon: LucideIcons.link,
                  label: 'Cobranças',
                  onPressed: onOpenLinks,
                ),
                _MonoActionButton(
                  icon: LucideIcons.refreshCw,
                  label: 'Atualizar',
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _iconMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenLinksSection extends StatelessWidget {
  final AsyncValue<List<PaymentLink>> linksAsync;
  final List<PaymentLink> links;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;
  final ValueChanged<String> onCopyAddress;

  const _OpenLinksSection({
    required this.linksAsync,
    required this.links,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
    required this.onCopyAddress,
  });

  @override
  Widget build(BuildContext context) {
    return linksAsync.when(
      loading: () => const _LoadingPanel(message: 'Carregando cobranças'),
      error: (error, _) => _ErrorPanel(message: error.toString()),
      data: (_) {
        if (links.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: LucideIcons.link2,
              title: 'Cobranças abertas',
              trailing: '${links.length}',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderSoft),
              ),
              child: Column(
                children: [
                  for (var index = 0;
                      index < links.take(3).length;
                      index++) ...[
                    if (index > 0) const Divider(height: 1, color: _borderSoft),
                    _PaymentLinkRow(
                      link: links[index],
                      amount: MoneyDisplay.formatAmountFromBtc(
                        btcAmount: links[index].amountBtc,
                        currency: selectedCurrency,
                        btcUsd: btcUsd,
                        btcEur: btcEur,
                        btcBrl: btcBrl,
                      ),
                      onCopyAddress: () =>
                          onCopyAddress(links[index].depositAddress),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentLinkRow extends StatelessWidget {
  final PaymentLink link;
  final String amount;
  final VoidCallback onCopyAddress;

  const _PaymentLinkRow({
    required this.link,
    required this.amount,
    required this.onCopyAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        link.isOnboardingVoucher ? 'Voucher onboarding' : 'Link de pagamento';
    final moment = link.expiresAt != null
        ? 'Expira ${_relativeTime(link.expiresAt!)}'
        : link.createdAt != null
            ? _relativeTime(link.createdAt!)
            : 'Agora';

    return InkWell(
      onTap: () => FinancialActivityDetailsSheet.show(
        context,
        paymentLink: link,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            const _MonoIconBox(icon: LucideIcons.link),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_linkStatusLabel(link)} · $moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: onCopyAddress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.copy,
                        size: 12,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'copiar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _textMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final AsyncValue<List<Transaction>> historyAsync;
  final List<Transaction> rows;
  final bool isCompact;

  const _HistorySection({
    required this.historyAsync,
    required this.rows,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      loading: () => const _LoadingPanel(message: 'Atualizando ledger'),
      error: (error, _) => _ErrorPanel(message: error.toString()),
      data: (_) {
        if (rows.isEmpty) {
          return const _EmptyPanel(
            icon: LucideIcons.receipt,
            title: 'Sem movimentações',
            message: 'Nada nesta página.',
          );
        }

        if (isCompact) {
          return Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderSoft),
            ),
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0) const Divider(height: 1, color: _borderSoft),
                  _HistoryListRow(
                    transaction: rows[index],
                    onTap: () => FinancialActivityDetailsSheet.show(
                      context,
                      transaction: rows[index],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderSoft),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 980,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HistoryTableHeader(),
                  const Divider(height: 1, color: _borderSoft),
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0) const Divider(height: 1, color: _borderSoft),
                    _HistoryTableRow(
                      transaction: rows[index],
                      onTap: () => FinancialActivityDetailsSheet.show(
                        context,
                        transaction: rows[index],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryListRow extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _HistoryListRow({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountLabel = _transactionAmountLabel(
      transaction: transaction,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final counterparty = _counterpartyLabel(transaction);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _MonoIconBox(icon: _historyTypeIcon(transaction)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _historyTypeLabel(transaction),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusText(transaction.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    counterparty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _DepositsScreenState._timeFormat
                        .format(transaction.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTableHeader extends StatelessWidget {
  const _HistoryTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          _TableHeadCell(width: 240, text: 'Tipo'),
          _TableHeadCell(width: 140, text: 'Status'),
          _TableHeadCell(width: 170, text: 'Valor'),
          _TableHeadCell(width: 280, text: 'Contraparte'),
          _TableHeadCell(width: 140, text: 'Data'),
        ],
      ),
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
    final theme = Theme.of(context);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountLabel = _transactionAmountLabel(
      transaction: transaction,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 240,
              child: Row(
                children: [
                  _MonoIconBox(
                      icon: _historyTypeIcon(transaction), small: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _historyTypeLabel(transaction),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 140, child: _StatusText(transaction.status)),
            SizedBox(
              width: 170,
              child: Text(
                amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: Text(
                _counterpartyLabel(transaction),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                _DepositsScreenState._dateFormat.format(transaction.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int size;
  final bool isLoading;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onSizeChanged;

  const _PaginationControls({
    required this.page,
    required this.size,
    required this.isLoading,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        children: [
          Text(
            'Pág. ${page + 1}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: size,
              dropdownColor: _surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              iconEnabledColor: _textMuted,
              items: const [10, 25, 50].map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(isCompact ? '$value' : '$value por página'),
                );
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        onSizeChanged(value);
                      }
                    },
            ),
          ),
          const Spacer(),
          _IconButtonShell(
            tooltip: 'Anterior',
            icon: LucideIcons.chevronLeft,
            onPressed: onPrevious,
          ),
          const SizedBox(width: 8),
          _IconButtonShell(
            tooltip: 'Próxima',
            icon: LucideIcons.chevronRight,
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 17, color: _iconMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _MonoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _MonoActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed?.call();
              },
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: disabled ? _background : _surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color:
                    disabled ? _textMuted.withValues(alpha: 0.42) : _iconMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: disabled
                      ? _textMuted.withValues(alpha: 0.42)
                      : _textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButtonShell extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _IconButtonShell({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: disabled ? _background : _surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderSoft),
              ),
              child: Icon(
                icon,
                size: 17,
                color: disabled
                    ? _textMuted.withValues(alpha: 0.36)
                    : _textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconButtonShell(
          tooltip: 'Alertas',
          icon: LucideIcons.bell,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _textPrimary,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _background,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonoIconBox extends StatelessWidget {
  final IconData icon;
  final bool small;

  const _MonoIconBox({
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 34.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _surfacePressed,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Icon(icon, size: small ? 14 : 16, color: _iconMuted),
    );
  }
}

class _StatusText extends StatelessWidget {
  final TransactionStatus status;

  const _StatusText(this.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_statusIcon(status), size: 12, color: _textMuted),
        const SizedBox(width: 5),
        Text(
          _statusLabel(status),
          style: theme.textTheme.labelSmall?.copyWith(
            color: _textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _TableHeadCell extends StatelessWidget {
  final double width;
  final String text;

  const _TableHeadCell({
    required this.width,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _textMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String message;

  const _LoadingPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, size: 17, color: _textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Falha ao atualizar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
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

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderSoft),
      ),
      child: Row(
        children: [
          _MonoIconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MonoActionButton(
                    icon: LucideIcons.refreshCw,
                    label: 'Atualizar',
                    onPressed: onRefresh,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _MonoActionButton(
                          icon: LucideIcons.bell,
                          label: 'Alertas',
                          onPressed: onNotifications,
                        ),
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 3,
                          top: -3,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _textPrimary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: _background,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                    height: 1,
                                  ),
                            ),
                          ),
                        ),
                    ],
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

bool _isCredit(Transaction tx) {
  return tx.type == TransactionType.receive ||
      tx.type == TransactionType.deposit;
}

String _transactionAmountLabel({
  required Transaction transaction,
  required Currency currency,
  required double? btcUsd,
  required double? btcEur,
  required double? btcBrl,
}) {
  if (transaction.type == TransactionType.swap) {
    return MoneyDisplay.formatAmountFromBtc(
      btcAmount: transaction.amountBTC,
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  final signedAmount =
      _isCredit(transaction) ? transaction.amountBTC : -transaction.amountBTC;

  return MoneyDisplay.formatAmountFromBtc(
    btcAmount: signedAmount,
    currency: currency,
    btcUsd: btcUsd,
    btcEur: btcEur,
    btcBrl: btcBrl,
    signed: true,
  );
}

String _counterpartyLabel(Transaction tx) {
  final value = (_isCredit(tx) ? tx.fromAddress : tx.toAddress).trim();
  if (value.isEmpty) {
    return 'Sem contraparte';
  }
  return _DepositsScreenState.shorten(value, head: 12, tail: 6);
}

String _historyTypeLabel(Transaction tx) {
  switch (tx.type) {
    case TransactionType.deposit:
      return 'Depósito';
    case TransactionType.withdrawal:
      return 'Saque';
    case TransactionType.send:
      return tx.isInternal ? 'Envio interno' : 'Envio';
    case TransactionType.receive:
      return tx.isInternal ? 'Recebimento interno' : 'Recebimento';
    case TransactionType.swap:
      return 'Swap';
    case TransactionType.fee:
      return 'Taxa';
  }
}

IconData _historyTypeIcon(Transaction tx) {
  switch (tx.type) {
    case TransactionType.deposit:
      return LucideIcons.arrowDownToLine;
    case TransactionType.receive:
      return LucideIcons.arrowDownLeft;
    case TransactionType.withdrawal:
      return LucideIcons.arrowUpFromLine;
    case TransactionType.send:
      return LucideIcons.arrowUpRight;
    case TransactionType.swap:
      return LucideIcons.arrowLeftRight;
    case TransactionType.fee:
      return LucideIcons.receipt;
  }
}

String _statusLabel(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.confirmed:
      return 'Concluído';
    case TransactionStatus.confirming:
      return 'Confirmando';
    case TransactionStatus.pending:
      return 'Pendente';
    case TransactionStatus.failed:
      return 'Falhou';
  }
}

IconData _statusIcon(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.confirmed:
      return LucideIcons.checkCircle2;
    case TransactionStatus.confirming:
      return LucideIcons.loader2;
    case TransactionStatus.pending:
      return LucideIcons.clock3;
    case TransactionStatus.failed:
      return LucideIcons.alertCircle;
  }
}

String _linkStatusLabel(PaymentLink link) {
  if (link.isVerifyingOnboarding) {
    return 'Verificando';
  }
  if (link.isPending) {
    return 'Pendente';
  }
  if (link.isPaid || link.isCompleted) {
    return 'Pago';
  }
  if (link.isExpired) {
    return 'Expirado';
  }
  return link.status;
}

String _relativeTime(DateTime date) {
  final localDate = date.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localDate);
  if (difference.isNegative) {
    final future = localDate.difference(now);
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
  return _DepositsScreenState._dateTimeFormat.format(localDate);
}
