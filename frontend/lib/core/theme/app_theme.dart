import 'package:flutter/material.dart';
import 'package:kerosene/core/navigation/app_page_transitions.dart';
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
      case AppThemeVariant.light:
        return const AppThemePalette(
          background: Color(0xFFF7F7F5),
          backgroundTop: Color(0xFFFFFFFF),
          backgroundMid: Color(0xFFF7F7F5),
          backgroundBottom: Color(0xFFEDEDEA),
          surface: Color(0xFFFFFFFF),
          border: Color(0xFFD9DAD6),
          inputFill: Color(0xFFF0F1EE),
        );
    }
  }

  static ThemeData themeFor(AppThemeVariant variant) {
    final palette = paletteFor(variant);
    final isLight = variant == AppThemeVariant.light;
    final brightness = isLight ? Brightness.light : Brightness.dark;
    final onSurface = isLight ? const Color(0xFF181A17) : AppColors.white;
    final onSurfaceVariant =
        isLight ? const Color(0xFF62675F) : AppColors.white70;
    final hintColor = isLight
        ? const Color(0xFF8B9087)
        : Colors.white.withValues(alpha: 0.48);
    final labelColor = isLight
        ? const Color(0xFF5F645B)
        : Colors.white.withValues(alpha: 0.72);
    final baseTextTheme =
        isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme;
    final colorScheme = isLight
        ? ColorScheme.light(
            primary: AppColors.black,
            secondary: AppColors.secondary,
            surface: palette.surface,
            surfaceContainerHighest: palette.inputFill,
            error: AppColors.error,
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            onError: AppColors.white,
            secondaryContainer: AppColors.secondary.withValues(alpha: 0.12),
            onSecondaryContainer: onSurface,
          )
        : ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: palette.surface,
            surfaceContainerHighest: palette.inputFill,
            error: AppColors.error,
            onPrimary: AppColors.white,
            onSecondary: AppColors.white,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            onError: AppColors.white,
            secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
            onSecondaryContainer: AppColors.white,
          );
    final filledBackground = isLight ? AppColors.black : AppColors.white;
    final filledForeground = isLight ? AppColors.white : AppColors.black;
    final disabledBackground =
        onSurface.withValues(alpha: isLight ? 0.08 : 0.08);
    final disabledForeground =
        onSurface.withValues(alpha: isLight ? 0.38 : 0.54);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.border,
      fontFamily: AppTypography.fontFamily,
      useMaterial3: true,
      colorScheme: colorScheme,
      disabledColor: onSurface.withValues(alpha: 0.42),
      pageTransitionsTheme: kerosenePageTransitionsTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: onSurface,
        selectionColor: onSurface.withValues(alpha: 0.18),
        selectionHandleColor: onSurface,
      ),
      // Base TextTheme: Inter for body/labels.
      // Display and hero moments use Newsreader.
      // Financial and technical values use IBM Plex Mono with tabular figures.
      textTheme: AppTypography.interTextTheme(baseTextTheme).copyWith(
        displayLarge: AppTypography.displayLarge.copyWith(color: onSurface),
        displayMedium: AppTypography.display.copyWith(color: onSurface),
        displaySmall: AppTypography.h2.copyWith(color: onSurface),
        headlineLarge: AppTypography.display.copyWith(color: onSurface),
        headlineMedium: AppTypography.h2.copyWith(color: onSurface),
        headlineSmall: AppTypography.h3.copyWith(color: onSurface),
        titleLarge: AppTypography.h2.copyWith(color: onSurface),
        titleMedium: AppTypography.h3.copyWith(color: onSurface),
        titleSmall: AppTypography.descriptionStrong.copyWith(color: onSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: onSurface),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: onSurface),
        bodySmall: AppTypography.bodySmall.copyWith(color: onSurfaceVariant),
        labelLarge: AppTypography.buttonText.copyWith(color: onSurface),
        labelMedium: AppTypography.captionLarge.copyWith(color: onSurfaceVariant),
        labelSmall: AppTypography.caption.copyWith(color: onSurfaceVariant),
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
        hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
        labelStyle: AppTypography.bodyMedium.copyWith(color: labelColor),
        floatingLabelStyle: AppTypography.bodyMedium.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: labelColor,
        suffixIconColor: labelColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: filledBackground,
          foregroundColor: filledForeground,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
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
          backgroundColor: filledBackground,
          foregroundColor: filledForeground,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
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
          foregroundColor: onSurface,
          disabledForegroundColor: onSurface.withValues(alpha: 0.52),
          side: BorderSide(color: onSurface.withValues(alpha: 0.22)),
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
          foregroundColor: onSurface,
          disabledForegroundColor: onSurface.withValues(alpha: 0.50),
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
          foregroundColor: onSurface,
          disabledForegroundColor: onSurface.withValues(alpha: 0.46),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2,
        iconTheme: IconThemeData(color: onSurface),
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
        modalBarrierColor:
            Colors.black.withValues(alpha: isLight ? 0.30 : 0.74),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.bodyMedium.copyWith(color: onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: filledBackground,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: filledForeground,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: filledForeground,
        disabledActionTextColor: filledForeground.withValues(alpha: 0.48),
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
