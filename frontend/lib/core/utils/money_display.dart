import 'package:intl/intl.dart';

import '../providers/price_provider.dart';

class MoneyDisplay {
  const MoneyDisplay._();

  static const List<Currency> pickerCurrencies = [
    Currency.btc,
    Currency.usd,
    Currency.brl,
  ];

  static String symbolFor(Currency currency) {
    switch (currency) {
      case Currency.btc:
        return 'BTC';
      case Currency.usd:
        return 'US\$';
      case Currency.eur:
        return 'EUR';
      case Currency.brl:
        return 'R\$';
    }
  }

  static String tickerSymbolFor(Currency currency) {
    switch (currency) {
      case Currency.btc:
        return '₿';
      case Currency.usd:
        return 'US\$';
      case Currency.eur:
        return '€';
      case Currency.brl:
        return 'R\$';
    }
  }

  static String localeFor(Currency currency) {
    switch (currency) {
      case Currency.btc:
      case Currency.usd:
        return 'en_US';
      case Currency.eur:
        return 'de_DE';
      case Currency.brl:
        return 'pt_BR';
    }
  }

  static int decimalsFor(Currency currency) {
    switch (currency) {
      case Currency.btc:
        return 8;
      case Currency.usd:
      case Currency.eur:
      case Currency.brl:
        return 2;
    }
  }

  static double convertFromBtcAmount({
    required double btcAmount,
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return convertFromBtc(
      btcAmount,
      currency,
      btcUsd,
      btcEur,
      btcBrl,
    );
  }

  static double convertToBtcAmount({
    required double amount,
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return convertToBtc(
      amount,
      currency,
      btcUsd,
      btcEur,
      btcBrl,
    );
  }

  static String format({
    required double amount,
    required Currency currency,
    bool withSymbol = true,
    int? decimalPlaces,
  }) {
    final decimals = decimalPlaces ?? decimalsFor(currency);
    final locale = localeFor(currency);

    if (currency == Currency.btc) {
      final formatter = NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = decimals
        ..maximumFractionDigits = decimals;
      final value = formatter.format(amount);
      if (!withSymbol) {
        return value;
      }
      return '${tickerSymbolFor(currency)} $value';
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: withSymbol ? '${symbolFor(currency)} ' : '',
      decimalDigits: decimals,
    );
    return formatter.format(amount).trim();
  }

  static String formatAmountFromBtc({
    required double btcAmount,
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    bool withSymbol = true,
    bool signed = false,
  }) {
    final value = convertFromBtcAmount(
      btcAmount: btcAmount,
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final formatted = format(
      amount: value.abs(),
      currency: currency,
      withSymbol: withSymbol,
    );

    if (!signed) {
      return formatted;
    }

    final prefix = btcAmount >= 0 ? '+' : '-';
    return '$prefix$formatted';
  }

  static String formatQuote({
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (currency == Currency.btc) {
      return '1 BTC = 1 BTC';
    }

    final rate = convertFromBtcAmount(
      btcAmount: 1,
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    if (rate <= 0) {
      return 'Cotacao ao vivo indisponivel';
    }

    return '1 BTC = ${format(amount: rate, currency: currency)}';
  }

  static Currency fallbackFiatFor(Currency currency) {
    switch (currency) {
      case Currency.btc:
        return Currency.brl;
      case Currency.usd:
      case Currency.eur:
      case Currency.brl:
        return Currency.btc;
    }
  }
}
