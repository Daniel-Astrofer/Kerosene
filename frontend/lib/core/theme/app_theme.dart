import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teste/core/navigation/app_page_transitions.dart';
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
        colors: [backgroundTop, backgroundMid, backgroundBottom],
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
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: palette.surface,
        surfaceContainerHighest: palette.inputFill,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
        onSurfaceVariant: AppColors.white70,
        onError: AppColors.white,
        secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
        onSecondaryContainer: AppColors.white,
      ),
      disabledColor: AppColors.white.withValues(alpha: 0.42),
      pageTransitionsTheme: kerosenePageTransitionsTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.white,
        selectionColor: AppColors.white.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.white,
      ),
      // Base TextTheme: Inter for body/labels. Headings are mapped through
      // AppTypography to IBM Plex Serif and IBM Plex Sans Hebrew.
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: AppTypography.h1,
        displayMedium: AppTypography.h1,
        displaySmall: AppTypography.h2,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.h3,
        titleSmall: AppTypography.bodyLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.buttonText,
        labelMedium: AppTypography.caption,
        labelSmall: AppTypography.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.48),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
        ),
        floatingLabelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: Colors.white.withValues(alpha: 0.72),
        suffixIconColor: Colors.white.withValues(alpha: 0.72),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.white.withValues(alpha: 0.08),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.white.withValues(alpha: 0.08),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.54),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: AppTypography.buttonText.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.surface,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.52),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.26)),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: AppTypography.buttonText.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.50),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          textStyle: AppTypography.buttonText.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.46),
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
        modalBarrierColor: Colors.black.withValues(alpha: 0.74),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.white,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.black,
        disabledActionTextColor: AppColors.black.withValues(alpha: 0.48),
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
