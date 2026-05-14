import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';

class AnimatedGlowBackdrop extends StatefulWidget {
  const AnimatedGlowBackdrop({super.key});

  @override
  State<AnimatedGlowBackdrop> createState() => _AnimatedGlowBackdropState();
}

class _AnimatedGlowBackdropState extends State<AnimatedGlowBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * math.pi * 2;

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF02050C),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(t * 0.35) * 0.18,
                      -0.35 + math.cos(t * 0.28) * 0.12,
                    ),
                    radius: 1.05,
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      const Color(0xFF02050C),
                    ],
                  ),
                ),
              ),
            ),
            _GlowOrb(
              size: size.width * 0.82,
              left: -size.width * 0.18 + math.sin(t * 0.9) * 42,
              top: -size.width * 0.20 + math.cos(t * 0.8) * 56,
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.32,
                  ),
            ),
            _GlowOrb(
              size: size.width * 0.76,
              right: -size.width * 0.22 + math.cos(t * 1.15) * 48,
              top: size.height * 0.16 + math.sin(t * 0.72) * 54,
              color: AppColors.accent.withValues(alpha: 0.20),
            ),
            _GlowOrb(
              size: size.width * 0.88,
              left: size.width * 0.06 + math.cos(t * 0.62) * 36,
              bottom: -size.width * 0.28 + math.sin(t * 1.05) * 60,
              color: Theme.of(context).colorScheme.secondary.withValues(
                    alpha: 0.24,
                  ),
            ),
            _GlowRibbon(
              alignment: Alignment.topRight,
              width: size.width * 0.58,
              height: 220,
              angle: -0.52 + math.sin(t * 0.75) * 0.08,
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.20,
                  ),
              offset: Offset(
                math.cos(t * 0.95) * 18,
                math.sin(t * 0.65) * 24,
              ),
            ),
            _GlowRibbon(
              alignment: Alignment.bottomLeft,
              width: size.width * 0.64,
              height: 240,
              angle: 0.68 + math.cos(t * 0.62) * 0.09,
              color: AppColors.accent.withValues(alpha: 0.14),
              offset: Offset(
                math.sin(t * 0.72) * 20,
                math.cos(t * 0.88) * 20,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: color.a * 0.48),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowRibbon extends StatelessWidget {
  final Alignment alignment;
  final double width;
  final double height;
  final double angle;
  final Color color;
  final Offset offset;

  const _GlowRibbon({
    required this.alignment,
    required this.width,
    required this.height,
    required this.angle,
    required this.color,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withValues(alpha: 0),
                      color,
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
