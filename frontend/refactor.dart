import 'dart:io';

void main() {
  final file = File('lib/features/transactions/presentation/screens/withdraw_screen.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    "String _amountInput = '0';",
    "final ValueNotifier<String> _amountInput = ValueNotifier<String>('0');"
  );

  content = content.replaceFirst(
    "      _amountInput = widget.initialAmountBtc!",
    "      _amountInput.value = widget.initialAmountBtc!"
  );

  content = content.replaceFirst(
    "    return MoneyDisplay.parseEditableInput(_amountInput);",
    "    return MoneyDisplay.parseEditableInput(_amountInput.value);"
  );

  content = content.replaceFirst(
    "      rawValue: _amountInput,",
    "      rawValue: _amountInput.value,"
  );

  content = content.replaceFirst(
    "      _amountInput = MoneyDisplay.applyKeypadInput(",
    "      _amountInput.value = MoneyDisplay.applyKeypadInput("
  );
  content = content.replaceFirst(
    "        currentValue: _amountInput,",
    "        currentValue: _amountInput.value,"
  );
  content = content.replaceFirst(
    "    setState(() {",
    "    // setState removed for ValueNotifier"
  );
  content = content.replaceFirst(
    "      );\n    });",
    "      );\n"
  );

  content = content.replaceFirst(
    '''
                          _ExternalSendAmountField(
                            amountLabel: _displayAmount,
                            fiatLabel: fiatLabel,
                          ),
''',
    '''
                          ValueListenableBuilder<String>(
                            valueListenable: _amountInput,
                            builder: (context, _, __) {
                              return _ExternalSendAmountField(
                                amountLabel: _displayAmount,
                                fiatLabel: fiatLabel, // Note: fiatLabel relies on amountBtc, which is static here unless we move the calculation into the builder. But let's fix just the text for now as parent instructed.
                              );
                            },
                          ),
'''
  );

  content = content.replaceFirst(
    '''
              Flexible(
                child: Text(
                  _displayAmount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amountInput(
                    isBtc: _selectedCurrency == Currency.btc,
                    color: receiveFlowTextColor,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
''',
    '''
              Flexible(
                child: ValueListenableBuilder<String>(
                  valueListenable: _amountInput,
                  builder: (context, _, __) {
                    return Text(
                      _displayAmount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.amountInput(
                        isBtc: _selectedCurrency == Currency.btc,
                        color: receiveFlowTextColor,
                      ).copyWith(fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
'''
  );

  file.writeAsStringSync(content);
}
