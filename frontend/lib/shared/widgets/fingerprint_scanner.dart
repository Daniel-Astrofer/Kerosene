import 'package:flutter/material.dart';
import 'package:kerosene/design_system/icons.dart';

class KeroseneFingerprintScanner extends StatelessWidget {
  final double size;

  const KeroseneFingerprintScanner({super.key, this.size = 96});

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
            KeroseneIcons.biometric,
            color: color,
            size: size * 0.54,
          ),
        ),
      ),
    );
  }
}
