import 'package:flutter/material.dart';

/// Color tokens for the backend-served admin surface.
class AdminColors {
  AdminColors._();

  static const Color background = Color(0xFF0E0E10);
  static const Color backgroundElevated = Color(0xFF151519);
  static const Color surface = Color(0xFF1A1A1E);
  static const Color surfaceElevated = Color(0xFF222228);
  static const Color surfaceHover = Color(0xFF2A2A30);

  static const Color borderSubtle = Color(0xFF25252B);
  static const Color border = Color(0xFF303036);
  static const Color borderStrong = Color(0xFF46464E);

  static const Color textPrimary = Color(0xFFF2F2F4);
  static const Color textSecondary = Color(0xFFB7B7C0);
  static const Color textTertiary = Color(0xFF7E7E88);
  static const Color textDisabled = Color(0xFF565660);

  static const Color accent = Color(0xFFE5C978);
  static const Color info = Color(0xFF7AA7E8);
  static const Color positive = Color(0xFF55C98B);
  static const Color warning = Color(0xFFE6B95C);
  static const Color negative = Color(0xFFE06C75);

  static const Color positiveSubtle = Color(0x1F55C98B);
  static const Color warningSubtle = Color(0x1FE6B95C);
  static const Color negativeSubtle = Color(0x1FE06C75);
  static const Color infoSubtle = Color(0x1F7AA7E8);
  static const Color accentSubtle = Color(0x1FE5C978);

  static const Color sidebarBg = Color(0xFF111114);
  static const Color sidebarHover = Color(0xFF1B1B20);
  static const Color sidebarActive = Color(0xFF24242A);
  static const Color sidebarText = textSecondary;
  static const Color sidebarTextActive = textPrimary;

  static const Color tableHeader = Color(0xFF17171B);
  static const Color tableRowHover = Color(0xFF202026);
  static const Color tableRowAlt = Color(0xFF151519);

  static const Color chartLine = accent;
  static const Color chartArea = Color(0x1FE5C978);
  static const Color chartGrid = borderSubtle;

  static Color withAlpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
