import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/entities/external_transfer.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/admin_data_table.dart';

/// On-chain BTC operations module.
class OnchainScreen extends ConsumerWidget {
  const OnchainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(adminExternalTransfersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'On-chain Operations',
            subtitle: 'Bitcoin blockchain transactions and confirmations',
          ),
          transfersAsync.when(
            data: (transfers) {
              final onchain = transfers.where((t) => t.isOnchain).toList();
              final totalVolume = onchain.fold<double>(0, (s, t) => s + t.amountBtc.abs());
              final totalFees = onchain.fold<double>(0, (s, t) => s + t.networkFeeBtc);
              final completed = onchain.where((t) => t.status.toUpperCase() == 'COMPLETED' || t.status.toUpperCase() == 'SETTLED').length;
              final pending = onchain.where((t) => t.status.toUpperCase() == 'PENDING' || t.status.toUpperCase() == 'PROCESSING').length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: AdminMetricCard(label: 'Total Operations', value: '${onchain.length}', icon: Icons.link, accentColor: AdminColors.accent)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Volume', value: '${totalVolume.toStringAsFixed(8)} BTC', icon: Icons.swap_horiz)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Network Fees', value: '${totalFees.toStringAsFixed(8)} BTC', icon: Icons.payments_outlined, accentColor: AdminColors.warning)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Status', value: '$completed confirmed', subtitle: '$pending pending', icon: Icons.check_circle_outline, accentColor: AdminColors.positive)),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  AdminDataTable<ExternalTransfer>(
                    data: onchain,
                    columns: [
                      AdminColumn(header: 'Ref', cellBuilder: (t) => SelectableText(t.externalReference.isNotEmpty ? (t.externalReference.length > 12 ? '${t.externalReference.substring(0, 12)}...' : t.externalReference) : t.id.length > 12 ? '${t.id.substring(0, 12)}...' : t.id, style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'Direction', cellBuilder: (t) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(t.isOutbound ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: t.isOutbound ? AdminColors.negative : AdminColors.positive), const SizedBox(width: 4), Text(t.isOutbound ? 'Sent' : 'Received', style: AdminTypography.tableCell)])),
                      AdminColumn(header: 'Amount', isNumeric: true, cellBuilder: (t) => Text(t.amountBtc.abs().toStringAsFixed(8), style: AdminTypography.tableCellMono), sortKey: (t) => t.amountBtc.abs()),
                      AdminColumn(header: 'Fee', isNumeric: true, cellBuilder: (t) => Text(t.networkFeeBtc.toStringAsFixed(8), style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'Status', cellBuilder: (t) {
                        final v = switch (t.status.toUpperCase()) { 'COMPLETED' || 'SETTLED' => AdminBadgeVariant.positive, 'CANCELLED' => AdminBadgeVariant.negative, _ => AdminBadgeVariant.warning };
                        return AdminStatusBadge(label: t.status, variant: v);
                      }),
                      AdminColumn(header: 'Wallet', cellBuilder: (t) => Text(t.walletName, style: AdminTypography.tableCell)),
                      AdminColumn(header: 'Date', cellBuilder: (t) => Text(t.createdAt != null ? '${t.createdAt!.year}-${t.createdAt!.month.toString().padLeft(2, '0')}-${t.createdAt!.day.toString().padLeft(2, '0')}' : '—', style: AdminTypography.tableCell), sortKey: (t) => t.createdAt?.millisecondsSinceEpoch ?? 0),
                    ],
                    emptyMessage: 'No on-chain operations found',
                  ),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(AdminTheme.spacing3xl), child: CircularProgressIndicator(color: AdminColors.textTertiary))),
            error: (e, _) => AdminErrorState(message: 'Failed to load on-chain data: $e', onRetry: () => ref.invalidate(adminExternalTransfersProvider)),
          ),
        ],
      ),
    );
  }
}
