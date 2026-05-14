import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

class AnimatedOnionLogo extends StatefulWidget {
  final double size;
  final Color color;
  final Color? fillColor;
  final double strokeWidth;
  final Duration duration;
  final bool play;

  const AnimatedOnionLogo({
    super.key,
    required this.color,
    this.size = 24,
    this.fillColor,
    this.strokeWidth = 2,
    this.duration = const Duration(seconds: 1),
    this.play = true,
  });

  @override
  State<AnimatedOnionLogo> createState() => _AnimatedOnionLogoState();
}

class _AnimatedOnionLogoState extends State<AnimatedOnionLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.play) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedOnionLogo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    if (!oldWidget.play && widget.play) {
      _startAnimation();
      return;
    }

    if (widget.play &&
        (oldWidget.color != widget.color ||
            oldWidget.fillColor != widget.fillColor ||
            oldWidget.strokeWidth != widget.strokeWidth)) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final progress = _curve.value;
        final opacity = 0.45 + (progress * 0.55);
        final scale = 0.88 + (progress * 0.12);

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _AnimatedOnionLogoPainter(
                progress: progress,
                color: widget.color,
                fillColor: widget.fillColor,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedOnionLogoPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color? fillColor;
  final double strokeWidth;

  const _AnimatedOnionLogoPainter({
    required this.progress,
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPath = _buildBodyPath(size);
    final accentPaths = [
      _buildCenterLeafPath(size),
      _buildLeftLeafPath(size),
      _buildRightLeafPath(size),
      bodyPath,
      _buildCenterLayerPath(size),
      _buildLeftLayerPath(size),
      _buildRightLayerPath(size),
    ];

    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.10);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final resolvedFill = fillColor ?? color.withValues(alpha: 0.12);
    final fillOpacity = ((progress - 0.42) / 0.58).clamp(0.0, 1.0);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = resolvedFill.withValues(alpha: fillOpacity * 0.9);

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.05 * fillOpacity);

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.58),
      size.shortestSide * 0.34,
      glowPaint,
    );
    canvas.drawPath(bodyPath, fillPaint);
    _drawGhostPaths(canvas, accentPaths, ghostPaint);
    _drawTrimmedPaths(canvas, accentPaths, strokePaint, progress);
  }

  Path _buildBodyPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..cubicTo(w * 0.60, h * 0.08, w * 0.72, h * 0.14, w * 0.71, h * 0.28)
      ..cubicTo(w * 0.86, h * 0.34, w * 0.91, h * 0.57, w * 0.82, h * 0.72)
      ..cubicTo(w * 0.74, h * 0.86, w * 0.61, h * 0.96, w * 0.50, h * 0.95)
      ..cubicTo(w * 0.39, h * 0.96, w * 0.26, h * 0.86, w * 0.18, h * 0.72)
      ..cubicTo(w * 0.09, h * 0.57, w * 0.14, h * 0.34, w * 0.29, h * 0.28)
      ..cubicTo(w * 0.28, h * 0.14, w * 0.40, h * 0.08, w * 0.50, h * 0.20)
      ..close();
  }

  Path _buildCenterLeafPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.50, h * 0.26)
      ..cubicTo(w * 0.49, h * 0.16, w * 0.52, h * 0.08, w * 0.57, h * 0.02);
  }

  Path _buildLeftLeafPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.46, h * 0.24)
      ..cubicTo(w * 0.38, h * 0.16, w * 0.34, h * 0.08, w * 0.36, h * 0.01);
  }

  Path _buildRightLeafPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.54, h * 0.24)
      ..cubicTo(w * 0.62, h * 0.16, w * 0.66, h * 0.08, w * 0.64, h * 0.01);
  }

  Path _buildCenterLayerPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.50, h * 0.33)
      ..cubicTo(w * 0.48, h * 0.46, w * 0.48, h * 0.62, w * 0.50, h * 0.82);
  }

  Path _buildLeftLayerPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.38, h * 0.34)
      ..cubicTo(w * 0.31, h * 0.47, w * 0.31, h * 0.62, w * 0.38, h * 0.79);
  }

  Path _buildRightLayerPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.62, h * 0.34)
      ..cubicTo(w * 0.69, h * 0.47, w * 0.69, h * 0.62, w * 0.62, h * 0.79);
  }

  void _drawGhostPaths(Canvas canvas, List<Path> paths, Paint paint) {
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawTrimmedPaths(
    Canvas canvas,
    List<Path> paths,
    Paint paint,
    double progress,
  ) {
    final safeProgress = progress.clamp(0.0, 1.0);
    if (safeProgress <= 0) {
      return;
    }

    final metrics = <PathMetric>[];
    var totalLength = 0.0;

    for (final path in paths) {
      for (final metric in path.computeMetrics()) {
        metrics.add(metric);
        totalLength += metric.length;
      }
    }

    if (totalLength == 0) {
      return;
    }

    final targetLength = totalLength * safeProgress;
    var drawnLength = 0.0;
    final reveal = Path();

    for (final metric in metrics) {
      if (drawnLength >= targetLength) {
        break;
      }

      final remaining = targetLength - drawnLength;
      final segmentLength = math.min(metric.length, remaining);

      if (segmentLength > 0) {
        reveal.addPath(metric.extractPath(0, segmentLength), Offset.zero);
      }

      drawnLength += metric.length;
    }

    canvas.drawPath(reveal, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedOnionLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
