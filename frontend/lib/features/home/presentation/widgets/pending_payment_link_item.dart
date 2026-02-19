import 'package:flutter/material.dart';
import '../../../transactions/domain/entities/payment_link.dart';

class PendingPaymentLinkItem extends StatelessWidget {
  final PaymentLink paymentLink;
  final VoidCallback? onTap;

  const PendingPaymentLinkItem({
    super.key,
    required this.paymentLink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeLeft = paymentLink.expiresAt != null
        ? paymentLink.expiresAt!.difference(DateTime.now())
        : Duration.zero;

    final isExpired =
        timeLeft.isNegative && !paymentLink.isCompleted && !paymentLink.isPaid;
    final isCompleted = paymentLink.isCompleted || paymentLink.isPaid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF00FF94).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF00FF94).withValues(alpha: 0.1)
                    : const Color(0xFFF7931A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.hourglass_top_rounded,
                color: isCompleted
                    ? const Color(0xFF00FF94)
                    : const Color(0xFFF7931A),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Deposit Received' : 'Pending Deposit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentLink.description.isNotEmpty
                        ? paymentLink.description
                        : 'Awaiting payment...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Amount & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${paymentLink.amountBtc.toStringAsFixed(8)} BTC',
                  style: const TextStyle(
                    color: Color(0xFF00FF94),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!isCompleted) ...[
                      Icon(
                        Icons.timer_outlined,
                        color: isExpired
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.5),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isCompleted
                          ? 'Completed'
                          : (isExpired ? 'Expired' : _formatDuration(timeLeft)),
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFF00FF94)
                            : (isExpired
                                  ? Colors.red
                                  : Colors.white.withValues(alpha: 0.5)),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
