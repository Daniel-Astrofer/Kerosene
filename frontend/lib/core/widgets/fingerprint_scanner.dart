import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CyberFingerprintScanner extends StatelessWidget {
  final double size;

  const CyberFingerprintScanner({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Icon(
            LucideIcons.fingerprint,
            color: color,
            size: size * 0.54,
          ),
        ),
      ),
    );
  }
}
