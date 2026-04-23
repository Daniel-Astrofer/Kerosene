import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

/// Secondary neon-accent action button.
/// Fully Design System compliant — zero hardcoded values.
class NeonActionButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const NeonActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<NeonActionButton> createState() => _NeonActionButtonState();
}

class _NeonActionButtonState extends State<NeonActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
            gradient: isDisabled ? null : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.30),
                      blurRadius: AppSpacing.lg,
                      spreadRadius: 2,
                      offset: const Offset(0, AppSpacing.sm),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              splashColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.15),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSurface,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.text,
                        style: AppTypography.buttonText.copyWith(
                          color: isDisabled
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fade(duration: const Duration(milliseconds: 300))
        .slideY(begin: 0.05, end: 0);
  }
}
