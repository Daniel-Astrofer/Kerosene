import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'tx_detail_overlay.dart';

class LatestTxPopup extends ConsumerStatefulWidget {
  final bool suppressed;

  const LatestTxPopup({
    super.key,
    this.suppressed = false,
  });

  @override
  ConsumerState<LatestTxPopup> createState() => _LatestTxPopupState();
}

class _LatestTxPopupState extends ConsumerState<LatestTxPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  Transaction? _lastShownTx;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    _controller.forward(from: 0);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(filteredTransactionsProvider);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    return txsAsync.when(
      data: (txs) {
        if (txs.isEmpty) return const SizedBox.shrink();
        final latestTx = txs.first;

        if (widget.suppressed) {
          if (_controller.status != AnimationStatus.dismissed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _controller.reverse();
              }
            });
          }
          _lastShownTx = latestTx;
          return const SizedBox.shrink();
        }

        // Auto-show when new transaction detected
        if (_lastShownTx == null || _lastShownTx!.id != latestTx.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastShownTx = latestTx;
            _show();
          });
        }

        return IgnorePointer(
          ignoring: _controller.status == AnimationStatus.dismissed,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
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
                      child: GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: '',
                            barrierColor: Colors.black.withValues(alpha: 0.55),
                            transitionDuration:
                                const Duration(milliseconds: 400),
                            pageBuilder: (context, anim1, anim2) =>
                                TxDetailOverlay(
                              tx: latestTx,
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
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              _buildIconBadge(latestTx),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getLabelFor(latestTx.type).toUpperCase(),
                                      style: AppTypography.caption.copyWith(
                                        color: _getColorFor(latestTx.type),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      MoneyDisplay.formatAmountFromBtc(
                                        btcAmount: latestTx.amountBTC,
                                        currency: selectedCurrency,
                                        btcUsd: btcUsd,
                                        btcEur: btcEur,
                                        btcBrl: btcBrl,
                                      ),
                                      style: AppTypography.number.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 16,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    if (selectedCurrency != Currency.btc) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatBTC(latestTx.amountBTC),
                                        style: AppTypography.caption.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withValues(alpha: 0.52),
                                          fontSize: 10,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDate(latestTx.timestamp),
                                    style: AppTypography.caption.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.4),
                                      fontSize: 10,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF070B10),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusLabel(latestTx.status),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC7CDD6),
                                      ),
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
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildIconBadge(Transaction tx) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Icon(
          _getIconFor(tx.type),
          color: _getColorFor(tx.type),
          size: 16,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                  color: _getColorFor(tx.type).withValues(alpha: 0.5),
                  width: 1),
            ),
            child: Icon(
              LucideIcons.bitcoin,
              color: AppColors.warning,
              size: 8,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return LucideIcons.arrowDownLeft;
      case TransactionType.send:
        return LucideIcons.arrowUpRight;
      case TransactionType.deposit:
        return LucideIcons.download;
      case TransactionType.withdrawal:
        return LucideIcons.upload;
      default:
        return LucideIcons.arrowRight;
    }
  }

  Color _getColorFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
      case TransactionType.deposit:
        return AppColors.success;
      case TransactionType.send:
        return AppColors.error;
      case TransactionType.withdrawal:
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  String _getLabelFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
        return 'Recebido';
      case TransactionType.send:
        return 'Enviado';
      case TransactionType.deposit:
        return 'Depósito';
      case TransactionType.withdrawal:
        return 'Saque';
      default:
        return 'Transação';
    }
  }

  String _formatBTC(double v) => '${v.toStringAsFixed(8)} BTC';

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    return '${diff.inMinutes}m atrás';
  }

  String _getStatusLabel(TransactionStatus s) => s.name.toUpperCase();
}
