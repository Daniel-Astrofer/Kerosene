import 'package:flutter/material.dart';
import '../providers/appearance_provider.dart';
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

class AppThemePalette {
  final Color background;
  final Color backgroundTop;
  final Color backgroundMid;
  final Color backgroundBottom;
  final Color surface;
  final Color border;
  final Color inputFill;

  const AppThemePalette({
    required this.background,
    required this.backgroundTop,
    required this.backgroundMid,
    required this.backgroundBottom,
    required this.surface,
    required this.border,
    required this.inputFill,
  });

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          backgroundTop,
          backgroundMid,
          backgroundBottom,
        ],
      );
}

class AppTheme {
  static AppThemePalette paletteFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.dark:
        return const AppThemePalette(
          background: Color(0xFF081019),
          backgroundTop: Color(0xFF0B1420),
          backgroundMid: Color(0xFF111B28),
          backgroundBottom: Color(0xFF070B10),
          surface: Color(0xFF151F2B),
          border: Color(0xFF233244),
          inputFill: Color(0xFF101722),
        );
      case AppThemeVariant.amoled:
        return const AppThemePalette(
          background: Color(0xFF000000),
          backgroundTop: Color(0xFF050608),
          backgroundMid: Color(0xFF0A0C10),
          backgroundBottom: Color(0xFF000000),
          surface: Color(0xFF13161B),
          border: Color(0xFF20242C),
          inputFill: Color(0xFF0E1014),
        );
      case AppThemeVariant.dimmed:
        return const AppThemePalette(
          background: Color(0xFF14181E),
          backgroundTop: Color(0xFF1B2028),
          backgroundMid: Color(0xFF212733),
          backgroundBottom: Color(0xFF11151A),
          surface: Color(0xFF262C36),
          border: Color(0xFF343C49),
          inputFill: Color(0xFF20252E),
        );
    }
  }

  static ThemeData themeFor(AppThemeVariant variant) {
    final palette = paletteFor(variant);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.border,
      fontFamily: 'HubotSans',
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: palette.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSurface: AppColors.white,
        secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelSmall: AppTypography.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: palette.border, width: 1),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme => themeFor(AppThemeVariant.amoled);

  // ─── Gradients ─────────────────────────────────
  // Preserving from existing theme.
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [Color(0xFF0F1018), Color(0xFF050508)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
