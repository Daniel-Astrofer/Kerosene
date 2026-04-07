import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';

/// Cyber-minimalist text field with floating label and subtle glass effect.
/// Strictly uses AppColors, AppTypography, and AppSpacing tokens.
class ModernAuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const ModernAuthTextField({
    super.key,
    this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppSpacing.md),
                border: Border.all(color: AppColors.white10),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.white70, size: AppSpacing.md),
                  SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      obscureText: isPassword,
                      onChanged: onChanged,
                      validator: validator,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.white30,
                          fontWeight: FontWeight.w300,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  if (suffixIcon != null) suffixIcon!,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -AppSpacing.sm,
          left: AppSpacing.md,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
