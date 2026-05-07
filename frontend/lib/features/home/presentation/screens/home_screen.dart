import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:teste/main.dart' show sharedPreferencesProvider;
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/navigation/app_page_transitions.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/widgets/state_feedback_view.dart';
import 'package:teste/core/widgets/animated_typewriter_text.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/qr_payment_parser.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/shared/widgets/bitcoin_refresh_indicator.dart';
import 'package:teste/shared/widgets/bouncing_button_wrapper.dart';
import 'package:teste/shared/widgets/interaction_utils.dart';

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
import 'package:teste/features/wallet/presentation/widgets/wallet_credit_card.dart';
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

// ─── Riverpod Provider para o Popup ──────────────────────────────────────────
final txPopupProvider = ChangeNotifierProvider<TxPopupNotifier>((ref) {
  return TxPopupNotifier();
});

const Color _homeBackgroundColor = authenticatedSurfaceBackgroundColor;
const Color _homeLowerSurfaceColor = _homeBackgroundColor;

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

  void showLoading() {
    _dismissTimer?.cancel();
    _active = true;
    _status = TxPopupStatus.loading;
    _label = 'Atualizando carteira';
    _address = 'Buscando saldo e transações';
    _amount = '...';
    _time = 'agora';
    notifyListeners();
  }

  void showSuccess() {
    _dismissTimer?.cancel();
    _status = TxPopupStatus.success;
    _label = 'Atualizado';
    _address = 'Saldo e transações sincronizados';
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
  String? _firstUseActionPanelUserId;
  int _greetingAnimationSeed = 0;
  late final ProviderSubscription<ReceivedTxEvent?> _receivedTxSubscription;
  final AppPrimaryNavigationController _navBarController =
      AppPrimaryNavigationController();

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

        ref
            .read(txPopupProvider)
            .show(
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
    _navBarController.dispose();
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
    _navBarController.triggerRefreshAnimation();
    if (mounted) {
      setState(() {
        _greetingAnimationSeed++;
      });
    }

    try {
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(depositsProvider);
      ref.invalidate(depositBalanceProvider);

      await Future.wait([
        ref.read(walletProvider.notifier).refresh(),
        ref.read(transactionHistoryProvider.future),
      ]);
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

      ref
          .read(txPopupProvider)
          .show(
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

      ref
          .read(txPopupProvider)
          .show(
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
        kind: _HomeActionIconKind.internalTransfer,
        label: context.l10n.homeSendInternalLabel,
        subtitle: context.l10n.homeSendInternalSubtitle,
        onTap: () => _openSend(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.sendOnChain,
        label: context.l10n.homeSendOnchainLabel,
        subtitle: context.l10n.homeSendOnchainSubtitle,
        onTap: () => _openSendOnChain(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.payLightning,
        label: context.l10n.homeSendLightningLabel,
        subtitle: context.l10n.homeSendLightningSubtitle,
        onTap: () => _openSendLightning(walletState),
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
    final theme = Theme.of(context);
    final sidebarOpen = ref.watch(notificationSidebarProvider);
    final navigationClearance = AppPrimaryNavigationBar.scaffoldBottomClearance(
      context,
    );
    final responsive = context.responsive;
    final contentMaxWidth = responsive.mobileContentMaxWidth;
    final pageHorizontalPadding = responsive.horizontalPadding;

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
    final authenticatedUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;
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

    final showFirstUseReadyPanel =
        authenticatedUserId != null &&
        isReadyActionsVariant &&
        !hasTransactions &&
        _firstUseActionPanelUserId == authenticatedUserId;
    final showPrimaryActionPanel =
        !isReadyActionsVariant || showFirstUseReadyPanel;

    // ── NOME DE USUÁRIO REAL E SEGURO ──
    String userName = '';

    if (authState is AuthAuthenticated) {
      final fullName = authState.user.name.trim();
      if (fullName.isNotEmpty) {
        userName = fullName
            .split(' ')
            .first; // Pega o primeiro nome para UI limpa
      }
    } else if (activeWallet != null) {
      userName = activeWallet.name;
    } else if (authState is AuthLoading) {
      userName = '...';
    }

    if (userName.isEmpty || userName == 'Not Found') {
      userName = 'Usuário';
    }

    return Scaffold(
      backgroundColor: _homeBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _homeBackgroundColor),
          const _HomeRealtimeBootstrap(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                BitcoinRefreshIndicator(onRefresh: _refreshHomeData),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: _HomeBalanceSection(
                            userName: userName,
                            activeWallet: activeWallet,
                            greetingAnimationSeed: _greetingAnimationSeed,
                          ).animate().fade(duration: 320.ms),
                        ),
                      ),
                      ColoredBox(
                        color: _homeLowerSurfaceColor,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentMaxWidth,
                            ),
                            child: Column(
                              children: [
                                if (showPrimaryActionPanel) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: pageHorizontalPadding,
                                    ),
                                    child: _PrimaryActionPanel(
                                      icon: !hasWallet
                                          ? LucideIcons.wallet
                                          : !hasBalance
                                          ? LucideIcons.download
                                          : LucideIcons.arrowUpRight,
                                      title: !hasWallet
                                          ? context
                                                .l10n
                                                .homePrimaryNoWalletTitle
                                          : !hasBalance
                                          ? context
                                                .l10n
                                                .homePrimaryReadyNoBalanceTitle
                                          : context.l10n.homePrimaryReadyTitle,
                                      subtitle: !hasWallet
                                          ? context
                                                .l10n
                                                .homePrimaryNoWalletSubtitle
                                          : !hasBalance
                                          ? context
                                                .l10n
                                                .homePrimaryReadyNoBalanceSubtitle
                                          : context
                                                .l10n
                                                .homePrimaryReadySubtitle,
                                      primaryLabel: !hasWallet
                                          ? context.l10n.homeCreateWalletAction
                                          : !hasBalance
                                          ? context.l10n.homeDepositFundsAction
                                          : context.l10n.homeSendBtcAction,
                                      primaryIconKind: !hasWallet
                                          ? _HomeActionIconKind.createWallet
                                          : !hasBalance
                                          ? _HomeActionIconKind.primaryDeposit
                                          : _HomeActionIconKind.primarySend,
                                      primaryIcon: !hasWallet
                                          ? LucideIcons.plus
                                          : !hasBalance
                                          ? LucideIcons.download
                                          : LucideIcons.arrowUpRight,
                                      onPrimaryTap: !hasWallet
                                          ? _openCreateWallet
                                          : !hasBalance
                                          ? () => _openDeposit(walletState)
                                          : () => _openSend(walletState),
                                      secondaryLabel: hasWallet && hasBalance
                                          ? context.l10n.homeReceiveBtcAction
                                          : hasWallet
                                          ? context.l10n.homeViewDepositsAction
                                          : null,
                                      secondaryIcon: hasWallet && hasBalance
                                          ? LucideIcons.arrowDownLeft
                                          : hasWallet
                                          ? LucideIcons.list
                                          : null,
                                      secondaryIconKind: hasWallet && hasBalance
                                          ? _HomeActionIconKind.primaryReceive
                                          : hasWallet
                                          ? _HomeActionIconKind.viewDeposits
                                          : null,
                                      onSecondaryTap: hasWallet && hasBalance
                                          ? () => _openReceiveHub(walletState)
                                          : hasWallet
                                          ? () => unawaited(
                                              _pushFromBottom<void>(
                                                (_) => const DepositsScreen(
                                                  showPrimaryNavigation: true,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                                if (hasWallet) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: pageHorizontalPadding,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _HomeActionSection(
                                          title: context.l10n.homeSendTitle,
                                          actions: _buildSendActions(
                                            walletState,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xl),
                                        _ReceiveTransferTextPanel(
                                          onTap: () =>
                                              _openReceiveHub(walletState),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(
                                  height: AppSpacing.xl + AppSpacing.md,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 500,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: pageHorizontalPadding,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.l10n.recentTransactions,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        const _TransactionsList(),
                                        SizedBox(height: navigationClearance),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                  child: Container(color: Colors.black.withValues(alpha: 0.42)),
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
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.home,
            controller: _navBarController,
          ),
        ],
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
    final linkAsync = linkId == null
        ? null
        : ref.watch(paymentLinkDetailProvider(linkId));
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
                        fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBalanceSection extends ConsumerWidget {
  final String userName;
  final Wallet? activeWallet;
  final int greetingAnimationSeed;

  const _HomeBalanceSection({
    required this.userName,
    required this.activeWallet,
    required this.greetingAnimationSeed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final responsive = context.responsive;
    final selectedCurrency = ref.watch(currencyProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final notificationCount = ref.watch(sessionNotificationUnreadCountProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final activeBalanceBtc = activeWallet?.balance ?? 0.0;
    final quoteCurrency = selectedCurrency == Currency.btc
        ? Currency.brl
        : selectedCurrency;
    final hasSelectedQuote = switch (quoteCurrency) {
      Currency.btc => true,
      Currency.usd => btcUsd != null && btcUsd > 0,
      Currency.eur => btcEur != null && btcEur > 0,
      Currency.brl => btcBrl != null && btcBrl > 0,
    };
    final convertedBalanceValue = MoneyDisplay.convertFromBtcAmount(
      btcAmount: activeBalanceBtc,
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
    return ColoredBox(
      color: _homeBackgroundColor,
      child: SizedBox(
        height: responsive.isTinyPhone
            ? 292
            : (responsive.isCompact ? 308 : 316),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.horizontalPadding,
            responsive.isTinyPhone ? 14 : 18,
            responsive.horizontalPadding,
            responsive.isTinyPhone ? 22 : 28,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedTypewriterText(
                        key: ValueKey(
                          'home_greeting_$greetingAnimationSeed-$userName',
                        ),
                        text: context.l10n.helloUser(userName),
                        textAlign: TextAlign.left,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        typingDuration: const Duration(milliseconds: 34),
                      ),
                    ),
                    _BalanceVisibilityButton(
                      icon: balanceSettings.isHidden
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(balanceSettingsProvider.notifier)
                            .toggleVisibility();
                      },
                    ),
                    const SizedBox(width: 6),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await HapticFeedback.selectionClick();
                            ref
                                .read(notificationSidebarProvider.notifier)
                                .toggle();
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          color: colorScheme.onPrimary.withValues(alpha: 0.84),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF11151A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF242A31)),
                            ),
                          ),
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              color: const Color(0xFFA84242),
                              child: Text(
                                notificationCount > 9
                                    ? '9+'
                                    : '$notificationCount',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Saldo BTC',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedBalanceDisplay(
                    balance: activeBalanceBtc,
                    prefix: '${MoneyDisplay.tickerSymbolFor(Currency.btc)} ',
                    decimalPlaces: balanceSettings.decimalPlaces,
                    locale: MoneyDisplay.localeFor(Currency.btc),
                    enableFlash: false,
                    isHidden: balanceSettings.isHidden,
                    digitWidthFactor: 0.72,
                    characterSpacing: 0.8,
                    decimalScaleFactor: 0.64,
                    separatorScaleFactor: 0.64,
                    onDecimalTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(balanceSettingsProvider.notifier)
                          .cycleDecimals();
                    },
                    style: AppTypography.amountInput(isBtc: true).copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.94),
                      fontSize: responsive.compactFontSize(
                        tiny: 34,
                        compact: 38,
                        regular: 42,
                        wide: 46,
                      ),
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                convertedBalanceLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceVisibilityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BalanceVisibilityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableWalletCard extends StatefulWidget {
  final Wallet? activeWallet;
  final VoidCallback onEmptyWalletTap;

  const _DraggableWalletCard({
    required this.activeWallet,
    required this.onEmptyWalletTap,
  });

  @override
  State<_DraggableWalletCard> createState() => _DraggableWalletCardState();
}

class _DraggableWalletCardState extends State<_DraggableWalletCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0; // vertical tilt (up/down)
  double _tiltY = 0; // horizontal tilt (left/right)
  late AnimationController _springController;
  Animation<Offset>? _springAnimation;

  static const double _maxTilt = 0.35; // ~20 degrees max tilt
  static const double _perspective = 0.0012;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _springController.addListener(() {
      if (_springAnimation != null) {
        setState(() {
          _tiltX = _springAnimation!.value.dx;
          _tiltY = _springAnimation!.value.dy;
        });
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _tiltY += details.delta.dx * 0.006;
      _tiltX -= details.delta.dy * 0.006;
      _tiltX = _tiltX.clamp(-_maxTilt, _maxTilt);
      _tiltY = _tiltY.clamp(-_maxTilt, _maxTilt);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _springAnimation =
        Tween<Offset>(begin: Offset(_tiltX, _tiltY), end: Offset.zero).animate(
          CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
        );
    _springController.forward(from: 0);
  }

  Matrix4 _buildTiltMatrix() {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, _perspective) // perspective
      ..rotateX(_tiltX) // tilt forward/backward
      ..rotateY(_tiltY); // tilt left/right
    return matrix;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Transform(
        alignment: FractionalOffset.center,
        transform: _buildTiltMatrix(),
        child: SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 336,
              height: 190,
              child: widget.activeWallet != null
                  ? WalletCreditCard(
                      wallet: widget.activeWallet,
                      colorIndex: 0,
                      isSelected: true,
                      showDetails: true,
                      tiltX: _tiltX,
                      tiltY: _tiltY,
                    )
                  : WalletCreditCard(
                      wallet: null,
                      colorIndex: 2,
                      isSelected: true,
                      isAddCard: true,
                      onTap: widget.onEmptyWalletTap,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceTick {
  final DateTime timestamp;
  final double price;

  const _PriceTick({required this.timestamp, required this.price});
}

class _HomeLiveBitcoinBackdrop extends ConsumerStatefulWidget {
  const _HomeLiveBitcoinBackdrop();

  @override
  ConsumerState<_HomeLiveBitcoinBackdrop> createState() =>
      _HomeLiveBitcoinBackdropState();
}

class _HomeLiveBitcoinBackdropState
    extends ConsumerState<_HomeLiveBitcoinBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ProviderSubscription<AsyncValue<double>> _priceSubscription;
  final List<_PriceTick> _priceHistory = <_PriceTick>[];
  static const Duration _historyWindow = Duration(hours: 1);
  static const int _maxSamples = 500;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _priceSubscription = ref.listenManual<AsyncValue<double>>(
      btcPriceProvider,
      (previous, next) {
        next.whenData(_recordPrice);
      },
    );

    // Fetch real kline data from Binance on startup
    unawaited(_fetchBinanceKlines());
  }

  /// Fetches real 1-hour kline data from Binance REST API.
  Future<void> _fetchBinanceKlines() async {
    if (_seeded) return;

    try {
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m&limit=60',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final body = utf8.decode(response.bodyBytes);

      final List<dynamic> klines = jsonDecode(body) as List<dynamic>;
      if (klines.isEmpty) return;

      _seeded = true;
      final ticks = <_PriceTick>[];

      for (final kline in klines) {
        final openTime = DateTime.fromMillisecondsSinceEpoch(
          (kline[0] as num).toInt(),
        );
        final closePrice = double.parse(kline[4] as String);
        ticks.add(_PriceTick(timestamp: openTime, price: closePrice));
      }

      if (!mounted || ticks.isEmpty) return;

      setState(() {
        _priceHistory.insertAll(0, ticks);
      });

      debugPrint(
        '📊 Binance klines loaded: ${ticks.length} candles, '
        'range ${ticks.first.price.toStringAsFixed(0)}-${ticks.last.price.toStringAsFixed(0)}',
      );
    } catch (e) {
      debugPrint('📊 Binance klines fetch failed: $e');
      // Fallback: will use live WebSocket data as it arrives
    }
  }

  void _recordPrice(double price) {
    if (!_seeded) {
      unawaited(_fetchBinanceKlines());
    }

    final now = DateTime.now();

    // Only record if the price actually changed (to avoid horizontal flat lines)
    if (_priceHistory.isNotEmpty && _priceHistory.last.price == price) {
      return;
    }

    setState(() {
      _priceHistory.add(_PriceTick(timestamp: now, price: price));
      _priceHistory.removeWhere(
        (tick) => now.difference(tick.timestamp) > _historyWindow,
      );
      if (_priceHistory.length > _maxSamples) {
        _priceHistory.removeRange(0, _priceHistory.length - _maxSamples);
      }
    });
  }

  @override
  void dispose() {
    _priceSubscription.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendIsUp =
        _priceHistory.length < 2 ||
        _priceHistory.last.price >= _priceHistory.first.price;
    final lineColor = trendIsUp
        ? const Color(0xFF15D07A)
        : const Color(0xFFD84C5D);
    final lineGlowColor = trendIsUp
        ? const Color(0x4515D07A)
        : const Color(0x45D84C5D);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _HomeLiveBitcoinPainter(
            now: DateTime.now(),
            history: List<_PriceTick>.unmodifiable(_priceHistory),
            lineColor: lineColor,
            lineGlowColor: lineGlowColor,
          ),
        );
      },
    );
  }
}

class _HomeLiveBitcoinPainter extends CustomPainter {
  final DateTime now;
  final List<_PriceTick> history;
  final Color lineColor;
  final Color lineGlowColor;

  const _HomeLiveBitcoinPainter({
    required this.now,
    required this.history,
    required this.lineColor,
    required this.lineGlowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (history.isEmpty) {
      canvas.restore();
      return;
    }

    final windowStart = now.subtract(
      _HomeLiveBitcoinBackdropState._historyWindow,
    );
    final visibleTicks =
        history
            .where((tick) => !tick.timestamp.isBefore(windowStart))
            .toList(growable: false)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (visibleTicks.length < 2) {
      canvas.restore();
      return;
    }

    // Filter out consecutive ticks with the same price (no horizontal segments)
    final filtered = <_PriceTick>[visibleTicks.first];
    for (var i = 1; i < visibleTicks.length; i++) {
      if (visibleTicks[i].price != visibleTicks[i - 1].price) {
        filtered.add(visibleTicks[i]);
      }
    }
    if (filtered.length < 2) {
      // If all prices were the same, just use first and last
      filtered.clear();
      filtered.add(visibleTicks.first);
      filtered.add(visibleTicks.last);
    }

    final smoothedPrices = <double>[];
    var smoothedValue = filtered.first.price;
    for (final tick in filtered) {
      smoothedValue = lerpDouble(smoothedValue, tick.price, 0.2) ?? tick.price;
      smoothedPrices.add(smoothedValue);
    }

    final sortedPrices = List<double>.from(smoothedPrices)..sort();
    final lowerIndex = ((sortedPrices.length - 1) * 0.12).floor();
    final upperIndex = ((sortedPrices.length - 1) * 0.88).ceil();
    var visualMin = sortedPrices[lowerIndex];
    var visualMax = sortedPrices[upperIndex];

    if ((visualMax - visualMin).abs() < 1.0) {
      visualMin = sortedPrices.first;
      visualMax = sortedPrices.last;
    }

    final center = (visualMin + visualMax) / 2;
    final halfRange = math.max(1.0, (visualMax - visualMin) / 2);
    final displayHalfRange = halfRange * 1.2;
    final verticalPadding = math.max(8.0, size.height * 0.07);
    final xOverscan = size.width * 0.08;

    final points = <Offset>[];
    for (var i = 0; i < filtered.length; i++) {
      final x = filtered.length == 1
          ? size.width / 2
          : -xOverscan +
                (i / (filtered.length - 1)) * (size.width + (xOverscan * 2));
      final clampedPrice = smoothedPrices[i].clamp(
        center - displayHalfRange,
        center + displayHalfRange,
      );
      final normalized =
          ((clampedPrice - (center - displayHalfRange)) /
                  (displayHalfRange * 2))
              .clamp(0.0, 1.0);
      final softened = 0.5 + (math.sin((normalized - 0.5) * math.pi) * 0.5);
      final y =
          (size.height - verticalPadding) -
          (softened * (size.height - (verticalPadding * 2)));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final glowPaint = Paint()
      ..color = lineGlowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeLiveBitcoinPainter oldDelegate) {
    return oldDelegate.now != now ||
        oldDelegate.history != history ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineGlowColor != lineGlowColor;
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
                                    fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w600,
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
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return context.l10n.homeNow;
    if (diff.inHours < 1) return context.l10n.homeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return context.l10n.homeHoursAgo(diff.inHours);
    if (diff.inDays == 1) {
      return context.l10n.homeYesterdayAt(
        '${_pad(dt.hour)}:${_pad(dt.minute)}',
      );
    }
    return '${_pad(dt.day)}/${_pad(dt.month)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  static _StatusStyle _statusStyle(BuildContext context, TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return _StatusStyle(
          context.l10n.pending,
          Color(0xFFC6A96B),
          LucideIcons.hourglass,
        );
      case TransactionStatus.confirming:
        return _StatusStyle(
          context.l10n.apiDisplayConfirming,
          Color(0xFFC6A96B),
          LucideIcons.loader2,
        );
      case TransactionStatus.confirmed:
        return _StatusStyle(
          context.l10n.apiDisplayCompleted,
          Color(0xFFA8C7B1),
          LucideIcons.clipboardCheck,
        );
      case TransactionStatus.failed:
        return _StatusStyle(
          context.l10n.apiDisplayCancelled,
          Color(0xFFD59A9A),
          LucideIcons.clipboardX,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredtxsAsync = ref.watch(filteredTransactionsProvider);
    final walletState = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final responsive = context.responsive;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final activeWallet = walletState is WalletLoaded
        ? walletState.selectedWallet ??
              (walletState.wallets.isNotEmpty
                  ? walletState.wallets.first
                  : null)
        : null;

    return filteredtxsAsync.when(
      data: (txs) {
        if (txs.isEmpty) {
          final hasWallet = activeWallet != null;
          final hasBalance = (activeWallet?.balance ?? 0) > 0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              AppSpacing.md,
              responsive.horizontalPadding,
              AppSpacing.xl,
            ),
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
        final visibleTxs = txs.take(6).toList(growable: false);

        return Column(
          children: [
            ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: AppSpacing.xs,
              ),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: visibleTxs.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFF20252B),
              ),
              itemBuilder: (context, index) {
                final tx = visibleTxs[index];
                final visual = TransactionVisualSpec.fromTransaction(tx);
                final status = _statusStyle(context, tx.status);
                final amountLabel = MoneyDisplay.formatAmountFromBtc(
                  btcAmount: tx.amountBTC,
                  currency: selectedCurrency,
                  btcUsd: btcUsd,
                  btcEur: btcEur,
                  btcBrl: btcBrl,
                );

                return RepaintBoundary(
                  child: InkWell(
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
                    child: ColoredBox(
                      color: const Color(0xFF111418),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            TransactionTypeIconBadge(
                              spec: visual,
                              size: 34,
                              iconSize: 17,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visual.localizedLabel(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        status.icon,
                                        color: status.color,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${status.label} · ${_formatDate(context, tx.timestamp)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall!
                                              .copyWith(
                                                color: colorScheme.onPrimary
                                                    .withValues(alpha: 0.42),
                                                fontSize: 10,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 144),
                              child: Text(
                                '${visual.prefix}$amountLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTypography.number.copyWith(
                                  color: visual.amountColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (txs.length > visibleTxs.length)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  AppSpacing.md,
                  responsive.horizontalPadding,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      _buildBottomUpRoute(
                        builder: (_) =>
                            const DepositsScreen(showPrimaryNavigation: true),
                      ),
                    ),
                    child: Text(context.l10n.homeFullHistory),
                  ),
                ),
              ),
          ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderStrongColor,
        showShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: monochromePanelDecoration(
              color: monoSurfaceRaisedColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Icon(icon, color: monoTextColor, size: 18),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: monoTextColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: monoMutedTextColor,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: monochromeFilledButtonStyle(minHeight: 50),
              icon: Icon(actionIcon, size: 16),
              label: Text(actionLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.icon);
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

class _PrimaryActionPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final _HomeActionIconKind? primaryIconKind;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final _HomeActionIconKind? secondaryIconKind;
  final VoidCallback? onSecondaryTap;

  const _PrimaryActionPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    this.primaryIconKind,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryIconKind,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary.withValues(alpha: 0.94),
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final hasSecondary =
                  secondaryLabel != null && onSecondaryTap != null;
              final isCompact = constraints.maxWidth < 360;

              final primaryButton = _ActionPanelButton(
                label: primaryLabel,
                icon: primaryIcon,
                kind: primaryIconKind,
                onTap: onPrimaryTap,
                backgroundColor: const Color(0xFF565C67),
                foregroundColor: AppColors.white,
              );

              final secondaryButton = hasSecondary
                  ? _ActionPanelButton(
                      label: secondaryLabel!,
                      icon: secondaryIcon ?? LucideIcons.arrowUpRight,
                      kind: secondaryIconKind,
                      onTap: onSecondaryTap!,
                      backgroundColor: const Color(0xFF4A505B),
                      foregroundColor: AppColors.white,
                    )
                  : null;

              if (!hasSecondary) {
                return primaryButton;
              }

              if (isCompact) {
                return Column(
                  children: [
                    primaryButton,
                    const SizedBox(height: AppSpacing.sm),
                    secondaryButton!,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: primaryButton),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: secondaryButton!),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
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

class _HomeActionSection extends StatelessWidget {
  final String title;
  final List<_QuickActionData> actions;

  const _HomeActionSection({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _HomeQuickActionsRow(actions: actions),
      ],
    );
  }
}

class _ReceiveTransferTextPanel extends StatelessWidget {
  final VoidCallback onTap;

  const _ReceiveTransferTextPanel({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: context.l10n.homeOpenReceiveScreen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.04),
            ),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: monochromePanelDecoration(
                color: monoSurfaceAltColor,
                borderColor: monoBorderStrongColor,
                showShadow: false,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Crie uma transferência',
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: monoTextColor,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: monochromePanelDecoration(
                          color: monoSurfaceRaisedColor,
                          borderColor: monoBorderStrongColor,
                          showShadow: false,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.arrowRight,
                          color: monoTextColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'para ser paga por outra pessoa',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: monoTextColor,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gere uma cobrança com destino e valor definidos por link de pagamento, QR, on-chain ou Lightning.',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: monoMutedTextColor,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'TOQUE PARA ABRIR',
                    style: AppTypography.caption.copyWith(
                      color: monoMutedTextColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeQuickActionsRow extends StatelessWidget {
  final List<_QuickActionData> actions;

  const _HomeQuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = context.responsive;
        final itemWidth = responsive.isTinyPhone ? 92.0 : _quickActionItemWidth;
        final totalWidth =
            (actions.length * itemWidth) +
            (math.max(0, actions.length - 1) * _quickActionGap);

        if (constraints.maxWidth.isFinite &&
            totalWidth <= constraints.maxWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: _quickActionGap),
                Expanded(
                  child: _QuickActionBtn(
                    index: index,
                    kind: actions[index].kind,
                    label: actions[index].label,
                    subtitle: actions[index].subtitle,
                    onTap: actions[index].onTap,
                  ),
                ),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: _quickActionGap),
                _QuickActionBtn(
                  index: index,
                  kind: actions[index].kind,
                  label: actions[index].label,
                  subtitle: actions[index].subtitle,
                  itemWidth: itemWidth,
                  onTap: actions[index].onTap,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

const double _quickActionButtonSize = 58;
const double _quickActionItemWidth = 104;
const double _quickActionIconSize = 23;
const double _quickActionGap = 8.4;

// ── Quick Action Button ────────────────────────────────────────────────────────
class _QuickActionBtn extends StatefulWidget {
  final int index;
  final _HomeActionIconKind kind;
  final String label;
  final String subtitle;
  final double? itemWidth;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.index,
    required this.kind,
    required this.label,
    required this.subtitle,
    this.itemWidth,
    required this.onTap,
  });

  @override
  State<_QuickActionBtn> createState() => _QuickActionBtnState();
}

class _QuickActionBtnState extends State<_QuickActionBtn>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 230),
    );

    Future<void>.delayed(Duration(milliseconds: 120 + (widget.index * 70)), () {
      if (!mounted) {
        return;
      }
      _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  Future<void> _handleTap() async {
    _pressController.reverse();
    unawaited(KeroseneFeedback.lightImpact());
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemWidth = widget.itemWidth ?? _quickActionItemWidth;
    final buttonSize = math.min(_quickActionButtonSize, itemWidth * 0.58);
    final iconSize = math.min(_quickActionIconSize, buttonSize * 0.42);

    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _pressController]),
      builder: (context, _) {
        final intro = Curves.easeOutCubic.transform(_introController.value);
        final press = Curves.easeOutCubic.transform(_pressController.value);

        return Opacity(
          opacity: intro,
          child: Transform.translate(
            offset: Offset(0, ((1 - intro) * 10) + (press * 2)),
            child: Transform.scale(
              scale: (0.986 + (intro * 0.014)) - (press * 0.024),
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  label: '${widget.label}. ${widget.subtitle}',
                  child: Tooltip(
                    message: '${widget.label}: ${widget.subtitle}',
                    child: InkWell(
                      onTapDown: _handleTapDown,
                      onTapCancel: _handleTapCancel,
                      onTapUp: (_) => _handleTapCancel(),
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(999),
                      overlayColor: WidgetStatePropertyAll(
                        Colors.white.withValues(alpha: 0.06),
                      ),
                      child: SizedBox(
                        width: itemWidth,
                        height: 88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF111418),
                                border: Border.all(
                                  color: const Color(0xFF2A3037),
                                  width: 1.1,
                                ),
                              ),
                              child: Center(
                                child: _HomeActionIcon(
                                  kind: widget.kind,
                                  press: press,
                                  size: iconSize,
                                  iconColor: Colors.white.withValues(
                                    alpha: 0.76,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall!.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
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

class _HomeActionIcon extends StatelessWidget {
  final _HomeActionIconKind kind;
  final double press;
  final Color iconColor;
  final double size;

  const _HomeActionIcon({
    required this.kind,
    required this.iconColor,
    this.press = 0,
    this.size = _quickActionIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, press * 1.1),
      child: Transform.scale(scale: 1 - (press * 0.03), child: _buildIcon()),
    );
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
        return Icon(LucideIcons.repeat2, size: size, color: iconColor);
      case _HomeActionIconKind.sendOnChain:
        return Icon(LucideIcons.link, size: size, color: iconColor);
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

class _ActionPanelButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _HomeActionIconKind? kind;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ActionPanelButton({
    required this.label,
    required this.icon,
    this.kind,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceBase = Color.lerp(
      const Color(0xFF111418),
      backgroundColor,
      0.18,
    )!;

    return BouncingButtonWrapper(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: surfaceBase,
            border: Border.all(color: const Color(0xFF282E35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (kind != null)
                  _HomeActionIcon(
                    kind: kind!,
                    size: 18,
                    iconColor: foregroundColor.withValues(alpha: 0.86),
                  )
                else
                  Icon(
                    icon,
                    size: 18,
                    color: foregroundColor.withValues(alpha: 0.86),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: foregroundColor.withValues(alpha: 0.58),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
