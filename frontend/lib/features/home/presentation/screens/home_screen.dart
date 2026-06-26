// ignore_for_file: unused_import, unused_element

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/core/navigation/deferred_page.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/app_notification_surface.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo.dart';
import 'package:kerosene/core/providers/currency_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/shared/widgets/state_feedback_view.dart';
import 'package:kerosene/shared/widgets/bitcoin_refresh_indicator.dart';
import 'package:kerosene/shared/widgets/bouncing_button_wrapper.dart';

import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/features/financial_activity/domain/entities/payment_link.dart';
import 'package:kerosene/features/financial_activity/domain/entities/tx_status.dart';
import '../../../financial_activity/presentation/screens/deposits_screen.dart'
    deferred as deposits;
import '../../../financial_activity/presentation/providers/transaction_provider.dart';
import '../../../financial_activity/presentation/widgets/statement_transaction_card.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import 'package:kerosene/features/financial_accounts/presentation/providers/balance_websocket_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/balance_settings_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/receive/presentation/widgets/receive_flow_ui.dart';
import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_flow_selector.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_screen.dart'
    deferred as bitcoin_accounts;
import 'package:kerosene/features/send/presentation/screens/send_money_screen.dart'
    deferred as send_money;
import '../widgets/animated_balance_display.dart';
import '../widgets/home_bitcoin_market_chart_card.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/notifications/presentation/notification_navigation.dart';
import 'package:kerosene/features/notifications/presentation/notification_visuals.dart';
import 'package:kerosene/features/notifications/presentation/screens/notification_center_screen.dart';

import 'home_screen_surface.dart';
import 'home_screen_education.dart';
import 'home_screen_send_method.dart';
import 'home_screen_payment_link.dart';
import 'home_screen_balance.dart';
import 'home_screen_navigation.dart';
import 'home_screen_transactions.dart';

enum HomeLedgerBalanceView { total, platform, onChain }

enum HomeActivityFilter { all, incoming, outgoing, pending, failed }

final homeLedgerBalanceViewProvider = StateProvider<HomeLedgerBalanceView>((
  ref,
) {
  return HomeLedgerBalanceView.total;
});

final homeLedgerBalancePageProvider = StateProvider<int>((ref) => 0);

final homeActivityFilterProvider = StateProvider<HomeActivityFilter>((ref) {
  return HomeActivityFilter.all;
});

final homeRouteActiveProvider = StateProvider<bool>((ref) => true);

const Color homeBackgroundColor = AppColors.hexFF000000;
const Color homeCardColor = AppColors.hexFF141517;
const Color homePanelTopColor = AppColors.hexFF1A1A1A;
const Color homePanelBottomColor = AppColors.hexFF121212;
const Color homePanelBorderColor = AppColors.hexFF2A2A2A;
const Color homeMutedTextColor = AppColors.hexFFA3A3A3;
const Color homeAmberColor = AppColors.hexFFF59E0B;
const Color homePositiveColor = AppColors.hexFF4ADE80;
const double homeDensityScale = 1.0;

double homeSize(double value) => value * homeDensityScale;

double homeFontSize(double value) => value;

bool isLightningPaymentPayload(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final withoutPrefix = trimmed.toLowerCase().startsWith('lightning:')
      ? trimmed.substring(10).trim()
      : trimmed;
  final lower = withoutPrefix.toLowerCase();

  return RegExp(r'^(lnbc|lntb|lnbcrt)[0-9][0-9a-z]+$').hasMatch(lower) ||
      RegExp(r'^lnurl[0-9a-z]+$').hasMatch(lower);
}

bool isOnChainPaymentPayload(String raw, String candidate) {
  final trimmedRaw = raw.trim().toLowerCase();
  final trimmedCandidate = candidate.trim();

  return trimmedRaw.startsWith('bitcoin:') ||
      RegExp(
        r'^(1|3|bc1|m|n|2|tb1|bcrt1)[a-zA-HJ-NP-Z0-9]{20,90}$',
      ).hasMatch(trimmedCandidate);
}

