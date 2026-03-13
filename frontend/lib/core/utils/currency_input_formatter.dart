import 'package:flutter/services.dart';

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
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allow digits and only ONE decimal separator (point or comma)
    String text = newValue.text.replaceAll(',', '.');

    // Count dots
    int dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) {
      return oldValue;
    }

    // Regex to allow digits and one dot
    final regExp = RegExp(r'^\d*\.?\d*$');
    if (!regExp.hasMatch(text)) {
      return oldValue;
    }

    // Restrict decimal places
    if (text.contains('.')) {
      String decimalsPart = text.split('.')[1];
      if (decimalsPart.length > decimals) {
        return oldValue;
      }
    }

    // Optional: add thousands separator but it might be annoying while typing
    // For now, let's keep it simple and just allow standard decimal typing
    // to match user expectation of "not ATM style"

    return newValue.copyWith(
      text: newValue.text
          .replaceAll('.', '.')
          .replaceAll(',', ','), // keep original separator visually
      selection: newValue.selection,
    );
  }
}
