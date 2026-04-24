import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_typography.dart';

const Color monoBackgroundColor = Color(0xFF020202);
const Color monoSurfaceColor = Color(0xFF0D0D0D);
const Color monoSurfaceAltColor = Color(0xFF141414);
const Color monoSurfaceRaisedColor = Color(0xFF1A1A1A);
const Color monoBorderColor = Color(0xFF262626);
const Color monoBorderStrongColor = Color(0xFF383838);
const Color monoDividerColor = Color(0xFF1B1B1B);
const Color monoTextColor = Color(0xFFF1F1ED);
const Color monoMutedTextColor = Color(0xFFA0A09B);
const Color monoFaintTextColor = Color(0xFF6B6B66);

const BorderRadius monoRadius = BorderRadius.zero;

BoxDecoration monochromePanelDecoration({
  Color color = monoSurfaceColor,
  Color borderColor = monoBorderColor,
  bool showShadow = true,
}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: borderColor),
    boxShadow: showShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              spreadRadius: -18,
              offset: const Offset(0, 14),
            ),
          ]
        : null,
  );
}

InputDecoration monochromeInputDecoration({
  required String label,
  String? hintText,
  String? counterText,
  Widget? suffixIcon,
  Widget? prefixIcon,
}) {
  const border = OutlineInputBorder(
    borderRadius: monoRadius,
    borderSide: BorderSide(color: monoBorderStrongColor),
  );

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    counterText: counterText,
    suffixIcon: suffixIcon,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: monoSurfaceAltColor,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md + 2,
    ),
    labelStyle: AppTypography.bodySmall.copyWith(
      color: monoMutedTextColor,
    ),
    hintStyle: AppTypography.bodySmall.copyWith(
      color: monoFaintTextColor,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: monoRadius,
      borderSide: BorderSide(color: monoTextColor),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: monoRadius,
      borderSide: BorderSide(color: monoTextColor),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: monoRadius,
      borderSide: BorderSide(color: monoTextColor),
    ),
  );
}

ButtonStyle monochromeFilledButtonStyle({
  bool emphasis = true,
  bool destructive = false,
  double minHeight = 52,
}) {
  final background = destructive
      ? monoSurfaceAltColor
      : emphasis
          ? monoTextColor
          : monoSurfaceAltColor;
  final foreground = destructive
      ? monoTextColor
      : emphasis
          ? Colors.black
          : monoTextColor;
  final border =
      destructive || emphasis ? monoBorderStrongColor : monoBorderColor;

  return FilledButton.styleFrom(
    backgroundColor: background,
    foregroundColor: foreground,
    minimumSize: Size.fromHeight(minHeight),
    textStyle: AppTypography.buttonText.copyWith(
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
    ),
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
    side: BorderSide(color: border),
  );
}

ButtonStyle monochromeTextButtonStyle() {
  return TextButton.styleFrom(
    foregroundColor: monoMutedTextColor,
    textStyle: AppTypography.caption.copyWith(
      color: monoMutedTextColor,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w700,
    ),
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
  );
}

ButtonStyle monochromeOutlinedButtonStyle({
  double minHeight = 48,
  Color foregroundColor = monoTextColor,
}) {
  return OutlinedButton.styleFrom(
    minimumSize: Size.fromHeight(minHeight),
    foregroundColor: foregroundColor,
    side: const BorderSide(color: monoBorderStrongColor),
    backgroundColor: monoSurfaceAltColor,
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
    textStyle: AppTypography.buttonText.copyWith(
      letterSpacing: 0.4,
      fontWeight: FontWeight.w600,
    ),
  );
}
