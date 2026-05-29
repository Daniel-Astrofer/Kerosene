import 'package:flutter_test/flutter_test.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';

void main() {
  group('MoneyDisplay editable input helpers', () {
    test('shows only zero by default', () {
      expect(
        MoneyDisplay.formatEditableInput(
          rawValue: '0',
          currency: Currency.btc,
          withSymbol: false,
        ),
        '0',
      );
    });

    test('preserves only typed decimal places for btc', () {
      expect(
        MoneyDisplay.formatEditableInput(
          rawValue: '12.34',
          currency: Currency.btc,
          withSymbol: false,
        ),
        '12.34',
      );
    });

    test('uses locale separator for fiat input display', () {
      expect(
        MoneyDisplay.formatEditableInput(
          rawValue: '1234.5',
          currency: Currency.brl,
          withSymbol: false,
        ),
        '1.234,5',
      );
    });

    test('keeps trailing decimal separator while typing', () {
      expect(
        MoneyDisplay.formatEditableInput(
          rawValue: '0.',
          currency: Currency.usd,
          withSymbol: false,
        ),
        '0.',
      );
    });

    test('keypad input limits btc decimals and preserves zero state', () {
      var value = '0';
      value = MoneyDisplay.applyKeypadInput(
        currentValue: value,
        key: '.',
        currency: Currency.btc,
      );
      value = MoneyDisplay.applyKeypadInput(
        currentValue: value,
        key: '1',
        currency: Currency.btc,
      );

      for (final digit in ['2', '3', '4', '5', '6', '7', '8', '9']) {
        value = MoneyDisplay.applyKeypadInput(
          currentValue: value,
          key: digit,
          currency: Currency.btc,
        );
      }

      expect(value, '0.12345678');

      final unchanged = MoneyDisplay.applyKeypadInput(
        currentValue: value,
        key: '9',
        currency: Currency.btc,
      );
      expect(unchanged, '0.12345678');

      expect(
        MoneyDisplay.applyKeypadInput(
          currentValue: '0',
          key: '0',
          currency: Currency.btc,
        ),
        '0',
      );
    });
  });
}
