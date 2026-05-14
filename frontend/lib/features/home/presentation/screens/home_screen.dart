import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:teste/main.dart' show sharedPreferencesProvider;
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/navigation/app_page_transitions.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/widgets/state_feedback_view.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/shared/widgets/bitcoin_refresh_indicator.dart';
import 'package:teste/shared/widgets/bouncing_button_wrapper.dart';

import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/domain/entities/tx_status.dart';
import '../../../transactions/presentation/screens/deposits_screen.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/balance_websocket_provider.dart';
import '../../../wallet/presentation/providers/balance_settings_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
import '../../../wallet/presentation/screens/deposit/deposit_amount_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/nfc_interaction_screen.dart';
import '../../../wallet/presentation/screens/receive_hub_screen.dart';
import '../widgets/animated_balance_display.dart';
import '../../../transactions/presentation/screens/withdraw_screen.dart';
import '../../../transactions/presentation/widgets/transaction_visuals.dart';
import '../widgets/latest_tx_popup.dart';
import '../widgets/tx_detail_overlay.dart';
import 'qr_scanner_screen.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:teste/features/notifications/presentation/widgets/session_notification_sidebar.dart';

enum _HomeLedgerBalanceView { total, platform, onChain }

enum _HomeActivityFilter { platform, onChain, notices }

final _homeLedgerBalanceViewProvider =
    StateProvider<_HomeLedgerBalanceView>((ref) {
  return _HomeLedgerBalanceView.total;
});

final _homeActivityFilterProvider = StateProvider<_HomeActivityFilter>((ref) {
  return _HomeActivityFilter.onChain;
});

