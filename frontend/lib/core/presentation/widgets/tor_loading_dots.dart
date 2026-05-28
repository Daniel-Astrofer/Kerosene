import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teste/core/motion/app_motion.dart';

class TorLoadingDots extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final double travel;
  final Color? color;

  const TorLoadingDots({
    super.key,
    this.dotSize = 7,
    this.spacing = 7,
    this.travel = 8,
    this.color,
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
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    final width = widget.dotSize * 3 + widget.spacing * 2;

    if (KeroseneMotion.reduceMotion(context)) {
      return SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => _Dot(
              size: widget.dotSize,
              color: color.withValues(alpha: 0.72),
              left: index == 0 ? 0 : widget.spacing,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: widget.dotSize + widget.travel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (index) {
              final phase = (_controller.value + index * 0.18) % 1;
              final offset = math.sin(phase * math.pi * 2) * widget.travel / 2;
              return Transform.translate(
                offset: Offset(0, offset),
                child: _Dot(
                  size: widget.dotSize,
                  color: color.withValues(alpha: 0.42 + 0.46 * phase),
                  left: index == 0 ? 0 : widget.spacing,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final double left;
  final Color color;

  const _Dot({
    required this.size,
    required this.left,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
