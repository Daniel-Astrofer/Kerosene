import 'package:flutter/animation.dart';

class AppAnimations {
  const AppAnimations._();

  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 180);
  static const Duration emphasized = Duration(milliseconds: 260);
  static const Duration routeIn = Duration(milliseconds: 136);
  static const Duration routeOut = Duration(milliseconds: 92);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuart;
}
