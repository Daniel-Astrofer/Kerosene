import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kerosene Typography System.
///
/// Only these families are allowed in the app:
/// - Inter: body copy, forms, labels, actions.
/// - IBM Plex Sans Hebrew: numbers, balances, hashes, dense technical data.
/// - IBM Plex Serif: primary editorial/display headings.
class AppTypography {
  // Canonical font-family constants. Keep these strings stable for const
  // TextStyle usages that cannot call GoogleFonts directly.
  static const String fontFamily = 'Inter';
  static const String bodyFontFamily = fontFamily;
  static const String sansHebrewFontFamily = 'IBMPlexSansHebrew';
  static const String titleFontFamily = serifFontFamily;
  static const String monoFontFamily = sansHebrewFontFamily;
  static const String numericFontFamily = sansHebrewFontFamily;
  static const String serifFontFamily = 'IBMPlexSerif';

  static final TextStyle h1 = GoogleFonts.ibmPlexSerif(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h2 = GoogleFonts.ibmPlexSansHebrew(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle h3 = GoogleFonts.ibmPlexSansHebrew(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0,
  );

  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.5,
    letterSpacing: 0,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.5,
    letterSpacing: 0,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.4,
    letterSpacing: 0,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white38,
    letterSpacing: 0,
  );

  static final TextStyle buttonText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: Colors.white,
  );

  static final TextStyle number = GoogleFonts.ibmPlexSansHebrew(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: Colors.white,
    letterSpacing: 0,
  );

  static TextStyle amountInput({
    required bool isBtc,
    Color color = Colors.white,
  }) {
    return GoogleFonts.ibmPlexSansHebrew(
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
    return GoogleFonts.ibmPlexSansHebrew(
      textStyle: textStyle,
      color: color ?? textStyle?.color,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      height: height ?? textStyle?.height,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
    );
  }
}
