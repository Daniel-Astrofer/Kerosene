import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../wallet/domain/entities/transaction.dart';

class TransactionSuccessDialog extends StatefulWidget {
  final TransactionType type;
  final double? amount;
  final String? counterparty;

  const TransactionSuccessDialog({
    super.key,
    this.type = TransactionType.send,
    this.amount,
    this.counterparty,
  });

  @override
  State<TransactionSuccessDialog> createState() =>
      _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState extends State<TransactionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _opacityAnimation;

  bool get _isReceived => widget.type == TransactionType.receive;
  Color get _color =>
      _isReceived ? const Color(0xFF00FF94) : const Color(0xFF7B61FF);
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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: GlassContainer(
          width: 280,
          height: 320,
          blur: 20,
          opacity: 0.1,
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: widget.type == TransactionType.send
                      ? CustomPaint(
                          painter: _CheckmarkPainter(progress: _checkAnimation),
                        )
                      : ScaleTransition(
                          scale: _checkAnimation,
                          child: Icon(_icon, color: Colors.black, size: 48),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    Text(
                      _isReceived ? "Received!" : "Sent!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.amount != null) ...[
                      Text(
                        "${widget.amount!.toStringAsFixed(8)} BTC",
                        style: TextStyle(
                          color: _color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.counterparty != null
                          ? (_isReceived
                                ? "From: ${widget.counterparty}"
                                : "To: ${widget.counterparty}")
                          : "Transaction Completed",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final Animation<double> progress;

  _CheckmarkPainter({required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
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
    return oldDelegate.progress.value != progress.value;
  }
}
