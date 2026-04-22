import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/entities/payment_link.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/admin_data_table.dart';

/// Payment Links management module.
class PaymentLinksScreen extends ConsumerWidget {
  const PaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(adminPaymentLinksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Payment Links',
            subtitle: 'Track creation, conversion, and lifecycle of payment links',
          ),
          linksAsync.when(
            data: (links) {
              final paid = links.where((l) => l.isPaid || l.isCompleted).toList();
              final pending = links.where((l) => l.isPending && !l.isExpired).toList();
              final expired = links.where((l) => l.isExpired).toList();
              final totalAmount = links.fold<double>(0, (s, l) => s + l.amountBtc);
              final paidAmount = paid.fold<double>(0, (s, l) => s + l.amountBtc);
              final conversionRate = links.isNotEmpty ? paid.length / links.length : 0.0;

              // Average time to payment (for paid links with both createdAt and paidAt)
              final paidWithDates = paid.where((l) => l.createdAt != null && l.paidAt != null).toList();
              final avgPaymentMinutes = paidWithDates.isNotEmpty
                  ? paidWithDates.fold<double>(0, (s, l) => s + l.paidAt!.difference(l.createdAt!).inMinutes) / paidWithDates.length
                  : 0.0;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: AdminMetricCard(label: 'Total Links', value: '${links.length}', subtitle: '${totalAmount.toStringAsFixed(6)} BTC total', icon: Icons.qr_code_2_outlined)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Paid', value: '${paid.length}', subtitle: '${paidAmount.toStringAsFixed(6)} BTC collected', icon: Icons.check_circle_outline, accentColor: AdminColors.positive)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Conversion', value: '${(conversionRate * 100).toStringAsFixed(1)}%', subtitle: '${pending.length} pending • ${expired.length} expired', icon: Icons.trending_up, accentColor: conversionRate > 0.5 ? AdminColors.positive : AdminColors.warning)),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(child: AdminMetricCard(label: 'Avg Time', value: avgPaymentMinutes > 0 ? '${avgPaymentMinutes.toStringAsFixed(0)} min' : '—', subtitle: 'creation to payment', icon: Icons.timer_outlined)),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  AdminDataTable<PaymentLink>(
                    data: links,
                    columns: [
                      AdminColumn(header: 'ID', cellBuilder: (l) => SelectableText(l.id.length > 10 ? '${l.id.substring(0, 10)}...' : l.id, style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'Amount', isNumeric: true, cellBuilder: (l) => Text(l.amountBtc.toStringAsFixed(8), style: AdminTypography.tableCellMono), sortKey: (l) => l.amountBtc),
                      AdminColumn(header: 'Net Amount', isNumeric: true, cellBuilder: (l) => Text(l.netAmountBtc.toStringAsFixed(8), style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'Fee', isNumeric: true, cellBuilder: (l) => Text(l.depositFeeBtc.toStringAsFixed(8), style: AdminTypography.tableCellMono)),
                      AdminColumn(header: 'Status', cellBuilder: (l) {
                        AdminBadgeVariant v;
                        String label;
                        if (l.isCompleted) { v = AdminBadgeVariant.positive; label = 'Completed'; }
                        else if (l.isPaid) { v = AdminBadgeVariant.positive; label = 'Paid'; }
                        else if (l.isExpired) { v = AdminBadgeVariant.negative; label = 'Expired'; }
                        else { v = AdminBadgeVariant.warning; label = 'Pending'; }
                        return AdminStatusBadge(label: label, variant: v);
                      }),
                      AdminColumn(header: 'Description', cellBuilder: (l) => Text(l.description.isNotEmpty ? (l.description.length > 20 ? '${l.description.substring(0, 20)}...' : l.description) : '—', style: AdminTypography.tableCell)),
                      AdminColumn(header: 'Created', cellBuilder: (l) => Text(l.createdAt != null ? '${l.createdAt!.year}-${l.createdAt!.month.toString().padLeft(2, '0')}-${l.createdAt!.day.toString().padLeft(2, '0')}' : '—', style: AdminTypography.tableCell), sortKey: (l) => l.createdAt?.millisecondsSinceEpoch ?? 0),
                      AdminColumn(header: 'Paid At', cellBuilder: (l) => Text(l.paidAt != null ? '${l.paidAt!.year}-${l.paidAt!.month.toString().padLeft(2, '0')}-${l.paidAt!.day.toString().padLeft(2, '0')} ${l.paidAt!.hour.toString().padLeft(2, '0')}:${l.paidAt!.minute.toString().padLeft(2, '0')}' : '—', style: AdminTypography.tableCell)),
                    ],
                    emptyMessage: 'No payment links found',
                  ),
                ],
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(AdminTheme.spacing3xl), child: CircularProgressIndicator(color: AdminColors.textTertiary))),
            error: (e, _) => AdminErrorState(message: 'Failed to load payment links: $e', onRetry: () => ref.invalidate(adminPaymentLinksProvider)),
          ),
        ],
      ),
    );
  }
}
