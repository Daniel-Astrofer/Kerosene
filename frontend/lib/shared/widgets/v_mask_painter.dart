import 'package:flutter/material.dart';

class VMaskPainter extends CustomPainter {
  final double progress;
  final Color color;

  VMaskPainter({required this.progress, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Scale factor to fit the mask nicely
    final scale = width / 100;

    // Transform canvas to center and scale
    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.scale(scale);
    canvas.translate(-50, -50); // Move origin to top-left of 100x100 box

    // --- Defining the MINIMALIST WIDE-SMILE V Mask Paths ---

    // 1. Face Outline (Simple clean curve)
    path.moveTo(20, 20);
    path.quadraticBezierTo(50, 5, 80, 20); // Forehead
    path.quadraticBezierTo(90, 25, 90, 45); // Right Temple
    path.quadraticBezierTo(90, 80, 50, 95); // Right Jaw to Chin
    path.quadraticBezierTo(10, 80, 10, 45); // Left Jaw
    path.quadraticBezierTo(10, 25, 20, 20); // Left Temple

    // 2. Eyebrows (High, clean arches, no extra fluff)
    // Left
    path.moveTo(25, 28);
    path.quadraticBezierTo(35, 15, 45, 28);
    // Right
    path.moveTo(75, 28);
    path.quadraticBezierTo(65, 15, 55, 28);

    // 3. Eyes ( Clean stylized shape, NO wrinkles)
    // Left
    path.moveTo(25, 38);
    path.quadraticBezierTo(35, 34, 42, 38); // Top
    path.quadraticBezierTo(35, 42, 25, 38); // Bottom
    // Right
    path.moveTo(58, 38);
    path.quadraticBezierTo(65, 34, 75, 38); // Top
    path.quadraticBezierTo(65, 42, 58, 38); // Bottom

    // 4. Nose (Minimalist - just the vertical slits/nostrils)
    path.moveTo(48, 45);
    path.lineTo(46, 55); // Left side
    path.moveTo(52, 45);
    path.lineTo(54, 55); // Right side

    // 5. Moustache (WIDE and UNCLUTTERED)
    // Left Curl - swooping wide out
    path.moveTo(50, 58);
    path.quadraticBezierTo(40, 58, 30, 62);
    path.quadraticBezierTo(15, 65, 15, 50); // Sharp wide curl up

    // Right Curl - swooping wide out
    path.moveTo(50, 58);
    path.quadraticBezierTo(60, 58, 70, 62);
    path.quadraticBezierTo(85, 65, 85, 50); // Sharp wide curl up

    // 6. Smile (The static wide grin)
    path.moveTo(25, 70);
    path.quadraticBezierTo(50, 80, 75, 70);

    // 7. Goatee (Simple Dagger)
    path.moveTo(50, 80); // Start under smile
    path.lineTo(50, 90); // Down stroke
    path.moveTo(48, 82); // Cross-bar minimal
    path.lineTo(52, 82);

    // 8. Cheeks (Subtle wide curves)
    path.moveTo(20, 55);
    path.quadraticBezierTo(25, 60, 30, 58); // Left blush

    path.moveTo(80, 55);
    path.quadraticBezierTo(75, 60, 70, 58); // Right blush

    // Compute metrics for animation
    final metrics = path.computeMetrics().toList(); // Convert to List!
    final totalLength = metrics.fold(
      0.0,
      (prev, metric) => prev + metric.length,
    );

    double currentLength = 0.0;
    final drawLength = totalLength * progress;

    for (final metric in metrics) {
      if (currentLength + metric.length <= drawLength) {
        // Draw full path segment
        canvas.drawPath(metric.extractPath(0, metric.length), paint);
      } else {
        // Draw partial path segment
        final remaining = drawLength - currentLength;
        if (remaining > 0) {
          canvas.drawPath(metric.extractPath(0, remaining), paint);
        }
        // Don't break here! We might have multiple disconnected paths (eyes, mouth, etc.)
        // Actually, if we want to draw them sequentially, breaking IS correct if we consider 'drawLength' as total progress across ALL paths.
        // The issue might be that 'path.computeMetrics()' returns metrics for EACH contour.
        // My logic below sums total length correctly.
        // The issue is likely that 'extractPath' works on the *specific* metric.

        // Wait, if I break, I stop drawing subsequent contours.
        // CORRECT LOGIC:
        // We draw full segments until we reach the partial one.
        // Once we draw the partial one, we are DONE for this frame.
        break;
      }
      currentLength += metric.length;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(VMaskPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
