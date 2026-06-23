import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:kerosene/core/motion/app_motion.dart';

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
      duration: KeroseneMotion.calm,
    );

    _checkController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.slow,
    );

    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: KeroseneMotion.spring,
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
        _checkController.reset();
        await widget.onRefresh();
      },
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        if (refreshState == RefreshIndicatorMode.done &&
            _lastState != RefreshIndicatorMode.done) {
          _checkController.forward();
        }
        _lastState = refreshState;

        final pullProgress =
            (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        final opacity = (pulledExtent / 48.0).clamp(0.0, 1.0);
        final scale = (0.62 + (pullProgress * 0.38)).clamp(0.62, 1.0);

        final pullRotation = pullProgress * 2 * pi;
        if (refreshState == RefreshIndicatorMode.drag ||
            refreshState == RefreshIndicatorMode.armed) {
          if (_spinnerController.isAnimating) _spinnerController.stop();
        } else if (refreshState == RefreshIndicatorMode.refresh) {
          if (!_spinnerController.isAnimating) _spinnerController.repeat();
        } else if (refreshState == RefreshIndicatorMode.done ||
            refreshState == RefreshIndicatorMode.inactive) {
          if (_spinnerController.isAnimating) _spinnerController.stop();
        }

        return SizedBox(
          height: refreshIndicatorExtent,
          child: Center(
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
                    final rotation =
                        refreshState == RefreshIndicatorMode.refresh
                            ? _spinnerController.value * 2 * pi
                            : pullRotation;

                    return CustomPaint(
                      size: const Size(30, 30),
                      painter: PullLoadingPainter(
                        rotation: rotation,
                        pullProgress: pullProgress,
                        checkProgress: _checkAnim.value,
                        isDone: refreshState == RefreshIndicatorMode.done,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PullLoadingPainter extends CustomPainter {
  final double rotation;
  final double pullProgress;
  final double checkProgress;
  final bool isDone;

  const PullLoadingPainter({
    required this.rotation,
    required this.pullProgress,
    required this.checkProgress,
    required this.isDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!isDone) canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    if (isDone && checkProgress > 0) {
      _drawCheckmark(canvas, center, radius, checkProgress);
    } else {
      _drawLoadingGlyph(canvas, center, radius, pullProgress);
    }

    canvas.restore();
  }

  void _drawLoadingGlyph(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    final stroke = radius * 0.16;
    final ringRadius = radius - stroke;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);
    final trackPaint = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = CupertinoColors.white;
    final sweep = pi * (0.42 + (1.28 * progress.clamp(0.0, 1.0)));

    canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);
    canvas.drawArc(rect, -pi / 2, sweep, false, activePaint);

    final dotAngle = (-pi / 2) + sweep;
    final dotOffset = Offset(
      center.dx + cos(dotAngle) * ringRadius,
      center.dy + sin(dotAngle) * ringRadius,
    );
    canvas.drawCircle(dotOffset, stroke * 0.70, dotPaint);
  }

  void _drawCheckmark(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    final path = Path();
    final r = radius * 0.62;
    final p1 = Offset(center.dx - r * 0.72, center.dy + r * 0.06);
    final p2 = Offset(center.dx - r * 0.24, center.dy + r * 0.54);
    final p3 = Offset(center.dx + r * 0.82, center.dy - r * 0.52);

    path
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    final checkPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(progress.clamp(0.0, 1.0));
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, checkPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PullLoadingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.pullProgress != pullProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.isDone != isDone;
  }
}
