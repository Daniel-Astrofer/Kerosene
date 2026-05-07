import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// CyberTheme — Sistema de design "Cyberpunk/Minimalist" do Kerosene
class CyberTheme {
  // ─── Colors ──────────────────────────────────────────
  static const Color bgDeep = AppColors.background;
  static const Color bgCard = AppColors.surface;
  static const Color border = AppColors.darkGrey;
  static const Color textSecondary = AppColors.grey;

  static const Color neonCyan = AppColors.primary;
  static const Color neonAmber = AppColors.warning;
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color neonGreen = AppColors.success;
  static const Color neonRed = AppColors.error;

  // ─── Gradients ───────────────────────────────────────
  static final LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDeep, bgDeep, const Color(0xFF050510), const Color(0xFF0A0A1F)],
    stops: const [0.0, 0.6, 0.9, 1.0],
  );

  // ─── Typography ──────────────────────────────────────
  static TextStyle heading({double size = 24, Color color = Colors.white}) {
    return AppTypography.h2.copyWith(fontSize: size, color: color);
  }

  static TextStyle label({double size = 12, Color color = Colors.white70}) {
    return AppTypography.caption.copyWith(fontSize: size, color: color);
  }

  // ─── Decorations ─────────────────────────────────────
  static List<BoxShadow> subtleGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.1),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> glow(Color color, {double blur = 12}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  // ─── UI Components ───────────────────────────────────
  static InputDecoration cyberInput({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: neonCyan.withValues(alpha: 0.7), size: 20),
      suffixIcon: suffix,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonRed, width: 1.5),
      ),
    );
  }

  static ButtonStyle neonButton(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: bgDeep,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}
