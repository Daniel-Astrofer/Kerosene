import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
/// Cybercore Design System — Kerosene Fintech
/// ═══════════════════════════════════════════════════════════════
/// All design tokens for the High-Tech / Industrial aesthetic.
/// Usage: `CyberTheme.neonCyan`, `CyberTheme.bgDeep`, etc.
///
/// DO NOT use raw Color() literals in screens. Import this file.
/// ═══════════════════════════════════════════════════════════════
class CyberTheme {
  CyberTheme._(); // Non-instantiable

  // ─── Background Palette ────────────────────────────────────
  static const Color bgDeep = Color(0xFF050508);
  static const Color bgSurface = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF0E0E16);
  static const Color bgInput = Color(0xFF12121C);
  static const Color bgElevated = Color(0xFF181824);

  // ─── Neon / Accent Palette ─────────────────────────────────
  static const Color neonCyan = Color(0xFF00D4FF); // Was Cyan/Green, now Neon Blue
  static const Color neonBlue = Color(0xFF4CC9F0); // A lighter blue
  static const Color neonRed = Color(0xFFFF003C); // Error / Destructive
  static const Color neonPurple = Color(0xFF7B61FF); // Accent / Branding
  static const Color neonAmber = Color(0xFFFFC371); // Warnings

  // ─── Text Hierarchy ────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAEAF0);
  static const Color textSecondary = Color(0xFF8A8A9C);
  static const Color textMuted = Color(0xFF5A5A6E);

  // ─── Border / Divider ──────────────────────────────────────
  static const Color border = Color(0xFF1E1E30);
  static const Color borderActive = Color(0xFF2A2A40);

  // ─── Gradients ─────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgDeep, Color(0xFF080808)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F1018), Color(0xFF0A0A10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient neonBtnGradient(Color c) => LinearGradient(
    colors: [c, c.withValues(alpha: 0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glow Shadows ─────────────────────────────────────────
  static List<BoxShadow> glow(Color c, {double blur = 20, double spread = 0}) =>
      [
        BoxShadow(
          color: c.withValues(alpha: 0.25),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> subtleGlow(Color c) => [
    BoxShadow(
      color: c.withValues(alpha: 0.08),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // ─── Shapes ────────────────────────────────────────────────
  /// Industrial beveled shape for cards and containers
  static const BeveledRectangleBorder beveledShape = BeveledRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    ),
  );

  static ShapeDecoration beveledDecoration({
    Color? borderColor,
    Color? fillColor,
  }) => ShapeDecoration(
    color: fillColor ?? bgCard,
    shape: BeveledRectangleBorder(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      side: BorderSide(color: borderColor ?? border, width: 1),
    ),
  );

  // ─── Text Styles (Monospaced Data) ─────────────────────────
  static TextStyle monoData({
    double size = 14,
    Color? color,
    FontWeight? weight,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    color: color ?? textPrimary,
    fontWeight: weight ?? FontWeight.w500,
  );

  static TextStyle heading({double size = 28, Color? color}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color ?? textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle label({double size = 12, Color? color}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color ?? textSecondary,
    letterSpacing: 1.2,
  );

  // ─── Input Decoration ──────────────────────────────────────
  static InputDecoration cyberInput({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
    hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.6), fontSize: 13),
    filled: true,
    fillColor: bgInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: neonCyan, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: neonRed, width: 1),
    ),
    prefixIcon: icon != null ? Icon(icon, color: textMuted, size: 20) : null,
    suffixIcon: suffix,
  );

  // ─── Button Styles ─────────────────────────────────────────
  static ButtonStyle neonButton(Color c) => ElevatedButton.styleFrom(
    backgroundColor: c,
    foregroundColor: bgDeep,
    elevation: 0,
    shadowColor: c.withValues(alpha: 0.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    ),
  );

  static ButtonStyle ghostButton({Color? borderColor}) =>
      OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: BorderSide(color: borderColor ?? border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      );
}
