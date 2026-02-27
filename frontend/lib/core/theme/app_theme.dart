import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'HubotSans',
    useMaterial3: true,

    // ─── Color Scheme ────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary1,
      surface: AppColors.darkSurface,
      error: AppColors.error,
    ),

    // ─── Page Transitions ────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // ─── Text Theme ──────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        fontFamily: 'HubotSansExpanded',
        color: Colors.white,
        letterSpacing: -1.0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
    ),

    // ─── Input Decoration (Cybercore) ────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF12121C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E1E30), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E1E30), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
      labelStyle: const TextStyle(color: Color(0xFF8A8A9C)),
    ),

    // ─── Button Theme (Neon Glow) ────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ─── AppBar Theme ────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // ─── Card Theme ──────────────────────────────
    cardTheme: CardThemeData(
      color: const Color(0xFF0E0E16),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ─── Dialog Theme ────────────────────────────
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF0E0E16),
      surfaceTintColor: Colors.transparent,
    ),

    // ─── Bottom Sheet Theme ──────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF0E0E16),
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Color(0xFF0E0E16),
    ),

    // ─── Popup Menu Theme ────────────────────────
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF0E0E16),
      surfaceTintColor: Colors.transparent,
    ),
  );

  // ─── Gradients ─────────────────────────────────
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [Color(0xFF0F1018), Color(0xFF050508)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
