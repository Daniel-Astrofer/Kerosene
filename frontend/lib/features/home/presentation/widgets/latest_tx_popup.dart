import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'tx_detail_overlay.dart';

class LatestTxPopup extends ConsumerStatefulWidget {
  const LatestTxPopup({super.key});

  @override
  ConsumerState<LatestTxPopup> createState() => _LatestTxPopupState();
}

class _LatestTxPopupState extends ConsumerState<LatestTxPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Transaction? _lastShownTx;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    _controller.forward();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(filteredTransactionsProvider);

    return txsAsync.when(
      data: (txs) {
        if (txs.isEmpty) return const SizedBox.shrink();
        final latestTx = txs.first;

        // Auto-show when new transaction detected
        if (_lastShownTx == null || _lastShownTx!.id != latestTx.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastShownTx = latestTx;
            _show();
          });
        }

        return SlideTransition(
          position: _offsetAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GlassContainer(
                blur: 24,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _getColorFor(latestTx.type).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                child: GestureDetector(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, anim1, anim2) => TxDetailOverlay(
                        tx: latestTx,
                        onClose: () => Navigator.pop(context),
                      ),
                      transitionBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(
                          opacity: anim1,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
                            ),
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.transparent, // Ensure full area is tappable
                    child: Row(
                      children: [
                        _buildIconBadge(latestTx),
                        const SizedBox(width: 12),
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
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatBTC(latestTx.amountBTC),
                                style: AppTypography.number.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                ),
                              ),
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
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(latestTx.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusLabel(latestTx.status),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(latestTx.status),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getColorFor(tx.type).withValues(alpha: 0.1),
          ),
        ),
        Icon(
          _getIconFor(tx.type),
          color: _getColorFor(tx.type),
          size: 20,
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
              border: Border.all(color: _getColorFor(tx.type).withValues(alpha: 0.5), width: 1),
            ),
            child: Icon(
              LucideIcons.bitcoin,
              color: AppColors.warning,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive: return LucideIcons.arrowDownLeft;
      case TransactionType.send: return LucideIcons.arrowUpRight;
      case TransactionType.deposit: return LucideIcons.download;
      case TransactionType.withdrawal: return LucideIcons.upload;
      default: return LucideIcons.arrowRight;
    }
  }

  Color _getColorFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive:
      case TransactionType.deposit: return AppColors.success;
      case TransactionType.send: return AppColors.error;
      case TransactionType.withdrawal: return AppColors.warning;
      default: return AppColors.secondary;
    }
  }

  String _getLabelFor(TransactionType type) {
    switch (type) {
      case TransactionType.receive: return 'Recebido';
      case TransactionType.send: return 'Enviado';
      case TransactionType.deposit: return 'Depósito';
      case TransactionType.withdrawal: return 'Saque';
      default: return 'Transação';
    }
  }

  String _formatBTC(double v) => '${v.toStringAsFixed(8)} BTC';

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    return '${diff.inMinutes}m atrás';
  }

  Color _getStatusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.confirmed: return AppColors.success;
      case TransactionStatus.pending: return AppColors.warning;
      case TransactionStatus.failed: return AppColors.error;
      default: return AppColors.grey;
    }
  }

  String _getStatusLabel(TransactionStatus s) => s.name.toUpperCase();
}
