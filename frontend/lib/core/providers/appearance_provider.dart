import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Variants ──────────────────────────────────
enum AppThemeVariant { dark, amoled, dimmed }

extension AppThemeVariantX on AppThemeVariant {
  String get label {
    switch (this) {
      case AppThemeVariant.dark:
        return 'Dark';
      case AppThemeVariant.amoled:
        return 'AMOLED Black';
      case AppThemeVariant.dimmed:
        return 'Dimmed';
    }
  }

  String get description {
    switch (this) {
      case AppThemeVariant.dark:
        return 'Dark grey surfaces with depth';
      case AppThemeVariant.amoled:
        return 'Pure black saves battery on OLED';
      case AppThemeVariant.dimmed:
        return 'Softer contrast for night use';
    }
  }
}

// ─── Font Scale ───────────────────────────────────────
enum AppFontScale { small, normal, large, xlarge }

extension AppFontScaleX on AppFontScale {
  String get label {
    switch (this) {
      case AppFontScale.small:
        return 'Small';
      case AppFontScale.normal:
        return 'Normal';
      case AppFontScale.large:
        return 'Large';
      case AppFontScale.xlarge:
        return 'Extra Large';
    }
  }

  double get scaleFactor {
    switch (this) {
      case AppFontScale.small:
        return 0.85;
      case AppFontScale.normal:
        return 1.0;
      case AppFontScale.large:
        return 1.15;
      case AppFontScale.xlarge:
        return 1.3;
    }
  }
}

// ─── State ────────────────────────────────────────────
class AppearanceState {
  final AppThemeVariant themeVariant;
  final AppFontScale fontScale;

  const AppearanceState({
    this.themeVariant = AppThemeVariant.amoled,
    this.fontScale = AppFontScale.normal,
  });

  AppearanceState copyWith({
    AppThemeVariant? themeVariant,
    AppFontScale? fontScale,
  }) {
    return AppearanceState(
      themeVariant: themeVariant ?? this.themeVariant,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────
class AppearanceNotifier extends Notifier<AppearanceState> {
  static const _themeKey = 'appearance_theme';
  static const _fontKey = 'appearance_font_scale';

  @override
  AppearanceState build() {
    _load();
    return const AppearanceState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? AppThemeVariant.amoled.index;
    final fontIndex = prefs.getInt(_fontKey) ?? AppFontScale.normal.index;

    state = AppearanceState(
      themeVariant: AppThemeVariant.values[themeIndex.clamp(0, AppThemeVariant.values.length - 1)],
      fontScale: AppFontScale.values[fontIndex.clamp(0, AppFontScale.values.length - 1)],
    );
  }

  Future<void> setThemeVariant(AppThemeVariant variant) async {
    state = state.copyWith(themeVariant: variant);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, variant.index);
  }

  Future<void> setFontScale(AppFontScale scale) async {
    state = state.copyWith(fontScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontKey, scale.index);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(AppearanceNotifier.new);
