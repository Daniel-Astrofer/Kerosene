import 'package:flutter/material.dart';
import 'interaction_utils.dart';

/// A wrapper that adds a "bouncing" physics-based reaction to any clickable widget.
/// Reduces scale on touch and bounces back with elastic curve.
class BouncingButtonWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool enableHaptic;

  const BouncingButtonWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.tooltip,
    this.enableHaptic = true,
  });

  @override
  State<BouncingButtonWrapper> createState() => _BouncingButtonWrapperState();
}

class _BouncingButtonWrapperState extends State<BouncingButtonWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _release();
      if (widget.enableHaptic) {
        KeroseneFeedback.lightImpact();
      }
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _release();
    }
  }

  void _release() {
    _controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (widget.onTap == null) return body;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: widget.tooltip != null
          ? Tooltip(message: widget.tooltip!, child: body)
          : body,
    );
  }
}
