import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashedRect extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double gap;
  final Widget child;

  const DashedRect({
    super.key,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, strokeWidth: strokeWidth, gap: gap),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double x = size.width;
    final double y = size.height;

    final Path topPath = _getDashedPath(
      a: const Offset(0, 0),
      b: Offset(x, 0),
      gap: gap,
    );

    final Path rightPath = _getDashedPath(
      a: Offset(x, 0),
      b: Offset(x, y),
      gap: gap,
    );

    final Path bottomPath = _getDashedPath(
      a: Offset(x, y),
      b: Offset(0, y),
      gap: gap,
    );

    final Path leftPath = _getDashedPath(
      a: Offset(0, y),
      b: const Offset(0, 0),
      gap: gap,
    );

    canvas.drawPath(topPath, dashedPaint);
    canvas.drawPath(rightPath, dashedPaint);
    canvas.drawPath(bottomPath, dashedPaint);
    canvas.drawPath(leftPath, dashedPaint);
  }

  Path _getDashedPath({
    required Offset a,
    required Offset b,
    required double gap,
  }) {
    Size size = Size(b.dx - a.dx, b.dy - a.dy);
    Path path = Path();
    path.moveTo(a.dx, a.dy);
    bool shouldDraw = true;
    math.Point currentPoint = math.Point(a.dx, a.dy);

    num radians = math.atan(size.height / size.width);

    num dx = math.cos(radians) * gap < 0
        ? math.cos(radians) * gap * -1
        : math.cos(radians) * gap;
    num dy = math.sin(radians) * gap < 0
        ? math.sin(radians) * gap * -1
        : math.sin(radians) * gap;

    while (currentPoint.x <= b.dx && currentPoint.y <= b.dy) {
      if (shouldDraw) {
        path.lineTo(currentPoint.x.toDouble(), currentPoint.y.toDouble());
      } else {
        path.moveTo(currentPoint.x.toDouble(), currentPoint.y.toDouble());
      }
      shouldDraw = !shouldDraw;
      currentPoint = math.Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
