import 'dart:math' as math;

import 'package:flutter/material.dart';

class DraggableCard3D extends StatefulWidget {
  final Widget child;
  final List<Widget> backgroundCards;
  final double initialHeight;
  final VoidCallback? onDragComplete;

  const DraggableCard3D({
    super.key,
    required this.child,
    this.backgroundCards = const [],
    this.initialHeight = 210,
    this.onDragComplete,
  });

  @override
  State<DraggableCard3D> createState() => _DraggableCard3DState();
}

class _DraggableCard3DState extends State<DraggableCard3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _resetAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _dragOffset = _resetAnimation.value);
      });
    _resetAnimation = AlwaysStoppedAnimation<double>(_dragOffset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetPosition() {
    _controller.stop();
    _resetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > widget.initialHeight * 0.42 ||
        velocity.abs() > 720) {
      widget.onDragComplete?.call();
      _dragOffset = 0;
      _controller.reset();
      setState(() {});
      return;
    }
    _resetPosition();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / widget.initialHeight).clamp(0.0, 1.0);
    final rotation =
        (_dragOffset / widget.initialHeight).clamp(-1.0, 1.0) * 0.08;

    return SizedBox(
      height: widget.initialHeight + 112,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          for (var i = math.min(widget.backgroundCards.length, 3) - 1;
              i >= 0;
              i--)
            Positioned(
              top: 24.0 + (i * 26),
              left: 14.0 + (i * 8),
              right: 14.0 + (i * 8),
              child: Transform.scale(
                scale: 1 - (i * 0.035) + (progress * 0.018),
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: (0.76 - (i * 0.12)).clamp(0.0, 1.0),
                  child: IgnorePointer(child: widget.backgroundCards[i]),
                ),
              ),
            ),
          Positioned(
            top: _dragOffset,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() => _dragOffset += details.primaryDelta ?? 0);
              },
              onVerticalDragEnd: _handleDragEnd,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(rotation),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
