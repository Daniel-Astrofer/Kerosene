import 'package:flutter/material.dart';

/// Kerosene — Core Color Tokens
/// Aligned with the Cybercore Design System (see cyber_theme.dart)
class AppColors {
  // ─── Deep Background ───────────────────────────
  static const Color background = Color(0xFF000000); // Preto AMOLED puro
  static const Color darkSurface = Color(
    0xFF0A0A0A,
  ); // Superfície levemente elevada

  // ─── Primary Accent (Neon Cyan) ────────────────
  static const Color primary = Color(0xFF00FFC2);

  // ─── Secondary Blues ───────────────────────────
  static const Color secondary1 = Color(0xFF00B4FF);
  static const Color secondary2 = Color(0xFF3579A0);
  static const Color secondary3 = Color(0xFF386075);
  static const Color secondary4 = Color(0xFF22424B);

  // ─── Neutral Colors ────────────────────────────
  static const Color grey = Color(0xFF5A5A6E);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ─── Semantic Colors ───────────────────────────
  static const Color success = Color(0xFF00FFC2);
  static const Color error = Color(0xFFFF003C);
  static const Color warning = Color(0xFFFFC371);
}
