import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Kerosene — Borders and Radii
class AppRadius {
  static final BorderRadius small = BorderRadius.circular(AppSpacing.sm);
  static final BorderRadius medium = BorderRadius.circular(AppSpacing.md);
  static final BorderRadius large = BorderRadius.circular(AppSpacing.lg);
}

/// Kerosene — Shadows
class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> neonGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.4),
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(0, 0),
    ),
  ];
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'HubotSans',
    useMaterial3: true,

    // ─── Color Scheme ────────────────────────────
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
    ),

    // ─── Page Transitions ────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // ─── Text Theme ──────────────────────────────
    textTheme: TextTheme(
      displayLarge: AppTypography.h1,
      titleLarge: AppTypography.h2,
      titleMedium: AppTypography.h3,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      labelSmall: AppTypography.caption,
    ),

    // ─── Input Decoration ────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF12121C),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.darkGrey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.darkGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: Colors.white.withValues(alpha: 0.25),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey),
    ),

    // ─── Button Theme (Gradient-friendly) ────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.transparent, // We use BouncingButton for gradients
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md + 2,
          horizontal: AppSpacing.lg,
        ),
        textStyle: AppTypography.buttonText,
      ),
    ),

    // ─── AppBar Theme ────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.h2,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // ─── Card Theme ──────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
    ),

    // ─── Dialog Theme ────────────────────────────
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // ─── Bottom Sheet Theme ──────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surface,
    ),

    // ─── Popup Menu Theme ────────────────────────
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // ─── Gradients ─────────────────────────────────
  // Preserving from existing theme.
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [Color(0xFF0F1018), Color(0xFF050508)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
