import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

enum BouncingButtonVariant { solid, outlined }

/// Reusable Physics-based scale animation button complying with Figma guidelines.
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
    final isSolid = widget.variant == BouncingButtonVariant.solid;
    final horizontalPadding =
        widget.width == double.infinity ? AppSpacing.lg : AppSpacing.md;

    final foregroundColor = isDisabled
        ? const Color(0xFFA0A09B) // authEntryMuted
        : (isSolid
            ? const Color(0xFF020202) // authEntryInk
            : widget.color ?? const Color(0xFFECECE6));

    final flatColor = isSolid
        ? (isDisabled
            ? const Color(0xFF131313) // authEntrySurfaceRaised
            : widget.color ?? const Color(0xFFECECE6)) // authEntryButton
        : Colors.transparent;

    final borderColor = isSolid
        ? Colors.transparent
        : (isDisabled
            ? const Color(0xFF131313)
            : widget.color ?? const Color(0xFFECECE6));

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutBack,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: flatColor,
          borderRadius: BorderRadius.zero,
          border: isSolid ? null : Border.all(color: borderColor, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.height),
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
              borderRadius: BorderRadius.zero,
              splashColor: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableTextWidth = math.max(
                    0,
                    constraints.maxWidth -
                        (horizontalPadding * 2) -
                        (widget.icon != null ? 28 : 0),
                  );

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.md,
                    ),
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
                                  AnimatedGlyphIcon(
                                    icon: widget.icon!,
                                    color: foregroundColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: availableTextWidth.toDouble(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      style: AppTypography.buttonText.copyWith(
                                        color: foregroundColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
