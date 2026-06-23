import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_display_preferences_provider.dart';
import 'price_provider.dart';

class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() {
    return ref.watch(appDisplayPreferencesProvider).currency;
  }

  Future<void> setCurrency(Currency currency) {
    return ref
        .read(appDisplayPreferencesProvider.notifier)
        .setCurrency(currency);
  }

  Future<void> toggleCurrency() {
    return ref.read(appDisplayPreferencesProvider.notifier).toggleCurrency();
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(
  CurrencyNotifier.new,
);
