import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/localization/app_localization_manager.dart';

import 'price_provider.dart';
import 'shared_preferences_provider.dart';

class AppDisplayPreferencesState {
  final Locale locale;
  final Currency currency;

  const AppDisplayPreferencesState({
    required this.locale,
    required this.currency,
  });

  AppDisplayPreferencesState copyWith({
    Locale? locale,
    Currency? currency,
  }) {
    return AppDisplayPreferencesState(
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
    );
  }
}

class AppDisplayPreferencesNotifier
    extends Notifier<AppDisplayPreferencesState> {
  static const String _localeKey = 'app_locale';
  static const String _currencyKey = 'app_currency';

  @override
  AppDisplayPreferencesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final locale = AppLocalizationManager.resolve(
      Locale(prefs.getString(_localeKey) ??
          AppLocalizationManager.deviceOrFallback().languageCode),
    );
    final currency = _parseCurrency(prefs.getString(_currencyKey));

    return AppDisplayPreferencesState(
      locale: locale,
      currency: currency,
    );
  }

  Future<void> setLocale(Locale locale) async {
    final next = AppLocalizationManager.resolve(locale);
    state = state.copyWith(locale: next);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_localeKey, next.languageCode);
  }

  Future<void> setCurrency(Currency currency) async {
    state = state.copyWith(currency: currency);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_currencyKey, currency.code);
  }

  Future<void> toggleCurrency() async {
    switch (state.currency) {
      case Currency.usd:
        await setCurrency(Currency.brl);
        break;
      case Currency.brl:
        await setCurrency(Currency.eur);
        break;
      case Currency.eur:
        await setCurrency(Currency.btc);
        break;
      case Currency.btc:
        await setCurrency(Currency.usd);
        break;
    }
  }

  Currency _parseCurrency(String? code) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return Currency.brl;
    }
    return Currency.values.firstWhere(
      (currency) => currency.code == normalized,
      orElse: () => Currency.brl,
    );
  }
}

final appDisplayPreferencesProvider =
    NotifierProvider<AppDisplayPreferencesNotifier, AppDisplayPreferencesState>(
  AppDisplayPreferencesNotifier.new,
);
