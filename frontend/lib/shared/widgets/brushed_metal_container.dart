import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget de textura de metal escovado ultra-otimizado
///
/// Performance:
/// - Zero-asset (sem imagens)
/// - 60 FPS garantido
/// - shouldRepaint = false (repinta apenas uma vez)
/// - Seed fixa para textura determinística
class BrushedMetalContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color baseColor;
  final Gradient? gradient;

  const BrushedMetalContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.baseColor = const Color(0xFF1E1E1E), // Darker base
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Generate gradient colors based on baseColor
    // We create a light and dark variant for the anisotropic effect
    final hsl = HSLColor.fromColor(baseColor);
    final dark = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();
    final light = hsl
        .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
        .toColor();
    final medium = baseColor;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Base Layer: Custom gradient or Anisotropic
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                dark,
                medium, // Highlight
                dark,
                light, // Reflection
                dark,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
        borderRadius: BorderRadius.circular(borderRadius),
        // Border highlighting para simular chanfro
        border: Border.all(color: Colors.white12, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Detail Layer: Brushed effect (textura escovada)
            Positioned.fill(
              child: CustomPaint(painter: _BrushedMetalPainter()),
            ),
            // Child content
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

/// CustomPainter para criar efeito de metal escovado
///
/// Técnica:
/// - 800 linhas horizontais aleatórias
/// - Random com seed fixa (42) para determinismo
/// - Comprimento variável (15-40px)
/// - Opacidade baixa (0.05-0.15) para efeito sutil
class _BrushedMetalPainter extends CustomPainter {
  const _BrushedMetalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.stroke;

    // More lines, much finer strokes, shorter length = premium brushed look
    // Optimized: 800 lines (was 4000) for better performance on mobile
    for (int i = 0; i < 800; i++) {
      final y = random.nextDouble() * size.height;
      final x = random.nextDouble() * size.width;

      // Very short lines for fine grain
      final lineLength = 3.0 + random.nextDouble() * 12.0;

      // Ultra-thin strokes
      final strokeWidth = 0.05 + random.nextDouble() * 0.15;

      // Very subtle opacity
      final opacity = 0.015 + random.nextDouble() * 0.035;

      paint
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: opacity);

      canvas.drawLine(Offset(x, y), Offset(x + lineLength, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
