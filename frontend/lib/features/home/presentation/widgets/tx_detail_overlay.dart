import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'animated_tx_icon.dart';
import '../../../wallet/domain/entities/transaction.dart';

class TxDetailOverlay extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onClose;

  const TxDetailOverlay({
    super.key,
    required this.tx,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(tx.status);
    final typeLabel = _typeLabel(tx.type);
    final amountSign =
        tx.type == TransactionType.send || tx.type == TransactionType.withdrawal
            ? '-'
            : '+';
    final amountColor =
        tx.type == TransactionType.send || tx.type == TransactionType.withdrawal
            ? const Color(0xFFFF453A)
            : const Color(0xFF00E5BC);

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onClose,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                onTap: () {}, // Prevent closing when tapping the card
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + 0.2 * value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101B35).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: amountColor.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── HEADER ICON ───────────────────────────────────
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: amountColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: amountColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: AnimatedTxIcon(
                                  kind: _iconKindFor(tx),
                                  color: amountColor,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              typeLabel,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$amountSign${tx.amountBTC.toStringAsFixed(8)} BTC',
                              style: AppTypography.h1.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── DETAILS GRID ──────────────────────────────────
                            _buildDetailRow(
                              context,
                              kind: TxIconKind.pending,
                              label: 'Status',
                              value: tx.status.displayName,
                              valueColor: statusColor,
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            _buildDetailRow(
                              context,
                              kind: TxIconKind.clock,
                              label: 'Data e Hora',
                              value:
                                  '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year} ${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            _buildDetailRow(
                              context,
                              kind: TxIconKind.address,
                              label: tx.type == TransactionType.send
                                  ? 'Destinatário'
                                  : 'Remetente',
                              value: _abbrewAddress(
                                  tx.type == TransactionType.send
                                      ? tx.toAddress
                                      : tx.fromAddress),
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            _buildDetailRow(
                              context,
                              kind: TxIconKind.network,
                              label: 'ID da Transação',
                              value: _abbrewAddress(tx.id),
                            ),

                            if (tx.feeSatoshis > 0) ...[
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                context,
                                kind: TxIconKind.fee,
                                label: 'Taxa de Rede',
                                value:
                                    '${(tx.feeSatoshis / 100000000).toStringAsFixed(8)} BTC',
                              ),
                            ],

                            if (tx.isInternal) ...[
                              const Divider(height: 24, color: Colors.white10),
                              _buildDetailRow(
                                context,
                                kind: TxIconKind.card,
                                label: 'Método',
                                value: 'Transferência Interna',
                                valueColor: const Color(0xFF7B61FF),
                              ),
                            ],

                            const SizedBox(height: 40),

                            // ── ACTIONS ───────────────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _buildButton(
                                    label: 'Compartilhar',
                                    icon: Icons.share_rounded,
                                    onTap: () {},
                                    isPrimary: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildButton(
                                    label: 'Blockchain',
                                    icon: Icons.open_in_new_rounded,
                                    onTap: () {},
                                    isPrimary: true,
                                    color: amountColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required TxIconKind kind,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: AnimatedTxIcon(
              kind: kind,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: valueColor ?? Theme.of(context).colorScheme.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary
              ? (color ?? const Color(0xFF00E5BC)).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? (color ?? const Color(0xFF00E5BC)).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isPrimary
                    ? (color ?? const Color(0xFF00E5BC))
                    : Colors.white70,
                size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isPrimary
                    ? (color ?? const Color(0xFF00E5BC))
                    : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return const Color(0xFFFF9F0A);
      case TransactionStatus.confirming:
        return const Color(0xFFFFCC00);
      case TransactionStatus.confirmed:
        return const Color(0xFF00C896);
      case TransactionStatus.failed:
        return const Color(0xFFFF453A);
    }
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.send:
        return 'ENVIO';
      case TransactionType.receive:
        return 'RECEBIMENTO';
      case TransactionType.deposit:
        return 'DEPÓSITO';
      case TransactionType.withdrawal:
        return 'SAQUE';
      case TransactionType.swap:
        return 'SWAP';
      case TransactionType.fee:
        return 'TAXA';
    }
  }

  TxIconKind _iconKindFor(Transaction tx) {
    switch (tx.type) {
      case TransactionType.send:
        return TxIconKind.send;
      case TransactionType.receive:
        return TxIconKind.receive;
      case TransactionType.deposit:
        return TxIconKind.deposit;
      case TransactionType.withdrawal:
        return TxIconKind.withdrawal;
      case TransactionType.swap:
        return TxIconKind.swap;
      case TransactionType.fee:
        return TxIconKind.fee;
    }
  }

  String _abbrewAddress(String addr) {
    if (addr.length <= 16) return addr;
    return '${addr.substring(0, 8)}...${addr.substring(addr.length - 8)}';
  }
}
