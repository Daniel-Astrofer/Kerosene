import 'package:flutter/material.dart';

class TorLoadingDots extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final double travel;
  final Color color;
  final Duration duration;

  const TorLoadingDots({
    super.key,
    this.dotSize = 10,
    this.spacing = 12,
    this.travel = 16,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<TorLoadingDots> createState() => _TorLoadingDotsState();
}

class _TorLoadingDotsState extends State<TorLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: _TorLoadingDot(
            controller: _controller,
            index: index,
            size: widget.dotSize,
            travel: widget.travel,
            color: widget.color,
          ),
        );
      }),
    );
  }
}

class _TorLoadingDot extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final double size;
  final double travel;
  final Color color;

  const _TorLoadingDot({
    required this.controller,
    required this.index,
    required this.size,
    required this.travel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final start = index * 0.15;
    final end = start + 0.5;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: _TorBouncyCurve(),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dy = -travel * animation.value;
        final opacity = 0.2 + (0.8 * animation.value);
        final scale = 0.8 + (0.3 * animation.value);

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TorBouncyCurve extends Curve {
  @override
  double transformInternal(double t) {
    return (t < 0.5)
        ? Curves.easeOutCubic.transform(t * 2)
        : Curves.easeInCubic.transform(1 - (t - 0.5) * 2);
  }
}
