import 'package:flutter/material.dart';

/// Motion tokens tuned for high-refresh devices.
///
/// The goal is to keep common transitions inside a 120 Hz frame budget by
/// animating only compositor-friendly properties: opacity and transform.
class KeroseneMotion {
  KeroseneMotion._();

  static const int targetRefreshRateFps = 120;
  static const Duration frameBudget = Duration(microseconds: 8333);

  static const Duration pageIn = Duration(milliseconds: 140);
  static const Duration pageOut = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 90);
  static const Duration standard = Duration(milliseconds: 140);
  static const Duration emphasized = Duration(milliseconds: 180);

  static const Curve enterCurve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve exitCurve = Cubic(0.7, 0.0, 0.84, 0.0);
  static const Curve standardCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  static const Offset pageSlideBegin = Offset(0.035, 0);
}
