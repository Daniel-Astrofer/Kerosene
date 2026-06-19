import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Kerosene Typography System.
///
/// This is the only mobile-app layer allowed to call GoogleFonts directly.
/// Feature code must consume these tokens or Theme.of(context).textTheme.
///
/// Brand direction:
/// - Display / hero / onboarding: Newsreader.
/// - UI / section hierarchy / descriptions: Inter.
/// - Financial values / BTC / sats / hashes: IBM Plex Mono.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';
  static const String bodyFontFamily = fontFamily;
  static const String displayFontFamily = 'Newsreader';
  static const String titleFontFamily = displayFontFamily;
  static const String monoFontFamily = 'IBMPlexMono';
  static const String numericFontFamily = monoFontFamily;
  static const String financialFontFamily = monoFontFamily;

  // Temporary aliases retained while older widgets migrate names.
  // New code should prefer displayFontFamily or financialFontFamily.
  static const String serifFontFamily = displayFontFamily;
  static const String sansHebrewFontFamily = financialFontFamily;

  static TextTheme interTextTheme(TextTheme textTheme) {
    return GoogleFonts.interTextTheme(textTheme);
  }

  // ─────────────────────────────────────────────────────────────
  // Display / hero
  // Usage: main screens, onboarding, hero, large calls.
  // Newsreader, 500/600, mobile 36–44, web 56–72.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle display = newsreader(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.06,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayLarge = newsreader(
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 1.04,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayWeb = newsreader(
    fontSize: 64,
    fontWeight: FontWeight.w600,
    height: 1.04,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle displayWebLarge = newsreader(
    fontSize: 72,
    fontWeight: FontWeight.w600,
    height: 1.02,
    letterSpacing: -1.4,
    color: AppColors.textPrimary,
  );

  // Compatibility aliases.
  static final TextStyle h1 = display;
  static final TextStyle h1Web = displayWeb;

  // ─────────────────────────────────────────────────────────────
  // H2
  // Usage: section titles.
  // Inter, 650/700, mobile 24–30, web 36–44.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle h2 = inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle h2Small = inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle h2Web = inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle h2WebLarge = inter(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────
  // H3
  // Usage: cards, blocks and subtitles.
  // Inter, 600, 18–22.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle h3 = inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.18,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle h3Small = inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.18,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static final TextStyle h3Large = inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.18,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────
  // Description / body
  // Usage: descriptions, long text, explanations.
  // Inter, 400/450, 15–17, line height 1.45–1.60.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle bodyLarge = inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyMedium = inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodySmall = inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  static final TextStyle description = inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  static final TextStyle descriptionStrong = inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────
  // Caption / metadata
  // Usage: dates, labels, secondary status.
  // Inter, 500, 12–13, line height 1.35.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle caption = inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.1,
    color: AppColors.textMuted,
  );

  static final TextStyle captionLarge = inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.1,
    color: AppColors.textMuted,
  );

  static final TextStyle label = inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static final TextStyle buttonText = inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────────────────────────────────────
  // Financial values
  // Usage: BTC, sats, balance, fees, TXID, hashes.
  // IBM Plex Mono, 500/600, tabular figures.
  // ─────────────────────────────────────────────────────────────

  static final TextStyle number = financial(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle amount = financial(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.08,
    color: AppColors.textPrimary,
  );

  static final TextStyle amountLarge = financial(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static final TextStyle amountSmall = financial(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.12,
    color: AppColors.textPrimary,
  );

  static final TextStyle mono = financial(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static TextStyle amountInput({
    required bool isBtc,
    Color color = AppColors.textPrimary,
  }) {
    return financial(
      fontSize: isBtc ? 48 : 56,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.02,
    );
  }

  static TextStyle financial({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return ibmPlexMono(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight ?? FontWeight.w500,
      height: height ?? textStyle?.height ?? 1.08,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing ?? 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle technicalMono({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return financial(
      textStyle: textStyle,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle inter({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.inter(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle newsreader({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.newsreader(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle ibmPlexMono({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.ibmPlexMono(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}
