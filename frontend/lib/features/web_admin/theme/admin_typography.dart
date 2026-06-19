import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_typography.dart';

import 'admin_colors.dart';

/// Kerosene Enterprise — Typography Scale.
/// Uses the shared Kerosene font families: Newsreader, Inter and IBM Plex Mono.
class AdminTypography {
  AdminTypography._();

  static const String fontFamily = AppTypography.bodyFontFamily;
  static const String titleFontFamily = AppTypography.displayFontFamily;
  static const String monoFontFamily = AppTypography.financialFontFamily;

  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _title({
    required double fontSize,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: titleFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _mono({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final TextStyle displayLarge = _title(
    fontSize: 48,
    color: AdminColors.textPrimary,
    height: 1.1,
  );

  static final TextStyle displayMedium = _title(
    fontSize: 36,
    color: AdminColors.textPrimary,
    height: 1.15,
  );

  static final TextStyle h1 = _title(
    fontSize: 28,
    color: AdminColors.textPrimary,
    height: 1.2,
  );

  static final TextStyle h2 = _title(
    fontSize: 22,
    color: AdminColors.textPrimary,
    height: 1.25,
  );

  static final TextStyle h3 = _title(
    fontSize: 18,
    color: AdminColors.textPrimary,
    height: 1.3,
  );

  static final TextStyle h4 = _title(
    fontSize: 15,
    color: AdminColors.textPrimary,
    height: 1.35,
  );

  static final TextStyle bodyLarge = _sans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyMedium = _sans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
    height: 1.5,
  );

  static final TextStyle bodySmall = _sans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AdminColors.textTertiary,
    height: 1.4,
  );

  static final TextStyle label = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    height: 1.3,
  );

  static final TextStyle caption = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AdminColors.textTertiary,
    height: 1.3,
  );

  static final TextStyle metric = _mono(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    height: 1.1,
  );

  static final TextStyle metricSmall = _mono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    height: 1.15,
  );

  static final TextStyle mono = _mono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
    height: 1.4,
  );

  static final TextStyle button = _sans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
  );

  static final TextStyle buttonSmall = _sans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminColors.textSecondary,
  );

  static final TextStyle tableHeader = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    height: 1.3,
  );

  static final TextStyle tableCell = _sans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    height: 1.4,
  );

  static final TextStyle tableCellMono = _mono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    height: 1.4,
  );
}
