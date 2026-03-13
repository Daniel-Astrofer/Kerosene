import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

// ─── BASE WIDGET FOR ANIMATED CYBER ICONS ─────────────────────
abstract class CyberIconPainter extends CustomPainter {
  final double progress;
  final Color color;

  CyberIconPainter({required this.progress, required this.color});

  @override
  bool shouldRepaint(covariant CyberIconPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class AnimatedCyberIcon extends StatefulWidget {
  final bool isActive;
  final CustomPainter Function(double progress, Color color) painterBuilder;
  final Duration duration;
  final double size;

  const AnimatedCyberIcon({
    super.key,
    required this.isActive,
    required this.painterBuilder,
    this.duration = const Duration(milliseconds: 600),
    this.size = 24.0,
  });

  @override
  State<AnimatedCyberIcon> createState() => _AnimatedCyberIconState();
}

class _AnimatedCyberIconState extends State<AnimatedCyberIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCyberIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final color = widget.isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.5);
          return CustomPaint(
            painter: widget.painterBuilder(_animation.value, color),
          );
        },
      ),
    );
  }
}

// ─── 1. CYBER HOME ICON (Self-Drawing Hexagon House) ────────────────
class CyberHomeIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberHomeIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) =>
          _HomePainter(progress: progress, color: color),
    );
  }
}

class _HomePainter extends CyberIconPainter {
  _HomePainter({required super.progress, required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // House Path
    final path = Path();
    path.moveTo(w * 0.5, h * 0.1); // Top Tip
    path.lineTo(w * 0.9, h * 0.4); // Right Roof
    path.lineTo(w * 0.9, h * 0.9); // Right Wall (Bottom)
    path.lineTo(w * 0.1, h * 0.9); // Left Wall (Bottom)
    path.lineTo(w * 0.1, h * 0.4); // Left Roof
    path.close();

    // Draw the path based on progress (Trim Path effect)
    drawPathValidatingProgress(canvas, path, paint, progress);

    // Door (Only appears if active)
    if (progress > 0.8) {
      final doorPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final doorH = h * 0.3 * (progress - 0.8) * 5.0; // Grows up
      final doorRect = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.9 - doorH / 2),
        width: w * 0.25,
        height: doorH,
      );
      canvas.drawRect(doorRect, doorPaint);
    }
  }

  // Helper to simulate "Path Trimming"
  void drawPathValidatingProgress(
    Canvas canvas,
    Path path,
    Paint paint,
    double progress,
  ) {
    final pathMetrics = path.computeMetrics();
    for (var metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }
}

// ─── 5. CYBER EYE ICON (Privacy Toggle) ────────────────────────────
class CyberEyeIcon extends StatelessWidget {
  final bool isVisible;
  final double size;

  const CyberEyeIcon({super.key, required this.isVisible, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isVisible,
      size: size,
      duration: const Duration(milliseconds: 500),
      painterBuilder: (progress, color) => _EyePainter(progress, color),
    );
  }
}

class _EyePainter extends CustomPainter {
  final double progress; // 1.0 = Visible (Open), 0.0 = Hidden (Closed/Slash)
  final Color color;

  _EyePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Eye Shape (Outline)
    // Always visible, but maybe squints a bit when closed?
    final eyePath = Path();
    eyePath.moveTo(0, h * 0.5);
    eyePath.quadraticBezierTo(
      w * 0.5,
      h * (0.1 + 0.4 * (1 - progress)),
      w,
      h * 0.5,
    );
    eyePath.quadraticBezierTo(
      w * 0.5,
      h * (0.9 - 0.4 * (1 - progress)),
      0,
      h * 0.5,
    );
    canvas.drawPath(eyePath, paint);

    // Pupil (Only visible when open)
    if (progress > 0.0) {
      final pupilPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, (w * 0.15) * progress, pupilPaint);
    }

    // Slash (Only visible when closed)
    if (progress < 1.0) {
      final slashProgress = 1.0 - progress;
      final p1 = Offset(w * 0.2, h * 0.8);
      final p2 = Offset(w * 0.8, h * 0.2);

      // Draw partial slash based on progress
      final slashPath = Path();
      slashPath.moveTo(p1.dx, p1.dy);
      slashPath.lineTo(
        p1.dx + (p2.dx - p1.dx) * slashProgress,
        p1.dy + (p2.dy - p1.dy) * slashProgress,
      );

      canvas.drawPath(slashPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─── 6. CYBER PLUS ICON (Add Funds) ────────────────────────────────
class CyberPlusIcon extends StatelessWidget {
  final bool isActive; // Usually true implies "appearing"
  final double size;

  const CyberPlusIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) => _PlusPainter(progress, color),
    );
  }
}

