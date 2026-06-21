import 'package:flutter/material.dart';

/// Standard icon wrapper for Kerosene UI.
///
/// Keeps size, color and semantics consistent across product surfaces.
class KeroseneIcon extends StatelessWidget {
  const KeroseneIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      semanticLabel: semanticLabel,
    );
  }
}
