import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'bouncing_button_wrapper.dart';

/// A high-end error feedback view using CustomPaint for minimalist geometric art.
/// Features a "breathing" animation to keep the screen alive.
class NativeErrorFeedbackView extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const NativeErrorFeedbackView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  State<NativeErrorFeedbackView> createState() =>
      _NativeErrorFeedbackViewState();
}

class _NativeErrorFeedbackViewState extends State<NativeErrorFeedbackView>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Breathing Animated Geometric Art
              Center(
                child: AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final scale = 1.0 + (_breathingController.value * 0.05);
                    final opacity = 0.7 + (_breathingController.value * 0.3);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: _ErrorGeometricPainter(
                            progress: _breathingController.value,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.bodyMedium!,
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
              BouncingButtonWrapper(
                onTap: widget.onRetry,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: Center(
                    child: Text(
                      'TENTAR NOVAMENTE',
                      style: AppTypography.buttonText.copyWith(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorGeometricPainter extends CustomPainter {
  final double progress;

  _ErrorGeometricPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Draw an abstract warning triangle
    final path = Path();
    final h = radius * math.sqrt(3);
    path.moveTo(center.dx, center.dy - radius); // Top
    path.lineTo(center.dx - radius, center.dy + h / 3); // Bottom Left
    path.lineTo(center.dx + radius, center.dy + h / 3); // Bottom Right
    path.close();

    // Subtle line animation based on progress
    canvas.drawPath(path, paint);

    // Inner decorative lines
    final innerPaint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 + (progress * 10)) * math.pi / 180;
      final offset = Offset(
        center.dx + math.cos(angle) * (radius * 0.5),
        center.dy + math.sin(angle) * (radius * 0.5),
      );
      canvas.drawCircle(offset, 4 + (progress * 4), innerPaint);
    }
  }

  @override
  bool shouldRepaint(_ErrorGeometricPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
