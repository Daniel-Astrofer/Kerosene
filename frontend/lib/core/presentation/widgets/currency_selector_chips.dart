import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';

import '../../providers/currency_provider.dart';
import '../../providers/price_provider.dart';
import '../../utils/money_display.dart';

class CurrencySelectorChips extends ConsumerWidget {
  final List<Currency> currencies;
  final Currency? value;
  final ValueChanged<Currency>? onChanged;
  final bool persistSelection;
  final EdgeInsetsGeometry padding;

  const CurrencySelectorChips({
    super.key,
    this.currencies = MoneyDisplay.pickerCurrencies,
    this.value,
    this.onChanged,
    this.persistSelection = true,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = value ?? ref.watch(currencyProvider);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final currency in currencies)
            _CurrencyChip(
              currency: currency,
              selected: currency == selectedCurrency,
              onTap: () async {
                await HapticFeedback.selectionClick();
                if (persistSelection) {
                  await ref
                      .read(currencyProvider.notifier)
                      .setCurrency(currency);
                }
                onChanged?.call(currency);
              },
            ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final Currency currency;
  final bool selected;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.isTinyPhone ? 10 : 14,
          vertical: responsive.isTinyPhone ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          currency.code,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.68),
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