// ─── Riverpod Provider para o Popup ──────────────────────────────────────────
final txPopupProvider = ChangeNotifierProvider<TxPopupNotifier>((ref) {
  return TxPopupNotifier();
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

enum TxPopupStatus { idle, loading, success }

class TxPopupNotifier extends ChangeNotifier {
  bool _active = false;
  TxPopupStatus _status = TxPopupStatus.idle;
  bool _isSent = false;
  String _label = '';
  String _address = '';
  String _amount = '';
  String _time = '';
  Timer? _dismissTimer;

  bool get active => _active;
  TxPopupStatus get status => _status;
  bool get isSent => _isSent;
  String get label => _label;
  String get address => _address;
  String get amount => _amount;
  String get time => _time;

  void _scheduleHide(Duration duration) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, hide);
  }

  void show({
    required bool isSent,
    required String label,
    required String address,
    required String amount,
    required String time,
  }) {
    _dismissTimer?.cancel();
    _active = true;
    _status = TxPopupStatus.idle;
    _isSent = isSent;
    _label = label;
    _address = address;
    _amount = amount;
    _time = time;
    notifyListeners();
    _scheduleHide(const Duration(seconds: 4));
  }

  void showLoading({
    required String label,
    required String address,
    required String amount,
    required String time,
  }) {
    _dismissTimer?.cancel();
    _active = true;
    _status = TxPopupStatus.loading;
    _label = label;
    _address = address;
    _amount = amount;
    _time = time;
    notifyListeners();
  }

  void showSuccess({
    required String label,
    required String address,
  }) {
    _dismissTimer?.cancel();
    _status = TxPopupStatus.success;
    _label = label;
    _address = address;
    notifyListeners();
    _scheduleHide(const Duration(milliseconds: 1600));
  }

  void hide() {
    _dismissTimer?.cancel();
    _active = false;
    _status = TxPopupStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isNfcAvailable = false;
  Future<void>? _refreshHomeFuture;
  String? _firstUseActionPanelUserId;
  late final ProviderSubscription<ReceivedTxEvent?> _receivedTxSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_checkNfcAvailability());
    _receivedTxSubscription = ref.listenManual<ReceivedTxEvent?>(
      receivedTxEventProvider,
      (previous, next) {
        if (next == null || !mounted) {
          return;
        }

        ref.read(receivedTxEventProvider.notifier).consumeEvent(next.id);

        final selectedCurrency = ref.read(currencyProvider);
        final btcUsd = ref.read(latestBtcPriceProvider);
        final btcEur = ref.read(btcEurPriceProvider);
        final btcBrl = ref.read(btcBrlPriceProvider);

        // Central notification removed per user request

        final sender = next.sender ?? '';
        final shortAddress = sender.length > 12
            ? '${sender.substring(0, 6)}...${sender.substring(sender.length - 4)}'
            : sender;

        ref.read(txPopupProvider).show(
              isSent: false,
              label: context.l10n.homeTxReceived,
              address: shortAddress,
              amount: MoneyDisplay.formatAmountFromBtc(
                btcAmount: next.amount,
                currency: selectedCurrency,
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
                signed: true,
              ),
              time: context.l10n.homeNow,
            );
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
      title: context.l10n.homeWalletRequiredTitle,
      message: context.l10n.homeWalletRequiredMessage,
    );
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      if (!mounted) {
        return;
      }
      setState(() {
        _isNfcAvailable = availability == NfcAvailability.enabled;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNfcAvailable = false;
      });
    }
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

      await Future.wait<dynamic>(
        [walletRefresh, historyRefresh],
        eagerError: false,
      );
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

  String _compactCounterparty(String value) {
    final normalized = value.trim();
    if (normalized.length <= 18) {
      return normalized;
    }
    return '${normalized.substring(0, 8)}...${normalized.substring(normalized.length - 6)}';
  }

  Future<void> _presentFinancialActionResult(dynamic result) async {
    if (result == null) {
      return;
    }

    await _syncAfterFinancialAction();

    if (!mounted) {
      return;
    }

    final selectedCurrency = ref.read(currencyProvider);
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);

    if (result is TxStatus) {
      final amountBtc = result.amountReceived > 0 ? result.amountReceived : 0.0;
      final counterparty = result.receiver.isNotEmpty
          ? result.receiver
          : result.sender.isNotEmpty
              ? result.sender
              : context.l10n.apiDisplayCompleted;

      // Central notification removed per user request

      ref.read(txPopupProvider).show(
            isSent: true,
            label: context.l10n.homeTxSent,
            address: _compactCounterparty(counterparty),
            amount: amountBtc > 0
                ? MoneyDisplay.formatAmountFromBtc(
                    btcAmount: amountBtc,
                    currency: selectedCurrency,
                    btcUsd: btcUsd,
                    btcEur: btcEur,
                    btcBrl: btcBrl,
                    signed: true,
                  )
                : '--',
            time: context.l10n.homeNow,
          );
      return;
    }

    if (result is PaymentLink) {
      final counterparty = result.description.isNotEmpty
          ? result.description
          : result.depositAddress;

      // Central notification removed per user request

      ref.read(txPopupProvider).show(
            isSent: true,
            label: context.l10n.homeTxPaid,
            address: _compactCounterparty(counterparty),
            amount: result.amountBtc > 0
                ? MoneyDisplay.formatAmountFromBtc(
                    btcAmount: result.amountBtc,
                    currency: selectedCurrency,
                    btcUsd: btcUsd,
                    btcEur: btcEur,
                    btcBrl: btcBrl,
                    signed: true,
                  )
                : '--',
            time: context.l10n.homeNow,
          );
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

  Future<void> _openWithdrawFlow({
    required Wallet wallet,
    required WithdrawEntryMode entryMode,
    String? initialDestination,
    double? initialAmountBtc,
    String? initialDescription,
  }) async {
    final result = await _pushFromBottom<TxStatus>(
      (_) => WithdrawScreen(
        wallet: wallet,
        entryMode: entryMode,
        initialDestination: initialDestination,
        initialAmountBtc: initialAmountBtc,
        initialDescription: initialDescription,
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

    unawaited(
      _openWithdrawFlow(wallet: wallet, entryMode: WithdrawEntryMode.onChain),
    );
  }

  void _openSendLightning(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(
      _openWithdrawFlow(wallet: wallet, entryMode: WithdrawEntryMode.lightning),
    );
  }

  void _openReceiveHub(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(
      _pushFromBottom<void>((_) => ReceiveHubScreen(initialWallet: wallet)),
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

  Future<void> _openSendNfc(WalletState walletState) async {
    if (!_isNfcAvailable) {
      AppNotice.showInfo(
        context,
        title: context.l10n.nfc,
        message: context.l10n.homeNfcUnavailable,
      );
      return;
    }

    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final payload = await _pushFromBottom<dynamic>(
      (_) => const NfcInteractionScreen(amountDisplay: '0'),
    );

    if (!mounted || payload is! String || payload.trim().isEmpty) {
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
        _openWithdrawFlow(
          wallet: wallet,
          entryMode: WithdrawEntryMode.lightning,
          initialDestination: candidate,
          initialAmountBtc:
              parsed?.amountBtc ?? _extractLightningAmountBtc(candidate),
          initialDescription: parsed?.message ?? parsed?.label,
        ),
      );
      return;
    }

    if (_looksLikeOnChainRequest(trimmed, candidate)) {
      unawaited(
        _openWithdrawFlow(
          wallet: wallet,
          entryMode: WithdrawEntryMode.onChain,
          initialDestination: candidate,
          initialAmountBtc: parsed?.amountBtc,
          initialDescription: parsed?.message,
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
    final created = await _pushFromBottom<bool>(
      (_) => const CreateWalletScreen(),
    );
    if (created != true || !mounted) {
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

  List<_QuickActionData> _buildSendActions(WalletState walletState) {
    final actions = <_QuickActionData>[
      _QuickActionData(
        kind: _HomeActionIconKind.sendOnChain,
        label: context.l10n.homeSendMethodOnchainLabel,
        subtitle: context.l10n.homeSendMethodOnchainSubtitle,
        onTap: () => _openSendOnChain(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.payLightning,
        label: context.l10n.homeSendMethodLightningLabel,
        subtitle: context.l10n.homeSendMethodLightningSubtitle,
        onTap: () => _openSendLightning(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.internalTransfer,
        label: context.l10n.homeSendMethodInternalLabel,
        subtitle: context.l10n.homeSendMethodInternalSubtitle,
        onTap: () => _openSend(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.scanQr,
        label: context.l10n.homeScanQrLabel,
        subtitle: context.l10n.homeScanQrSubtitle,
        onTap: () {
          unawaited(_openSendQr(walletState));
        },
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.payLink,
        label: context.l10n.homePaymentLinkLabel,
        subtitle: context.l10n.homePaymentLinkSubtitle,
        onTap: () {
          unawaited(_openSendPaymentLink(walletState));
        },
      ),
    ];

    if (_isNfcAvailable) {
      actions.add(
        _QuickActionData(
          kind: _HomeActionIconKind.sendNfc,
          label: context.l10n.homeNfcPayLabel,
          subtitle: context.l10n.homeNfcPaySubtitle,
          onTap: () {
            unawaited(_openSendNfc(walletState));
          },
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final sidebarOpen = ref.watch(notificationSidebarProvider);
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
        _pushFromBottom<void>(
          (_) => const DepositsScreen(showPrimaryNavigation: true),
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
      userName = context.l10n.profileFallbackUser;
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
                                const _HomeLoadingContent()
                                    .animate()
                                    .fade(duration: 220.ms)
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
                                            _openReceiveHub(walletState),
                                        onSend: () =>
                                            _openSendActionsSheet(walletState),
                                        onViewStatement: openStatement,
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
                                                  ? context.l10n
                                                      .homePrimaryReadyNoBalanceTitle
                                                  : context.l10n
                                                      .homePrimaryReadyTitle,
                                          subtitle: !hasWallet
                                              ? context.l10n
                                                  .homePrimaryNoWalletSubtitle
                                              : !hasBalance
                                                  ? context.l10n
                                                      .homePrimaryReadyNoBalanceSubtitle
                                                  : context.l10n
                                                      .homePrimaryReadySubtitle,
                                          actionLabel: !hasWallet
                                              ? context
                                                  .l10n.homeCreateWalletAction
                                              : !hasBalance
                                                  ? context.l10n
                                                      .homeDepositFundsAction
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
                                        title:
                                            _homeRecentActivitiesTitle(context),
                                        actionLabel: _homeViewAllLabel(context),
                                        onAction: openStatement,
                                      ),
                                      SizedBox(height: _homeSize(12)),
                                      const _HomeActivityFilterChips(),
                                      SizedBox(height: _homeSize(14)),
                                      const _TransactionsList(),
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: LatestTxPopup(
                  suppressed: ref.watch(txPopupProvider).active,
                ),
              ),
            ),
            const _TxPopupWidget(restingTop: -92.0, activeTop: 12.0),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !sidebarOpen,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(notificationSidebarProvider.notifier).close(),
                  child: AnimatedOpacity(
                    opacity: sidebarOpen ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutExpo,
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.42)),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutExpo,
              top: 0,
              bottom: 0,
              right: sidebarOpen ? 0 : -360,
              child: SessionNotificationSidebar(
                showCloseButton: true,
                onClose: () =>
                    ref.read(notificationSidebarProvider.notifier).close(),
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

class _HomePageBackground extends StatelessWidget {
  const _HomePageBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _homeBackgroundColor);
  }
}

class _HomeEntryTransition extends StatefulWidget {
  final Widget child;

  const _HomeEntryTransition({required this.child});

  @override
  State<_HomeEntryTransition> createState() => _HomeEntryTransitionState();
}

class _HomeEntryTransitionState extends State<_HomeEntryTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curve;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          transformHitTests: false,
          child: widget.child,
        ),
      ),
    );
  }
}

class _HomeGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const _HomeGlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_homePanelTopColor, _homePanelBottomColor],
        ),
        border: Border.all(color: _homePanelBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: content,
    );

    return RepaintBoundary(child: clipped);
  }
}

class _HomeLoadingContent extends StatelessWidget {
  const _HomeLoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _HomeSkeletonBox(
              width: _homeSize(40),
              height: _homeSize(40),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(22),
                borderRadius: BorderRadius.circular(_homeSize(7)),
              ),
            ),
            SizedBox(width: _homeSize(44)),
            _HomeSkeletonBox(
              width: _homeSize(24),
              height: _homeSize(24),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(16)),
            _HomeSkeletonBox(
              width: _homeSize(24),
              height: _homeSize(24),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: _homeSize(18)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(18)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(132),
                height: _homeSize(14),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(18)),
              _HomeSkeletonBox(
                width: _homeSize(160),
                height: _homeSize(16),
                borderRadius: BorderRadius.circular(_homeSize(6)),
              ),
              SizedBox(height: _homeSize(8)),
              _HomeSkeletonBox(
                width: _homeSize(220),
                height: _homeSize(12),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(22)),
              _HomeSkeletonBox(
                width: _homeSize(238),
                height: _homeSize(44),
                borderRadius: BorderRadius.circular(_homeSize(10)),
              ),
              SizedBox(height: _homeSize(10)),
              _HomeSkeletonBox(
                width: _homeSize(118),
                height: _homeSize(14),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(8)),
              _HomeSkeletonBox(
                width: _homeSize(92),
                height: _homeSize(13),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(24)),
              _HomeSkeletonBox(
                width: _homeSize(104),
                height: _homeSize(34),
                borderRadius: BorderRadius.circular(_homeSize(8)),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(50),
                borderRadius: BorderRadius.circular(_homeSize(12)),
              ),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeSkeletonBox(
                height: _homeSize(50),
                borderRadius: BorderRadius.circular(_homeSize(12)),
              ),
            ),
          ],
        ),
        SizedBox(height: _homeSize(14)),
        const _HomePaginationDots(count: 3, activeIndex: 0),
        SizedBox(height: _homeSize(24)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(16)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeSkeletonBox(
                      width: _homeSize(152),
                      height: _homeSize(18),
                      borderRadius: BorderRadius.circular(_homeSize(6)),
                    ),
                    SizedBox(height: _homeSize(10)),
                    _HomeSkeletonBox(
                      width: _homeSize(178),
                      height: _homeSize(38),
                      borderRadius: BorderRadius.circular(_homeSize(6)),
                    ),
                    SizedBox(height: _homeSize(16)),
                    _HomeSkeletonBox(
                      width: _homeSize(86),
                      height: _homeSize(34),
                      borderRadius: BorderRadius.circular(_homeSize(8)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _homeSize(18)),
              _HomeSkeletonBox(
                width: _homeSize(92),
                height: _homeSize(92),
                borderRadius: BorderRadius.circular(_homeSize(18)),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(28)),
        _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(16)),
          padding: EdgeInsets.all(_homeSize(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(154),
                height: _homeSize(16),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(20)),
              Row(
                children: [
                  _HomeSkeletonBox(
                    width: _homeSize(96),
                    height: _homeSize(96),
                    borderRadius: BorderRadius.circular(_homeSize(999)),
                  ),
                  SizedBox(width: _homeSize(24)),
                  Expanded(
                    child: Column(
                      children: [
                        _HomeSkeletonBox(
                          height: _homeSize(16),
                          borderRadius: BorderRadius.circular(_homeSize(5)),
                        ),
                        SizedBox(height: _homeSize(14)),
                        _HomeSkeletonBox(
                          height: _homeSize(16),
                          borderRadius: BorderRadius.circular(_homeSize(5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(28)),
        _HomeSkeletonBox(
          width: _homeSize(112),
          height: _homeSize(22),
          borderRadius: BorderRadius.circular(_homeSize(7)),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            _HomeSkeletonBox(
              width: _homeSize(96),
              height: _homeSize(30),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
            SizedBox(width: _homeSize(8)),
            _HomeSkeletonBox(
              width: _homeSize(112),
              height: _homeSize(30),
              borderRadius: BorderRadius.circular(_homeSize(999)),
            ),
          ],
        ),
        SizedBox(height: _homeSize(10)),
        const _HomeLoadingTransactionRow(),
        const _HomeLoadingTransactionRow(),
        const _HomeLoadingTransactionRow(),
      ],
    );
  }
}

class _HomeLoadingTransactionRow extends StatelessWidget {
  const _HomeLoadingTransactionRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _homeSize(14)),
      child: Row(
        children: [
          _HomeSkeletonBox(
            width: _homeSize(40),
            height: _homeSize(40),
            borderRadius: BorderRadius.circular(_homeSize(999)),
          ),
          SizedBox(width: _homeSize(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeSkeletonBox(
                  width: _homeSize(136),
                  height: _homeSize(14),
                  borderRadius: BorderRadius.circular(_homeSize(5)),
                ),
                SizedBox(height: _homeSize(7)),
                _HomeSkeletonBox(
                  width: _homeSize(104),
                  height: _homeSize(11),
                  borderRadius: BorderRadius.circular(_homeSize(5)),
                ),
              ],
            ),
          ),
          SizedBox(width: _homeSize(14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _HomeSkeletonBox(
                width: _homeSize(90),
                height: _homeSize(13),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
              SizedBox(height: _homeSize(7)),
              _HomeSkeletonBox(
                width: _homeSize(70),
                height: _homeSize(11),
                borderRadius: BorderRadius.circular(_homeSize(5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _HomeSkeletonBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.035)),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1300.ms,
          color: Colors.white.withValues(alpha: 0.08),
        );
  }
}

class _HomeHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;

  const _HomeHeaderIconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkResponse(
            onTap: onTap,
            radius: _homeSize(24),
            child: SizedBox(
              width: _homeSize(42),
              height: _homeSize(42),
              child: Center(
                child: Icon(
                  icon,
                  size: _homeSize(24),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: _homeSize(5),
            top: _homeSize(5),
            child: Container(
              width: _homeSize(9),
              height: _homeSize(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _homeAmberColor,
                border: Border.all(color: const Color(0xFF06090B), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeBalanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _HomeBalanceActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BouncingButtonWrapper(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: _homeSize(48)),
        padding: EdgeInsets.symmetric(horizontal: _homeSize(14)),
        decoration: BoxDecoration(
          color: primary ? Colors.white : _homeCardColor,
          borderRadius: BorderRadius.circular(_homeSize(12)),
          border: Border.all(
            color: primary ? Colors.white : _homePanelBorderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: _homeSize(18),
              color: primary ? Colors.black : Colors.white,
            ),
            SizedBox(width: _homeSize(8)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary ? Colors.black : Colors.white,
                  fontSize: _homeFontSize(14),
                  fontWeight: FontWeight.w300,
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

class _HomePaginationDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _HomePaginationDots({
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) SizedBox(width: _homeSize(6)),
          Container(
            width: _homeSize(6),
            height: _homeSize(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == activeIndex
                  ? Colors.white
                  : _homeMutedTextColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeSetupNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _HomeSetupNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(18)),
      padding: EdgeInsets.all(_homeSize(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _homeSize(42),
            height: _homeSize(42),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_homeSize(12)),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              icon,
              size: _homeSize(24),
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(width: _homeSize(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: _homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: _homeSize(5)),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: _homeFontSize(12),
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: _homeSize(12)),
                TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(LucideIcons.arrowRight, size: _homeSize(15)),
                  label: Text(actionLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: _homeAmberColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, _homeSize(34)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: _homeFontSize(14),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0,
                    ),
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

class _HomeEducationCarousel extends ConsumerStatefulWidget {
  const _HomeEducationCarousel();

  @override
  ConsumerState<_HomeEducationCarousel> createState() =>
      _HomeEducationCarouselState();
}

class _HomeEducationCarouselState
    extends ConsumerState<_HomeEducationCarousel> {
  final PageController _pageController = PageController();
  int _activeIndex = 0;
  _HomeLedgerBalanceView? _lastView;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = ref.watch(_homeLedgerBalanceViewProvider);
    final cards = _homeEducationCards(view);

    if (_lastView != view) {
      _lastView = view;
      _activeIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }

    return Column(
      children: [
        SizedBox(
          height: _homeSize(154),
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _activeIndex = index);
            },
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : _homeSize(4),
                  right: index == cards.length - 1 ? 0 : _homeSize(4),
                ),
                child: _HomeGlassPanel(
                  borderRadius: BorderRadius.circular(_homeSize(16)),
                  padding: EdgeInsets.all(_homeSize(18)),
                  child: Row(
                    children: [
                      Container(
                        width: _homeSize(46),
                        height: _homeSize(46),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          card.icon,
                          color: Colors.white,
                          size: _homeSize(21),
                        ),
                      ),
                      SizedBox(width: _homeSize(16)),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.ebGaramond(
                                textStyle: theme.textTheme.titleMedium,
                                color: Colors.white,
                                fontSize: _homeFontSize(20),
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: _homeSize(8)),
                            Text(
                              card.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _homeMutedTextColor,
                                fontSize: _homeFontSize(12),
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: _homeSize(12)),
                            Text(
                              card.tag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: _homeFontSize(10),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: _homeSize(12)),
        _HomePaginationDots(
          count: cards.length,
          activeIndex: _activeIndex.clamp(0, cards.length - 1),
        ),
      ],
    );
  }
}

class _HomeEducationCardData {
  final IconData icon;
  final String title;
  final String body;
  final String tag;

  const _HomeEducationCardData({
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
  });
}

List<_HomeEducationCardData> _homeEducationCards(_HomeLedgerBalanceView view) {
  return switch (view) {
    _HomeLedgerBalanceView.platform => const [
        _HomeEducationCardData(
          icon: LucideIcons.repeat2,
          title: 'Kerosene',
          body:
              'Use transferências internas quando o destino também usa Kerosene. O envio é rápido e sem taxa de rede.',
          tag: 'uso interno',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.fingerprint,
          title: 'Hash da carteira',
          body:
              'Para receber internamente, compartilhe somente o hash que a sua própria carteira disponibiliza.',
          tag: 'identidade da carteira',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.zap,
          title: 'Lightning',
          body:
              'Use Lightning para pagar faturas ou endereços relâmpago com confirmação quase imediata.',
          tag: 'pagamentos rápidos',
        ),
      ],
    _HomeLedgerBalanceView.onChain => const [
        _HomeEducationCardData(
          icon: LucideIcons.bitcoin,
          title: 'Bitcoin on-chain',
          body:
              'Use on-chain para guardar valor, mover para autocustódia ou enviar para uma carteira Bitcoin externa.',
          tag: 'rede principal',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.activity,
          title: 'Confirmações',
          body:
              'Transações on-chain entram em blocos. Valores maiores costumam exigir mais confirmações.',
          tag: 'tempo de rede',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.gauge,
          title: 'Taxas',
          body:
              'A taxa varia conforme a rede. Antes de confirmar, revise o total debitado e o valor que chega.',
          tag: 'custo da rede',
        ),
      ],
    _ => const [
        _HomeEducationCardData(
          icon: LucideIcons.bitcoin,
          title: 'Bitcoin',
          body:
              'Bitcoin é dinheiro digital escasso. Você pode usar caminhos diferentes conforme urgência e destino.',
          tag: 'fundamento',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.zap,
          title: 'Lightning',
          body:
              'Lightning é indicado para pagamentos menores e rápidos, usando invoice, LNURL ou endereço relâmpago.',
          tag: 'pagamento instantâneo',
        ),
        _HomeEducationCardData(
          icon: LucideIcons.wallet,
          title: 'Kerosene',
          body:
              'A Kerosene organiza envio interno, Lightning e on-chain em fluxos separados para reduzir erro.',
          tag: 'como escolher',
        ),
      ],
  };
}

class _HomeFundsDistributionSection extends StatelessWidget {
  final WalletState walletState;
  final VoidCallback onViewStatement;

  const _HomeFundsDistributionSection({
    required this.walletState,
    required this.onViewStatement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallets = walletState is WalletLoaded
        ? (walletState as WalletLoaded).wallets
        : const <Wallet>[];
    final onchainBalance = _sumWallets(
      wallets.where((wallet) => wallet.isSelfCustody),
    );
    final keroseneBalance = _sumWallets(
      wallets.where((wallet) => wallet.isKeroseneCustody),
    );
    final totalBalance = onchainBalance + keroseneBalance;
    final onchainShare = totalBalance > 0 ? onchainBalance / totalBalance : 0.0;
    final keroseneShare =
        totalBalance > 0 ? keroseneBalance / totalBalance : 0.0;
    final totalLabel = totalBalance > 0 ? '100%' : '0%';

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(16)),
      padding: EdgeInsets.all(_homeSize(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _homeFundsDistributionTitle(context),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: _homeFontSize(14),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewStatement,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.72),
                  padding: EdgeInsets.symmetric(horizontal: _homeSize(8)),
                  minimumSize: Size(0, _homeSize(32)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelSmall?.copyWith(
                    fontSize: _homeFontSize(12),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
                child: Text(_homeViewStatementShortLabel(context)),
              ),
            ],
          ),
          SizedBox(height: _homeSize(14)),
          Row(
            children: [
              SizedBox(
                width: _homeSize(96),
                height: _homeSize(96),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(_homeSize(96)),
                      painter: _HomeDistributionChartPainter(
                        onchainShare: onchainShare,
                        keroseneShare: keroseneShare,
                      ),
                    ),
                    Text(
                      totalLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: _homeFontSize(12),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _homeSize(24)),
              Expanded(
                child: Column(
                  children: [
                    _HomeDistributionLegendRow(
                      color: _homeAmberColor,
                      label: context.l10n.homeOnchainWalletLabel,
                      percent: onchainShare,
                    ),
                    SizedBox(height: _homeSize(14)),
                    _HomeDistributionLegendRow(
                      color: _homePositiveColor,
                      label: context.l10n.homeKeroseneWalletLabel,
                      percent: keroseneShare,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _sumWallets(Iterable<Wallet> wallets) {
    return wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
  }
}

class _HomeDistributionLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;

  const _HomeDistributionLegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentLabel = '${(percent * 100).toStringAsFixed(1)}%';

    return Row(
      children: [
        Container(
          width: _homeSize(10),
          height: _homeSize(10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: _homeSize(8)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _homeMutedTextColor,
              fontSize: _homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(width: _homeSize(8)),
        Text(
          percentLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: _homeFontSize(12),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _HomeDistributionChartPainter extends CustomPainter {
  final double onchainShare;
  final double keroseneShare;

  const _HomeDistributionChartPainter({
    required this.onchainShare,
    required this.keroseneShare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _homeSize(5);
    final strokeWidth = _homeSize(4);
    final basePaint = Paint()
      ..color = _homePanelBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _homeSize(3);
    canvas.drawCircle(center, radius, basePaint);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final onchainSweep = (math.pi * 2) * onchainShare.clamp(0.0, 1.0);
    final keroseneSweep = (math.pi * 2) * keroseneShare.clamp(0.0, 1.0);

    if (onchainSweep > 0) {
      segmentPaint.color = _homeAmberColor;
      canvas.drawArc(rect, start, onchainSweep, false, segmentPaint);
    }
    if (keroseneSweep > 0) {
      segmentPaint.color = _homePositiveColor;
      canvas.drawArc(
        rect,
        start + onchainSweep,
        keroseneSweep,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeDistributionChartPainter oldDelegate) {
    return oldDelegate.onchainShare != onchainShare ||
        oldDelegate.keroseneShare != keroseneShare;
  }
}

class _HomeActivityFilterChips extends ConsumerWidget {
  const _HomeActivityFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(_homeActivityFilterProvider);
    final filters = selectedFilter == _HomeActivityFilter.platform
        ? const [
            _HomeActivityFilter.platform,
            _HomeActivityFilter.onChain,
            _HomeActivityFilter.notices,
          ]
        : const [
            _HomeActivityFilter.onChain,
            _HomeActivityFilter.platform,
            _HomeActivityFilter.notices,
          ];

    void selectFilter(_HomeActivityFilter filter) {
      HapticFeedback.selectionClick();
      ref.read(_homeActivityFilterProvider.notifier).state = filter;
      if (filter == _HomeActivityFilter.platform) {
        ref.read(_homeLedgerBalanceViewProvider.notifier).state =
            _HomeLedgerBalanceView.platform;
      } else if (filter == _HomeActivityFilter.onChain) {
        ref.read(_homeLedgerBalanceViewProvider.notifier).state =
            _HomeLedgerBalanceView.onChain;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) SizedBox(width: _homeSize(8)),
            _HomeActivityFilterChip(
              label: _homeFilterLabel(context, filters[index]),
              selected: selectedFilter == filters[index],
              onTap: () => selectFilter(filters[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeActivityFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HomeActivityFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_homeSize(999)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: _homeSize(16),
            vertical: _homeSize(7),
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : _homeCardColor,
            borderRadius: BorderRadius.circular(_homeSize(999)),
            border: Border.all(
              color: selected ? Colors.white : _homePanelBorderColor,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? Colors.black : _homeMutedTextColor,
              fontSize: _homeFontSize(12),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

String _homeFundsDistributionTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Fund Distribution',
    'es' => 'Distribución de fondos',
    _ => 'Distribuição de Fundos',
  };
}

String _homeRecentActivitiesTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Activities',
    'es' => 'Actividades',
    _ => 'Atividades',
  };
}

String _homeViewAllLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'View all',
    'es' => 'Ver todas',
    _ => 'Ver todas',
  };
}

String _homeViewStatementShortLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Statement',
    'es' => 'Extracto',
    _ => 'Extrato',
  };
}

String _homeOnchainFilterLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain',
    'es' => 'On-chain',
    _ => 'On-chain',
  };
}

String _homePlatformFilterLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Platform',
    'es' => 'Plataforma',
    _ => 'Plataforma',
  };
}

String _homeNoticesFilterLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Notices',
    'es' => 'Avisos',
    _ => 'Avisos',
  };
}

String _homeFilterLabel(BuildContext context, _HomeActivityFilter filter) {
  return switch (filter) {
    _HomeActivityFilter.platform => _homePlatformFilterLabel(context),
    _HomeActivityFilter.onChain => _homeOnchainFilterLabel(context),
    _HomeActivityFilter.notices => _homeNoticesFilterLabel(context),
  };
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _HomeSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: _homeAmberColor,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _SendMethodScreen extends StatefulWidget {
  final List<_QuickActionData> actions;

  const _SendMethodScreen({required this.actions});

  @override
  State<_SendMethodScreen> createState() => _SendMethodScreenState();
}

class _SendMethodScreenState extends State<_SendMethodScreen> {
  static const Color _screenBackground = Color(0xFF000000);
  static const Color _mutedTextColor = Color(0xFFA0A0A0);

  _HomeActionIconKind? _selectedKind;

  List<_QuickActionData> get _transferActions {
    final actionsByKind = {
      for (final action in widget.actions) action.kind: action,
    };
    const orderedKinds = [
      _HomeActionIconKind.internalTransfer,
      _HomeActionIconKind.payLightning,
      _HomeActionIconKind.sendOnChain,
    ];

    return [
      for (final kind in orderedKinds)
        if (actionsByKind[kind] != null) actionsByKind[kind]!,
    ];
  }

  void _selectAction(_QuickActionData action) {
    HapticFeedback.selectionClick();
    setState(() => _selectedKind = action.kind);

    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      action.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isNarrow = mediaQuery.size.width < 360;
    final horizontalPadding = isNarrow ? 20.0 : 24.0;
    final transferActions = _transferActions;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.authBackAction,
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.72),
                      minimumSize: const Size.square(44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.arrowLeft, size: 24),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44, height: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _localizedTransferTitle(context),
                          style: GoogleFonts.ebGaramond(
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            color: Colors.white,
                            fontSize: isNarrow ? 38 : 42,
                            fontWeight: FontWeight.w300,
                            height: 1.02,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedTransferSubtitle(context),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _mutedTextColor,
                                    fontSize: 14,
                                    height: 1.35,
                                    letterSpacing: 0,
                                  ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < transferActions.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _SendMethodOptionButton(
                                  action: transferActions[index],
                                  label: _localizedTransferOptionLabel(
                                    context,
                                    transferActions[index].kind,
                                  ),
                                  selected: _selectedKind ==
                                      transferActions[index].kind,
                                  showFeeBadge: transferActions[index].kind ==
                                      _HomeActionIconKind.internalTransfer,
                                  feeLabel: _localizedTransferFeeLabel(context),
                                  onTap: () =>
                                      _selectAction(transferActions[index]),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _localizedLearnMoreTitle(context),
                          style: GoogleFonts.ebGaramond(
                            textStyle: Theme.of(context).textTheme.titleLarge,
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SendEducationCard(
                          title: _localizedEducationTitle(context),
                          body: _localizedEducationBody(context),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            AppNotice.showInfo(
                              context,
                              title: _localizedEducationTitle(context),
                              message: _localizedEducationBody(context),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 120,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedTransferTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Transfer',
      'es' => 'Transferir',
      _ => 'Transferir',
    };
  }

  String _localizedTransferSubtitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Choose how you want to send your funds.',
      'es' => 'Elige cómo quieres enviar tus fondos.',
      _ => 'Escolha como deseja enviar seus fundos.',
    };
  }

  String _localizedTransferOptionLabel(
    BuildContext context,
    _HomeActionIconKind kind,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return switch (kind) {
      _HomeActionIconKind.internalTransfer => switch (languageCode) {
          'en' => 'Internal\nTransfer',
          'es' => 'Transferencia\nInterna',
          _ => 'Transferência\nInterna',
        },
      _HomeActionIconKind.payLightning => switch (languageCode) {
          'en' => 'Lightning\nTransfer',
          'es' => 'Transferencia\nLightning',
          _ => 'Transferência\nLightning',
        },
      _HomeActionIconKind.sendOnChain => switch (languageCode) {
          'en' => 'On-chain\nTransfer',
          'es' => 'Transferencia\nOn-chain',
          _ => 'Transferência\nOn-chain',
        },
      _ => '',
    };
  }

  String _localizedTransferFeeLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => '0 fees',
      'es' => '0 comisiones',
      _ => '0 taxas',
    };
  }

  String _localizedLearnMoreTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'Learn more',
      'es' => 'Saber más',
      _ => 'Saiba mais',
    };
  }

  String _localizedEducationTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => 'How do transactions work?',
      'es' => '¿Cómo funcionan las transacciones?',
      _ => 'Como funcionam as transações?',
    };
  }

  String _localizedEducationBody(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' =>
        'Understand the differences between networks and choose the best option to protect your wealth.',
      'es' =>
        'Entiende las diferencias entre las redes y elige la mejor opción para proteger tu patrimonio.',
      _ =>
        'Entenda as diferenças entre as redes e escolha a melhor opção para proteger seu patrimônio.',
    };
  }
}

class _SendMethodOptionButton extends StatelessWidget {
  final _QuickActionData action;
  final String label;
  final bool selected;
  final bool showFeeBadge;
  final String feeLabel;
  final VoidCallback onTap;

  const _SendMethodOptionButton({
    required this.action,
    required this.label,
    required this.selected,
    required this.showFeeBadge,
    required this.feeLabel,
    required this.onTap,
  });

  static const Color _panelColor = Color(0xFF111111);
  static const Color _borderColor = Color(0xFF222222);
  static const Color _feeTextColor = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final labelSize = isNarrow ? 11.0 : 12.0;

    return Semantics(
      button: true,
      selected: selected,
      label: label.replaceAll('\n', ' '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: 124,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.10)
                          : _panelColor,
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.54)
                            : _borderColor,
                      ),
                    ),
                    child: Center(
                      child: _HomeActionIcon(
                        kind: action.kind,
                        iconColor: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w300,
                          height: 1.12,
                          letterSpacing: 0,
                        ),
                  ),
                  if (showFeeBadge) ...[
                    const SizedBox(height: 7),
                    Text(
                      feeLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _feeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            height: 1,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendEducationCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;

  const _SendEducationCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  static const Color _panelColor = Color(0xFF111111);
  static const Color _borderColor = Color(0xFF222222);
  static const Color _mutedTextColor = Color(0xFFA0A0A0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.black,
                    child: Image.asset(
                      'assets/logo/kerosene-logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          LucideIcons.bitcoin,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _mutedTextColor,
                              fontSize: 12,
                              height: 1.35,
                              letterSpacing: 0,
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

class _HomeRealtimeBootstrap extends ConsumerWidget {
  const _HomeRealtimeBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(balanceWebSocketServiceProvider);
    return const SizedBox.shrink();
  }
}

enum _PaymentPayloadKind {
  empty,
  paymentLink,
  onChain,
  lightning,
  internal,
  invalid,
}

class _PaymentPayloadDraft {
  final _PaymentPayloadKind kind;
  final String normalizedPayload;
  final String title;
  final String destinationLabel;
  final String? supportingLabel;
  final String actionLabel;
  final double? amountBtc;
  final IconData icon;

  const _PaymentPayloadDraft({
    required this.kind,
    required this.normalizedPayload,
    required this.title,
    required this.destinationLabel,
    required this.actionLabel,
    required this.icon,
    this.supportingLabel,
    this.amountBtc,
  });

  bool get canContinue =>
      kind != _PaymentPayloadKind.empty && kind != _PaymentPayloadKind.invalid;

  bool get isPaymentLink => kind == _PaymentPayloadKind.paymentLink;

  String? get paymentLinkId => isPaymentLink
      ? QrPaymentParser.extractPaymentLinkId(normalizedPayload)
      : null;

  static _PaymentPayloadDraft analyze(BuildContext context, String raw) {
    final l10n = context.l10n;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.empty,
        normalizedPayload: '',
        title: l10n.homePendingLinkTitle,
        destinationLabel: l10n.homePendingLinkMessage,
        actionLabel: l10n.homePayloadActionContinue,
        icon: LucideIcons.link2,
      );
    }

    final explicitLinkId = QrPaymentParser.extractPaymentLinkId(trimmed);
    if (explicitLinkId != null) {
      return _paymentLink(context, explicitLinkId, normalizedPayload: trimmed);
    }

    final parsed = QrPaymentParser.decode(trimmed);
    final candidate = parsed?.address ?? trimmed;
    if (_isLightningPaymentPayload(candidate)) {
      final normalized = candidate.toLowerCase().startsWith('lightning:')
          ? candidate.substring(10).trim()
          : candidate;
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.lightning,
        normalizedPayload: normalized,
        title: l10n.homeLightningPaymentTitle,
        destinationLabel: _shortPaymentValue(normalized),
        supportingLabel:
            parsed?.message ?? parsed?.label ?? l10n.homeInvoiceOrLnurl,
        actionLabel: l10n.homePayloadActionContinueLightning,
        amountBtc: parsed?.amountBtc ?? _extractLightningAmountBtc(normalized),
        icon: LucideIcons.zap,
      );
    }

    if (_isOnChainPaymentPayload(trimmed, candidate)) {
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.onChain,
        normalizedPayload: trimmed,
        title: l10n.homeOnchainPaymentTitle,
        destinationLabel: _shortPaymentValue(candidate),
        supportingLabel:
            parsed?.message ?? parsed?.label ?? l10n.homeBitcoinAddress,
        actionLabel: l10n.homePayloadActionContinueOnchain,
        amountBtc: parsed?.amountBtc,
        icon: LucideIcons.link,
      );
    }

    if (trimmed.toLowerCase().startsWith('kerosene:pay') &&
        parsed != null &&
        parsed.address.trim().isNotEmpty) {
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.internal,
        normalizedPayload: trimmed,
        title: l10n.homeInternalTransferTitle,
        destinationLabel: parsed.label?.trim().isNotEmpty == true
            ? parsed.label!.trim()
            : parsed.address.trim(),
        supportingLabel: parsed.address.trim(),
        actionLabel: l10n.homePayloadActionContinueInternal,
        amountBtc: parsed.amountBtc,
        icon: LucideIcons.repeat2,
      );
    }

    if (trimmed.startsWith('@') &&
        RegExp(r'^@[a-zA-Z0-9_]{3,30}$').hasMatch(trimmed)) {
      final username = trimmed.substring(1);
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.internal,
        normalizedPayload: username,
        title: l10n.homeInternalTransferTitle,
        destinationLabel: '@$username',
        supportingLabel: l10n.homeKeroseneUser,
        actionLabel: l10n.homePayloadActionContinueInternal,
        icon: LucideIcons.repeat2,
      );
    }

    if (RegExp(r'\s').hasMatch(trimmed)) {
      return _PaymentPayloadDraft(
        kind: _PaymentPayloadKind.invalid,
        normalizedPayload: '',
        title: l10n.homeInvalidLinkTitle,
        destinationLabel: l10n.homeInvalidLinkMessage,
        actionLabel: l10n.homePayloadActionContinue,
        icon: LucideIcons.alertCircle,
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.isNotEmpty && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return _paymentLink(context, last);
      }
    }

    return _paymentLink(context, trimmed);
  }

  static _PaymentPayloadDraft _paymentLink(
    BuildContext context,
    String id, {
    String? normalizedPayload,
  }) {
    final l10n = context.l10n;
    final normalizedId = id.trim();
    return _PaymentPayloadDraft(
      kind: _PaymentPayloadKind.paymentLink,
      normalizedPayload: normalizedPayload ?? 'kerosene:link:$normalizedId',
      title: l10n.homeInternalLinkTitle,
      destinationLabel: _shortPaymentValue(normalizedId),
      supportingLabel: l10n.homePaymentId,
      actionLabel: l10n.homePayloadActionLoadLink,
      icon: LucideIcons.link2,
    );
  }
}

String _shortPaymentValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 34) {
    return trimmed;
  }
  return '${trimmed.substring(0, 18)}...${trimmed.substring(trimmed.length - 10)}';
}

class _PaymentLinkEntryScreen extends ConsumerStatefulWidget {
  const _PaymentLinkEntryScreen();

  @override
  ConsumerState<_PaymentLinkEntryScreen> createState() =>
      _PaymentLinkEntryScreenState();
}

class _PaymentLinkEntryScreenState
    extends ConsumerState<_PaymentLinkEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _PaymentPayloadDraft.analyze(context, _controller.text);
    final linkId = draft.paymentLinkId;
    final linkAsync =
        linkId == null ? null : ref.watch(paymentLinkDetailProvider(linkId));
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    return ReceiveFlowScaffold(
      title: context.l10n.homePaymentLinkTitle,
      subtitle: context.l10n.homePaymentLinkSubtitle,
      bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                  child: ReceiveFlowSectionLabel(
                    context.l10n.homePayloadLabel.toUpperCase(),
                  ),
                ),
                const Divider(height: 1, color: receiveFlowDividerColor),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 7,
                  onChanged: (_) => setState(() {}),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: receiveFlowTextColor,
                        fontFamily: 'JetBrainsMono',
                        height: 1.35,
                      ),
                  decoration: InputDecoration(
                    hintText: context.l10n.homePayloadHint,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowFaintTextColor,
                          height: 1.35,
                        ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowSecondaryButton(
            label: context.l10n.homePasteAction.toUpperCase(),
            icon: LucideIcons.clipboardPaste,
            onTap: _pasteFromClipboard,
          ),
          const SizedBox(height: AppSpacing.xl),
          _PaymentPayloadPreview(
            draft: draft,
            linkAsync: linkAsync,
            selectedCurrency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          ),
          const SizedBox(height: AppSpacing.xl),
          ReceiveFlowPrimaryButton(
            label: draft.actionLabel,
            icon: LucideIcons.arrowRight,
            onTap: draft.canContinue
                ? () => Navigator.of(context).pop(draft.normalizedPayload)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentPayloadPreview extends StatelessWidget {
  final _PaymentPayloadDraft draft;
  final AsyncValue<PaymentLink>? linkAsync;
  final Currency selectedCurrency;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;

  const _PaymentPayloadPreview({
    required this.draft,
    required this.linkAsync,
    required this.selectedCurrency,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
  });

  @override
  Widget build(BuildContext context) {
    final link = linkAsync?.asData?.value;
    final amountBtc = link?.amountBtc ?? draft.amountBtc;
    final amountLabel = amountBtc != null && amountBtc > 0
        ? MoneyDisplay.formatAmountFromBtc(
            btcAmount: amountBtc,
            currency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          )
        : draft.isPaymentLink
            ? context.l10n.homeAmountFromLink
            : context.l10n.homeAmountNotProvided;
    final destination = link?.isInternalPaymentRequest == true
        ? (link!.destinationHash?.trim().isNotEmpty == true
            ? _shortPaymentValue(link.destinationHash!)
            : context.l10n.homeDestinationLocked)
        : draft.destinationLabel;
    final support = linkAsync?.isLoading == true
        ? context.l10n.homeLoadingLinkData
        : linkAsync?.hasError == true
            ? context.l10n.homeLinkValidationLater
            : link?.description.trim().isNotEmpty == true
                ? link!.description.trim()
                : draft.supportingLabel;

    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: receiveFlowPanelRaisedColor,
                  border: Border.all(color: receiveFlowBorderStrongColor),
                ),
                child: Icon(draft.icon, color: receiveFlowTextColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: receiveFlowTextColor,
                            fontWeight: FontWeight.w300,
                            height: 1.1,
                          ),
                    ),
                    if (support != null && support.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        support,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receiveFlowMutedTextColor,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentPreviewRow(
            label: context.l10n.homeNetworkLabel,
            value: _networkLabel(context, draft.kind),
          ),
          const ReceiveFlowDivider(),
          _PaymentPreviewRow(
            label: context.l10n.homeDestinationLabel,
            value: destination,
          ),
          const ReceiveFlowDivider(),
          _PaymentPreviewRow(
            label: context.l10n.homeAmountLabel,
            value: amountLabel,
          ),
        ],
      ),
    );
  }

  String _networkLabel(BuildContext context, _PaymentPayloadKind kind) {
    return switch (kind) {
      _PaymentPayloadKind.paymentLink => context.l10n.homeNetworkInternal,
      _PaymentPayloadKind.onChain => context.l10n.homeNetworkOnchain,
      _PaymentPayloadKind.lightning => context.l10n.homeNetworkLightning,
      _PaymentPayloadKind.internal => context.l10n.homeNetworkInternal,
      _PaymentPayloadKind.invalid => context.l10n.homeNetworkInvalid,
      _PaymentPayloadKind.empty => context.l10n.homeNetworkWaiting,
    };
  }
}

class _PaymentPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentPreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: receiveFlowFaintTextColor,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontFamily: value.length > 18 ? 'JetBrainsMono' : null,
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBalanceSection extends ConsumerStatefulWidget {
  final String userName;
  final WalletState walletState;
  final Wallet? activeWallet;
  final VoidCallback onReceive;
  final VoidCallback onSend;
  final VoidCallback onViewStatement;

  const _HomeBalanceSection({
    required this.userName,
    required this.walletState,
    required this.activeWallet,
    required this.onReceive,
    required this.onSend,
    required this.onViewStatement,
  });

  @override
  ConsumerState<_HomeBalanceSection> createState() =>
      _HomeBalanceSectionState();
}

class _HomeBalanceSectionState extends ConsumerState<_HomeBalanceSection> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _pageIndexFor(ref.read(_homeLedgerBalanceViewProvider)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final selectedCurrency = ref.watch(currencyProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final notificationCount = ref.watch(sessionNotificationUnreadCountProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final btcDailyChangePercent = ref.watch(btcDailyChangePercentProvider);
    final selectedView = ref.watch(_homeLedgerBalanceViewProvider);
    final wallets = widget.walletState is WalletLoaded
        ? (widget.walletState as WalletLoaded).wallets
        : const <Wallet>[];
    final quoteCurrency =
        selectedCurrency == Currency.btc ? Currency.brl : selectedCurrency;
    final hasSelectedQuote = switch (quoteCurrency) {
      Currency.btc => true,
      Currency.usd => btcUsd != null && btcUsd > 0,
      Currency.eur => btcEur != null && btcEur > 0,
      Currency.brl => btcBrl != null && btcBrl > 0,
    };

    ref.listen<_HomeLedgerBalanceView>(
      _homeLedgerBalanceViewProvider,
      (previous, next) {
        final page = _pageIndexFor(next);
        if (!_pageController.hasClients) {
          return;
        }

        final currentPage =
            _pageController.page ?? _pageController.initialPage.toDouble();
        if ((currentPage - page).abs() < 0.05) {
          return;
        }

        unawaited(
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        );
      },
    );

    _HomeBalanceCardData cardDataFor(_HomeLedgerBalanceView view) {
      final scopedWallets = _walletsForView(wallets, view);
      final primaryWallet = _primaryWalletForView(
        activeWallet: widget.activeWallet,
        scopedWallets: scopedWallets,
        view: view,
      );
      final balanceBtc = _sumWallets(scopedWallets);
      final convertedBalanceValue = MoneyDisplay.convertFromBtcAmount(
        btcAmount: balanceBtc,
        currency: quoteCurrency,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      );
      final convertedBalanceLabel = balanceSettings.isHidden
          ? '${MoneyDisplay.tickerSymbolFor(quoteCurrency)} ••••••••'
          : hasSelectedQuote
              ? MoneyDisplay.format(
                  amount: convertedBalanceValue,
                  currency: quoteCurrency,
                )
              : '${quoteCurrency.code} indisponivel';
      final dailyChangeValue = hasSelectedQuote && btcDailyChangePercent != null
          ? convertedBalanceValue * (btcDailyChangePercent / 100)
          : null;
      final isDailyChangePositive = (dailyChangeValue ?? 0) >= 0;
      final dailyChangeColor =
          isDailyChangePositive ? _homePositiveColor : const Color(0xFFFF5A67);
      final dailyChangeSign = isDailyChangePositive ? '+' : '-';
      final percentSeparator =
          MoneyDisplay.localeFor(quoteCurrency).startsWith('en') ? '.' : ',';
      final dailyChangePercentLabel = btcDailyChangePercent
          ?.abs()
          .toStringAsFixed(2)
          .replaceAll('.', percentSeparator);
      final dailyChangeLabel = dailyChangePercentLabel != null
          ? '$dailyChangeSign$dailyChangePercentLabel% (24h)'
          : '${quoteCurrency.code} indisponivel';

      return _HomeBalanceCardData(
        view: view,
        wallet: primaryWallet,
        balanceBtc: balanceBtc,
        convertedBalanceLabel: convertedBalanceLabel,
        dailyChangeLabel: dailyChangeLabel,
        dailyChangeColor: dailyChangeColor,
        decimalPlaces: balanceSettings.decimalPlaces,
        balanceHidden: balanceSettings.isHidden,
      );
    }

    void toggleVisibility() {
      HapticFeedback.lightImpact();
      ref.read(balanceSettingsProvider.notifier).toggleVisibility();
    }

    void selectPage(int page) {
      final view = switch (page) {
        0 => _HomeLedgerBalanceView.total,
        1 => _HomeLedgerBalanceView.platform,
        _ => _HomeLedgerBalanceView.onChain,
      };
      ref.read(_homeLedgerBalanceViewProvider.notifier).state = view;
      if (view == _HomeLedgerBalanceView.platform) {
        ref.read(_homeActivityFilterProvider.notifier).state =
            _HomeActivityFilter.platform;
      } else if (view == _HomeLedgerBalanceView.onChain) {
        ref.read(_homeActivityFilterProvider.notifier).state =
            _HomeActivityFilter.onChain;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  _HomeAvatar(name: widget.userName),
                  SizedBox(width: _homeSize(12)),
                  Expanded(
                    child: Text(
                      _localizedGreeting(context, widget.userName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ebGaramond(
                        textStyle: theme.textTheme.titleLarge,
                        color: Colors.white,
                        fontSize: responsive.compactFontSize(
                          tiny: _homeFontSize(22),
                          compact: _homeFontSize(24),
                          regular: _homeFontSize(25),
                        ),
                        fontWeight: FontWeight.w300,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _homeSize(12)),
            _HomeHeaderIconButton(
              icon: balanceSettings.isHidden
                  ? LucideIcons.eyeOff
                  : LucideIcons.eye,
              onTap: toggleVisibility,
            ),
            SizedBox(width: _homeSize(8)),
            _HomeHeaderIconButton(
              icon: LucideIcons.bell,
              hasBadge: notificationCount > 0,
              onTap: () async {
                await HapticFeedback.selectionClick();
                ref.read(notificationSidebarProvider.notifier).toggle();
              },
            ),
          ],
        ),
        SizedBox(height: _homeSize(18)),
        SizedBox(
          height: responsive.isTinyPhone ? _homeSize(276) : _homeSize(286),
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: selectPage,
            children: [
              _HomeBalanceCard(
                data: cardDataFor(_HomeLedgerBalanceView.total),
                onViewStatement: widget.onViewStatement,
              ),
              _HomeBalanceCard(
                data: cardDataFor(_HomeLedgerBalanceView.platform),
                onViewStatement: widget.onViewStatement,
              ),
              _HomeBalanceCard(
                data: cardDataFor(_HomeLedgerBalanceView.onChain),
                onViewStatement: widget.onViewStatement,
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(16)),
        Row(
          children: [
            Expanded(
              child: _HomeBalanceActionButton(
                icon: LucideIcons.arrowDown,
                label: context.l10n.homeReceiveActionShort,
                onTap: widget.onReceive,
                primary: true,
              ),
            ),
            SizedBox(width: _homeSize(12)),
            Expanded(
              child: _HomeBalanceActionButton(
                icon: LucideIcons.arrowUp,
                label: context.l10n.homeSendTitle,
                onTap: widget.onSend,
                primary: false,
              ),
            ),
          ],
        ),
        SizedBox(height: _homeSize(14)),
        _HomePaginationDots(
          count: 3,
          activeIndex: _pageIndexFor(selectedView),
        ),
      ],
    );
  }

  static int _pageIndexFor(_HomeLedgerBalanceView view) {
    return switch (view) {
      _HomeLedgerBalanceView.total => 0,
      _HomeLedgerBalanceView.platform => 1,
      _HomeLedgerBalanceView.onChain => 2,
    };
  }

  static List<Wallet> _walletsForView(
    List<Wallet> wallets,
    _HomeLedgerBalanceView view,
  ) {
    if (view == _HomeLedgerBalanceView.total) {
      return wallets;
    }

    final filtered = wallets
        .where(
          (wallet) => view == _HomeLedgerBalanceView.onChain
              ? wallet.isSelfCustody
              : wallet.isKeroseneCustody,
        )
        .toList(growable: false);
    return filtered;
  }

  static Wallet? _primaryWalletForView({
    required Wallet? activeWallet,
    required List<Wallet> scopedWallets,
    required _HomeLedgerBalanceView view,
  }) {
    if (view == _HomeLedgerBalanceView.total) {
      return activeWallet ??
          (scopedWallets.isNotEmpty ? scopedWallets.first : null);
    }

    final activeMatches = activeWallet != null &&
        (view == _HomeLedgerBalanceView.onChain
            ? activeWallet.isSelfCustody
            : activeWallet.isKeroseneCustody);
    if (activeMatches) {
      return activeWallet;
    }
    return scopedWallets.isNotEmpty ? scopedWallets.first : null;
  }

  static double _sumWallets(List<Wallet> wallets) {
    return wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
  }

  static String _localizedGreeting(BuildContext context, String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.l10n.homeGreetingMorning(userName);
    }
    if (hour < 18) {
      return context.l10n.homeGreetingAfternoon(userName);
    }
    return context.l10n.homeGreetingEvening(userName);
  }
}

class _HomeBalanceCardData {
  final _HomeLedgerBalanceView view;
  final Wallet? wallet;
  final double balanceBtc;
  final String convertedBalanceLabel;
  final String dailyChangeLabel;
  final Color dailyChangeColor;
  final int decimalPlaces;
  final bool balanceHidden;

  const _HomeBalanceCardData({
    required this.view,
    required this.wallet,
    required this.balanceBtc,
    required this.convertedBalanceLabel,
    required this.dailyChangeLabel,
    required this.dailyChangeColor,
    required this.decimalPlaces,
    required this.balanceHidden,
  });
}

class _HomeBalanceCard extends ConsumerWidget {
  final _HomeBalanceCardData data;
  final VoidCallback onViewStatement;

  const _HomeBalanceCard({
    required this.data,
    required this.onViewStatement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final isTotal = data.view == _HomeLedgerBalanceView.total;
    final title = switch (data.view) {
      _HomeLedgerBalanceView.platform => _homeInternalBalanceTitle(context),
      _HomeLedgerBalanceView.onChain => _homeOnchainBalanceTitle(context),
      _HomeLedgerBalanceView.total => _homeTotalBalanceTitle(context),
    };
    final walletName = switch (data.view) {
      _HomeLedgerBalanceView.platform => _homeGlobalWalletTitle(context),
      _HomeLedgerBalanceView.onChain =>
        _nonEmpty(data.wallet?.name, _homeOnchainWalletCardTitle(context)),
      _HomeLedgerBalanceView.total => _homeConsolidatedWalletTitle(context),
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _homeMutedTextColor,
                        fontSize: _homeFontSize(12),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: _homeSize(8)),
                  Icon(
                    data.balanceHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: _homeSize(14),
                    color: _homeMutedTextColor,
                  ),
                ],
              ),
            ),
            if (isTotal)
              Icon(
                LucideIcons.wallet,
                size: _homeSize(20),
                color: Colors.white.withValues(alpha: 0.72),
              )
            else
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AppPrimaryNavigationBar.navigateTo(
                    context,
                    AppPrimaryDestination.settings,
                  );
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: _homeSize(32),
                  height: _homeSize(32),
                ),
                icon: Icon(
                  LucideIcons.settings,
                  size: _homeSize(20),
                  color: _homeMutedTextColor,
                ),
              ),
          ],
        ),
        SizedBox(height: _homeSize(10)),
        Text(
          walletName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: _homeFontSize(14),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: _homeSize(15)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBalanceDisplay(
                balance: data.balanceBtc,
                decimalPlaces: data.decimalPlaces,
                locale: MoneyDisplay.localeFor(Currency.btc),
                enableFlash: false,
                isHidden: data.balanceHidden,
                digitWidthFactor: 0.72,
                characterSpacing: 0.1,
                decimalScaleFactor: 0.78,
                separatorScaleFactor: 0.78,
                onDecimalTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(balanceSettingsProvider.notifier).cycleDecimals();
                },
                style: AppTypography.amountInput(isBtc: true).copyWith(
                  color: Colors.white,
                  fontSize: responsive.compactFontSize(
                    tiny: _homeFontSize(isTotal ? 36 : 32),
                    compact: _homeFontSize(isTotal ? 42 : 38),
                    regular: _homeFontSize(isTotal ? 46 : 42),
                  ),
                  fontFamily: GoogleFonts.junge().fontFamily,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: _homeSize(6),
                  bottom: _homeSize(4),
                ),
                child: Text(
                  'BTC',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _homeMutedTextColor,
                    fontSize: _homeFontSize(16),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _homeSize(5)),
        Text(
          data.convertedBalanceLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _homeMutedTextColor,
            fontSize: _homeFontSize(14),
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: _homeSize(5)),
        Row(
          children: [
            Icon(
              data.dailyChangeColor == _homePositiveColor
                  ? LucideIcons.arrowUp
                  : LucideIcons.arrowDown,
              color: data.dailyChangeColor,
              size: _homeSize(12),
            ),
            SizedBox(width: _homeSize(5)),
            Flexible(
              child: Text(
                data.dailyChangeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: data.dailyChangeColor,
                  fontSize: _homeFontSize(13),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: onViewStatement,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.82),
              side: BorderSide(
                color: Colors.white.withValues(alpha: isTotal ? 0.36 : 1),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _homeSize(12),
                vertical: _homeSize(7),
              ),
              minimumSize: Size(0, _homeSize(34)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_homeSize(8)),
              ),
              textStyle: theme.textTheme.labelSmall?.copyWith(
                fontSize: _homeFontSize(12),
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
            ),
            child: Text(_homeStatementActionLabel(context)),
          ),
        ),
      ],
    );

    if (isTotal) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          _homeSize(6),
          _homeSize(20),
          _homeSize(6),
          _homeSize(20),
        ),
        child: content,
      );
    }

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(18)),
      padding: EdgeInsets.all(_homeSize(20)),
      child: content,
    );
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}

class _HomeAvatar extends StatelessWidget {
  final String name;

  const _HomeAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = _initialFor(name);

    return Container(
      width: _homeSize(40),
      height: _homeSize(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _homeCardColor,
        border: Border.all(color: _homePanelBorderColor),
        image: const DecorationImage(
          image: AssetImage('assets/logo/kerosene-logo.png'),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }

  static String _initialFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '...') {
      return 'K';
    }
    return trimmed.characters.first.toUpperCase();
  }
}

String _homeInternalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Internal balance',
    'es' => 'Saldo interno',
    _ => 'Saldo Interno',
  };
}

String _homeOnchainBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain balance',
    'es' => 'Saldo On-chain',
    _ => 'Saldo Onchain',
  };
}

