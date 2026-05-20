import 'package:flutter/material.dart';

/// Kerosene — Core Color Tokens
class AppColors {
  // ─── Core Colors ─────────────────────────────────────
  static const Color primary = Color(0xFFF2A900); // Bitcoin gold
  static const Color secondary = Color(0xFF4B8BFF); // Institutional blue
  static const Color accent = Color(0xFF22C7A9); // Teal accent
  static const Color background = Color(0xFF030405);
  static const Color surface = Color(0xFF15171A);

  // Backward compatibility from initial design
  static const Color darkSurface = surface;
  static const Color secondary1 = Color(0xFF4B8BFF);
  static const Color secondary2 = Color(0xFF2D6CDF);
  static const Color secondary3 = Color(0xFF22C7A9);
  static const Color secondary4 = Color(0xFF3A4048);

  // ─── Semantic Colors ─────────────────────────────────
  static const Color error = Color(0xFFFF5A67);
  static const Color warning = Color(0xFFFFC46B);
  static const Color success = Color(0xFF3EDB9B);

  // ─── Neutral Colors ──────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF8B929E);
  static const Color darkGrey = Color(0xFF252A31);

  // ─── Transparency Tokens (Legacy/Shortcut) ─────────────
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  // ─── Extended Tokens for Compatibility ────────────────
  static const Color bgDeep = background;
  static const Color bgCard = surface;
  static const Color border = Color(0xFF2B3037);
  static const Color textPrimary = white;
  static const Color textSecondary = white70;
  static const Color textMuted = grey;
  static const Color neonCyan = accent;
  static const Color bgInput = Color(0xFF101215);

  static const Color surfaceLight = Color(0xFF1C2025);
  static const Color surfaceDark = Color(0xFF070809);

  /// Button gradient used by solid action surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8C45B), Color(0xFFF2A900)],
  );

  /// Alias kept for clarity
  static const LinearGradient buttonGradient = primaryGradient;

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF11151B), Color(0xFF030405)],
  );

  static const LinearGradient onboardingBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF030405),
      Color(0xFF10171B),
      Color(0xFF15120A),
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
