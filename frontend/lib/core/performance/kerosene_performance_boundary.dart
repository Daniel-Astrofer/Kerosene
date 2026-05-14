import 'package:flutter/material.dart';

/// Global paint boundary for full-screen app content.
///
/// This keeps route transitions, overlays and scroll surfaces from repainting
/// more of the tree than needed on high-refresh devices.
class KerosenePerformanceBoundary extends StatelessWidget {
  final Widget child;

  const KerosenePerformanceBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}
