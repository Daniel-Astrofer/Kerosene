import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

class ModernAuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;

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
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.30),
        width: 1,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            fontFamily: 'HubotSansCondensed',
            color: Colors.white.withValues(alpha: 0.76),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          autofocus: autofocus,
          enabled: enabled,
          cursorColor: Colors.white,
          style: AppTypography.bodyLarge.copyWith(
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.58),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.48),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: enabled ? 0.055 : 0.025),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 18,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: enabled ? 0.64 : 0.34),
                size: 16,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: suffixIcon,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            focusedErrorBorder: focusedBorder,
            errorStyle: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFFF6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
