import 'package:flutter/material.dart';
import 'package:kerosene/core/presentation/widgets/subtle_noise_overlay.dart';

const Color authenticatedSurfaceBackgroundColor = Color(0xFF080A0D);

class AmbientSideGlowBackdrop extends StatelessWidget {
  final Color backgroundColor;
  final bool showAmbientEffects;
  final bool simpleGradient;

  const AmbientSideGlowBackdrop({
    super.key,
    this.backgroundColor = const Color(0xFF050505),
    this.showAmbientEffects = true,
    this.simpleGradient = false,
  });

  const AmbientSideGlowBackdrop.authenticated({
    super.key,
    this.backgroundColor = authenticatedSurfaceBackgroundColor,
  })  : showAmbientEffects = false,
        simpleGradient = false;

  @override
  Widget build(BuildContext context) {
    if (simpleGradient) {
      final topColor = Color.lerp(
            backgroundColor,
            const Color(0xFF101A24),
            0.68,
          ) ??
          backgroundColor;
      final bottomColor = Color.lerp(
            backgroundColor,
            const Color(0xFF020304),
            0.36,
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
              backgroundColor,
              bottomColor,
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      );
    }

    if (!showAmbientEffects) {
      return ColoredBox(color: backgroundColor);
    }

    final topColor = Color.lerp(
          backgroundColor,
          const Color(0xFF0D141D),
          0.58,
        ) ??
        backgroundColor;
    final midColor = Color.lerp(
          backgroundColor,
          const Color(0xFF0A1017),
          0.30,
        ) ??
        backgroundColor;
    final upperMidColor = Color.lerp(
          topColor,
          const Color(0xFF111B27),
          0.34,
        ) ??
        topColor;
    final centerColor = Color.lerp(
          upperMidColor,
          const Color(0xFF0C131B),
          0.42,
        ) ??
        upperMidColor;
    final lowerMidColor = Color.lerp(
          midColor,
          const Color(0xFF060A0E),
          0.32,
        ) ??
        midColor;
    final bottomColor = Color.lerp(
          backgroundColor,
          const Color(0xFF020405),
          0.20,
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
            centerColor,
            midColor,
            lowerMidColor,
            bottomColor,
          ],
          stops: const [0.0, 0.14, 0.34, 0.56, 0.80, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.05, -0.78),
                  radius: 1.36,
                  colors: [
                    Colors.white.withValues(alpha: 0.024),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.12, -0.10),
                  radius: 1.28,
                  colors: [
                    const Color(0xFF1A2638).withValues(alpha: 0.20),
                    const Color(0xFF0E1823).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.54, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, 0.28),
                  radius: 1.12,
                  colors: [
                    const Color(0xFF122131).withValues(alpha: 0.10),
                    const Color(0xFF0A1118).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.2, 0.0),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF2E86FF).withValues(alpha: 0.14),
                      const Color(0xFF2E86FF).withValues(alpha: 0.05),
                      const Color(0xFF2E86FF).withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.2, 0.0),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF00C3A5).withValues(alpha: 0.12),
                      const Color(0xFF00C3A5).withValues(alpha: 0.05),
                      const Color(0xFF00C3A5).withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.48, 1.0],
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
                    Colors.white.withValues(alpha: 0.012),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.10),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: SubtleNoiseOverlay(
              opacity: 0.012,
              step: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class CyberBackground extends StatelessWidget {
  final Widget child;
  final bool useScroll;
  final bool resizeToAvoidBottomInset;
  final List<Widget>? extraOverlays;
  final Color backgroundColor;
  final bool showAmbientEffects;
  final bool simpleGradient;

  const CyberBackground({
    super.key,
    required this.child,
    this.useScroll = true,
    this.resizeToAvoidBottomInset = true,
    this.extraOverlays,
    this.backgroundColor = const Color(0xFF050505),
    this.showAmbientEffects = true,
    this.simpleGradient = false,
  });

  const CyberBackground.authenticated({
    super.key,
    required this.child,
    this.useScroll = true,
    this.resizeToAvoidBottomInset = true,
    this.extraOverlays,
    this.backgroundColor = authenticatedSurfaceBackgroundColor,
  })  : showAmbientEffects = false,
        simpleGradient = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          Positioned.fill(
            child: showAmbientEffects
                ? AmbientSideGlowBackdrop(
                    backgroundColor: backgroundColor,
                    simpleGradient: simpleGradient,
                  )
                : AmbientSideGlowBackdrop.authenticated(
                    backgroundColor: backgroundColor,
                  ),
          ),
          if (extraOverlays != null) ...extraOverlays!,
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget content = child;

                if (useScroll) {
                  content = SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: child,
                        ),
                      ),
                    ),
                  );
                } else {
                  content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: child,
                    ),
                  );
                }

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }
}
