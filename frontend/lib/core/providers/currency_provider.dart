import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'price_provider.dart';

class CurrencyNotifier extends Notifier<Currency> {
  static const String _currencyKey = 'app_currency';

  @override
  Currency build() {
    _loadCurrency();
    return Currency.usd;
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString(_currencyKey);
    if (currencyCode != null) {
      // Find currency by code, defaulting to USD if not found or error
      try {
        final currency = Currency.values.firstWhere(
          (c) => c.code == currencyCode,
          orElse: () => Currency.usd,
        );
        state = currency;
      } catch (_) {
        state = Currency.usd;
      }
    }
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }

  void toggleCurrency() {
    switch (state) {
      case Currency.btc:
        setCurrency(Currency.usd);
        break;
      case Currency.usd:
        setCurrency(Currency.brl);
        break;
      case Currency.brl:
        setCurrency(Currency.eur);
        break;
      case Currency.eur:
        setCurrency(Currency.btc);
    }
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(
  CurrencyNotifier.new,
);
