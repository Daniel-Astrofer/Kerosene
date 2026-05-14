import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/cyber_background.dart';
import '../../domain/entities/deposit.dart';
import '../providers/transaction_provider.dart';

class DepositsScreen extends ConsumerStatefulWidget {
  const DepositsScreen({super.key});

  @override
  ConsumerState<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends ConsumerState<DepositsScreen> {
  @override
  Widget build(BuildContext context) {
    final depositsAsync = ref.watch(depositsProvider);

    return CyberBackground(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: depositsAsync.when(
              data: (deposits) {
                if (deposits.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(depositsProvider);
                  },
                  backgroundColor: const Color(0xFF1A1A24),
                  color: const Color(0xFF00FF94),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: deposits.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _buildDepositCard(deposits[index]),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF94)),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading deposits',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppBar(
      title: Text(
        "DEPÓSITOS",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
          fontFamily: 'JetBrainsMono',
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No deposits yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositCard(Deposit deposit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(deposit.status),
              const Spacer(),
              Text(
                '${deposit.amountBtc.toStringAsFixed(8)} BTC',
                style: const TextStyle(
                  color: Color(0xFFD0F288),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.alternate_email_rounded,
            'TXID',
            _shortenTxid(deposit.txid),
            onTap: () => _copyToClipboard(deposit.txid),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'DATA',
            _formatTimestamp(deposit.createdAt ?? DateTime.now()),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow(
            Icons.verified_user_outlined,
            'CONFIRMAÇÕES',
            '${deposit.confirmations}/6',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case 'confirmed':
        color = const Color(0xFF00FF94);
        icon = Icons.check_circle;
        label = 'Confirmed';
        break;
      case 'credited':
        color = Colors.blue;
        icon = Icons.account_balance_wallet;
        label = 'Credited';
        break;
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.copy,
            size: 12,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
          ),
      ],
    );
  }

  String _shortenTxid(String txid) {
    if (txid.length <= 16) return txid;
    return '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TXID copied!'),
        backgroundColor: Color(0xFF00FF94),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }
}
