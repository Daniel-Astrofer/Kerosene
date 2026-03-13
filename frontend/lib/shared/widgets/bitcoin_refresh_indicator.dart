import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BitcoinRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const BitcoinRefreshIndicator({super.key, required this.onRefresh});

  @override
  State<BitcoinRefreshIndicator> createState() =>
      _BitcoinRefreshIndicatorState();
}

class _BitcoinRefreshIndicatorState extends State<BitcoinRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _spinnerController;
  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  RefreshIndicatorMode _lastState = RefreshIndicatorMode.inactive;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: 120.0,
      refreshIndicatorExtent: 70.0,
      onRefresh: () async {
        // Reset check animation when starting refresh
        _checkController.reset();
        await widget.onRefresh();
      },
      builder:
          (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            // State transition detection
            if (refreshState == RefreshIndicatorMode.done &&
                _lastState != RefreshIndicatorMode.done) {
              _checkController.forward();
            }
            _lastState = refreshState;

            final double opacity = (pulledExtent / 50.0).clamp(0.0, 1.0);
            final double scale = (pulledExtent / 100.0).clamp(0.0, 1.2);

            // Rotation logic
            double rotation = 0;
            if (refreshState == RefreshIndicatorMode.drag ||
                refreshState == RefreshIndicatorMode.armed) {
              rotation = (pulledExtent / 100.0) * 2 * pi;
              if (_spinnerController.isAnimating) _spinnerController.stop();
            } else if (refreshState == RefreshIndicatorMode.refresh) {
              if (!_spinnerController.isAnimating) _spinnerController.repeat();
              rotation = _spinnerController.value * 2 * pi;
            } else if (refreshState == RefreshIndicatorMode.done) {
              if (_spinnerController.isAnimating) _spinnerController.stop();
              // Align to upright
              rotation = 0;
            }

            return Container(
              height: refreshIndicatorExtent,
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _spinnerController,
                      _checkController,
                    ]),
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(30, 30),
                        painter: BitcoinPainter(
                          rotation: rotation,
                          checkProgress: _checkAnim.value,
                          isDone: refreshState == RefreshIndicatorMode.done,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}

class BitcoinPainter extends CustomPainter {
  final double rotation;
  final double checkProgress;
  final bool isDone;

  BitcoinPainter({
    required this.rotation,
    required this.checkProgress,
    required this.isDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Rotate Canvas
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Se estiver "Done", a rotação deve parar ou fazer um flip?
    // Vamos manter a rotação zero se done, controlado pelo widget.
    if (!isDone) canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // 2. Coin Body (Gold Gradient)
    final Paint bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFE6AC00), // Darker Gold
          const Color(0xFFFFE145), // Light Gold
          const Color(0xFFC79200),
        ],
        [0.0, 0.4, 0.6, 1.0],
      );

    // Shadow/Glow
    final Paint shadowPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius, shadowPaint);
    canvas.drawCircle(center, radius, bodyPaint);

    // 3. Glassmorphism / Shine
    final Paint shinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width * 0.5, size.height),
        [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(center, radius * 0.9, shinePaint);

    // 4. Content (B or Check)
    if (isDone && checkProgress > 0) {
      // Draw Checkmark
      _drawCheckmark(canvas, size, center, radius, checkProgress);
    } else {
      // Draw Bitcoin Symbol
      // Fade out B if transitioning?
      double bOpacity = 1.0;
      if (isDone) bOpacity = 1.0 - checkProgress;

      if (bOpacity > 0) {
        _drawBitcoinSymbol(canvas, center, radius, bOpacity);
      }
    }

    canvas.restore();
  }

  void _drawBitcoinSymbol(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity,
  ) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '₿',
        style: TextStyle(
          fontSize: radius * 1.4,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: opacity * 0.9),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2 * opacity),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawCheckmark(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double progress,
  ) {
    // Simple Check Path
    final Path path = Path();
    // Percentuais relativos ao centro/raio
    final double r = radius * 0.6;

    // Check coordinates (approx)
    final Offset p1 = Offset(center.dx - r * 0.7, center.dy + r * 0.1);
    final Offset p2 = Offset(center.dx - r * 0.2, center.dy + r * 0.6);
    final Offset p3 = Offset(center.dx + r * 0.8, center.dy - r * 0.5);

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);

    // Animated Path drawing?
    // Simples: desenhar path completo com opacidade, ou usar path metric.
    // Para MVP bonito e rápido: Desenhar path completo mas com scale/opacity.
    // Ou cortar o path (PathMetrics).

    // Vamos desenhar completo com scale (elasticOut do controller já dá o pop).

    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [Colors.white, const Color(0xFFE0FFFF)],
      );

    // Scale transformation for pop effect
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final double scale = progress; // 0 to 1 (elastic)
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawPath(path, checkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(BitcoinPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.isDone != isDone;
  }
}
