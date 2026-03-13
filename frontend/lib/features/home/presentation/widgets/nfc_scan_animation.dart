import 'package:flutter/material.dart';

class NfcScanAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const NfcScanAnimation({
    super.key,
    this.size = 200,
    this.color = const Color(0xFF00FF94),
  });

  @override
  State<NfcScanAnimation> createState() => _NfcScanAnimationState();
}

class _NfcScanAnimationState extends State<NfcScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Waves
          CustomPaint(
            painter: _RadarPainter(animation: _controller, color: widget.color),
            size: Size(widget.size, widget.size),
          ),
          // Central Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.nfc,
              size: widget.size * 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RadarPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw 3 pulsing circles
    for (int i = 0; i < 3; i++) {
      final double start = i * 0.33;
      double progress = (animation.value + start) % 1.0;

      // Opacity fades out as it grows
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity * 0.5);

      // Radius grows
      final double radius = maxRadius * progress;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
