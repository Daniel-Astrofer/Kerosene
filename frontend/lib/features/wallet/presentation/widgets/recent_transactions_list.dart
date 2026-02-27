import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/transaction.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Lista de transações recentes
class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Nenhuma transação encontrada',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white54,
              fontSize: 14,
            ),
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
    return TransactionItemWidget(transaction: transaction);
  }
}

class TransactionItemWidget extends StatefulWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  State<TransactionItemWidget> createState() => _TransactionItemWidgetState();
}

class _TransactionItemWidgetState extends State<TransactionItemWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isSent =
        t.type == TransactionType.send ||
        t.type == TransactionType.withdrawal ||
        t.amountBTC < 0;

    // Constrained Cyber Colors
    final Color primaryColor = isSent
        ? const Color(0xFFFF003C) // Neon Red
        : const Color(0xFF00FFC2); // Cybercore Neon Green/Cyan

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: BeveledRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            side: BorderSide(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            decoration: BoxDecoration(
              color: const Color(
                0xFF0A0A0A,
              ).withValues(alpha: 0.8), // Deep Black
              border: Border.all(
                color: primaryColor.withValues(alpha: _isExpanded ? 0.6 : 0.2),
                width: 1,
              ),
              boxShadow: [
                if (_isExpanded)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Hard-surface Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isSent ? Icons.north_east : Icons.south_west,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Informações
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.description ??
                                  "TX_${t.id.substring(0, 6).toUpperCase()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeago.format(t.timestamp),
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Valor Monospace
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBtcAmount(
                            t.amountBTC.abs(),
                            isSent,
                            primaryColor,
                          ),
                          const SizedBox(height: 6),
                          _buildCyberStatusBadge(t.status, primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expansão (Detalhes da Transação)
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: primaryColor.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        _buildDetailRow('TXID', t.id, primaryColor),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          'DATE',
                          t.timestamp.toString(),
                          primaryColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildDetailRow(
                            'FEE',
                            '${t.feeSatoshis} SATS',
                            primaryColor,
                          ),
                        ),
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
        ),
      ),
    );
  }

  Widget _buildBtcAmount(double amount, bool isSent, Color color) {
    final parts = amount.toStringAsFixed(8).split('.');
    final integerPart = parts[0];
    final fractionalPart = parts.length > 1 ? '.${parts[1]}' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          isSent ? '-' : '+',
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          integerPart,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          fractionalPart,
          style: GoogleFonts.jetBrainsMono(
            color: color.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'BTC',
          style: GoogleFonts.jetBrainsMono(
            color: color.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCyberStatusBadge(TransactionStatus status, Color baseColor) {
    String text;
    bool isPulsing = false;

    switch (status) {
      case TransactionStatus.pending:
      case TransactionStatus.confirming:
        text = 'PROCESSING';
        isPulsing = true;
        break;
      case TransactionStatus.confirmed:
        text = 'CONFIRMED';
        break;
      case TransactionStatus.failed:
        text = 'FAILED';
        break;
    }

    return FadeTransition(
      opacity: isPulsing ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.15),
          border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPulsing) ...[
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.rectangle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                color: baseColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
