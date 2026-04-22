import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_typography.dart';

/// Kerosene Enterprise — Material Theme Data
/// Square corners, monochrome palette, institutional look.
class AdminTheme {
  AdminTheme._();

  // ─── Spacing Tokens ─────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacing3xl = 48;

  // ─── Border Radius ──────────────────────────────
  static const double radiusNone = 0;
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 6;

  static BorderRadius get borderRadiusXs =>
      BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm =>
      BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd =>
      BorderRadius.circular(radiusMd);

  // ─── Sidebar ────────────────────────────────────
  static const double sidebarWidth = 240;
  static const double sidebarCollapsedWidth = 64;

  // ─── Top Bar ────────────────────────────────────
  static const double topBarHeight = 56;

  // ─── ThemeData ──────────────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.background,
      canvasColor: AdminColors.background,
      dividerColor: AdminColors.border,
      fontFamily: 'HubotSans',
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.accent,
        secondary: AdminColors.info,
        surface: AdminColors.surface,
        error: AdminColors.negative,
        onPrimary: AdminColors.textPrimary,
        onSurface: AdminColors.textPrimary,
        onError: AdminColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: AdminTypography.displayLarge,
        headlineLarge: AdminTypography.h1,
        headlineMedium: AdminTypography.h2,
        headlineSmall: AdminTypography.h3,
        titleLarge: AdminTypography.h3,
        titleMedium: AdminTypography.h4,
        bodyLarge: AdminTypography.bodyLarge,
        bodyMedium: AdminTypography.bodyMedium,
        bodySmall: AdminTypography.bodySmall,
        labelLarge: AdminTypography.button,
        labelMedium: AdminTypography.label,
        labelSmall: AdminTypography.caption,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AdminColors.borderStrong),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.backgroundElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusSm,
          borderSide: const BorderSide(color: AdminColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusSm,
          borderSide: const BorderSide(color: AdminColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusSm,
          borderSide: const BorderSide(color: AdminColors.accent, width: 1.5),
        ),
        hintStyle: AdminTypography.bodyMedium.copyWith(
          color: AdminColors.textDisabled,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.accent,
          foregroundColor: AdminColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
          padding: const EdgeInsets.symmetric(
            vertical: spacingMd,
            horizontal: spacingXl,
          ),
          textStyle: AdminTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textSecondary,
          side: const BorderSide(color: AdminColors.border),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
          padding: const EdgeInsets.symmetric(
            vertical: spacingMd,
            horizontal: spacingXl,
          ),
          textStyle: AdminTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusSm),
          padding: const EdgeInsets.symmetric(
            vertical: spacingSm,
            horizontal: spacingLg,
          ),
          textStyle: AdminTypography.buttonSmall,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusSm,
          side: const BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AdminColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusSm,
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AdminColors.surfaceElevated,
          borderRadius: borderRadiusSm,
          border: Border.all(color: AdminColors.border),
        ),
        textStyle: AdminTypography.caption.copyWith(
          color: AdminColors.textPrimary,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AdminColors.tableHeader),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AdminColors.tableRowHover;
          }
          return Colors.transparent;
        }),
        headingTextStyle: AdminTypography.tableHeader,
        dataTextStyle: AdminTypography.tableCell,
        dividerThickness: 1,
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AdminColors.textSecondary,
        size: 20,
      ),
    );
  }
}
