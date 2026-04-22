import 'package:flutter/material.dart';

/// Kerosene Enterprise — Monochromatic Color System
/// Designed for corporate financial dashboards with maximum clarity.
class AdminColors {
  AdminColors._();

  // ─── Base Tones ──────────────────────────────────
  static const Color background = Color(0xFF0E0E10);
  static const Color backgroundElevated = Color(0xFF141416);
  static const Color surface = Color(0xFF1A1A1E);
  static const Color surfaceElevated = Color(0xFF222228);
  static const Color surfaceHover = Color(0xFF2A2A30);

  // ─── Borders ─────────────────────────────────────
  static const Color border = Color(0xFF2C2C32);
  static const Color borderSubtle = Color(0xFF222228);
  static const Color borderStrong = Color(0xFF3A3A42);

  // ─── Text ────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F2);
  static const Color textSecondary = Color(0xFF9A9AA4);
  static const Color textTertiary = Color(0xFF6A6A74);
  static const Color textDisabled = Color(0xFF4A4A54);

  // ─── Operational Status ──────────────────────────
  static const Color positive = Color(0xFF2ECC71);
  static const Color positiveSubtle = Color(0xFF1A3A2A);
  static const Color negative = Color(0xFFE74C3C);
  static const Color negativeSubtle = Color(0xFF3A1A1A);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningSubtle = Color(0xFF3A2E1A);
  static const Color info = Color(0xFF3498DB);
  static const Color infoSubtle = Color(0xFF1A2A3A);

  // ─── Accent (used sparingly) ─────────────────────
  static const Color accent = Color(0xFF6366F1);
  static const Color accentSubtle = Color(0xFF1E1E3A);

  // ─── Sidebar ─────────────────────────────────────
  static const Color sidebarBg = Color(0xFF0C0C0E);
  static const Color sidebarActive = Color(0xFF1C1C22);
  static const Color sidebarHover = Color(0xFF161618);
  static const Color sidebarText = Color(0xFF8A8A94);
  static const Color sidebarTextActive = Color(0xFFF0F0F2);

  // ─── Table ───────────────────────────────────────
  static const Color tableHeader = Color(0xFF161618);
  static const Color tableRowHover = Color(0xFF1C1C20);
  static const Color tableRowAlt = Color(0xFF141416);

  // ─── Chart ───────────────────────────────────────
  static const Color chartLine = Color(0xFF6366F1);
  static const Color chartArea = Color(0x1A6366F1);
  static const Color chartGrid = Color(0xFF1E1E22);

  // ─── Transparency helpers ────────────────────────
  static Color withAlpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
