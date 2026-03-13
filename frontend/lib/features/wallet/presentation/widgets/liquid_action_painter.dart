import 'package:flutter/material.dart';

class LiquidActionPainter extends CustomPainter {
  final Offset dragOffset;
  final double threshold;
  final Color color;
  final bool isSend;

  LiquidActionPainter({
    required this.dragOffset,
    required this.threshold,
    this.color = Colors.white,
    required this.isSend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragOffset == Offset.zero) return;

    final paint = Paint()
      ..color = color
          .withValues(alpha: 0.08) // Slightly softer default alpha
      ..style = PaintingStyle.fill;

    // Apply a dampening factor to the drag for a "looser" feel
    final dampenedDx = dragOffset.dx * 0.8;
    final dampenedDy = dragOffset.dy * 0.8;

    // Determine direction and "liquid" deformation based on primary axis
    if (dampenedDy.abs() > dampenedDx.abs()) {
      // Primarily Vertical
      if (dampenedDy > 0) {
        // Dragging DOWN -> Stretch from TOP
        final intensity = (dampenedDy / threshold).clamp(0.0, 1.3);
        _drawLiquidEdge(
          canvas,
          size,
          paint,
          dampenedDy,
          intensity,
          dampenedDx,
          EdgeDirection.top,
        );
      }
    } else {
      // Primarily Horizontal
      if (dampenedDx > 0) {
        // Dragging RIGHT -> Stretch from LEFT
        final intensity = (dampenedDx / threshold).clamp(0.0, 1.3);
        _drawLiquidEdge(
          canvas,
          size,
          paint,
          dampenedDx,
          intensity,
          dampenedDy,
          EdgeDirection.left,
        );
      } else if (dampenedDx < 0) {
        // Dragging LEFT -> Stretch from RIGHT
        final intensity = (dampenedDx.abs() / threshold).clamp(0.0, 1.3);
        _drawLiquidEdge(
          canvas,
          size,
          paint,
          dampenedDx.abs(),
          intensity,
          dampenedDy,
          EdgeDirection.right,
        );
      }
    }
  }

  void _drawLiquidEdge(
    Canvas canvas,
    Size size,
    Paint paint,
    double pull,
    double intensity,
    double tilt,
    EdgeDirection direction,
  ) {
    final path = Path();

    // Increased multipliers for a more "elastic/liquid" look (looser feel)
    final pullFactor = 1.4;
    final tiltFactor = 0.6;

    switch (direction) {
      case EdgeDirection.top:
        final controlY = pull * pullFactor;
        final tiltX = (size.width / 2) + (tilt * tiltFactor);
        path.moveTo(0, 0);
        path.quadraticBezierTo(tiltX, controlY, size.width, 0);
        break;
      case EdgeDirection.left:
        final controlX = pull * pullFactor;
        final tiltY = (size.height / 2) + (tilt * tiltFactor);
        path.moveTo(0, 0);
        path.quadraticBezierTo(controlX, tiltY, 0, size.height);
        break;
      case EdgeDirection.right:
        final controlX = size.width - (pull * pullFactor);
        final tiltY = (size.height / 2) + (tilt * tiltFactor);
        path.moveTo(size.width, 0);
        path.quadraticBezierTo(controlX, tiltY, size.width, size.height);
        break;
      case EdgeDirection.bottom:
        final controlY = size.height - (pull * pullFactor);
        final tiltX = (size.width / 2) + (tilt * tiltFactor);
        path.moveTo(0, size.height);
        path.quadraticBezierTo(tiltX, controlY, size.width, size.height);
        break;
    }

    path.close();
    canvas.drawPath(path, paint);

    // Dynamic Glow with softer blur
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.04 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * intensity);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidActionPainter oldDelegate) {
    return oldDelegate.dragOffset != dragOffset;
  }
}

enum EdgeDirection { top, left, right, bottom }
