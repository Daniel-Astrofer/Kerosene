import 'package:flutter/material.dart';

/// Kerosene — Typography System
/// Refactored for better visibility and cyber-minimalist UI using project fonts.
class AppTypography {
  static const String fontFamily = 'HubotSans';

  static final TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: Colors.white,
    letterSpacing: -1.0,
  );

  static final TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600, // SemiBold
    color: Colors.white,
    letterSpacing: -0.5,
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
    fontWeight: FontWeight.w300, // Light
    color: Colors.white70,
    height: 1.4,
  );

  static final TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w300, // Light
    color: Colors.white38,
    letterSpacing: 0.5,
  );

  static final TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600, // SemiBold
    letterSpacing: 1.0,
    color: Colors.white,
  );

  static final TextStyle number = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    color: Colors.white,
    letterSpacing: 1.0,
  );
}
