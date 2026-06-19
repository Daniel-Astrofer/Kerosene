import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

/// Admin color aliases backed by the public Kerosene brand tokens.
///
/// The admin surface keeps its semantic names because dashboards have table,
/// sidebar and chart-specific needs, but the color source is no longer a
/// parallel palette.
class AdminColors {
  AdminColors._();

  static const Color background = KeroseneBrandTokens.background;
  static const Color backgroundElevated = KeroseneBrandTokens.backgroundSoft;
  static const Color surface = KeroseneBrandTokens.surface;
  static const Color surfaceElevated = KeroseneBrandTokens.surfaceElevated;
  static const Color surfaceHover = KeroseneBrandTokens.surfaceHigh;

  static const Color borderSubtle = KeroseneBrandTokens.borderSubtle;
  static const Color border = KeroseneBrandTokens.border;
  static const Color borderStrong = KeroseneBrandTokens.borderStrong;

  static const Color textPrimary = KeroseneBrandTokens.textPrimary;
  static const Color textSecondary = KeroseneBrandTokens.textSecondary;
  static const Color textTertiary = KeroseneBrandTokens.textMuted;
  static const Color textDisabled = KeroseneBrandTokens.textDisabled;

  static const Color accent = KeroseneBrandTokens.brand;
  static const Color info = KeroseneBrandTokens.info;
  static const Color positive = KeroseneBrandTokens.success;
  static const Color warning = KeroseneBrandTokens.warning;
  static const Color negative = KeroseneBrandTokens.error;

  static const Color positiveSubtle = KeroseneBrandTokens.success;
  static const Color warningSubtle = KeroseneBrandTokens.warning;
  static const Color negativeSubtle = KeroseneBrandTokens.error;
  static const Color infoSubtle = KeroseneBrandTokens.info;
  static const Color accentSubtle = KeroseneBrandTokens.brand;

  static const Color sidebarBg = KeroseneBrandTokens.backgroundSoft;
  static const Color sidebarHover = KeroseneBrandTokens.surface;
  static const Color sidebarActive = KeroseneBrandTokens.surfaceHigh;
  static const Color sidebarText = textSecondary;
  static const Color sidebarTextActive = textPrimary;

  static const Color tableHeader = KeroseneBrandTokens.surface;
  static const Color tableRowHover = KeroseneBrandTokens.surfaceHigh;
  static const Color tableRowAlt = KeroseneBrandTokens.backgroundSoft;

  static const Color chartLine = accent;
  static const Color chartArea = KeroseneBrandTokens.brand;
  static const Color chartGrid = borderSubtle;

  static Color withAlpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
