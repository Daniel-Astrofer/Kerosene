import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/entities/external_transfer.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/admin_data_table.dart';

/// Lightning Network operations module.
class LightningScreen extends ConsumerWidget {
  const LightningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(adminExternalTransfersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Lightning Network',
            subtitle: 'Operational view of all Lightning payments',
          ),

          // KPI summary
          transfersAsync.when(
            data: (transfers) {
              final lightning =
                  transfers.where((t) => t.isLightning).toList();
              final sent = lightning.where((t) => t.isOutbound).toList();
              final received =
                  lightning.where((t) => !t.isOutbound).toList();
              final completed = lightning
                  .where((t) =>
                      t.status.toUpperCase() == 'COMPLETED' ||
                      t.status.toUpperCase() == 'SETTLED')
                  .toList();
              final failed = lightning
                  .where(
                      (t) => t.status.toUpperCase() == 'CANCELLED')
                  .toList();

              final totalVolume = lightning.fold<double>(
                  0, (sum, t) => sum + t.amountBtc.abs());
              final totalFees = lightning.fold<double>(
                  0, (sum, t) => sum + t.networkFeeBtc);
              final successRate = lightning.isNotEmpty
                  ? completed.length / lightning.length
                  : 0.0;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminMetricCard(
                          label: 'Total Operations',
                          value: '${lightning.length}',
                          subtitle:
                              '${sent.length} sent • ${received.length} received',
                          icon: Icons.flash_on_outlined,
                          accentColor: AdminColors.info,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: AdminMetricCard(
                          label: 'Volume',
                          value:
                              '${totalVolume.toStringAsFixed(8)} BTC',
                          icon: Icons.swap_horiz,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: AdminMetricCard(
                          label: 'Fees Paid',
                          value:
                              '${totalFees.toStringAsFixed(8)} BTC',
                          icon: Icons.payments_outlined,
                          accentColor: AdminColors.warning,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: AdminMetricCard(
                          label: 'Success Rate',
                          value:
                              '${(successRate * 100).toStringAsFixed(1)}%',
                          subtitle:
                              '${completed.length} completed • ${failed.length} failed',
                          icon: Icons.check_circle_outline,
                          accentColor: successRate > 0.9
                              ? AdminColors.positive
                              : AdminColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  AdminDataTable<ExternalTransfer>(
                    data: lightning,
                    columns: _buildColumns(),
                    emptyMessage: 'No Lightning operations found',
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AdminTheme.spacing3xl),
                child: CircularProgressIndicator(
                  color: AdminColors.textTertiary,
                ),
              ),
            ),
            error: (e, _) => AdminErrorState(
              message: 'Failed to load Lightning data: $e',
              onRetry: () =>
                  ref.invalidate(adminExternalTransfersProvider),
            ),
          ),
        ],
      ),
    );
  }

  List<AdminColumn<ExternalTransfer>> _buildColumns() {
    return [
      AdminColumn<ExternalTransfer>(
        header: 'ID',
        cellBuilder: (t) => SelectableText(
          t.id.length > 10 ? '${t.id.substring(0, 10)}...' : t.id,
          style: AdminTypography.tableCellMono,
        ),
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Direction',
        cellBuilder: (t) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                t.isOutbound
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: t.isOutbound
                    ? AdminColors.negative
                    : AdminColors.positive,
              ),
              const SizedBox(width: 4),
              Text(
                t.isOutbound ? 'Sent' : 'Received',
                style: AdminTypography.tableCell,
              ),
            ],
          );
        },
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Amount (BTC)',
        isNumeric: true,
        cellBuilder: (t) => Text(
          t.amountBtc.abs().toStringAsFixed(8),
          style: AdminTypography.tableCellMono,
        ),
        sortKey: (t) => t.amountBtc.abs(),
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Network Fee',
        isNumeric: true,
        cellBuilder: (t) => Text(
          t.networkFeeBtc.toStringAsFixed(8),
          style: AdminTypography.tableCellMono,
        ),
        sortKey: (t) => t.networkFeeBtc,
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Total Debited',
        isNumeric: true,
        cellBuilder: (t) => Text(
          t.totalDebitedBtc.toStringAsFixed(8),
          style: AdminTypography.tableCellMono,
        ),
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Status',
        cellBuilder: (t) {
          final variant = switch (t.status.toUpperCase()) {
            'COMPLETED' || 'SETTLED' => AdminBadgeVariant.positive,
            'CANCELLED' => AdminBadgeVariant.negative,
            _ => AdminBadgeVariant.warning,
          };
          return AdminStatusBadge(label: t.status, variant: variant);
        },
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Destination',
        cellBuilder: (t) => SelectableText(
          t.destination.length > 20
              ? '${t.destination.substring(0, 20)}...'
              : t.destination,
          style: AdminTypography.tableCell,
        ),
      ),
      AdminColumn<ExternalTransfer>(
        header: 'Date',
        cellBuilder: (t) => Text(
          t.createdAt != null
              ? '${t.createdAt!.year}-${t.createdAt!.month.toString().padLeft(2, '0')}-${t.createdAt!.day.toString().padLeft(2, '0')}'
              : '—',
          style: AdminTypography.tableCell,
        ),
        sortKey: (t) =>
            t.createdAt?.millisecondsSinceEpoch ?? 0,
      ),
    ];
  }
}
