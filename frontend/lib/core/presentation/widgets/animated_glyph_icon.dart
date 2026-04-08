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
        final revealProgress = ((progress - 0.06) / 0.94).clamp(0.0, 1.0);
        final bandEnd = progress.clamp(0.0, 1.0);
        final bandAccent = (bandEnd - 0.07).clamp(0.0, 1.0);
        final bandStart = (bandEnd - 0.22).clamp(0.0, 1.0);
        final finalOpacity = ((progress - 0.62) / 0.38).clamp(0.0, 1.0);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - progress) * 0.12,
                child: Transform.scale(
                  scale: 1.12 - (progress * 0.12),
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: widget.color.withValues(alpha: 0.60),
                  ),
                ),
              ),
              ClipRect(
                clipper: _RevealClipper(progress: revealProgress),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final end = bandEnd == 0 ? 0.001 : bandEnd;
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        widget.color.withValues(alpha: 0),
                        widget.color.withValues(alpha: 0.35),
                        widget.color,
                        widget.color.withValues(alpha: 0.80),
                      ],
                      stops: [
                        0.0,
                        bandStart,
                        bandAccent,
                        end,
                      ],
                    ).createShader(bounds);
                  },
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: Colors.white,
                  ),
                ),
              ),
              Opacity(
                opacity: finalOpacity,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  final double progress;

  const _RevealClipper({
    required this.progress,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
