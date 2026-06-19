import 'package:flutter/animation.dart';
import 'package:kerosene/core/motion/app_motion.dart';

class AppAnimations {
  const AppAnimations._();

  static const Duration instant = KeroseneMotion.instant;
  static const Duration fast = KeroseneMotion.fast;
  static const Duration standard = KeroseneMotion.short;
  static const Duration emphasized = KeroseneMotion.medium;
  static const Duration routeIn = KeroseneMotion.pageIn;
  static const Duration routeOut = KeroseneMotion.pageOut;

  static const Curve standardCurve = KeroseneMotion.standard;
  static const Curve emphasizedCurve = KeroseneMotion.entrance;
}
