import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kerosene — Typography System
/// Refactored for better visibility and cyber-minimalist UI using project fonts.
class AppTypography {
  static const String fontFamily = 'HubotSans';
  static const String spaceGroteskVariableFamily = 'SpaceGroteskVariable';
  static const String titleFontFamily = spaceGroteskVariableFamily;
  static const String monoFontFamily = 'IBM Plex Mono';
  static const String numericFontFamily = spaceGroteskVariableFamily;

  static final TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h2 = TextStyle(
    fontFamily: spaceGroteskVariableFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400, // Regular
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600, // SemiBold
    color: Colors.white,
  );

  static final TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500, // Medium (Visible on OLED)
    color: Colors.white,
    height: 1.5,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400, // Regular
    color: Colors.white,
    height: 1.5,
  );

  static final TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular for clearer rendering
    color: Colors.white70,
    height: 1.4,
  );

  static final TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500, // Medium for small uppercase labels
    color: Colors.white38,
    letterSpacing: 0,
  );

  static final TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600, // SemiBold
    letterSpacing: 0,
    color: Colors.white,
  );

  static final TextStyle number = TextStyle(
    fontFamily: numericFontFamily,
    fontSize: 18,
    fontWeight:
        FontWeight.w300, // Lightest weight supported by Space Grotesk VF
    color: Colors.white,
    letterSpacing: 0,
  );

  static TextStyle amountInput({
    required bool isBtc,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontFamily: numericFontFamily,
      fontSize: isBtc ? 48 : 56,
      fontWeight: FontWeight.w300,
      color: color,
      letterSpacing: 0,
      height: 1.0,
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
    return GoogleFonts.geistMono(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    ).copyWith(fontFamilyFallback: const ['JetBrainsMono', 'monospace']);
  }
}
