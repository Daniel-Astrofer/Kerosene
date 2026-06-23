import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_display_preferences_provider.dart';

class LocaleState {
  final Locale locale;

  LocaleState(this.locale);

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale ?? this.locale);
  }
}

class LocaleNotifier extends Notifier<LocaleState> {
  @override
  LocaleState build() {
    return LocaleState(ref.watch(appDisplayPreferencesProvider).locale);
  }

  Future<void> setLocale(Locale locale) {
    return ref.read(appDisplayPreferencesProvider.notifier).setLocale(locale);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
