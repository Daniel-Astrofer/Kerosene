import 'package:flutter/material.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
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
    final responsive = context.responsive;
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
        padding: EdgeInsets.all(responsive.isTinyPhone ? 14 : 16),
        width: responsive.clampWidth(responsive.isTinyPhone ? 244 : 280),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.03),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // BTC Value
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.isTinyPhone ? 88 : 112,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'VALOR',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.24),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          paymentLink.amountBtc.toStringAsFixed(8),
                          maxLines: 1,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: responsive.isTinyPhone ? 12 : 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
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
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.5),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.2),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.2),
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
