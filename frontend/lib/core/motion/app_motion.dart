import 'package:flutter/material.dart';

class KeroseneMotion {
  const KeroseneMotion._();

  static const int targetRefreshRateFps = 120;
  static const Duration frameBudget = Duration(microseconds: 8333);

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration pageIn = Duration(milliseconds: 136);
  static const Duration pageOut = Duration(milliseconds: 92);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration route = pageIn;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutExpo;
  static const Curve entrance = Curves.easeOutQuart;

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ||
        media?.accessibleNavigation == true;
  }

  static Duration duration(BuildContext context, Duration duration) {
    return reduceMotion(context) ? instant : duration;
  }
}
