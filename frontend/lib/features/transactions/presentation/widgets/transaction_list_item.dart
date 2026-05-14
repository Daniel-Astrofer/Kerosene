import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';

class TransactionListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool isReceive = transaction.type == TransactionType.receive || transaction.type == TransactionType.deposit;
    final IconData icon = isReceive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
    final Color color = isReceive ? AppColors.success : Theme.of(context).colorScheme.error;
    final String label = isReceive ? 'Recebido' : 'Enviado';
    final String prefix = isReceive ? '+' : '-';
    
    // Fallback for types that are not receive/send
    final finalIcon = transaction.type == TransactionType.swap ? LucideIcons.arrowLeftRight : icon;
    final finalColor = transaction.type == TransactionType.swap ? Theme.of(context).colorScheme.secondary : color;
    final finalLabel = transaction.type == TransactionType.swap ? 'Swap' : label;
    final finalPrefix = transaction.type == TransactionType.swap ? '' : prefix;

    final counterparty = isReceive ? transaction.fromAddress : transaction.toAddress;
    final displayAddress = counterparty.length > 12 
        ? '${counterparty.substring(0, 6)}…${counterparty.substring(counterparty.length - 4)}'
        : counterparty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: finalColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: finalColor.withOpacity(0.2)),
            ),
            child: Icon(finalIcon, color: finalColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finalLabel,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  displayAddress,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$finalPrefix${_formatBTC(transaction.amountBTC)}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: finalColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(transaction.timestamp),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
