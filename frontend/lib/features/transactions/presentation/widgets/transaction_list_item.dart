import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/transaction_address_display.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/safe_display_text.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return '${diff.inMinutes}m atrás';
    if (diff.inDays < 1) return '${diff.inHours}h atrás';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatBTC(double v) {
    if (v < 0.00001) return '${(v * 1e8).toStringAsFixed(0)} sat';
    return '${v.toStringAsFixed(6)} BTC';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = TransactionVisualSpec.fromTransaction(transaction);
    final selectedCurrency = ref.watch(currencyProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: transaction.amountBTC,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    final counterparty = resolvePrimaryTransactionAddress(transaction).trim();
    final displayAddress = SafeDisplayText.displayAddress(
      context,
      counterparty,
    );
    final cardGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.lerp(const Color(0xFF101923), visual.amountColor, 0.18)!,
        Colors.black,
        const Color(0xFF121A24),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: visual.amountColor.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            TransactionTypeIconBadge(
              spec: visual,
              size: 44,
              iconSize: 20,
              borderRadius: 14,
              backgroundColor: const Color(0xFF111720),
              borderColor: visual.iconColor.withValues(alpha: 0.24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visual.localizedLabel(context),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayAddress,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.4)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${visual.prefix}$amountLabel',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: visual.amountColor,
                      ),
                ),
                if (selectedCurrency != Currency.btc) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${visual.prefix}${_formatBTC(transaction.amountBTC)}',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.3),
                        ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.timestamp),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
