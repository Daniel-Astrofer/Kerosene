import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/widgets/state_feedback_view.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/providers/ghost_mode_provider.dart';
import 'package:teste/l10n/l10n_extension.dart';

import 'package:teste/features/wallet/domain/entities/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/balance_websocket_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import '../../../wallet/presentation/widgets/wallet_credit_card.dart';
import '../../../wallet/presentation/screens/send_money_screen.dart';
import '../../../wallet/presentation/screens/receive_screen.dart';
import '../widgets/nfc_searching_overlay.dart';
import '../../../transactions/presentation/screens/withdraw_screen.dart';
import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';
import '../widgets/animated_tx_icon.dart';
import '../widgets/latest_tx_popup.dart';
import '../widgets/tx_detail_overlay.dart';
import '../../../security/presentation/screens/sovereignty_status_screen.dart';

// ─── Riverpod Provider para o Popup ──────────────────────────────────────────
final txPopupProvider = ChangeNotifierProvider<TxPopupNotifier>((ref) {
  return TxPopupNotifier();
});

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

  bool get active => _active;
  TxPopupStatus get status => _status;
  bool get isSent => _isSent;
  String get label => _label;
  String get address => _address;
  String get amount => _amount;
  String get time => _time;

  void show(
      {required bool isSent,
      required String label,
      required String address,
      required String amount,
      required String time}) {
    _active = true;
    _status = TxPopupStatus.idle;
    _isSent = isSent;
    _label = label;
    _address = address;
    _amount = amount;
    _time = time;
    notifyListeners();
  }

  void showLoading() {
    _active = true;
    _status = TxPopupStatus.loading;
    _label = 'Atualizando...';
    _address = 'Verificando rede Tor';
    _amount = '...';
    _time = 'agora';
    notifyListeners();
  }

  void showSuccess() {
    _status = TxPopupStatus.success;
    _label = 'Sincronizando ao Servidor';
    _address = 'Sincronizado';
    notifyListeners();
  }

  void hide() {
    _active = false;
    _status = TxPopupStatus.idle;
    notifyListeners();
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isNfcSearching = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<Color> _scaffoldBgColor =
      ValueNotifier<Color>(AppColors.surface);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateBgColor);
  }

  void _updateBgColor() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset < 300) {
      if (_scaffoldBgColor.value != AppColors.surface) {
        _scaffoldBgColor.value = AppColors.surface;
      }
    } else if (_scrollController.offset >
        _scrollController.position.maxScrollExtent - 200) {
      if (_scaffoldBgColor.value != AppColors.darkGrey) {
        _scaffoldBgColor.value = AppColors.darkGrey;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scaffoldBgColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<ReceivedTxEvent?>(receivedTxEventProvider, (previous, next) {
      if (next != null && mounted) {
        showDialog(
          context: context,
          barrierColor: AppColors.black.withOpacity(0.8),
          builder: (_) => TransactionSuccessDialog(
            type: TransactionType.receive,
            amount: next.amount,
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
              amount: '+${next.amount} BTC',
              time: 'agora',
            );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final ghostMode = ref.watch(ghostModeProvider);
    ref.watch(balanceWebSocketServiceProvider);

    // ── NOME DE USUÁRIO REAL E SEGURO ──
    String userName = '';

    if (authState is AuthAuthenticated) {
      final fullName = authState.user.name.trim();
      if (fullName.isNotEmpty) {
        userName =
            fullName.split(' ').first; // Pega o primeiro nome para UI limpa
      }
    } else if (walletState is WalletLoaded &&
        walletState.selectedWallet != null) {
      userName = walletState.selectedWallet!.name;
    } else if (authState is AuthLoading) {
      userName = '...';
    }

    if (userName.isEmpty || userName == 'Not Found') {
      userName = 'Usuário';
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Backgrounds (agora protegidos por ExcludeSemantics)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: ExcludeSemantics(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -100,
                      width: 400,
                      height: 400,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: ExcludeSemantics(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor,
                      colorScheme.primary.withOpacity(0.08),
                      colorScheme.secondary.withOpacity(0.12),
                      theme.scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            height: 120,
            child: const LatestTxPopup(),
          ),

          RefreshIndicator(
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            onRefresh: () async {
              await ref.read(walletProvider.notifier).refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -100,
                            left: -100,
                            width: 400,
                            height: 400,
                            child: ExcludeSemantics(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      colorScheme.secondary.withOpacity(0.3),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const SizedBox(
                                  height: AppSpacing.xxl + AppSpacing.sm),
                              Text(
                                context.l10n.helloUser(userName),
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.white.withOpacity(0.5),
                                  letterSpacing: -0.32,
                                ),
                              )
                                  .animate()
                                  .fade(duration: 300.ms)
                                  .slideY(begin: 0.05, end: 0),
                              const SizedBox(height: AppSpacing.lg),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: _OperationalSummaryCard(
                                  accountStatus: authState is AuthAuthenticated
                                      ? 'Autenticada'
                                      : authState is AuthLoading
                                          ? 'Verificando'
                                          : 'Pendente',
                                  walletStatus: walletState is WalletLoaded
                                      ? walletState.wallets.isEmpty
                                          ? 'Nenhuma carteira'
                                          : walletState.wallets.length == 1
                                              ? '1 carteira ativa'
                                              : '${walletState.wallets.length} carteiras ativas'
                                      : 'Sincronizando carteiras',
                                  protectionStatus:
                                      walletState is WalletLoaded &&
                                              walletState.selectedWallet != null
                                          ? _formatAccountSecurityLabel(
                                              walletState.selectedWallet!
                                                  .accountSecurity,
                                            )
                                          : 'Sem carteira',
                                  privacyStatus: ghostMode
                                      ? 'Rede onion ativa'
                                      : 'Conexão direta',
                                  onOpenSovereignty: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SovereigntyStatusScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.xl,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppColors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₿',
                                            style: theme.textTheme.displayLarge!
                                                .copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w100,
                                            ),
                                          ),
                                          if (walletState is WalletLoaded &&
                                              walletState.selectedWallet !=
                                                  null) ...[
                                            (() {
                                              final balanceStr = walletState
                                                  .selectedWallet!.balance
                                                  .toStringAsFixed(8);
                                              final parts =
                                                  balanceStr.split('.');
                                              final wholePart = parts[0];
                                              final decimalPart =
                                                  parts.length > 1
                                                      ? parts[1]
                                                      : '00000000';
                                              final mainDecimals =
                                                  decimalPart.length >= 3
                                                      ? decimalPart.substring(
                                                          0,
                                                          3,
                                                        )
                                                      : decimalPart;
                                              final subDecimals =
                                                  decimalPart.length > 3
                                                      ? decimalPart.substring(3)
                                                      : '';

                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    ' $wholePart',
                                                    style: theme
                                                        .textTheme.displayLarge!
                                                        .copyWith(
                                                      color: colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.55),
                                                      fontWeight:
                                                          FontWeight.w100,
                                                    ),
                                                  ),
                                                  Text(
                                                    '.',
                                                    style: theme
                                                        .textTheme.titleMedium!
                                                        .copyWith(
                                                      color: colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.55),
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      height: 2.2,
                                                    ),
                                                  ),
                                                  Text(
                                                    mainDecimals,
                                                    style: theme
                                                        .textTheme.titleLarge!
                                                        .copyWith(
                                                      color: colorScheme
                                                          .onPrimary
                                                          .withOpacity(0.55),
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  if (subDecimals.isNotEmpty)
                                                    Text(
                                                      subDecimals,
                                                      style: theme
                                                          .textTheme.labelSmall!
                                                          .copyWith(
                                                        color: colorScheme
                                                            .onPrimary
                                                            .withOpacity(
                                                          0.25,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w200,
                                                        fontSize: 10,
                                                        height: 2.5,
                                                      ),
                                                    ),
                                                ],
                                              );
                                            })(),
                                          ] else ...[
                                            Text(
                                              ' 0.000',
                                              style: theme
                                                  .textTheme.displayLarge!
                                                  .copyWith(
                                                color: colorScheme.onPrimary
                                                    .withOpacity(0.55),
                                                fontWeight: FontWeight.w100,
                                              ),
                                            ),
                                            Text(
                                              '.',
                                              style: theme
                                                  .textTheme.titleMedium!
                                                  .copyWith(
                                                color: colorScheme.onPrimary
                                                    .withOpacity(0.55),
                                                fontWeight: FontWeight.w100,
                                                height: 2.2,
                                              ),
                                            ),
                                            Text(
                                              '00',
                                              style: theme.textTheme.titleLarge!
                                                  .copyWith(
                                                color: colorScheme.onPrimary
                                                    .withOpacity(0.55),
                                                fontWeight: FontWeight.w100,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: 303,
                                        height: 175,
                                        child: walletState is WalletLoaded &&
                                                walletState.selectedWallet !=
                                                    null
                                            ? WalletCreditCard(
                                                wallet:
                                                    walletState.selectedWallet!,
                                                colorIndex: 0,
                                                isSelected: true,
                                                showDetails: true,
                                              )
                                            : GlassContainer(
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.plus,
                                                        color: colorScheme
                                                            .primary
                                                            .withOpacity(0.5),
                                                        size: 32,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Adicionar carteira',
                                                        style: theme.textTheme
                                                            .labelMedium!
                                                            .copyWith(
                                                          color: colorScheme
                                                              .onPrimary
                                                              .withOpacity(
                                                            0.45,
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
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _QuickActionBtn(
                                      icon: LucideIcons.arrowUpRight,
                                      label: context.l10n.send,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (walletState is WalletLoaded &&
                                            walletState.selectedWallet !=
                                                null) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      SendMoneyScreen(
                                                          walletId: walletState
                                                              .selectedWallet!
                                                              .id)));
                                        }
                                      },
                                    ),
                                    _QuickActionBtn(
                                      icon: LucideIcons.arrowDownLeft,
                                      label: context.l10n.receive,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (walletState is WalletLoaded &&
                                            walletState.selectedWallet !=
                                                null) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => ReceiveScreen(
                                                      initialWallet: walletState
                                                          .selectedWallet!)));
                                        }
                                      },
                                    ),
                                    _QuickActionBtn(
                                      icon: LucideIcons.arrowUpRight,
                                      label: 'Saque',
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (walletState is WalletLoaded &&
                                            walletState.selectedWallet !=
                                                null) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => WithdrawScreen(
                                                      wallet: walletState
                                                          .selectedWallet!)));
                                        }
                                      },
                                    ),
                                    _QuickActionBtn(
                                      icon: LucideIcons.download,
                                      label: 'Depósito',
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.pushNamed(
                                            context, '/deposits');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  height: AppSpacing.xl + AppSpacing.md),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl + AppSpacing.sm),
                              child: Text(
                                context.l10n.recentTransactions,
                                style: theme.textTheme.titleMedium!,
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
              ],
            ),
          ),

          if (_isNfcSearching)
            Positioned.fill(
              child: NfcSearchingOverlay(
                onCancel: () => setState(() => _isNfcSearching = false),
                onTagRead: (tagData) {
                  setState(() => _isNfcSearching = false);
                },
              ),
            ),

          const _TxPopupWidget(
            restingTop: -70.0,
            activeTop: 50.0,
          ),
        ],
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
        final topPos = widget.restingTop -
            (widget.restingTop - widget.activeTop) * _slideAnimation.value;
        return Positioned(
          top: topPos,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 314,
              height: 55.6,
              child: Container(
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  border: Border.all(color: const Color(0x0DFFFFFF)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (popupState.status !=
                                      TxPopupStatus.loading)
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: popupState.status ==
                                                  TxPopupStatus.success
                                              ? const Color(0xFF00FF11)
                                                  .withOpacity(0.8)
                                              : const Color(0x33FFFFFF),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  if (popupState.status ==
                                      TxPopupStatus.loading)
                                    ExcludeSemantics(
                                      // Spinner rotativo blindado
                                      child: Transform.rotate(
                                        angle: _spinAnimation.value,
                                        child: CustomPaint(
                                          size: const Size(30, 30),
                                          painter: _SpinningArcPainter(
                                              color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  if (popupState.status ==
                                      TxPopupStatus.loading)
                                    const Icon(Icons.sync_rounded,
                                        color: AppColors.primary, size: 14)
                                  else
                                    Icon(
                                      popupState.status == TxPopupStatus.success
                                          ? Icons.check_rounded
                                          : (popupState.isSent
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward),
                                      color: popupState.status ==
                                              TxPopupStatus.success
                                          ? const Color(0xFF00FF11)
                                          : const Color(0xFFFF9500),
                                      size: popupState.status ==
                                              TxPopupStatus.success
                                          ? 16
                                          : 12,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  popupState.label,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  popupState.address,
                                  style: AppTypography.caption.copyWith(
                                    fontFamily: 'JetBrainsMono',
                                    color: theme.colorScheme.onPrimary
                                        .withOpacity(0.7),
                                    fontSize: 9,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              popupState.amount,
                              style: AppTypography.bodyMedium.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                height: 1,
                              ),
                            ),
                            Text(
                              popupState.time,
                              style: AppTypography.caption.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 9,
                                height: 1.2,
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
