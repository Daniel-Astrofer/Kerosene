import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;

    final child = AnimatedSwitcher(
      duration: KeroseneMotion.fast,
      child: loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            textStyle: AppTypography.buttonText,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            textStyle: AppTypography.buttonText,
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(textStyle: AppTypography.buttonText),
          child: child,
        );
      case AppButtonVariant.danger:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
            textStyle: AppTypography.buttonText,
          ),
          child: child,
        );
    }
  }
}