class _PlusPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PlusPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          2.5 // Slightly thicker
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Horizontal Line (Draws from center out)
    final hLen = (w * 0.8) * progress;
    canvas.drawLine(
      Offset(center.dx - hLen / 2, center.dy),
      Offset(center.dx + hLen / 2, center.dy),
      paint,
    );

    // Vertical Line (Draws from center out)
    final vLen = (h * 0.8) * progress;
    canvas.drawLine(
      Offset(center.dx, center.dy - vLen / 2),
      Offset(center.dx, center.dy + vLen / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PlusPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─── 7. CYBER SEND ICON (Arrow Out) ────────────────────────────────
class CyberSendIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberSendIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) =>
          _ArrowPainter(progress, color, isSend: true),
    );
  }
}

// ─── 8. CYBER RECEIVE ICON (Arrow In) ──────────────────────────────
class CyberReceiveIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberReceiveIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) =>
          _ArrowPainter(progress, color, isSend: false),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isSend;

  _ArrowPainter(this.progress, this.color, {required this.isSend});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Send: Bottom-Left to Top-Right
    // Receive: Top-Right to Bottom-Left

    // We'll define the path for "Send" and then rotate 180 for "Receive" if needed?
    // actually Receive is usually "Down-Left" or "Down".
    // Let's stick to standard: Send = Up-Right, Receive = Down-Left.

    canvas.save();
    if (!isSend) {
      // Rotate 180 around center for Receive
      canvas.translate(w / 2, h / 2);
      canvas.rotate(pi);
      canvas.translate(-w / 2, -h / 2);
    }

    final path = Path();
    // Start P1 (Tail) -> End P2 (Head)
    final p1 = Offset(w * 0.2, h * 0.8);
    final p2 = Offset(w * 0.8, h * 0.2);

    // Draw Shaft
    // Animate length
    final currentP2 = Offset(
      lerpDouble(p1.dx, p2.dx, progress)!,
      lerpDouble(p1.dy, p2.dy, progress)!,
    );
    path.moveTo(p1.dx, p1.dy);
    path.lineTo(currentP2.dx, currentP2.dy);

    // Draw Arrowhead (Only if progress > 0.5)
    if (progress > 0.5) {
      final headProgress = (progress - 0.5) * 2.0;
      // Head is at P2. Points: (0.8, 0.2)
      // Wings: (0.55, 0.2) and (0.8, 0.45) roughly

      final wing1 = Offset(w * 0.55, h * 0.2); // Left of head
      final wing2 = Offset(w * 0.8, h * 0.45); // Below head

      // Lerp wings from P2 back to their positions
      final curWing1 = Offset(
        lerpDouble(p2.dx, wing1.dx, headProgress)!,
        lerpDouble(p2.dy, wing1.dy, headProgress)!,
      );
      final curWing2 = Offset(
        lerpDouble(p2.dx, wing2.dx, headProgress)!,
        lerpDouble(p2.dy, wing2.dy, headProgress)!,
      );

      // We actually want the head to stick to currentP2 if it's moving?
      // Simpler: Just draw full arrowhead at the tip of currentP2
      // But let's stick to "assembling" effect at final position for clearer read.

      // Let's draw the wings originating from currentP2
      // Vector from p2 to p1 direction is (-0.6, 0.6)

      // Fixed wings at final position (easier to read)
      path.moveTo(currentP2.dx, currentP2.dy);
      path.lineTo(curWing1.dx, curWing1.dy);
      path.moveTo(currentP2.dx, currentP2.dy);
      path.lineTo(curWing2.dx, curWing2.dy);
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isSend != isSend;
}

// ─── 2. CYBER MARKET ICON (Growing Bars) ───────────────────────────
class CyberMarketIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberMarketIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      duration: const Duration(milliseconds: 800),
      painterBuilder: (progress, color) => _MarketPainter(progress, color),
    );
  }
}

class _MarketPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MarketPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Bar 1 (Short)
    final h1 = h * 0.4 * (progress > 0.0 ? (0.5 + 0.5 * progress) : 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h - h1, w * 0.25, h1),
        const Radius.circular(2),
      ),
      paint,
    );

    // Bar 2 (Medium)
    final h2 = h * 0.6 * (progress > 0.0 ? (0.5 + 0.5 * progress) : 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.375, h - h2, w * 0.25, h2),
        const Radius.circular(2),
      ),
      paint,
    );

    // Bar 3 (Tall)
    final h3 = h * 0.9 * (progress > 0.0 ? (0.5 + 0.5 * progress) : 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.75, h - h3, w * 0.25, h3),
        const Radius.circular(2),
      ),
      paint,
    );

    // Trend Line (appears at end)
    if (progress > 0.8) {
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final path = Path();
      // Points based on top-center of bars
      const padding = 2.0;

      // Start: top of Bar 1
      path.moveTo(w * 0.125, h - h1 - padding);
      // Mid: top of Bar 2
      path.lineTo(w * 0.5, h - h2 - padding);
      // End: top of Bar 3
      path.lineTo(w * 0.875, h - h3 - padding);

      // Draw partial path for animation effect
      // But for simplicity in this step, just draw it
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarketPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─── 3. CYBER NFT ICON (Animated Diamond/Crystal) ──────────────────────────
class CyberNftIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberNftIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) => _NftPainter(progress, color),
    );
  }
}

