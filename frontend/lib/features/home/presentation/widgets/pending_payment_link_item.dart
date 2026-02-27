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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        width: 280, // Fixed width for horizontal scroll
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF00FF94).withValues(alpha: 0.2)
                : const Color(0xFFFFB800).withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isCompleted
                          ? const Color(0xFF00FF94)
                          : const Color(0xFFFFB800))
                      .withValues(alpha: 0.02),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF00FF94).withValues(alpha: 0.1)
                        : const Color(0xFFFFB800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_top_rounded,
                    color: isCompleted
                        ? const Color(0xFF00FF94)
                        : const Color(0xFFFFB800),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Status & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted
                            ? 'RECEBIDO'
                            : (isExpired ? 'EXPIRADO' : 'PENDENTE'),
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF00FF94)
                              : (isExpired
                                    ? Colors.redAccent
                                    : const Color(0xFFFFB800)),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (!isCompleted && !isExpired)
                        Text(
                          _formatDuration(timeLeft),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // BTC Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VALOR',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      paymentLink.amountBtc.toStringAsFixed(8),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              paymentLink.description.isNotEmpty
                  ? paymentLink.description
                  : 'Aguardando pagamento via rede Bitcoin...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Footer Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted ? 'Confirmado' : 'Link de Pagamento',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.2),
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
