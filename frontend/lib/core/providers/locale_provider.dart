import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show PlatformDispatcher;

class LocaleState {
  final Locale locale;

  LocaleState(this.locale);

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale ?? this.locale);
  }
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  static const String _localeKey = 'app_locale';

  LocaleNotifier() : super(LocaleState(PlatformDispatcher.instance.locale)) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      state = LocaleState(Locale(languageCode));
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = LocaleState(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((
  ref,
) {
  return LocaleNotifier();
});
