import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_visuals.dart';
import '../../domain/entities/transaction.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Lista de transações recentes com design premium e animações staggered
class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.ghost,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.1),
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nenhuma transação encontrada',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.3),
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ),
      ).animate().fade().scale(curve: Curves.easeOutBack);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return TransactionItemWidget(transaction: transactions[index])
            .animate(delay: (index * 50).ms)
            .fade(duration: 300.ms)
            .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class TransactionItemWidget extends StatefulWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  State<TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<TransactionItemWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final visual = TransactionVisualSpec.fromTransaction(t);
    final statusColor = visual.amountColor;

    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        padding: EdgeInsets.zero,
        border: Border.all(
          color: _isExpanded
              ? statusColor.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
          width: 1,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: [
                  // Icon Block
                  TransactionTypeIconBadge(
                    spec: visual,
                    size: 44,
                    iconSize: 20,
                    borderRadius: AppSpacing.sm,
                    backgroundColor: const Color(0xFF111720),
                    borderColor: statusColor.withValues(alpha: 0.24),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Info Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description ?? visual.localizedLabel(context),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(t.timestamp).toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                        .withValues(alpha: 0.3),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Amount Block
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBtcAmount(
                        t.amountBTC.abs(),
                        visual.prefix,
                        statusColor,
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(t.status, statusColor),
                    ],
                  ),
                ],
              ),
            ),

            // Details Expansion
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.05)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow('TXID', t.id),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDetailRow('TIMESTAMP', t.timestamp.toIso8601String()),
                    const SizedBox(height: AppSpacing.xs),
                    _buildDetailRow('BLOCKCHAIN FEE', '${t.feeSatoshis} SATS'),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtcAmount(double amount, String prefix, Color color) {
    final parts = amount.toStringAsFixed(8).split('.');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrainsMono'),
          ),
        Text(
          parts[0],
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrainsMono'),
        ),
        Text(
          '.${parts[1]}',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              fontFamily: 'JetBrainsMono'),
        ),
        const SizedBox(width: 4),
        Text(
          'BTC',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color.withValues(alpha: 0.4),
              fontWeight: FontWeight.w900,
              fontSize: 8),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TransactionStatus status, Color baseColor) {
    String text;
    bool isProcessing = false;

    switch (status) {
      case TransactionStatus.pending:
      case TransactionStatus.confirming:
        text = 'PROCESSANDO';
        isProcessing = true;
        break;
      case TransactionStatus.confirmed:
        text = 'CONFIRMADO';
        break;
      case TransactionStatus.failed:
        text = 'FALHOU';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isProcessing
            ? AppColors.warning.withValues(alpha: 0.1)
            : baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: isProcessing
                ? AppColors.warning.withValues(alpha: 0.3)
                : baseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing) ...[
            const SizedBox(
              width: 6,
              height: 6,
              child: CircularProgressIndicator(
                  strokeWidth: 1, color: AppColors.warning),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isProcessing ? AppColors.warning : baseColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.2),
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.5),
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                ),
          ),
        ),
      ],
    );
  }
}
