import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
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
        final visual = TransactionVisualSpec.fromTransaction(latestTx);

        // Seed with the current history entry so the popup is only used for
        // transactions that arrive after the screen is already mounted.
        if (_lastShownTx == null) {
          _lastShownTx = latestTx;
          return const SizedBox.shrink();
        }

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
        if (_lastShownTx!.id != latestTx.id) {
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
                      decoration: monochromePanelDecoration(
                        color: monoSurfaceColor,
                        borderColor: monoBorderStrongColor,
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
                              _buildIconBadge(visual),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visual.label.toUpperCase(),
                                      style: AppTypography.caption.copyWith(
                                        color: monoMutedTextColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 1.0,
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
                                        color: monoTextColor,
                                        fontSize: 16,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    if (selectedCurrency != Currency.btc) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatBTC(latestTx.amountBTC),
                                        style: AppTypography.caption.copyWith(
                                          color: monoMutedTextColor,
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
                                      color: monoFaintTextColor,
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
                                    decoration: monochromePanelDecoration(
                                      color: monoSurfaceAltColor,
                                      borderColor: monoBorderStrongColor,
                                      showShadow: false,
                                    ),
                                    child: Text(
                                      _getStatusLabel(latestTx.status),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: monoTextColor,
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

  Widget _buildIconBadge(TransactionVisualSpec visual) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: monochromePanelDecoration(
            color: monoSurfaceAltColor,
            borderColor: monoBorderStrongColor,
            showShadow: false,
          ),
        ),
        Icon(
          visual.icon,
          color: monoTextColor,
          size: 16,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: monochromePanelDecoration(
              color: monoSurfaceRaisedColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Icon(_secondaryIconFor(visual),
                color: monoMutedTextColor, size: 8),
          ),
        ),
      ],
    );
  }

  IconData _secondaryIconFor(TransactionVisualSpec visual) {
    switch (visual.family) {
      case TransactionVisualFamily.paymentLink:
        return LucideIcons.link;
      case TransactionVisualFamily.qrCode:
        return LucideIcons.scanLine;
      case TransactionVisualFamily.nfc:
        return LucideIcons.smartphoneNfc;
      case TransactionVisualFamily.lightning:
        return LucideIcons.zap;
      case TransactionVisualFamily.internalTransfer:
        return LucideIcons.receipt;
      default:
        return visual.isOutgoing
            ? LucideIcons.arrowUpRight
            : LucideIcons.arrowDownLeft;
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
