import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import '../../../wallet/domain/entities/transaction.dart';

class TransactionSuccessDialog extends ConsumerStatefulWidget {
  final TransactionType type;
  final double? amountBtc;
  final String? counterparty;

  const TransactionSuccessDialog({
    super.key,
    this.type = TransactionType.send,
    this.amountBtc,
    this.counterparty,
  });

  @override
  ConsumerState<TransactionSuccessDialog> createState() =>
      _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState
    extends ConsumerState<TransactionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _opacityAnimation;

  bool get _isReceived => widget.type == TransactionType.receive;
  Color get _color => AppNotificationStyle.accentFor(
        _isReceived ? AppNotificationTone.success : AppNotificationTone.warning,
      );
  IconData get _icon => _isReceived ? Icons.arrow_downward : Icons.arrow_upward;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-close after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final primaryAmount = widget.amountBtc == null
        ? null
        : MoneyDisplay.formatAmountFromBtc(
            btcAmount: widget.amountBtc!,
            currency: selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          );
    final secondaryAmount =
        widget.amountBtc == null || selectedCurrency == Currency.btc
            ? null
            : MoneyDisplay.format(
                amount: widget.amountBtc!,
                currency: Currency.btc,
              );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 296,
          constraints: const BoxConstraints(minHeight: 196),
          decoration: BoxDecoration(
            color: AppNotificationStyle.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppNotificationStyle.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: widget.type == TransactionType.send
                        ? CustomPaint(
                            painter: _CheckmarkPainter(
                              progress: _checkAnimation,
                              color: _color,
                            ),
                          )
                        : ScaleTransition(
                            scale: _checkAnimation,
                            child: Icon(_icon, color: _color, size: 24),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Column(
                    children: [
                      Text(
                        _isReceived ? "Received!" : "Sent!",
                        style: TextStyle(
                          color: AppNotificationStyle.titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (primaryAmount != null) ...[
                        Text(
                          primaryAmount,
                          style: TextStyle(
                            color: _color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansHebrew',
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (secondaryAmount != null) ...[
                          Text(
                            secondaryAmount,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.68),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                      Text(
                        widget.counterparty != null
                            ? (_isReceived
                                ? "From: ${widget.counterparty}"
                                : "To: ${widget.counterparty}")
                            : "Transaction Completed",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.72),
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
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

class _CheckmarkPainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Checkmark coordinates relative to 100x100 box
    // Start: 28, 52
    // Middle: 44, 68
    // End: 74, 34

    final p1 = const Offset(28, 52);
    final p2 = const Offset(44, 68);
    final p3 = const Offset(74, 34);

    final val = progress.value;

    // Draw first segment (0.0 to 0.5 of progress)
    if (val > 0) {
      final subVal1 = (val / 0.5).clamp(0.0, 1.0);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * subVal1,
        p1.dy + (p2.dy - p1.dy) * subVal1,
      );
    }

    // Draw second segment (0.5 to 1.0 of progress)
    if (val > 0.5) {
      final subVal2 = ((val - 0.5) / 0.5).clamp(0.0, 1.0);
      path.moveTo(p2.dx, p2.dy);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * subVal2,
        p2.dy + (p3.dy - p2.dy) * subVal2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress.value != progress.value ||
        oldDelegate.color != color;
  }
}
