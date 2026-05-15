import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kerosene — Typography System
/// IBM Plex typography system shared by the app.
class AppTypography {
  static const String fontFamily = 'IBM Plex Sans';
  static const String titleFontFamily = 'IBM Plex Serif';
  static const String monoFontFamily = 'IBM Plex Mono';
  static const String numericFontFamily = monoFontFamily;

  static TextStyle sans({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexSans(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    );
  }

  static TextStyle title({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexSerif(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: FontWeight.w300,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    );
  }

  static TextStyle mono({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    );
  }

  static final TextStyle h1 = title(
    fontSize: 32,
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h2 = title(
    fontSize: 24,
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h3 = title(
    fontSize: 20,
    color: Colors.white,
  );

  static final TextStyle bodyLarge = sans(
    fontSize: 17,
    fontWeight: FontWeight.w500, // Medium (Visible on OLED)
    color: Colors.white,
    height: 1.5,
  );

  static final TextStyle bodyMedium = sans(
    fontSize: 15,
    fontWeight: FontWeight.w400, // Regular
    color: Colors.white,
    height: 1.5,
  );

  static final TextStyle bodySmall = sans(
    fontSize: 13,
    fontWeight: FontWeight.w400, // Regular for clearer rendering
    color: Colors.white70,
    height: 1.4,
  );

  static final TextStyle caption = sans(
    fontSize: 11,
    fontWeight: FontWeight.w500, // Medium for small uppercase labels
    color: Colors.white38,
    letterSpacing: 0,
  );

  static final TextStyle buttonText = sans(
    fontSize: 15,
    fontWeight: FontWeight.w600, // SemiBold
    letterSpacing: 0,
    color: Colors.white,
  );

  static final TextStyle number = mono(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: 0,
  );

  static TextStyle amountInput({
    required bool isBtc,
    Color color = Colors.white,
  }) {
    return mono(
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
    return mono(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    );
  }
}
