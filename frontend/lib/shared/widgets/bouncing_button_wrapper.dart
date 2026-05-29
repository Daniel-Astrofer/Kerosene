import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'interaction_utils.dart';

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

class _BouncingButtonWrapperState extends State<BouncingButtonWrapper> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null || _pressed) {
      return;
    }
    setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) {
      return;
    }
    _release();
    if (widget.enableHaptic) {
      KeroseneFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) {
      return;
    }
    _release();
  }

  void _release() {
    if (!_pressed || !mounted) {
      return;
    }
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = KeroseneMotion.reduceMotion(context);
    final body = AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.96 : 1.0,
      duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
      curve: KeroseneMotion.standard,
      child: widget.child,
    );

    if (widget.onTap == null) return body;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        enabled: true,
        child: widget.tooltip != null
            ? Tooltip(message: widget.tooltip!, child: body)
            : body,
      ),
    );
  }
}