class _NftPainter extends CustomPainter {
  final double progress;
  final Color color;

  _NftPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Slight float animation effect on Y axis
    final floatY = sin(progress * pi) * 2;
    canvas.translate(0, -floatY);

    // Scale animation during entry
    final scale = 0.8 + (0.2 * progress);
    canvas.scale(scale, scale);
    canvas.translate(-w / 2, -h / 2);

    // Diamond Path
    final path = Path();
    path.moveTo(w * 0.5, h * 0.15); // Top
    path.lineTo(w * 0.85, h * 0.45); // Right
    path.lineTo(w * 0.5, h * 0.85); // Bottom
    path.lineTo(w * 0.15, h * 0.45); // Left
    path.close();

    // Inner facets (fade in based on progress)
    if (progress > 0.5) {
      final innerProgress = (progress - 0.5) * 2;
      final innerPaint = Paint()
        ..color = color.withValues(alpha: 0.5 * innerProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(
        Offset(w * 0.5, h * 0.15),
        Offset(w * 0.5, h * 0.85),
        innerPaint,
      ); // Vertical middle
      canvas.drawLine(
        Offset(w * 0.15, h * 0.45),
        Offset(w * 0.85, h * 0.45),
        innerPaint,
      ); // Horizontal middle

      // Top triangle facet
      final topFacetPath = Path();
      topFacetPath.moveTo(w * 0.35, h * 0.3);
      topFacetPath.lineTo(w * 0.65, h * 0.3);
      topFacetPath.lineTo(w * 0.5, h * 0.45);
      topFacetPath.close();
      canvas.drawPath(topFacetPath, innerPaint);
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NftPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─── 4. CYBER PROFILE ICON (Scanning Silhouette) ───────────────────
class CyberProfileIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberProfileIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      painterBuilder: (progress, color) => _ProfilePainter(progress, color),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProfilePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Head
    canvas.drawCircle(Offset(w * 0.5, h * 0.3), w * 0.2, paint);

    // Body (Arc)
    final path = Path();
    // Start left bottom
    path.moveTo(w * 0.2, h);
    // Curve up to neck
    path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.8, h);
    canvas.drawPath(path, paint);

    // Scan Line (only active)
    if (progress > 0.0) {
      final scanY = h * progress;
      final scanPaint = Paint()
        ..color = color.withValues(alpha: 0.8 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Draw scan line
      canvas.drawLine(Offset(0, scanY), Offset(w, scanY), scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─── 9. CYBER QR ICON (Scanning) ──────────────────────────────────
class CyberQrIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberQrIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      duration: const Duration(milliseconds: 1500),
      painterBuilder: (progress, color) =>
          _QrPainter(progress: progress, color: color),
    );
  }
}

class _QrPainter extends CyberIconPainter {
  _QrPainter({required super.progress, required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cornerLen = w * 0.25;

    // Corners
    final path = Path();
    // Top-Left
    path.moveTo(0, cornerLen);
    path.lineTo(0, 0);
    path.lineTo(cornerLen, 0);
    // Top-Right
    path.moveTo(w - cornerLen, 0);
    path.lineTo(w, 0);
    path.lineTo(w, cornerLen);
    // Bottom-Right
    path.moveTo(w, h - cornerLen);
    path.lineTo(w, h);
    path.lineTo(w - cornerLen, h);
    // Bottom-Left
    path.moveTo(cornerLen, h);
    path.lineTo(0, h);
    path.lineTo(0, h - cornerLen);

    canvas.drawPath(path, paint);

    // Scan Line
    if (progress > 0) {
      final scanY = h * progress;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, scanY, w, 2))
        ..strokeWidth = 2;

      canvas.drawLine(Offset(0, scanY), Offset(w, scanY), scanPaint);
    }
  }
}

// ─── 10. CYBER NFC ICON (Radio Waves) ──────────────────────────────
class CyberNfcIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CyberNfcIcon({super.key, required this.isActive, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedCyberIcon(
      isActive: isActive,
      size: size,
      duration: const Duration(milliseconds: 1200),
      painterBuilder: (progress, color) =>
          _NfcPainter(progress: progress, color: color),
    );
  }
}

class _NfcPainter extends CyberIconPainter {
  _NfcPainter({required super.progress, required super.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.2, h * 0.5);

    for (int i = 1; i <= 3; i++) {
      // Staggered wave animation
      // progress 0->1
      // wave 1: 0.0 -> 0.33
      // wave 2: 0.33 -> 0.66
      // wave 3: 0.66 -> 1.0
      // Or simpler: all grow but fade?

      // Let's do simple sequential growth
      final waveProgress = (progress * 3 - (i - 1)).clamp(0.0, 1.0);

      if (waveProgress > 0) {
        paint.color = color.withValues(alpha: waveProgress);
        final radius = (w * 0.25) * i;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 4,
          pi / 2,
          false,
          paint,
        );
      }
    }
  }
}
