import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/core/motion/app_motion.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

enum BouncingButtonVariant { solid, outlined }

class BouncingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final BouncingButtonVariant variant;
  final double width;
  final double height;
  final IconData? icon;
  final Color? color;
  final Color? glowColor;

  const BouncingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = BouncingButtonVariant.solid,
    this.width = double.infinity,
    this.height = 48.0,
    this.icon,
    this.color,
    this.glowColor,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final reduceMotion = KeroseneMotion.reduceMotion(context);

    final isSolid = widget.variant == BouncingButtonVariant.solid;

    final disabledContentColor =
        Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.4);
    final foregroundColor = isDisabled
        ? disabledContentColor
        : (isSolid
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.secondary);

    // When gradient is active, do NOT set color — Flutter ignores gradient if color is also set.
    final hasGradient = isSolid && !isDisabled && widget.color == null;
    final flatColor = isSolid
        ? (isDisabled
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : widget.color) // null when no custom color → gradient takes over
        : Colors.transparent;

    final borderColor = isSolid
        ? Colors.transparent
        : (isDisabled
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.secondary);

    return AnimatedScale(
      scale: _pressed && !reduceMotion ? 0.96 : 1.0,
      duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
      curve: KeroseneMotion.standard,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          // color must be null when gradient is used — they are mutually exclusive in Flutter
          color: hasGradient ? null : flatColor,
          gradient: hasGradient ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: isSolid ? null : Border.all(color: borderColor, width: 2),
          boxShadow: [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (isHighlighted) {
              if (!isDisabled) {
                setState(() => _pressed = isHighlighted);
              }
            },
            onTap: isDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(AppSpacing.md),
            splashColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(
                        color: foregroundColor,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: foregroundColor, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.text,
                          style: AppTypography.buttonText.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w800,
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
