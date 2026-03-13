import 'package:intl/intl.dart';
import '../providers/price_provider.dart';

class CurrencyLogic {
  /// Parses a string input (e.g., "1.234,56") into a double (1234.56).
  /// Handles both dot and comma as decimal separators based on locale assumptions or input.
  static double parseAmount(String text) {
    if (text.isEmpty) return 0.0;

    // Remove all non-numeric characters except dot and comma
    String cleanValue = text.replaceAll(RegExp(r'[^0-9.,]'), '');

    // Replace comma with dot for standard double parsing
    // This is a simplistic approach assuming the user inputs in a format where
    // the last separator is the decimal separator.
    // For "1.000,00" -> replace . with nothing, replace , with . -> 1000.00
    // For "1,000.00" -> replace , with nothing -> 1000.00

    if (cleanValue.contains(',') && cleanValue.contains('.')) {
      // Mixed separators implies thousands and decimal.
      // If last is comma: 1.234,56 -> remove dots, replace comma with dot
      if (cleanValue.lastIndexOf(',') > cleanValue.lastIndexOf('.')) {
        cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Last is dot: 1,234.56 -> remove commas
        cleanValue = cleanValue.replaceAll(',', '');
      }
    } else if (cleanValue.contains(',')) {
      // Only comma: 1234,56 -> replace with dot
      cleanValue = cleanValue.replaceAll(',', '.');
    }

    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Calculates the amount in the source currency unit (BTC, USD, EUR, BRL)
  /// from the raw input value.
  /// Note: The input `text` from CurrencyInputFormatter is usually the formatted string.
  /// If we use the raw unformatted string from the controller in the future, we need to be careful.
  ///
  /// BUT, for `CurrencyInputFormatter` used in `AddFundsScreen`, the text in the controller
  /// is already formatted (e.g. "1.234,56").
  static double getAmountFromInput(String text) {
    return parseAmount(text);
  }

  /// Converts an amount from a source currency to BTC.
  static double convertToBtc({
    required double amount, // In source currency (e.g. 100 USD)
    required Currency fromCurrency,
    required double? btcUsdPrice,
    required double? btcEurPrice,
    required double? btcBrlPrice,
  }) {
    if (amount <= 0) return 0.0;

    switch (fromCurrency) {
      case Currency.btc:
        return amount;
      case Currency.usd:
        return amount / (btcUsdPrice ?? 1);
      case Currency.eur:
        return amount / (btcEurPrice ?? 1);
      case Currency.brl:
        return amount / (btcBrlPrice ?? 1);
    }
  }

  /// Formats a double value into a string with the correct currency format.
  static String formatAmount(
    double amount,
    Currency currency, {
    String locale = 'en_US',
  }) {
    // Map our Currency enum to specific locales if needed, or use the app's current locale.
    // For specific currencies like BRL, we might want to force pt_BR format if that's the convention,
    // but usually, it should follow the user's locale preference (e.g. standard US format for BRL if user is US).
    // However, the request implies "fixed for the whole app", so we should respect the app's global locale.

    final formatter = NumberFormat.currency(
      locale: locale,
      customPattern: currency == Currency.btc ? '#,##0.00000000' : '#,##0.00',
      symbol:
          '', // We usually show the symbol separately or let the UI handle it
      decimalDigits: currency == Currency.btc ? 8 : 2,
    );
    return formatter.format(amount).trim();
  }
}
