import 'package:flutter/material.dart';
import 'admin_colors.dart';

/// Kerosene Enterprise — Typography Scale
/// Uses HubotSans with variants optimized for data-dense dashboards.
class AdminTypography {
  AdminTypography._();

  static const String _fontFamily = 'HubotSans';
  static const String _condensed = 'HubotSansCondensed';

  // ─── Display ─────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.15,
  );

  // ─── Headings ────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.35,
  );

  // ─── Body ────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AdminColors.textTertiary,
    height: 1.4,
  );

  // ─── Labels & Captions ──────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AdminColors.textTertiary,
    height: 1.3,
  );

  // ─── Numeric / Data ─────────────────────────────
  static const TextStyle metric = TextStyle(
    fontFamily: _condensed,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.1,
  );

  static const TextStyle metricSmall = TextStyle(
    fontFamily: _condensed,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.15,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: _condensed,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
    letterSpacing: 0,
    height: 1.4,
  );

  // ─── Button ─────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminColors.textSecondary,
    letterSpacing: 0,
  );

  // ─── Table ──────────────────────────────────────
  static const TextStyle tableHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminColors.textTertiary,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle tableCell = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle tableCellMono = TextStyle(
    fontFamily: _condensed,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AdminColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );
}
