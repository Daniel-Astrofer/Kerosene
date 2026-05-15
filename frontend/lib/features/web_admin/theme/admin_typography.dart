import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

/// Kerosene Enterprise — Typography Scale
/// Uses IBM Plex for data-dense dashboards.
class AdminTypography {
  AdminTypography._();

  static const String fontFamily = 'IBM Plex Sans';
  static const String titleFontFamily = 'IBM Plex Serif';
  static const String monoFontFamily = 'IBM Plex Mono';

  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSerif(
      fontSize: fontSize,
      fontWeight: FontWeight.w300,
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
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Display ─────────────────────────────────────
  static final TextStyle displayLarge = _title(
    fontSize: 48,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.1,
  );

  static final TextStyle displayMedium = _title(
    fontSize: 36,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.15,
  );

  // ─── Headings ────────────────────────────────────
  static final TextStyle h1 = _title(
    fontSize: 28,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.2,
  );

  static final TextStyle h2 = _title(
    fontSize: 22,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
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
    letterSpacing: 0,
    height: 1.35,
  );

  // ─── Body ────────────────────────────────────────
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

  // ─── Labels & Captions ──────────────────────────
  static final TextStyle label = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    letterSpacing: 0,
    height: 1.3,
  );

  static final TextStyle caption = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AdminColors.textTertiary,
    height: 1.3,
  );

  // ─── Numeric / Data ─────────────────────────────
  static final TextStyle metric = _mono(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.1,
  );

  static final TextStyle metricSmall = _mono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.15,
  );

  static final TextStyle mono = _mono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
    letterSpacing: 0,
    height: 1.4,
  );

  // ─── Button ─────────────────────────────────────
  static final TextStyle button = _sans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
  );

  static final TextStyle buttonSmall = _sans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminColors.textSecondary,
    letterSpacing: 0,
  );

  // ─── Table ──────────────────────────────────────
  static final TextStyle tableHeader = _sans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    letterSpacing: 0,
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
    letterSpacing: 0,
    height: 1.4,
  );
}
