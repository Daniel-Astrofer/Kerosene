import 'dart:math' as math;

import 'package:flutter/material.dart';

class SubtleNoiseOverlay extends StatelessWidget {
  final double opacity;
  final double step;

  const SubtleNoiseOverlay({
    super.key,
    this.opacity = 0.028,
    this.step = 4,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SubtleNoisePainter(
            opacity: opacity,
            step: step,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SubtleNoisePainter extends CustomPainter {
  final double opacity;
  final double step;

  const _SubtleNoisePainter({
    required this.opacity,
    required this.step,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..style = PaintingStyle.fill;
    final darkPaint = Paint()..style = PaintingStyle.fill;
    final dotSize = step <= 3 ? 1.0 : 1.15;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final noise = _hash(x, y);

        if (noise > 0.84) {
          lightPaint.color = Colors.white.withValues(
            alpha: opacity * ((noise - 0.84) / 0.16) * 0.8,
          );
          canvas.drawRect(
            Rect.fromLTWH(x, y, dotSize, dotSize),
            lightPaint,
          );
        } else if (noise < 0.10) {
          darkPaint.color = Colors.black.withValues(
            alpha: opacity * ((0.10 - noise) / 0.10),
          );
          canvas.drawRect(
            Rect.fromLTWH(x, y, dotSize, dotSize),
            darkPaint,
          );
        }
      }
    }
  }

  double _hash(double x, double y) {
    final value = math.sin((x * 12.9898) + (y * 78.233)) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _SubtleNoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.step != step;
  }
}
