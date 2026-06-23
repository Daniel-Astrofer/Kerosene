import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_list_item.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/design_system/icons.dart';

/// Reusable wallet transaction list with empty, loading and retry states.
class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const TransactionList({
    super.key,
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onRetry,
    this.physics,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (isLoading && transactions.isEmpty) {
      child = _StateContainer(
        icon: KeroseneIcons.receipt,
        title: 'Carregando transações',
        message: 'Sincronizando seu histórico recente.',
        trailing: const SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if ((errorMessage ?? '').trim().isNotEmpty && transactions.isEmpty) {
      child = _StateContainer(
        icon: KeroseneIcons.warning,
        title: 'Não foi possível carregar',
        message: errorMessage!.trim(),
        actionLabel: onRetry == null ? null : 'Tentar novamente',
        onActionPressed: onRetry,
      );
    } else if (transactions.isEmpty) {
      child = const _StateContainer(
        icon: KeroseneIcons.history,
        title: 'Sem transações ainda',
        message:
            'Quando você enviar, receber ou movimentar saldo, o histórico aparece aqui.',
      );
    } else {
      child = ListView.separated(
        key: const ValueKey('transaction-list-items'),
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          return TransactionListItem(transaction: transactions[index]);
        },
      );
    }

    if (onRefresh == null) {
      return child;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: child is ScrollView
          ? child
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              shrinkWrap: shrinkWrap,
              children: [child],
            ),
    );
  }
}

class _StateContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Widget? trailing;

  const _StateContainer({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 26),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.64),
                      height: 1.35,
                    ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.base),
                trailing!,
              ],
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(height: AppSpacing.base),
                OutlinedButton(
                  onPressed: onActionPressed,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
