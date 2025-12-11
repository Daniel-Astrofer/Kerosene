import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Lista de transações recentes
class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Nenhuma transação encontrada',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isSent = transaction.type == TransactionType.send;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSent
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSent ? Colors.red : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(transaction.timestamp),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Valor
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isSent ? '-' : '+'}\$${(transaction.amountBTC * 50000).toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSent ? Colors.red : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(transaction.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.confirming:
        color = Colors.blue;
        text = 'Confirming';
        break;
      case TransactionStatus.confirmed:
        color = Colors.green;
        text = 'Confirmed';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
