import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/localization/app_localization_manager.dart';

import 'shared_preferences_provider.dart';

class LocaleState {
  final Locale locale;

  LocaleState(this.locale);

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale ?? this.locale);
  }
}

class LocaleNotifier extends Notifier<LocaleState> {
  static const String _localeKey = 'app_locale';

  @override
  LocaleState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      return LocaleState(AppLocalizationManager.resolve(Locale(languageCode)));
    }
    return LocaleState(AppLocalizationManager.deviceOrFallback());
  }

  Future<void> setLocale(Locale locale) async {
    final next = AppLocalizationManager.resolve(locale);
    state = LocaleState(next);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_localeKey, next.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
