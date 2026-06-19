import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';

class AuthMotion {
  const AuthMotion._();

  static const Duration entrance = KeroseneMotion.medium;
  static const Duration step = KeroseneMotion.medium;
  static const Duration shake = KeroseneMotion.medium;
  static const Duration press = KeroseneMotion.pageOut;
  static const Duration ceremonial = KeroseneMotion.ceremonial;

  static bool reduce(BuildContext context) {
    return KeroseneMotion.reduceMotion(context);
  }

  static Duration staggerDelay(int index) {
    return KeroseneMotion.stagger(
      index,
      step: KeroseneMotion.authStagger,
      maxIndex: 10,
    );
  }
}

class AuthMotionEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Offset offset;
  final double scaleBegin;
  final Duration duration;

  const AuthMotionEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.035),
    this.scaleBegin = 0.985,
    this.duration = AuthMotion.entrance,
  });

  @override
  State<AuthMotionEntrance> createState() => _AuthMotionEntranceState();
}

class _AuthMotionEntranceState extends State<AuthMotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = KeroseneMotion.reduceMotion(context);
    final delay = AuthMotion.staggerDelay(widget.index);
    _controller.duration = reduce ? Duration.zero : widget.duration + delay;
    if (reduce) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (KeroseneMotion.reduceMotion(context)) {
      return widget.child;
    }

    final delay = AuthMotion.staggerDelay(widget.index);
    final totalMs = (widget.duration + delay).inMilliseconds;
    final start = totalMs == 0 ? 0.0 : delay.inMilliseconds / totalMs;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: KeroseneMotion.entrance),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: widget.scaleBegin,
            end: 1,
          ).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

class AuthMotionStagger extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AuthMotionStagger({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    var motionIndex = 0;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (final child in children)
          child is SizedBox
              ? child
              : AuthMotionEntrance(index: motionIndex++, child: child),
      ],
    );
  }
}

class AuthMotionShake extends StatefulWidget {
  final Widget child;
  final int triggerKey;
  final bool enabled;
  final double distance;

  const AuthMotionShake({
    super.key,
    required this.child,
    required this.triggerKey,
    this.enabled = true,
    this.distance = 7,
  });

  @override
  State<AuthMotionShake> createState() => _AuthMotionShakeState();
}

class _AuthMotionShakeState extends State<AuthMotionShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AuthMotion.shake,
    );
  }

  @override
  void didUpdateWidget(covariant AuthMotionShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled &&
        widget.triggerKey != oldWidget.triggerKey &&
        !KeroseneMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || KeroseneMotion.reduceMotion(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 4) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class AuthMotionPressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AuthMotionPressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<AuthMotionPressScale> createState() => _AuthMotionPressScaleState();
}

class _AuthMotionPressScaleState extends State<AuthMotionPressScale> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (!widget.enabled || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (KeroseneMotion.reduceMotion(context)) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AuthMotion.press,
        curve: KeroseneMotion.standard,
        child: widget.child,
      ),
    );
  }
}

class AuthDirectionalSwitcher extends StatelessWidget {
  final Widget child;
  final bool isForward;
  final Duration duration;

  const AuthDirectionalSwitcher({
    super.key,
    required this.child,
    required this.isForward,
    this.duration = AuthMotion.step,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: KeroseneMotion.duration(context, duration),
      switchInCurve: KeroseneMotion.entrance,
      switchOutCurve: KeroseneMotion.exit,
      transitionBuilder: (child, animation) {
        if (KeroseneMotion.reduceMotion(context)) {
          return FadeTransition(opacity: animation, child: child);
        }
        final isIncoming = child.key == this.child.key;
        final begin = isIncoming
            ? Offset(isForward ? 0.10 : -0.10, 0)
            : Offset(isForward ? -0.08 : 0.08, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
