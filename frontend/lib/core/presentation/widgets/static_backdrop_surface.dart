import 'package:flutter/material.dart';

class StaticBackdropSurface extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const StaticBackdropSurface({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF02050C),
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topColor = Color.lerp(
          backgroundColor,
          Colors.white,
          0.06,
        ) ??
        backgroundColor;
    final upperMidColor = Color.lerp(
          backgroundColor,
          const Color(0xFF0B1220),
          0.28,
        ) ??
        backgroundColor;
    final lowerMidColor = Color.lerp(
          backgroundColor,
          Colors.black,
          0.10,
        ) ??
        backgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topColor,
            upperMidColor,
            lowerMidColor,
            backgroundColor,
          ],
          stops: const [0.0, 0.24, 0.62, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.92),
                  radius: 1.24,
                  colors: [
                    Colors.white.withValues(alpha: 0.030),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.18,
            right: -size.width * 0.14,
            child: IgnorePointer(
              child: Container(
                width: size.width * 0.72,
                height: size.width * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.28,
            left: -size.width * 0.22,
            child: IgnorePointer(
              child: Container(
                width: size.width * 0.64,
                height: size.width * 0.64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7B61FF).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.16,
            right: size.width * 0.08,
            child: IgnorePointer(
              child: Container(
                width: size.width * 0.76,
                height: size.width * 0.76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.010),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