double? extractLightningAmountBtc(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final withoutPrefix = trimmed.toLowerCase().startsWith('lightning:')
      ? trimmed.substring(10).trim()
      : trimmed;
  final match = RegExp(
    r'^ln(?:bc|tb|bcrt)(\d+)([munp]?)1',
  ).firstMatch(withoutPrefix.toLowerCase());
  if (match == null) {
    return null;
  }

  final amount = double.tryParse(match.group(1) ?? '');
  if (amount == null || amount <= 0) {
    return null;
  }

  final multiplier = switch (match.group(2)) {
    'm' => 0.001,
    'u' => 0.000001,
    'n' => 0.000000001,
    'p' => 0.000000000001,
    _ => 1.0,
  };
  return amount * multiplier;
}

Route<T> _buildBottomUpRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return keroseneHorizontalRoute<T>(settings: settings, builder: builder);
}

class HomeScreen extends ConsumerStatefulWidget {
  static bool skipNextAuth = false;
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void>? _refreshHomeFuture;
  String? _firstUseActionPanelUserId;
  late final StateController<bool> homeRouteActiveController;

  @override
  void initState() {
    super.initState();
    homeRouteActiveController = ref.read(homeRouteActiveProvider.notifier);
    homeRouteActiveController.state = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHomeData();
    });
  }

  @override
  void dispose() {
    homeRouteActiveController.state = false;
    super.dispose();
  }

  Wallet? _resolveActiveWallet(WalletState walletState) {
    if (walletState is! WalletLoaded) {
      return null;
    }

    return walletState.selectedWallet ??
        (walletState.wallets.isNotEmpty ? walletState.wallets.first : null);
  }

  void _showWalletRequiredNotice() {
    AppNotice.showInfo(
      context,
      title: context.tr.homeWalletRequiredTitle,
      message: context.tr.homeWalletRequiredMessage,
    );
  }

  Future<void> _refreshHomeData() async {
    final activeRefresh = _refreshHomeFuture;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refresh = _performHomeRefresh();
    _refreshHomeFuture = refresh;

    return refresh.whenComplete(() {
      if (identical(_refreshHomeFuture, refresh)) {
        _refreshHomeFuture = null;
      }
    });
  }

  Future<void> _performHomeRefresh() async {
    try {
      final walletRefresh = ref.read(walletProvider.notifier).refresh();
      final historyRefresh = ref.refresh(transactionHistoryProvider.future);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);

      await Future.wait<dynamic>([
        walletRefresh,
        historyRefresh,
      ], eagerError: false);
    } catch (_) {}
  }

  Future<T?> _pushFromBottom<T>(WidgetBuilder builder) {
    return Navigator.of(context).push<T>(_buildBottomUpRoute(builder: builder));
  }

  Future<void> _syncAfterFinancialAction() async {
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(depositsProvider);
    ref.invalidate(depositBalanceProvider);
    await ref.read(walletProvider.notifier).refresh();
  }

  Future<void> _presentFinancialActionResult(dynamic result) async {
    if (result == null) {
      return;
    }

    await _syncAfterFinancialAction();

    if (!mounted) {
      return;
    }

    if (result is TxStatus) {
      return;
    }

    if (result is PaymentLink) {
      return;
    }
  }

  Future<void> _openSendFlow({
    required Wallet wallet,
    String? initialAddress,
    double? initialAmountBtc,
  }) async {
    final result = await _pushWalletSelectorFlow<dynamic>(
      title: context.tr.send,
      subtitle: context.tr.walletSelectorSendSubtitle,
      initialWallet: wallet,
      destinationBuilder: (selectedWallet) => DeferredPage(
        loadLibrary: send_money.loadLibrary,
        builder: (_) => send_money.SendMoneyScreen(
          walletId: selectedWallet.id,
          initialAddress: initialAddress,
          initialAmountBtc: initialAmountBtc,
        ),
      ),
    );

    await _presentFinancialActionResult(result);
  }

  Future<T?> _pushWalletSelectorFlow<T>({
    required String title,
    required String subtitle,
    required Wallet initialWallet,
    required Widget Function(Wallet wallet) destinationBuilder,
  }) {
    return _pushFromBottom<T>(
      (selectorContext) => WalletFlowSelector(
        title: title,
        subtitle: subtitle,
        initialWallet: initialWallet,
        onContinue: (selectedWallet) {
          Navigator.of(selectorContext).pushReplacement<T, void>(
            _buildBottomUpRoute<T>(
              builder: (_) => destinationBuilder(selectedWallet),
            ),
          );
        },
      ),
    );
  }

  void _openSend(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(_openSendFlow(wallet: wallet));
  }

  void _openReceiveFlow(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(
      _pushWalletSelectorFlow<void>(
        title: context.tr.receive,
        subtitle: context.tr.walletSelectorReceiveSubtitle,
        initialWallet: wallet,
        destinationBuilder: (selectedWallet) => DeferredPage(
          loadLibrary: deposits.loadLibrary,
          builder: (_) =>
              deposits.DepositsScreen(initialWallet: selectedWallet),
        ),
      ),
    );
  }

  void _openDeposit(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);

    if (wallet == null) {
      HapticFeedback.lightImpact();
      _showWalletRequiredNotice();
      return;
    }

    _openDepositForWallet(wallet);
  }

  void _openDepositForWallet(Wallet wallet) {
    HapticFeedback.lightImpact();

    unawaited(
      _pushWalletSelectorFlow<void>(
        title: context.tr.depositFlowDepositTitle,
        subtitle: context.tr.walletSelectorDepositSubtitle,
        initialWallet: wallet,
        destinationBuilder: (selectedWallet) => DeferredPage(
          loadLibrary: deposits.loadLibrary,
          builder: (_) =>
              deposits.DepositsScreen(initialWallet: selectedWallet),
        ),
      ),
    );
  }

  void _openCreateWallet() {
    HapticFeedback.lightImpact();
    unawaited(_openCreateWalletFlow());
  }

  Future<void> _openCreateWalletFlow() async {
    await _pushFromBottom<void>(
      (_) => DeferredPage(
        loadLibrary: bitcoin_accounts.loadLibrary,
        builder: (_) => bitcoin_accounts.BitcoinAccountsScreen(),
      ),
    );
    if (!mounted) {
      return;
    }

    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(depositsProvider);
    ref.invalidate(depositBalanceProvider);
  }

  String _firstUseActionPanelKey(String userId) =>
      'home.first_use_action_panel_seen.$userId';

  bool _hasSeenFirstUseActionPanel(String? userId) {
    if (userId == null || userId.isEmpty) {
      return true;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_firstUseActionPanelKey(userId)) ?? false;
  }

  void _activateFirstUseActionPanel(String userId) {
    if (_firstUseActionPanelUserId == userId) {
      return;
    }

    _firstUseActionPanelUserId = userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .setBool(_firstUseActionPanelKey(userId), true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final contentMaxWidth =
        responsive.isCompact ? responsive.mobileContentMaxWidth : homeSize(448);
    final pageHorizontalPadding =
        responsive.isTinyPhone ? homeSize(18) : homeSize(24);
    final navigationClearance =
        MediaQuery.viewPaddingOf(context).bottom + homeSize(112);

    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final transactionHistoryAsync = ref.watch(transactionHistoryProvider);
    final activeWallet = _resolveActiveWallet(walletState);
    final hasWallet = activeWallet != null;
    final hasBalance = (activeWallet?.balance ?? 0) > 0;
    final isReadyActionsVariant = hasWallet && hasBalance;
    final transactionHistory =
        transactionHistoryAsync.asData?.value ?? const <Transaction>[];
    final hasLoadedTransactionHistory = transactionHistoryAsync.hasValue;
    final hasTransactions = transactionHistory.isNotEmpty;
    final authenticatedUserId =
        authState is AuthAuthenticated ? authState.user.id : null;
    final hasSeenFirstUseActionPanel = _hasSeenFirstUseActionPanel(
      authenticatedUserId,
    );

    if (authenticatedUserId == null) {
      _firstUseActionPanelUserId = null;
    }

    if (authenticatedUserId != null &&
        isReadyActionsVariant &&
        hasLoadedTransactionHistory &&
        !hasTransactions &&
        !hasSeenFirstUseActionPanel) {
      _activateFirstUseActionPanel(authenticatedUserId);
    }

    final showFirstUseReadyPanel = authenticatedUserId != null &&
        isReadyActionsVariant &&
        !hasTransactions &&
        _firstUseActionPanelUserId == authenticatedUserId;
    final showPrimaryActionPanel =
        !isReadyActionsVariant || showFirstUseReadyPanel;
    final showHomeLoading = walletState is WalletInitial ||
        walletState is WalletLoading ||
        (!transactionHistoryAsync.hasValue &&
            transactionHistoryAsync.isLoading);

    void openStatement() {
      unawaited(
        _pushFromBottom<void>(
          (_) => DeferredPage(
            loadLibrary: deposits.loadLibrary,
            builder: (_) => deposits.TransactionStatementScreen(),
          ),
        ),
      );
    }

    // ── NOME DE USUÁRIO REAL E SEGURO ──
    String userName = '';

    if (authState is AuthAuthenticated) {
      final fullName = authState.user.name.trim();
      if (fullName.isNotEmpty) {
        userName =
            fullName.split(' ').first; // Pega o primeiro nome para UI limpa
      }
    } else if (activeWallet != null) {
      userName = activeWallet.name;
    } else if (authState is AuthLoading) {
      userName = '...';
    }

    if (userName.isEmpty || userName == 'Not Found') {
      userName = context.tr.homeFallbackUser;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: homeBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: homeBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const HomePageBackground(),
            const HomeRealtimeBootstrap(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  BitcoinRefreshIndicator(onRefresh: _refreshHomeData),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            pageHorizontalPadding,
                            responsive.isTinyPhone ? homeSize(8) : homeSize(16),
                            pageHorizontalPadding,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showHomeLoading)
                                const HomeLoadingContent().animate().fade(
                                      duration: 220.ms,
                                    )
                              else
                                HomeEntryTransition(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      HomeBalanceSection(
                                        userName: userName,
                                        walletState: walletState,
                                        activeWallet: activeWallet,
                                        onReceive: () =>
                                            _openReceiveFlow(walletState),
                                        onSend: () => _openSend(walletState),
                                        onViewStatement: openStatement,
                                        onOpenWallets: () =>
                                            AppPrimaryNavigationBar.navigateTo(
                                          context,
                                          AppPrimaryDestination.card,
                                        ),
                                      ),
                                      SizedBox(height: homeSize(18)),
                                      const HomeBitcoinMarketChartCard(),
                                      if (showPrimaryActionPanel) ...[
                                        SizedBox(height: homeSize(18)),
                                        HomeSetupNotice(
                                          icon: !hasWallet
                                              ? KeroseneIcons.wallet
                                              : !hasBalance
                                                  ? KeroseneIcons.download
                                                  : KeroseneIcons.send,
                                          title: !hasWallet
                                              ? context
                                                  .l10n.homePrimaryNoWalletTitle
                                              : !hasBalance
                                                  ? context.tr
                                                      .homePrimaryReadyNoBalanceTitle
                                                  : context
                                                      .tr.homePrimaryReadyTitle,
                                          subtitle: !hasWallet
                                              ? context.tr
                                                  .homePrimaryNoWalletSubtitle
                                              : !hasBalance
                                                  ? context.tr
                                                      .homePrimaryReadyNoBalanceSubtitle
                                                  : context.tr
                                                      .homePrimaryReadySubtitle,
                                          actionLabel: !hasWallet
                                              ? context
                                                  .l10n.homeCreateWalletAction
                                              : !hasBalance
                                                  ? context
                                                      .tr.homeDepositFundsAction
                                                  : context
                                                      .l10n.homeSendBtcAction,
                                          onAction: !hasWallet
                                              ? _openCreateWallet
                                              : !hasBalance
                                                  ? () =>
                                                      _openDeposit(walletState)
                                                  : () =>
                                                      _openSend(walletState),
                                        ),
                                      ],
                                      SizedBox(height: homeSize(24)),
                                      const HomeEducationCarousel(),
                                      SizedBox(height: homeSize(14)),
                                      SizedBox(height: homeSize(28)),
                                      HomeFundsDistributionSection(
                                        walletState: walletState,
                                        onViewStatement: openStatement,
                                      ),
                                      SizedBox(height: homeSize(28)),
                                      HomeSectionHeader(
                                        title: homeRecentActivitiesTitle(
                                          context,
                                        ),
                                        actionLabel: homeViewAllLabel(context),
                                        onAction: openStatement,
                                      ),
                                      SizedBox(height: homeSize(12)),
                                      if (hasTransactions) ...[
                                        const HomeActivityFilterChips(),
                                        SizedBox(height: homeSize(14)),
                                      ],
                                      HomeTransactionsList(
                                        onCreateWallet: _openCreateWallet,
                                        onDepositWallet: _openDepositForWallet,
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: navigationClearance),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const HomeBottomNavigationOverlay(
              currentDestination: AppPrimaryDestination.home,
            ),
          ],
        ),
      ),
    );
  }
}
