import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';

/// Neon-glowing CTA button — uses AppColors for the glow effect.
class NeonButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color baseColor;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.baseColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