String _homeTotalBalanceTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total balance',
    'es' => 'Saldo total',
    _ => 'Saldo Total',
  };
}

String _homeGlobalWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Global wallet',
    'es' => 'Cartera global',
    _ => 'Carteira Global',
  };
}

String _homeConsolidatedWalletTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Total Balance',
    'es' => 'Saldo Total',
    _ => 'Saldo Total',
  };
}

String _homeOnchainWalletCardTitle(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'On-chain wallet',
    'es' => 'Cartera On-chain',
    _ => 'Carteira On-chain',
  };
}

String _homeStatementActionLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Go to statement',
    'es' => 'Ir al extracto',
    _ => 'Ir para extrato',
  };
}

class _HomeBottomNavigationOverlay extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const _HomeBottomNavigationOverlay({required this.currentDestination});

  static const List<AppPrimaryDestination> _orderedDestinations = [
    AppPrimaryDestination.home,
    AppPrimaryDestination.card,
    AppPrimaryDestination.mining,
    AppPrimaryDestination.history,
    AppPrimaryDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(0, 0, _homeSize(24), _homeSize(32)),
            child: Align(
              alignment: Alignment.bottomRight,
              child: _HomeFloatingMenuButton(
                currentDestination: currentDestination,
                destinations: _orderedDestinations,
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: _homeSize(8)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _homeSize(128),
                height: _homeSize(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_homeSize(999)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFloatingMenuButton extends StatelessWidget {
  final AppPrimaryDestination currentDestination;
  final List<AppPrimaryDestination> destinations;

  const _HomeFloatingMenuButton({
    required this.currentDestination,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MaterialLocalizations.of(context).showMenuTooltip,
      child: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).showMenuTooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              _showMenu(context);
            },
            child: Container(
              width: _homeSize(56),
              height: _homeSize(56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _homeCardColor,
                border: Border.all(color: _homePanelBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: _homeSize(20),
                    offset: Offset(0, _homeSize(4)),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.menu,
                color: Colors.white,
                size: _homeSize(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _homeSize(16),
              0,
              _homeSize(16),
              _homeSize(16),
            ),
            child: _HomeGlassPanel(
              borderRadius: BorderRadius.circular(_homeSize(18)),
              padding: EdgeInsets.symmetric(vertical: _homeSize(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final destination in destinations)
                    _HomeMenuDestinationTile(
                      destination: destination,
                      selected: destination == currentDestination,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeMenuDestinationTile extends StatelessWidget {
  final AppPrimaryDestination destination;
  final bool selected;

  const _HomeMenuDestinationTile({
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final label = destination.label(context);
    final color = selected ? _homeAmberColor : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                AppPrimaryNavigationBar.navigateTo(context, destination);
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _homeSize(18),
            vertical: _homeSize(14),
          ),
          child: Row(
            children: [
              Icon(destination.icon, color: color, size: _homeSize(22)),
              SizedBox(width: _homeSize(14)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontSize: _homeFontSize(15),
                        fontWeight:
                            selected ? FontWeight.w300 : FontWeight.w300,
                        letterSpacing: 0,
                      ),
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  color: _homeAmberColor,
                  size: _homeSize(18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Popup Widget ────────────────────────────────────────────────
class _TxPopupWidget extends ConsumerStatefulWidget {
  final double restingTop;
  final double activeTop;

  const _TxPopupWidget({required this.restingTop, required this.activeTop});

  @override
  ConsumerState<_TxPopupWidget> createState() => _TxPopupWidgetState();
}

class _TxPopupWidgetState extends ConsumerState<_TxPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _slideController;
  late Animation<double> _spinAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _spinAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159265,
    ).animate(_spinController);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popupState = ref.watch(txPopupProvider);
    final theme = Theme.of(context);
    final safeTop = MediaQuery.of(context).padding.top;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (popupState.active &&
          !_slideController.isAnimating &&
          _slideController.isDismissed) {
        _slideController.forward();
      } else if (!popupState.active &&
          !_slideController.isAnimating &&
          _slideController.isCompleted) {
        _slideController.reverse();
      }
    });

    return AnimatedBuilder(
      animation: Listenable.merge([_spinAnimation, _slideAnimation]),
      builder: (context, child) {
        final restingTop = widget.restingTop;
        final visibleTop = safeTop + widget.activeTop;
        final topPos =
            restingTop - (restingTop - visibleTop) * _slideAnimation.value;
        final accent = popupState.status == TxPopupStatus.loading
            ? theme.colorScheme.primary
            : popupState.status == TxPopupStatus.success
                ? AppColors.success
                : popupState.isSent
                    ? AppColors.warning
                    : AppColors.success;
        final iconData = popupState.status == TxPopupStatus.loading
            ? Icons.sync_rounded
            : popupState.status == TxPopupStatus.success
                ? Icons.check_rounded
                : (popupState.isSent
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded);

        return Positioned(
          top: topPos,
          left: 16,
          right: 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Opacity(
                opacity: _slideAnimation.value.clamp(0.0, 1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppNotificationStyle.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (popupState.status == TxPopupStatus.loading)
                                  ExcludeSemantics(
                                    child: Transform.rotate(
                                      angle: _spinAnimation.value,
                                      child: CustomPaint(
                                        size: const Size(24, 24),
                                        painter: _SpinningArcPainter(
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                Icon(
                                  iconData,
                                  size:
                                      popupState.status == TxPopupStatus.success
                                          ? 16
                                          : 14,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  popupState.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppNotificationStyle.titleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    height: 1.1,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  popupState.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    fontFamily: 'JetBrainsMono',
                                    color: AppNotificationStyle.bodyColor,
                                    fontSize: 10,
                                    height: 1.1,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                popupState.amount,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppNotificationStyle.titleColor,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                  height: 1.1,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                popupState.time,
                                style: AppTypography.caption.copyWith(
                                  color: AppNotificationStyle.metaColor,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 10,
                                  height: 1.1,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpinningArcPainter extends CustomPainter {
  final Color color;
  _SpinningArcPainter({this.color = AppColors.success});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const sweepAngle = 1.5;
    canvas.drawArc(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      0,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TransactionsList extends ConsumerWidget {
  const _TransactionsList();

  static String _formatDate(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dt.year &&
        yesterday.month == dt.month &&
        yesterday.day == dt.day;
    final time = '${_pad(dt.hour)}:${_pad(dt.minute)}';

    if (isToday) {
      return context.l10n.homeTodayAt(time);
    }
    if (isYesterday) {
      return context.l10n.homeYesterdayAt(
        time,
      );
    }
    return '${_pad(dt.day)}/${_pad(dt.month)} $time';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);
    final selectedFilter = ref.watch(_homeActivityFilterProvider);
    final walletState = ref.watch(walletProvider);
    final activeWallet = walletState is WalletLoaded
        ? walletState.selectedWallet ??
            (walletState.wallets.isNotEmpty ? walletState.wallets.first : null)
        : null;

    return transactionsAsync.when(
      data: (txs) {
        final filteredTxs = _filterHomeTransactions(txs, selectedFilter);
        if (filteredTxs.isEmpty) {
          final hasWallet = activeWallet != null;
          final hasBalance = (activeWallet?.balance ?? 0) > 0;

          return Padding(
            padding: EdgeInsets.zero,
            child: _HomeEmptyTransactionsPanel(
              icon: !hasWallet
                  ? LucideIcons.wallet
                  : !hasBalance
                      ? LucideIcons.landmark
                      : LucideIcons.receipt,
              title: !hasWallet
                  ? context.l10n.homeEmptyNoWalletTitle
                  : !hasBalance
                      ? context.l10n.homeEmptyNoBalanceTitle
                      : context.l10n.homeEmptyNoTransactionsTitle,
              description: !hasWallet
                  ? context.l10n.homeEmptyNoWalletDescription
                  : !hasBalance
                      ? context.l10n.homeEmptyNoBalanceDescription
                      : context.l10n.homeEmptyNoTransactionsDescription,
              actionLabel: !hasWallet
                  ? context.l10n.homeCreateWalletAction
                  : !hasBalance
                      ? context.l10n.homeDepositAction
                      : context.l10n.homeRefreshAction,
              actionIcon: !hasWallet
                  ? LucideIcons.arrowRight
                  : !hasBalance
                      ? LucideIcons.download
                      : LucideIcons.refreshCw,
              onAction: () {
                if (!hasWallet) {
                  Navigator.of(context).push<void>(
                    _buildBottomUpRoute(
                      builder: (_) => const CreateWalletScreen(),
                    ),
                  );
                  return;
                }

                if (!hasBalance) {
                  Navigator.of(context).push<void>(
                    _buildBottomUpRoute(
                      builder: (_) => DepositAmountScreen(wallet: activeWallet),
                    ),
                  );
                  return;
                }

                ref.invalidate(transactionHistoryProvider);
              },
            ),
          );
        }
        final visibleTxs = filteredTxs.take(6).toList(growable: false);

        return _HomeGlassPanel(
          borderRadius: BorderRadius.circular(_homeSize(16)),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < visibleTxs.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _homePanelBorderColor,
                  ),
                _buildTransactionTile(context, visibleTxs[index]),
              ],
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: StateFeedbackView(
          state: FeedbackState.loading,
          title: context.l10n.homeLoadingTransactionsTitle,
          description: context.l10n.homeLoadingTransactionsSubtitle,
        ),
      ),
      error: (e, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: StateFeedbackView.networkError(
          context: context,
          onAction: () => ref.refresh(transactionHistoryProvider),
        ),
      ),
    );
  }

  static List<Transaction> _filterHomeTransactions(
    List<Transaction> txs,
    _HomeActivityFilter filter,
  ) {
    return switch (filter) {
      _HomeActivityFilter.platform => txs
          .where((tx) => tx.isInternal || tx.isLightning)
          .toList(growable: false),
      _HomeActivityFilter.onChain => txs
          .where((tx) => !tx.isInternal && !tx.isLightning)
          .toList(growable: false),
      _HomeActivityFilter.notices => txs
          .where(
            (tx) =>
                tx.status == TransactionStatus.pending ||
                tx.status == TransactionStatus.confirming ||
                tx.status == TransactionStatus.failed ||
                tx.type == TransactionType.fee,
          )
          .toList(growable: false),
    };
  }

  static Widget _buildTransactionTile(BuildContext context, Transaction tx) {
    final visual = TransactionVisualSpec.fromTransaction(tx);
    final amountLabel = _formatSignedBtcAmount(visual, tx);

    return _HomeTransactionTile(
      tx: tx,
      visual: visual,
      amountLabel: amountLabel,
      dateLabel: _formatDate(context, tx.timestamp),
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withValues(alpha: 0.55),
          transitionDuration: const Duration(milliseconds: 160),
          pageBuilder: (context, anim1, anim2) => TxDetailOverlay(
            tx: tx,
            onClose: () => Navigator.pop(context),
          ),
          transitionBuilder: (context, anim1, anim2, child) {
            return FadeTransition(opacity: anim1, child: child);
          },
        );
      },
    );
  }

  static String _formatSignedBtcAmount(
    TransactionVisualSpec visual,
    Transaction tx,
  ) {
    final amount = MoneyDisplay.format(
      amount: tx.amountBTC.abs(),
      currency: Currency.btc,
      withSymbol: false,
      decimalPlaces: 6,
    );
    return '${visual.prefix}$amount BTC';
  }
}

class _HomeTransactionTile extends StatelessWidget {
  final Transaction tx;
  final TransactionVisualSpec visual;
  final String amountLabel;
  final String dateLabel;
  final VoidCallback onTap;

  const _HomeTransactionTile({
    required this.tx,
    required this.visual,
    required this.amountLabel,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counterparty = _counterpartyLabel(context, tx);
    final networkLabel = _networkLabel(context, tx);
    final networkIsOnchain = _isOnchain(tx);
    final amountColor = visual.isIncoming
        ? _homePositiveColor
        : visual.isOutgoing
            ? Colors.white
            : _homeMutedTextColor;
    final iconColor = visual.isIncoming ? _homePositiveColor : Colors.white;
    final iconBackground = visual.isIncoming
        ? _homePositiveColor.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.10);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(_homeSize(16)),
            child: Row(
              children: [
                Container(
                  width: _homeSize(40),
                  height: _homeSize(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBackground,
                  ),
                  child: Icon(
                    _activityIcon(visual, tx),
                    color: iconColor,
                    size: _homeSize(18),
                  ),
                ),
                SizedBox(width: _homeSize(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              visual.localizedLabel(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontSize: _homeFontSize(14),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          SizedBox(width: _homeSize(8)),
                          _HomeNetworkBadge(
                            label: networkLabel,
                            highlighted: networkIsOnchain,
                          ),
                        ],
                      ),
                      SizedBox(height: _homeSize(4)),
                      Text(
                        counterparty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _homeMutedTextColor,
                          fontSize: _homeFontSize(12),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _homeSize(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: _homeSize(152)),
                      child: Text(
                        amountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: amountColor,
                          fontSize: _homeFontSize(14),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: _homeSize(4)),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _homeMutedTextColor,
                        fontSize: _homeFontSize(12),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _activityIcon(TransactionVisualSpec visual, Transaction tx) {
    if (tx.status == TransactionStatus.failed) {
      return LucideIcons.alertCircle;
    }
    if (tx.isLightning) {
      return LucideIcons.zap;
    }
    if (tx.isInternal) {
      return visual.isIncoming ? LucideIcons.link2 : LucideIcons.repeat2;
    }
    if (visual.isIncoming) {
      return LucideIcons.barChart3;
    }
    if (visual.isOutgoing) {
      return LucideIcons.barChart2;
    }
    return LucideIcons.receipt;
  }

  bool _isOnchain(Transaction tx) {
    return !tx.isInternal && !tx.isLightning;
  }

  String _networkLabel(BuildContext context, Transaction tx) {
    if (tx.isLightning) {
      return 'Lightning';
    }
    if (tx.isInternal) {
      return _homePlatformFilterLabel(context);
    }
    return _homeOnchainFilterLabel(context);
  }

  String _counterpartyLabel(BuildContext context, Transaction tx) {
    final sent = tx.type == TransactionType.send ||
        tx.type == TransactionType.withdrawal ||
        tx.type == TransactionType.fee;
    final rawAddress = sent ? tx.toAddress : tx.fromAddress;
    final fallback = tx.description?.trim();
    final value = rawAddress.trim().isNotEmpty
        ? rawAddress.trim()
        : (fallback?.isNotEmpty == true ? fallback! : tx.id);
    final short = _shortPaymentValue(value);
    final prefix = sent
        ? context.l10n.homeCounterpartyTo
        : context.l10n.homeCounterpartyFrom;
    return '$prefix $short';
  }
}

class _HomeNetworkBadge extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _HomeNetworkBadge({
    required this.label,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? _homeAmberColor : _homeMutedTextColor;
    final border = highlighted
        ? _homeAmberColor.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.10);
    final background = highlighted
        ? _homeAmberColor.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.05);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _homeSize(6),
        vertical: _homeSize(2),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_homeSize(6)),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: _homeFontSize(10),
              fontWeight: FontWeight.w300,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _HomeEmptyTransactionsPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _HomeEmptyTransactionsPanel({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _HomeGlassPanel(
      borderRadius: BorderRadius.circular(_homeSize(18)),
      padding: EdgeInsets.all(_homeSize(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _homeSize(40),
            height: _homeSize(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(_homeSize(12)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Icon(icon, color: Colors.white, size: _homeSize(18)),
          ),
          SizedBox(height: _homeSize(AppSpacing.lg)),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: _homeFontSize(16),
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _homeSize(6)),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: _homeFontSize(12),
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _homeSize(AppSpacing.lg)),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: Size.fromHeight(_homeSize(50)),
                backgroundColor: Colors.white,
                foregroundColor: _homeBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_homeSize(14)),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: _homeFontSize(14),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
              icon: Icon(actionIcon, size: _homeSize(16)),
              label: Text(actionLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HomeActionIconKind {
  createWallet,
  primaryDeposit,
  primarySend,
  primaryReceive,
  viewDeposits,
  internalTransfer,
  sendOnChain,
  payLightning,
  scanQr,
  payLink,
  sendNfc,
}

class _QuickActionData {
  final _HomeActionIconKind kind;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.kind,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _HomeActionIcon extends StatelessWidget {
  final _HomeActionIconKind kind;
  final Color iconColor;
  final double size;

  const _HomeActionIcon({
    required this.kind,
    required this.iconColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return _buildIcon();
  }

  Widget _buildIcon() {
    switch (kind) {
      case _HomeActionIconKind.createWallet:
        return Icon(LucideIcons.wallet, size: size, color: iconColor);
      case _HomeActionIconKind.primaryDeposit:
        return Icon(LucideIcons.landmark, size: size, color: iconColor);
      case _HomeActionIconKind.primarySend:
        return Icon(LucideIcons.arrowUpRight, size: size, color: iconColor);
      case _HomeActionIconKind.primaryReceive:
        return Icon(LucideIcons.arrowDownLeft, size: size, color: iconColor);
      case _HomeActionIconKind.viewDeposits:
        return Icon(LucideIcons.history, size: size, color: iconColor);
      case _HomeActionIconKind.internalTransfer:
        return Icon(LucideIcons.arrowLeftRight, size: size, color: iconColor);
      case _HomeActionIconKind.sendOnChain:
        return Icon(LucideIcons.link2, size: size, color: iconColor);
      case _HomeActionIconKind.payLightning:
        return Icon(LucideIcons.zap, size: size, color: iconColor);
      case _HomeActionIconKind.scanQr:
        return Icon(LucideIcons.scanLine, size: size, color: iconColor);
      case _HomeActionIconKind.payLink:
        return Icon(LucideIcons.link2, size: size, color: iconColor);
      case _HomeActionIconKind.sendNfc:
        return Icon(LucideIcons.smartphoneNfc, size: size, color: iconColor);
    }
  }
}
