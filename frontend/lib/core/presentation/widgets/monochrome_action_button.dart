import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

class MonochromeActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const MonochromeActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final textColor = Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDisabled ? 0.03 : 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDisabled ? 0.05 : 0.10),
              ),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor.withValues(alpha: 0.76),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: 18,
                            color: textColor.withValues(
                              alpha: isDisabled ? 0.30 : 0.76,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          text,
                          style: AppTypography.buttonText.copyWith(
                            color: textColor.withValues(
                              alpha: isDisabled ? 0.30 : 0.88,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
