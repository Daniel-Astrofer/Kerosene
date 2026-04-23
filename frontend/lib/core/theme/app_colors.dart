import 'package:flutter/material.dart';

/// Kerosene — Core Color Tokens
class AppColors {
  // ─── Core Colors ─────────────────────────────────────
  static const Color primary = Color(0xFF6A11CB); // Purple (Primary UI)
  static const Color secondary = Color(0xFF2575FC); // Blue (Secondary UI)
  static const Color accent = Color(0xFF00E5BC); // Neon Green (Accent only)
  static const Color background =
      Color(0xFF000000); // Deep AMOLED Black (Figma)
  static const Color surface = Color(0xFF1A1A1B); // Surface/Glass (Figma)

  // Backward compatibility from initial design
  static const Color darkSurface = Color(0xFF1A1A1B);
  static const Color secondary1 = Color(0xFF0073D0);
  static const Color secondary2 = Color(0xFF3579A0);
  static const Color secondary3 = Color(0xFF386075);
  static const Color secondary4 = Color(0xFF22424B);

  // ─── Semantic Colors ─────────────────────────────────
  static const Color error = Color(0xFFFF003C); // Neon Red/Crimson
  static const Color warning = Color(0xFFFFC371); // Neon Orange/Yellow
  static const Color success = Color(0xFF00FF9D); // Neon Green

  // ─── Neutral Colors ──────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF5A5A6E);
  static const Color darkGrey = Color(0xFF1E1E30);

  // ─── Transparency Tokens (Legacy/Shortcut) ─────────────
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  // ─── Extended Tokens for Compatibility ────────────────
  static const Color bgDeep = background;
  static const Color bgCard = surface;
  static const Color border = darkGrey;
  static const Color textPrimary = white;
  static const Color textSecondary = white70;
  static const Color textMuted = grey;
  static const Color neonCyan = primary;
  static const Color bgInput = Color(0xFF121212);

  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color surfaceDark = Color(0xFF050505);

  /// Button gradient: light blue (#60A5FA) → dark blue (#1D4ED8)
  /// Used by all BouncingButton solid instances in the auth flow.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
  );

  /// Alias kept for clarity
  static const LinearGradient buttonGradient = primaryGradient;

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0B1E), Color(0xFF000000)], // Subtly purplish black
  );

  static const Color onboardingBackgroundTop = Color(0xFF07090E);
  static const Color onboardingBackgroundMid = Color(0xFF0B1017);
  static const Color onboardingBackgroundBottom = Color(0xFF050608);

  static const LinearGradient onboardingBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      onboardingBackgroundTop,
      onboardingBackgroundMid,
      onboardingBackgroundBottom,
    ],
  );

  static TextStyle heading({required double size, Color color = white}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }
}
