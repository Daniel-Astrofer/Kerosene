import 'package:flutter/material.dart';

class AnimatedGlyphIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;
  final Duration delay;

  const AnimatedGlyphIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.duration = const Duration(milliseconds: 700),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedGlyphIcon> createState() => _AnimatedGlyphIconState();
}

class _AnimatedGlyphIconState extends State<AnimatedGlyphIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedGlyphIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.icon != widget.icon || oldWidget.color != widget.color) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    _controller.reset();
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) {
        return;
      }
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final progress = _curve.value;
        if (progress >= 0.999) {
          return _IconFrame(
            icon: widget.icon,
            size: widget.size,
            color: widget.color,
          );
        }

        final opacity = ((progress - 0.08) / 0.92).clamp(0.0, 1.0);
        final scale = 0.96 + (progress * 0.04);
        final verticalOffset = (1 - progress) * (widget.size <= 18 ? 1.5 : 2.5);

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: _IconFrame(
                icon: widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconFrame extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _IconFrame({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
