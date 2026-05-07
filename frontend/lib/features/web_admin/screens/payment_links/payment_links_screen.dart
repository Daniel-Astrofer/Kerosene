import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Payment-link aggregate metrics.
///
/// The enterprise terminal intentionally avoids listing link descriptions,
/// deposit addresses, txids, or per-user payloads.
class PaymentLinksScreen extends ConsumerWidget {
  const PaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminOperationalMetricsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Payment Metrics',
            subtitle:
                'Aggregate payment-link lifecycle metrics without exposing readable user payloads.',
          ),
          metricsAsync.when(
            data: (metrics) {
              final links = _map(metrics['paymentLinks']);
              final total = _int(links['linksCreated']);
              final paid = _int(links['linksPaid']);
              final pending = _int(links['linksPending']);
              final expired = _int(links['linksExpired']);
              final cancelled = _int(links['linksCancelled']);
              final totalAmount = _double(links['totalAmountBtc']);
              final paidAmount = _double(links['paidAmountBtc']);
              final conversionRate = total == 0 ? 0.0 : paid / total;

              return Column(
                children: [
                  AdminResponsiveGrid(
                    children: [
                      AdminMetricCard(
                        label: 'Total Links',
                        value: '$total',
                        subtitle: '${totalAmount.toStringAsFixed(6)} BTC total',
                        icon: Icons.qr_code_2_outlined,
                      ),
                      AdminMetricCard(
                        label: 'Paid',
                        value: '$paid',
                        subtitle: '${paidAmount.toStringAsFixed(6)} BTC paid',
                        icon: Icons.check_circle_outline,
                        accentColor: AdminColors.positive,
                      ),
                      AdminMetricCard(
                        label: 'Pending',
                        value: '$pending',
                        icon: Icons.hourglass_empty,
                        accentColor: AdminColors.warning,
                      ),
                      AdminMetricCard(
                        label: 'Expired / Cancelled',
                        value: '${expired + cancelled}',
                        subtitle: '$expired expired | $cancelled cancelled',
                        icon: Icons.block_outlined,
                        accentColor: AdminColors.negative,
                      ),
                      AdminMetricCard(
                        label: 'Conversion',
                        value: '${(conversionRate * 100).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.spacingXl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AdminTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      border: Border.all(color: AdminColors.border),
                      borderRadius: AdminTheme.borderRadiusSm,
                    ),
                    child: Text(
                      'Per-link descriptions, deposit addresses, txids and user identifiers are intentionally hidden from the enterprise terminal. Use integrity roots and aggregate counters for operations.',
                      style: AdminTypography.bodySmall.copyWith(
                        color: AdminColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
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
              message: 'Failed to load aggregate payment metrics: $e',
              onRetry: () => ref.invalidate(adminOperationalMetricsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
