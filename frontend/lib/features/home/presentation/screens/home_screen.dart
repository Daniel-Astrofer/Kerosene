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
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/widgets/state_feedback_view.dart';
import 'package:teste/core/widgets/animated_typewriter_text.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
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
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
import '../../../wallet/presentation/screens/deposit/deposit_amount_screen.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/nfc_interaction_screen.dart';
import '../../../wallet/presentation/screens/receive_hub_screen.dart';
import '../widgets/animated_balance_display.dart';
import '../../../transactions/presentation/screens/withdraw_screen.dart';
import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';
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

Route<T> _buildBottomUpRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.78,
          end: 1.0,
        ).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
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

  void show(
      {required bool isSent,
      required String label,
      required String address,
      required String amount,
      required String time}) {
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

        showDialog(
          context: context,
          barrierColor: AppColors.black.withValues(alpha: 0.8),
          builder: (_) => TransactionSuccessDialog(
            type: TransactionType.receive,
            amountBtc: next.amount,
            counterparty: next.sender,
          ),
        );

        final sender = next.sender ?? '';
        final shortAddress = sender.length > 12
            ? '${sender.substring(0, 6)}...${sender.substring(sender.length - 4)}'
            : sender;

        ref.read(txPopupProvider).show(
              isSent: false,
              label: 'Recebido',
              address: shortAddress,
              amount: MoneyDisplay.formatAmountFromBtc(
                btcAmount: next.amount,
                currency: selectedCurrency,
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
                signed: true,
              ),
              time: 'agora',
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
      title: 'Carteira necessária',
      message: 'Selecione ou crie uma carteira antes de usar esta ação.',
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
    return Navigator.of(
      context,
    ).push<T>(_buildBottomUpRoute(builder: builder));
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
              : 'Operação concluída';

      showDialog(
        context: context,
        barrierColor: AppColors.black.withValues(alpha: 0.8),
        builder: (_) => TransactionSuccessDialog(
          type: TransactionType.send,
          amountBtc: amountBtc > 0 ? amountBtc : null,
          counterparty: counterparty,
        ),
      );

      ref.read(txPopupProvider).show(
            isSent: true,
            label: 'Enviado',
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
            time: 'agora',
          );
      return;
    }

    if (result is PaymentLink) {
      final counterparty = result.description.isNotEmpty
          ? result.description
          : result.depositAddress;

      showDialog(
        context: context,
        barrierColor: AppColors.black.withValues(alpha: 0.8),
        builder: (_) => TransactionSuccessDialog(
          type: TransactionType.send,
          amountBtc: result.amountBtc > 0 ? result.amountBtc : null,
          counterparty: counterparty,
        ),
      );

      ref.read(txPopupProvider).show(
            isSent: true,
            label: 'Pago',
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
            time: 'agora',
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
      _openWithdrawFlow(
        wallet: wallet,
        entryMode: WithdrawEntryMode.onChain,
      ),
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
      _openWithdrawFlow(
        wallet: wallet,
        entryMode: WithdrawEntryMode.lightning,
      ),
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
      _pushFromBottom<void>(
        (_) => ReceiveHubScreen(initialWallet: wallet),
      ),
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
        message: 'NFC não está disponível neste dispositivo no momento.',
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

  void _openSendPaymentLink(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final insets = MediaQuery.of(context).viewInsets.bottom;
        return GlassContainer(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            insets + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Link de pagamento',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cole o payload completo ou somente o ID do link para continuar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.64),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: controller,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontFamily: 'JetBrainsMono',
                    ),
                decoration: InputDecoration(
                  hintText: 'kerosene://payment/pay/abc123 ou abc123',
                  hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.28),
                      ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  final normalized =
                      _normalizePaymentLinkPayload(controller.text);
                  if (normalized == null) {
                    AppNotice.showWarning(
                      context,
                      title: 'Link inválido',
                      message: 'Informe um link de pagamento válido.',
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _routeSendPayload(wallet, normalized);
                },
                icon: const Icon(LucideIcons.arrowUpRight),
                label: const Text('CONTINUAR'),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _normalizePaymentLinkPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (QrPaymentParser.extractPaymentLinkId(trimmed) != null) {
      return trimmed;
    }
    if (QrPaymentParser.decode(trimmed) != null ||
        trimmed.toLowerCase().startsWith('bitcoin:') ||
        trimmed.toLowerCase().startsWith('lightning:') ||
        _looksLikeLightningRequest(trimmed) ||
        _looksLikeOnChainRequest(trimmed, trimmed)) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return 'kerosene:link:$last';
      }
    }

    return 'kerosene:link:$trimmed';
  }

  void _routeSendPayload(Wallet wallet, String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (QrPaymentParser.extractPaymentLinkId(trimmed) != null) {
      unawaited(
        _openSendFlow(
          wallet: wallet,
          initialAddress: trimmed,
        ),
      );
      return;
    }

    final parsed = QrPaymentParser.decode(trimmed);
    final candidate = parsed?.address ?? trimmed;

    if (_looksLikeLightningRequest(candidate)) {
      AppNotice.showInfo(
        context,
        title: context.l10n.lightning,
        message:
            'Envios Lightning ainda não estão disponíveis no backend atual. Use um destino on-chain ou transferência interna.',
      );
      return;
    }

    if (_looksLikeOnChainRequest(trimmed, candidate)) {
      unawaited(
        _openWithdrawFlow(
          wallet: wallet,
          entryMode: WithdrawEntryMode.onChain,
          initialDestination: trimmed,
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

  bool _looksLikeOnChainRequest(String raw, String candidate) {
    final trimmedRaw = raw.trim().toLowerCase();
    final trimmedCandidate = candidate.trim();

    return trimmedRaw.startsWith('bitcoin:') ||
        RegExp(r'^(1|3|bc1|m|n|2|tb1)[a-zA-HJ-NP-Z0-9]{20,90}$')
            .hasMatch(trimmedCandidate);
  }

  void _openDeposit(WalletState walletState) {
    final wallet = _resolveActiveWallet(walletState);
    HapticFeedback.lightImpact();

    if (wallet == null) {
      _showWalletRequiredNotice();
      return;
    }

    unawaited(
      _pushFromBottom<void>(
        (_) => DepositAmountScreen(wallet: wallet),
      ),
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
        label: 'Cheque',
        subtitle: 'Transferência interna',
        onTap: () => _openSend(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.sendOnChain,
        label: 'Enviar On-chain',
        subtitle: 'Saque para endereço BTC',
        onTap: () => _openSendOnChain(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.payLightning,
        label: 'Pagar Lightning',
        subtitle: 'Invoice ou LNURL',
        onTap: () => _openSendLightning(walletState),
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.scanQr,
        label: 'Escanear QR',
        subtitle: 'Ler invoice ou endereco',
        onTap: () {
          unawaited(_openSendQr(walletState));
        },
      ),
      _QuickActionData(
        kind: _HomeActionIconKind.payLink,
        label: 'Link de pagamento',
        subtitle: 'Checkout interno ou ID',
        onTap: () => _openSendPaymentLink(walletState),
      ),
    ];

    if (_isNfcAvailable) {
      actions.add(
        _QuickActionData(
          kind: _HomeActionIconKind.sendNfc,
          label: 'Pagar por NFC',
          subtitle: 'Aproxime para iniciar',
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
    final navigationClearance =
        AppPrimaryNavigationBar.scaffoldBottomClearance(context);

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
    final hasSeenFirstUseActionPanel =
        _hasSeenFirstUseActionPanel(authenticatedUserId);

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
                          constraints: const BoxConstraints(maxWidth: 540),
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
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: Column(
                              children: [
                                if (showPrimaryActionPanel) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                    ),
                                    child: _PrimaryActionPanel(
                                      icon: !hasWallet
                                          ? LucideIcons.wallet
                                          : !hasBalance
                                              ? LucideIcons.download
                                              : LucideIcons.arrowUpRight,
                                      title: !hasWallet
                                          ? 'Estruture sua carteira principal'
                                          : !hasBalance
                                              ? 'Carteira pronta para uso'
                                              : 'Operacoes prontas para executar',
                                      subtitle: !hasWallet
                                          ? 'Crie sua carteira para habilitar recebimentos, transferencias e monitoramento com seguranca.'
                                          : !hasBalance
                                              ? 'Você pode depositar quando quiser e acompanhar a confirmacao da rede em tempo real.'
                                              : 'Acesse as operacoes essenciais da carteira com confirmacao clara e fluxo objetivo.',
                                      primaryLabel: !hasWallet
                                          ? 'Criar carteira'
                                          : !hasBalance
                                              ? 'Depositar fundos'
                                              : 'Enviar BTC',
                                      primaryIconKind: !hasWallet
                                          ? _HomeActionIconKind.createWallet
                                          : !hasBalance
                                              ? _HomeActionIconKind
                                                  .primaryDeposit
                                              : _HomeActionIconKind.primarySend,
                                      primaryIcon: !hasWallet
                                          ? LucideIcons.plus
                                          : !hasBalance
                                              ? LucideIcons.download
                                              : LucideIcons.arrowUpRight,
                                      onPrimaryTap: !hasWallet
                                          ? _openCreateWallet
                                          : !hasBalance
                                              ? () => _openDeposit(
                                                    walletState,
                                                  )
                                              : () => _openSend(
                                                    walletState,
                                                  ),
                                      secondaryLabel: hasWallet && hasBalance
                                          ? 'Receber BTC'
                                          : hasWallet
                                              ? 'Ver depositos'
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
                                          ? () => _openReceiveHub(
                                                walletState,
                                              )
                                          : hasWallet
                                              ? () => unawaited(
                                                    _pushFromBottom<void>(
                                                      (_) =>
                                                          const DepositsScreen(
                                                        showPrimaryNavigation:
                                                            true,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _HomeActionSection(
                                          title: 'Enviar',
                                          actions: _buildSendActions(
                                            walletState,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.xl,
                                        ),
                                        _ReceiveTransferTextPanel(
                                          onTap: () => _openReceiveHub(
                                            walletState,
                                          ),
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
                                    constraints:
                                        const BoxConstraints(maxWidth: 500),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                AppSpacing.xl + AppSpacing.sm,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.l10n.recentTransactions,
                                                style: theme
                                                    .textTheme.titleMedium!
                                                    .copyWith(
                                                  fontWeight: FontWeight.w700,
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
          const _TxPopupWidget(
            restingTop: -92.0,
            activeTop: 12.0,
          ),
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
    final selectedCurrency = ref.watch(currencyProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final notificationCount = ref.watch(sessionNotificationFeedProvider).length;
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final activeBalanceBtc = activeWallet?.balance ?? 0.0;
    final quoteCurrency =
        selectedCurrency == Currency.btc ? Currency.brl : selectedCurrency;
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
        height: 316,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                              side: const BorderSide(
                                color: Color(0xFF242A31),
                              ),
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
                    style: theme.textTheme.displayLarge!.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.94),
                      fontWeight: FontWeight.w600,
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

  const _BalanceVisibilityButton({
    required this.icon,
    required this.onTap,
  });

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
    _springAnimation = Tween<Offset>(
      begin: Offset(_tiltX, _tiltY),
      end: Offset.zero,
    ).animate(
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
              width: 303,
              height: 191,
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

  const _PriceTick({
    required this.timestamp,
    required this.price,
  });
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
    final trendIsUp = _priceHistory.length < 2 ||
        _priceHistory.last.price >= _priceHistory.first.price;
    final lineColor =
        trendIsUp ? const Color(0xFF15D07A) : const Color(0xFFD84C5D);
    final lineGlowColor =
        trendIsUp ? const Color(0x4515D07A) : const Color(0x45D84C5D);

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

    final windowStart =
        now.subtract(_HomeLiveBitcoinBackdropState._historyWindow);
    final visibleTicks = history
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
      final normalized = ((clampedPrice - (center - displayHalfRange)) /
              (displayHalfRange * 2))
          .clamp(0.0, 1.0);
      final softened = 0.5 + (math.sin((normalized - 0.5) * math.pi) * 0.5);
      final y = (size.height - verticalPadding) -
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
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midpoint.dx,
        midpoint.dy,
      );
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

    _spinController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _spinAnimation =
        Tween<double>(begin: 0, end: 2 * 3.14159265).animate(_spinController);

    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation =
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic);
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
                                        painter:
                                            _SpinningArcPainter(color: accent),
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

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}m atrás';
    if (diff.inDays < 1) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'Ontem ${_pad(dt.hour)}:${_pad(dt.minute)}';
    return '${_pad(dt.day)}/${_pad(dt.month)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  static _StatusStyle _statusStyle(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return const _StatusStyle(
            'Pendente', Color(0xFFC6A96B), LucideIcons.hourglass);
      case TransactionStatus.confirming:
        return const _StatusStyle(
            'Confirmando', Color(0xFFC6A96B), LucideIcons.loader2);
      case TransactionStatus.confirmed:
        return const _StatusStyle(
            'Confirmada', Color(0xFFA8C7B1), LucideIcons.clipboardCheck);
      case TransactionStatus.failed:
        return const _StatusStyle(
            'Cancelada', Color(0xFFD59A9A), LucideIcons.clipboardX);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredtxsAsync = ref.watch(filteredTransactionsProvider);
    final walletState = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final activeWallet = walletState is WalletLoaded
        ? walletState.selectedWallet ??
            (walletState.wallets.isNotEmpty ? walletState.wallets.first : null)
        : null;

    return filteredtxsAsync.when(
      data: (txs) {
        if (txs.isEmpty) {
          final hasWallet = activeWallet != null;
          final hasBalance = (activeWallet?.balance ?? 0) > 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: StateFeedbackView.empty(
              title: !hasWallet
                  ? 'Crie sua primeira carteira'
                  : !hasBalance
                      ? 'Adicione saldo para começar'
                      : 'Sem transações recentes',
              description: !hasWallet
                  ? 'Você precisa de uma carteira para começar a movimentar.'
                  : !hasBalance
                      ? 'Assim que entrar o primeiro depósito, suas movimentações aparecem aqui.'
                      : 'Novas movimentações vão aparecer automaticamente nesta área.',
              actionLabel: !hasWallet
                  ? 'Criar carteira'
                  : !hasBalance
                      ? 'Depositar'
                      : 'Atualizar',
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
                      builder: (_) => DepositAmountScreen(
                        wallet: activeWallet,
                      ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
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
                final status = _statusStyle(tx.status);
                final amountLabel = MoneyDisplay.formatAmountFromBtc(
                  btcAmount: tx.amountBTC,
                  currency: selectedCurrency,
                  btcUsd: btcUsd,
                  btcEur: btcEur,
                  btcBrl: btcBrl,
                );

                return InkWell(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black.withValues(alpha: 0.55),
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, anim1, anim2) => TxDetailOverlay(
                        tx: tx,
                        onClose: () => Navigator.pop(context),
                      ),
                      transitionBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(
                          opacity: anim1,
                          child: child,
                        );
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
                                  visual.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.88),
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
                                        '${status.label} · ${_formatDate(tx.timestamp)}',
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
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: visual.amountColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (txs.length > visibleTxs.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
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
                    child: const Text('Ver histórico completo'),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: StateFeedbackView(
          state: FeedbackState.loading,
          title: 'A carregar…',
          description: 'Sincronizando dispositivo.',
        ),
      ),
      error: (e, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: StateFeedbackView.networkError(
          onAction: () => ref.refresh(transactionHistoryProvider),
        ),
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
                    letterSpacing: -0.4,
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

  const _HomeActionSection({
    required this.title,
    required this.actions,
  });

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
            letterSpacing: -0.16,
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
      label: 'Abrir tela de recebimento',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crie uma transferência',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'para ser paga por outra pessoa',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gere uma cobrança com destino e valor definidos por link de pagamento, QR, on-chain ou Lightning.',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: Colors.white.withValues(alpha: 0.58),
                  height: 1.35,
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

class _HomeQuickActionsRow extends StatelessWidget {
  final List<_QuickActionData> actions;

  const _HomeQuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
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
              onTap: actions[index].onTap,
            ),
          ],
        ],
      ),
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
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.index,
    required this.kind,
    required this.label,
    required this.subtitle,
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

    Future<void>.delayed(
      Duration(milliseconds: 120 + (widget.index * 70)),
      () {
        if (!mounted) {
          return;
        }
        _introController.forward();
      },
    );
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
                        width: _quickActionItemWidth,
                        height: 88,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: _quickActionButtonSize,
                              height: _quickActionButtonSize,
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
                                  iconColor:
                                      Colors.white.withValues(alpha: 0.76),
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
                            const SizedBox(height: AppSpacing.md),
                            const _TransactionsList(),
                            const SizedBox(height: 100),
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
      child: Transform.scale(
        scale: 1 - (press * 0.03),
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (kind) {
      case _HomeActionIconKind.createWallet:
        return Icon(LucideIcons.badgePlus, size: size, color: iconColor);
      case _HomeActionIconKind.primaryDeposit:
        return Icon(LucideIcons.banknote, size: size, color: iconColor);
      case _HomeActionIconKind.primarySend:
        return Icon(LucideIcons.send, size: size, color: iconColor);
      case _HomeActionIconKind.primaryReceive:
        return Icon(LucideIcons.download, size: size, color: iconColor);
      case _HomeActionIconKind.viewDeposits:
        return Icon(LucideIcons.clipboardList, size: size, color: iconColor);
      case _HomeActionIconKind.internalTransfer:
        return Icon(LucideIcons.checkSquare, size: size, color: iconColor);
      case _HomeActionIconKind.sendOnChain:
        return Icon(LucideIcons.cloudHail, size: size, color: iconColor);
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
                      letterSpacing: -0.12,
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

  static String _abbrevAddress(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}';
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}m atrás';
    if (diff.inDays < 1) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'Ontem ${_pad(dt.hour)}:${_pad(dt.minute)}';
    return '${_pad(dt.day)}/${_pad(dt.month)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  static String _formatBTC(double v) {
    if (v < 0.00001) return '${(v * 1e8).toStringAsFixed(0)} sat';
    return '${v.toStringAsFixed(6)} BTC';
  }

  static _TxStyle _styleFor(Transaction tx) {
    switch (tx.type) {
      case TransactionType.receive:
        return const _TxStyle(
            icon: LucideIcons.arrowDownLeft,
            label: 'Recebido',
            prefix: '+',
            accent: AppColors.success,
            bg: AppColors.success);
      case TransactionType.send:
        return const _TxStyle(
            icon: LucideIcons.arrowUpRight,
            label: 'Enviado',
            prefix: '-',
            accent: AppColors.error,
            bg: AppColors.error);
      case TransactionType.deposit:
        return const _TxStyle(
            icon: LucideIcons.arrowDownLeft,
            label: 'Depósito',
            prefix: '+',
            accent: AppColors.success,
            bg: AppColors.success);
      case TransactionType.withdrawal:
        return const _TxStyle(
            icon: LucideIcons.arrowUpRight,
            label: 'Saque',
            prefix: '-',
            accent: AppColors.warning,
            bg: AppColors.warning);
      case TransactionType.swap:
        return const _TxStyle(
            icon: LucideIcons.arrowLeftRight,
            label: 'Swap',
            prefix: '',
            accent: AppColors.secondary,
            bg: AppColors.secondary);
      case TransactionType.fee:
        return const _TxStyle(
            icon: LucideIcons.zap,
            label: 'Taxa',
            prefix: '-',
            accent: AppColors.grey,
            bg: AppColors.grey);
    }
  }

  static TxIconKind _iconKindFor(Transaction tx) {
    switch (tx.type) {
      case TransactionType.receive:
        return TxIconKind.receive;
      case TransactionType.send:
        return TxIconKind.send;
      case TransactionType.deposit:
        return TxIconKind.deposit;
      case TransactionType.withdrawal:
        return TxIconKind.withdrawal;
      case TransactionType.swap:
        return TxIconKind.swap;
      case TransactionType.fee:
        return TxIconKind.fee;
    }
  }

  static TxIconKind? _methodIconKind(Transaction tx) {
    final desc = (tx.description ?? '').toLowerCase();
    if (desc.contains('nfc')) return TxIconKind.nfc;
    if (desc.contains('qr') || desc.contains('qrcode'))
      return TxIconKind.qrCode;
    return null;
  }

  static _StatusStyle _statusStyle(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return const _StatusStyle(
            'Pendente', AppColors.warning, LucideIcons.clock);
      case TransactionStatus.confirming:
        return const _StatusStyle(
            'Confirmando', AppColors.warning, LucideIcons.refreshCw);
      case TransactionStatus.confirmed:
        return const _StatusStyle(
            'Confirmada', AppColors.success, LucideIcons.checkCircle);
      case TransactionStatus.failed:
        return const _StatusStyle(
            'Falhou', AppColors.error, LucideIcons.alertCircle);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredtxsAsync = ref.watch(filteredTransactionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return filteredtxsAsync.when(
      data: (txs) {
        if (txs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: StateFeedbackView.empty(
              title: 'Sem transações',
              description:
                  'As tuas transações aparecerão aqui assim que realizares a primeira operação.',
              actionLabel: 'Atualizar',
              onAction: () => ref.refresh(transactionHistoryProvider),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final tx = txs[index];
            final style = _styleFor(tx);
            final status = _statusStyle(tx.status);
            final methodKind = _methodIconKind(tx);
            final txIconKind = _iconKindFor(tx);
            final counterparty = tx.type == TransactionType.send ||
                    tx.type == TransactionType.withdrawal
                ? tx.toAddress
                : tx.fromAddress;

            return InkWell(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: '',
                  barrierColor: colorScheme.onSurface.withOpacity(0.1),
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, anim1, anim2) => TxDetailOverlay(
                    tx: tx,
                    onClose: () => Navigator.pop(context),
                  ),
                  transitionBuilder: (context, anim1, anim2, child) {
                    return FadeTransition(
                      opacity: anim1,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                          CurvedAnimation(
                              parent: anim1, curve: Curves.easeOutBack),
                        ),
                        child: child,
                      ),
                    );
                  },
                );
              },
              borderRadius:
                  BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: style.bg.withOpacity(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: style.bg.withOpacity(0.22), width: 1),
                          ),
                          child: Center(
                            child: AnimatedTxIcon(
                              kind: txIconKind,
                              color: style.accent,
                              size: 24,
                            ),
                          ),
                        ),
                        if (methodKind != null)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: AppSpacing.lg,
                              height: AppSpacing.lg,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: colorScheme.surface, width: 1.5),
                              ),
                              child: Center(
                                child: AnimatedTxIcon(
                                  kind: methodKind,
                                  color: colorScheme.onPrimary.withOpacity(0.7),
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                style.label,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (tx.isInternal) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B61FF)
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Interno',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF7B61FF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _abbrevAddress(counterparty),
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: colorScheme.onPrimary.withOpacity(0.38),
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(status.icon, color: status.color, size: 10),
                              const SizedBox(width: AppSpacing.xs - 1),
                              Text(
                                status.label,
                                style: theme.textTheme.labelSmall!.copyWith(
                                    color: status.color,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10),
                              ),
                              if (tx.status ==
                                  TransactionStatus.confirming) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${tx.confirmations}/6',
                                  style: theme.textTheme.labelSmall!.copyWith(
                                      color: colorScheme.onPrimary
                                          .withOpacity(0.3),
                                      fontSize: 9),
                                ),
                              ],
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '·',
                                style: theme.textTheme.labelSmall!.copyWith(
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.2)),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _formatDate(tx.timestamp),
                                style: theme.textTheme.labelSmall!.copyWith(
                                    color:
                                        colorScheme.onPrimary.withOpacity(0.28),
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${style.prefix}${_formatBTC(tx.amountBTC)}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: style.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (tx.feeSatoshis > 0) ...[
                          const SizedBox(height: AppSpacing.xs - 1),
                          Text(
                            'Taxa ${_formatBTC(tx.feeBTC)}',
                            style: theme.textTheme.labelSmall!.copyWith(
                                color: colorScheme.onPrimary.withOpacity(0.25),
                                fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: StateFeedbackView(
          state: FeedbackState.loading,
          title: 'A carregar…',
          description: 'A sincronizar as tuas transações com a rede.',
        ),
      ),
      error: (e, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: StateFeedbackView.networkError(
          onAction: () => ref.refresh(transactionHistoryProvider),
        ),
      ),
    );
  }
}

class _TxStyle {
  final IconData icon;
  final String label;
  final String prefix;
  final Color accent;
  final Color bg;
  const _TxStyle(
      {required this.icon,
      required this.label,
      required this.prefix,
      required this.accent,
      required this.bg});
}

class _StatusStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.icon);
}

String _formatAccountSecurityLabel(String rawValue) {
  switch (rawValue.toUpperCase()) {
    case 'SHAMIR':
    case 'SHAMIR_SLIP39':
    case 'SLIP39':
      return 'Shamir SLIP-39';
    case 'MULTISIG':
    case 'MULTISIG_VAULT':
    case '2FA_MULTISIG':
      return 'Cofre multisig';
    case 'STANDARD':
    default:
      return 'Semente padrao';
  }
}

class _OperationalSummaryCard extends StatelessWidget {
  final String accountStatus;
  final String walletStatus;
  final String protectionStatus;
  final String privacyStatus;
  final VoidCallback onOpenSovereignty;

  const _OperationalSummaryCard({
    required this.accountStatus,
    required this.walletStatus,
    required this.protectionStatus,
    required this.privacyStatus,
    required this.onOpenSovereignty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo operacional',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Conta, carteiras, privacidade e postura de custódia visíveis sem dados sintéticos.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: AppColors.white.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _OperationalPill(label: 'Conta', value: accountStatus),
              _OperationalPill(label: 'Carteiras', value: walletStatus),
              _OperationalPill(label: 'Protecao', value: protectionStatus),
              _OperationalPill(label: 'Privacidade', value: privacyStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onOpenSovereignty,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Abrir relatorio de soberania',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.white.withOpacity(0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalPill extends StatelessWidget {
  final String label;
  final String value;

  const _OperationalPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: AppColors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Button ────────────────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          GlassContainer(
            blur: 20,
            opacity: 0.05,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: theme.textTheme.labelSmall!
                  .copyWith(color: theme.colorScheme.onPrimary)),
        ],
      ),
    );
  }
}
