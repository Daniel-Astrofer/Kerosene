import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/providers/shared_preferences_provider.dart';
import 'package:kerosene/core/presentation/widgets/app_notification_surface.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/providers/currency_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/widgets/state_feedback_view.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/shared/widgets/bitcoin_refresh_indicator.dart';
import 'package:kerosene/shared/widgets/bouncing_button_wrapper.dart';

import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/domain/entities/transaction.dart';
import 'package:kerosene/features/transactions/domain/entities/payment_link.dart';
import 'package:kerosene/features/transactions/domain/entities/tx_status.dart';
import '../../../transactions/presentation/screens/deposits_screen.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/statement_transaction_card.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/balance_websocket_provider.dart';
import '../../../wallet/presentation/providers/balance_settings_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:kerosene/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
import '../../../wallet/presentation/screens/deposit/deposit_amount_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../widgets/animated_balance_display.dart';
import 'qr_scanner_screen.dart';
import 'package:kerosene/features/notifications/domain/entities/session_notification_item.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/notifications/presentation/notification_navigation.dart';
import 'package:kerosene/features/notifications/presentation/notification_visuals.dart';
import 'package:kerosene/features/notifications/presentation/screens/notification_center_screen.dart';

part 'home_screen_surface.dart';
part 'home_screen_education.dart';
part 'home_screen_send_method.dart';
part 'home_screen_payment_link.dart';
part 'home_screen_balance.dart';
part 'home_screen_navigation.dart';
part 'home_screen_transactions.dart';

enum _HomeLedgerBalanceView { total, platform, onChain }

enum _HomeActivityFilter { platform, onChain, notices }

final _homeLedgerBalanceViewProvider = StateProvider<_HomeLedgerBalanceView>((
  ref,
) {
  return _HomeLedgerBalanceView.total;
});

final _homeActivityFilterProvider = StateProvider<_HomeActivityFilter>((ref) {
  return _HomeActivityFilter.onChain;
});

const Color _homeBackgroundColor = Color(0xFF000000);
const Color _homeCardColor = Color(0xFF141517);
const Color _homePanelTopColor = Color(0xFF1A1A1A);
const Color _homePanelBottomColor = Color(0xFF121212);
const Color _homePanelBorderColor = Color(0xFF2A2A2A);
const Color _homeMutedTextColor = Color(0xFFA3A3A3);
const Color _homeAmberColor = Color(0xFFF59E0B);
const Color _homePositiveColor = Color(0xFF4ADE80);
const double _homeDensityScale = 1.0;

double _homeSize(double value) => value * _homeDensityScale;

double _homeFontSize(double value) => value;

