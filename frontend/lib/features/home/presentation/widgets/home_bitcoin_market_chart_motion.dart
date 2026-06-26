import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import '../screens/home_screen.dart';

double homeBitcoinChartHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return homeSize(154);
  if (width < 430) return homeSize(174);
  return homeSize(190);
}

class HomeBitcoinChartStateTransition extends StatelessWidget {
  final Widget child;
  const HomeBitcoinChartStateTransition({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
      switchInCurve: KeroseneMotion.entrance,
      switchOutCurve: KeroseneMotion.exit,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: child,
    );
  }
}

class HomeBitcoinChartReveal extends StatelessWidget {
  final Widget child;
  const HomeBitcoinChartReveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (KeroseneMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(child.key),
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.long,
      curve: KeroseneMotion.entrance,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, homeSize(8) * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class HomeBitcoinChartAmbientPulse extends StatefulWidget {
  final Widget child;
  const HomeBitcoinChartAmbientPulse({super.key, required this.child});
  @override
  State<HomeBitcoinChartAmbientPulse> createState() => _HomeBitcoinChartAmbientPulseState();
}

class _HomeBitcoinChartAmbientPulseState extends State<HomeBitcoinChartAmbientPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.loop,
    )..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (KeroseneMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final opacity = 0.74 + (_controller.value * 0.26);
        return Opacity(opacity: opacity, child: child);
      },
    );
  }
}
