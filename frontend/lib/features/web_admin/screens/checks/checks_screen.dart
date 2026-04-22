import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/admin_data_table.dart';

/// Internal checks (internal ledger transfers) module.
class ChecksScreen extends ConsumerWidget {
  const ChecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminLedgerHistoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Internal Checks',
            subtitle: 'Platform internal transfers between accounts — instrument managed within the system',
          ),
          Container(
            margin: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
            padding: const EdgeInsets.all(AdminTheme.spacingMd),
            decoration: BoxDecoration(
              color: AdminColors.infoSubtle,
              border: Border.all(color: AdminColors.info.withValues(alpha: 0.3)),
              borderRadius: AdminTheme.borderRadiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AdminColors.info),
                const SizedBox(width: AdminTheme.spacingSm),
                Expanded(
                  child: Text(
                    'Internal checks are platform transfers between users. They settle instantly with zero network fees.',
                    style: AdminTypography.bodySmall.copyWith(color: AdminColors.info),
                  ),
                ),
              ],
            ),
          ),
          historyAsync.when(
            data: (txs) {
              final internal = txs.where((tx) => tx.isInternal).toList();
              final confirmed = internal.where((tx) => tx.status == TransactionStatus.confirmed).length;
              final pending = internal.where((tx) => tx.status == TransactionStatus.pending || tx.status == TransactionStatus.confirming).length;
              final totalVolume = internal.fold<double>(0, (s, tx) => s + tx.amountBTC);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: AdminMetricCard(label: 'Checks Issued', value: '${internal.length}', icon: Icons.receipt_long_outlined, accentColor: AdminColors.accent)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Compensated', value: '$confirmed', icon: Icons.check_circle_outline, accentColor: AdminColors.positive)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Pending', value: '$pending', icon: Icons.hourglass_empty, accentColor: AdminColors.warning)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Total Volume', value: '${totalVolume.toStringAsFixed(8)} BTC', icon: Icons.swap_horiz)),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  AdminDataTable<Transaction>(
                    data: internal,
                    columns: [
                      AdminColumn(header: 'ID', cellBuilder: (tx) => SelectableText(tx.id.length > 12 ? '${tx.id.substring(0, 12)}...' : tx.id, style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'From', cellBuilder: (tx) => Text(tx.fromAddress, style: AdminTypography.tableCell, overflow: TextOverflow.ellipsis)),
                      AdminColumn(header: 'To', cellBuilder: (tx) => Text(tx.toAddress, style: AdminTypography.tableCell, overflow: TextOverflow.ellipsis)),
                      AdminColumn(header: 'Amount', isNumeric: true, cellBuilder: (tx) => Text(tx.amountBTC.toStringAsFixed(8), style: AdminTypography.tableCellMono), sortKey: (tx) => tx.amountBTC),
                      AdminColumn(header: 'Status', cellBuilder: (tx) {
                        final v = switch (tx.status) { TransactionStatus.confirmed => AdminBadgeVariant.positive, TransactionStatus.pending || TransactionStatus.confirming => AdminBadgeVariant.warning, TransactionStatus.failed => AdminBadgeVariant.negative };
                        return AdminStatusBadge(label: tx.status.displayName, variant: v);
                      }),
                      AdminColumn(header: 'Description', cellBuilder: (tx) => Text(tx.description ?? '—', style: AdminTypography.tableCell, overflow: TextOverflow.ellipsis)),
                      AdminColumn(header: 'Date', cellBuilder: (tx) => Text('${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}-${tx.timestamp.day.toString().padLeft(2, '0')}', style: AdminTypography.tableCell), sortKey: (tx) => tx.timestamp.millisecondsSinceEpoch),
                    ],
                    emptyMessage: 'No internal checks found',
                  ),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(AdminTheme.spacing3xl), child: CircularProgressIndicator(color: AdminColors.textTertiary))),
            error: (e, _) => AdminErrorState(message: 'Failed to load internal checks: $e', onRetry: () => ref.invalidate(adminLedgerHistoryProvider)),
          ),
        ],
      ),
    );
  }
}