bool _isLightningPaymentPayload(String value) {
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

bool _isOnChainPaymentPayload(String raw, String candidate) {
  final trimmedRaw = raw.trim().toLowerCase();
  final trimmedCandidate = candidate.trim();

  return trimmedRaw.startsWith('bitcoin:') ||
      RegExp(
        r'^(1|3|bc1|m|n|2|tb1|bcrt1)[a-zA-HJ-NP-Z0-9]{20,90}$',
      ).hasMatch(trimmedCandidate);
}

double? _extractLightningAmountBtc(String value) {
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
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void>? _refreshHomeFuture;
  String? _firstUseActionPanelUserId;
  late final ProviderSubscription<ReceivedTxEvent?> _receivedTxSubscription;

  @override
  void initState() {
    super.initState();
    _receivedTxSubscription = ref.listenManual<ReceivedTxEvent?>(
      receivedTxEventProvider,
      (previous, next) {
        if (next == null || !mounted) {
          return;
        }

        ref.read(receivedTxEventProvider.notifier).consumeEvent(next.id);

        ref.invalidate(transactionHistoryProvider);
      },
    );
  }

  @override
  void dispose() {
    _receivedTxSubscription.close();
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
    final result = await _pushFromBottom<dynamic>(
      (_) => SendMoneyScreen(
        walletId: wallet.id,
        initialAddress: initialAddress,
        initialAmountBtc: initialAmountBtc,
      ),
    );

    await _presentFinancialActionResult(result);
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

  void _openSendActionsSheet(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final actions = _buildSendActions(walletState);
    unawaited(
      _pushFromBottom<void>((_) => _SendMethodScreen(actions: actions)),
    );
  }

  void _openSendOnChain(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(_openSendFlow(wallet: wallet));
  }

  void _openSendLightning(WalletState walletState) {
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
      _pushFromBottom<void>((_) => DepositsScreen(initialWallet: wallet)),
    );
  }

  Future<void> _openSendQr(WalletState walletState) async {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final payload = await _pushFromBottom<String>(
      (_) => const QrScannerScreen(),
    );

    if (!mounted || payload == null || payload.trim().isEmpty) {
      return;
    }

    _routeSendPayload(wallet, payload);
  }

  Future<void> _openSendPaymentLink(WalletState walletState) async {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final payload = await _pushFromBottom<String>(
      (_) => const _PaymentLinkEntryScreen(),
    );

    if (!mounted || payload == null || payload.trim().isEmpty) {
      return;
    }

    _routeSendPayload(wallet, payload);
  }

  void _routeSendPayload(Wallet wallet, String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (QrPaymentParser.extractPaymentLinkId(trimmed) != null) {
      unawaited(_openSendFlow(wallet: wallet, initialAddress: trimmed));
      return;
    }

    final parsed = QrPaymentParser.decode(trimmed);
    final candidate = parsed?.address ?? trimmed;

    if (_looksLikeLightningRequest(candidate)) {
      unawaited(
        _openSendFlow(
          wallet: wallet,
          initialAddress: candidate,
          initialAmountBtc:
              parsed?.amountBtc ?? _extractLightningAmountBtc(candidate),
        ),
      );
      return;
    }

    if (_looksLikeOnChainRequest(trimmed, candidate)) {
      unawaited(
        _openSendFlow(
          wallet: wallet,
          initialAddress: candidate,
          initialAmountBtc: parsed?.amountBtc,
        ),
      );
      return;
    }

    unawaited(
      _openSendFlow(
        wallet: wallet,
        initialAddress: trimmed,
        initialAmountBtc: parsed?.amountBtc,
      ),
    );
  }

  bool _looksLikeLightningRequest(String value) {
    return _isLightningPaymentPayload(value);
  }

  bool _looksLikeOnChainRequest(String raw, String candidate) {
    return _isOnChainPaymentPayload(raw, candidate);
  }

  void _openDeposit(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(
      _pushFromBottom<void>((_) => DepositAmountScreen(wallet: wallet)),
    );
  }

  void _openCreateWallet() {
    HapticFeedback.lightImpact();
    unawaited(_openCreateWalletFlow());
  }

  Future<void> _openCreateWalletFlow() async {
    await _pushFromBottom<void>(
      (_) => const BitcoinAccountsScreen(),
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

  List<_HomeSendActionData> _buildSendActions(WalletState walletState) {
    final actions = <_HomeSendActionData>[
      _HomeSendActionData(
        kind: _HomeSendActionKind.sendOnChain,
        label: context.tr.homeSendMethodOnchainLabel,
        subtitle: context.tr.homeSendMethodOnchainSubtitle,
        onTap: () => _openSendOnChain(walletState),
      ),
      _HomeSendActionData(
        kind: _HomeSendActionKind.payLightning,
        label: context.tr.homeSendMethodLightningLabel,
        subtitle: context.tr.homeSendMethodLightningSubtitle,
        onTap: () => _openSendLightning(walletState),
      ),
      _HomeSendActionData(
        kind: _HomeSendActionKind.internalTransfer,
        label: context.tr.homeSendMethodInternalLabel,
        subtitle: context.tr.homeSendMethodInternalSubtitle,
        onTap: () => _openSend(walletState),
      ),
      _HomeSendActionData(
        kind: _HomeSendActionKind.scanQr,
        label: context.tr.homeScanQrLabel,
        subtitle: context.tr.homeScanQrSubtitle,
        onTap: () {
          unawaited(_openSendQr(walletState));
        },
      ),
      _HomeSendActionData(
        kind: _HomeSendActionKind.payLink,
        label: context.tr.homePaymentLinkLabel,
        subtitle: context.tr.homePaymentLinkSubtitle,
        onTap: () {
          unawaited(_openSendPaymentLink(walletState));
        },
      ),
    ];

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final contentMaxWidth = responsive.isCompact
        ? responsive.mobileContentMaxWidth
        : _homeSize(448);
    final pageHorizontalPadding =
        responsive.isTinyPhone ? _homeSize(18) : _homeSize(24);
    final navigationClearance =
        MediaQuery.viewPaddingOf(context).bottom + _homeSize(112);

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
        _pushFromBottom<void>((_) => const TransactionStatementScreen()),
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
        systemNavigationBarColor: _homeBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _homeBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _HomePageBackground(),
            const _HomeRealtimeBootstrap(),
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
                            responsive.isTinyPhone
                                ? _homeSize(8)
                                : _homeSize(16),
                            pageHorizontalPadding,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showHomeLoading)
                                const _HomeLoadingContent().animate().fade(
                                      duration: 220.ms,
                                    )
                              else
                                _HomeEntryTransition(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _HomeBalanceSection(
                                        userName: userName,
                                        walletState: walletState,
                                        activeWallet: activeWallet,
                                        onReceive: () =>
                                            _openReceiveFlow(walletState),
                                        onSend: () =>
                                            _openSendActionsSheet(walletState),
                                        onViewStatement: openStatement,
                                        onOpenWallets: () =>
                                            AppPrimaryNavigationBar.navigateTo(
                                          context,
                                          AppPrimaryDestination.card,
                                        ),
                                      ),
                                      if (showPrimaryActionPanel) ...[
                                        SizedBox(height: _homeSize(18)),
                                        _HomeSetupNotice(
                                          icon: !hasWallet
                                              ? LucideIcons.wallet
                                              : !hasBalance
                                                  ? LucideIcons.download
                                                  : LucideIcons.arrowUpRight,
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
                                                  : () => _openSendActionsSheet(
                                                        walletState,
                                                      ),
                                        ),
                                      ],
                                      SizedBox(height: _homeSize(24)),
                                      const _HomeEducationCarousel(),
                                      SizedBox(height: _homeSize(14)),
                                      SizedBox(height: _homeSize(28)),
                                      _HomeFundsDistributionSection(
                                        walletState: walletState,
                                        onViewStatement: openStatement,
                                      ),
                                      SizedBox(height: _homeSize(28)),
                                      _HomeSectionHeader(
                                        title: _homeRecentActivitiesTitle(
                                          context,
                                        ),
                                        actionLabel: _homeViewAllLabel(context),
                                        onAction: openStatement,
                                      ),
                                      SizedBox(height: _homeSize(12)),
                                      const _HomeActivityFilterChips(),
                                      SizedBox(height: _homeSize(14)),
                                      const HomeTransactionsList(),
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
            const _HomeBottomNavigationOverlay(
              currentDestination: AppPrimaryDestination.home,
            ),
          ],
        ),
      ),
    );
  }
}
