import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final int maxDigits;
  final int decimals;
  final String symbol;

  CurrencyInputFormatter({
    this.maxDigits = 18,
    this.decimals = 8,
    this.symbol = '',
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove non-digits
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse value
    double value = double.tryParse(newText) ?? 0.0;

    // Calculate divisor based on decimals (e.g. 2 -> 100, 8 -> 100,000,000)
    int divisor = 1;
    for (int i = 0; i < decimals; i++) {
      divisor *= 10;
    }

    // Format
    final formatter = NumberFormat.currency(
      locale:
          'pt_BR', // Using pt_BR for comma separator as requested ("0.000,00")
      customPattern: decimals == 8 ? '#,##0.00000000' : '#,##0.00',
      symbol: symbol,
      decimalDigits: decimals,
    );

    double val = value / divisor;
    String newString = formatter.format(val).trim();

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
