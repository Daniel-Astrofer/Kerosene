import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';

import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import 'package:kerosene/design_system/icons.dart';

class PaymentLinksScreen extends ConsumerWidget {
  const PaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(paymentLinksProvider);
    final kpis = ref.watch(adminDashboardKpisProvider);
    final loadedLinks = links.asData?.value ?? const <PaymentLink>[];
    final observedVolume = _linksVolume(loadedLinks);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOperationalMetricsProvider);
        ref.invalidate(paymentLinksProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AdminTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionHeader(
              title: context.tr.adminRoutePaymentLinks,
              subtitle: context.tr.adminPaymentLinksSubtitle,
              trailing: OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(adminOperationalMetricsProvider);
                  ref.invalidate(paymentLinksProvider);
                },
                icon: const Icon(KeroseneIcons.refresh, size: 16),
                label: Text(context.tr.adminActionRefresh),
              ),
            ),
            AdminResponsiveGrid(
              children: [
                AdminMetricCard(
                  label: context.tr.adminPaymentLinksLinksCreated,
                  value: '${kpis.linksCreated}',
                  subtitle: context.tr.adminPaidOpen(
                    '${kpis.linksPaid}',
                    '${kpis.linksPending}',
                  ),
                  icon: KeroseneIcons.qr,
                ),
                AdminMetricCard(
                  label: context.tr.adminPaymentLinksObservedVolume,
                  value: '${observedVolume.toStringAsFixed(8)} BTC',
                  subtitle: loadedLinks.isEmpty
                      ? context.tr.adminPaymentLinksWaitingList
                      : context.tr.adminLinksLoaded('${loadedLinks.length}'),
                  icon: KeroseneIcons.wallet,
                  accentColor: AdminColors.accent,
                ),
                AdminMetricCard(
                  label: context.tr.adminPaymentLinksConversion,
                  value:
                      '${(kpis.linkConversionRate * 100).toStringAsFixed(1)}%',
                  subtitle: context.tr.adminSettledRatio(
                    '${kpis.linksPaid}',
                    '${kpis.linksCreated}',
                  ),
                  icon: KeroseneIcons.trendUp,
                  accentColor: kpis.linkConversionRate >= 0.8
                      ? AdminColors.positive
                      : AdminColors.warning,
                ),
                AdminMetricCard(
                  label: context.tr.adminPaymentLinksFailures,
                  value: '${kpis.linksExpired}',
                  subtitle: context.tr.adminPaymentLinksExpiredCancelled,
                  icon: KeroseneIcons.warning,
                  accentColor: kpis.linksExpired == 0
                      ? AdminColors.positive
                      : AdminColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.spacingXl),
            AdminPanel(
              title: context.tr.adminPaymentLinksLatestEvents,
              icon: KeroseneIcons.receipt,
              child: links.when(
                loading: () => const _PaymentLinksSkeleton(),
                error: (error, _) => AdminErrorState(
                  message: context.tr.adminPaymentLinksLoadError,
                  onRetry: () => ref.invalidate(paymentLinksProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AdminEmptyState(
                      title: context.tr.adminPaymentLinksEmptyTitle,
                      subtitle: context.tr.adminPaymentLinksEmptySubtitle,
                      icon: KeroseneIcons.qr,
                    );
                  }

                  final rows = items.take(24).map((link) {
                    return [
                      _MonoText(_short(link.id)),
                      Text(
                        link.description.trim().isEmpty
                            ? context.tr.adminPaymentLinksUnlabeled
                            : link.description.trim(),
                        style: AdminTypography.tableCell,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_effectiveAmount(link).toStringAsFixed(8)} BTC',
                        style: AdminTypography.tableCellMono,
                      ),
                      AdminStatusBadge(
                        label: link.status,
                        variant: _statusVariant(link.status),
                      ),
                      Text(
                        link.paymentRail,
                        style: AdminTypography.tableCell,
                      ),
                      _MonoText(_date(context, link.createdAt)),
                      _MonoText(
                          _date(context, link.paidAt ?? link.completedAt)),
                    ];
                  }).toList();

                  return AdminDataTable(
                    columns: [
                      context.tr.adminColumnId,
                      context.tr.adminColumnReference,
                      context.tr.adminColumnAmount,
                      context.tr.adminColumnStatus,
                      context.tr.adminColumnRail,
                      context.tr.adminColumnCreated,
                      context.tr.adminColumnSettled,
                    ],
                    rows: rows,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLinksSkeleton extends StatelessWidget {
  const _PaymentLinksSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AdminSkeleton(height: 42),
        SizedBox(height: AdminTheme.spacingSm),
        AdminSkeleton(height: 42),
        SizedBox(height: AdminTheme.spacingSm),
        AdminSkeleton(height: 42),
      ],
    );
  }
}

class _MonoText extends StatelessWidget {
  final String value;

  const _MonoText(this.value);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AdminTypography.tableCellMono,
      ),
    );
  }
}

double _linksVolume(List<PaymentLink> links) {
  return links.fold<double>(0, (total, link) => total + _effectiveAmount(link));
}

double _effectiveAmount(PaymentLink link) {
  if (link.netAmountBtc > 0) return link.netAmountBtc;
  if (link.grossAmountBtc > 0) return link.grossAmountBtc;
  return link.amountBtc;
}

AdminBadgeVariant _statusVariant(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'completed':
    case 'settled':
      return AdminBadgeVariant.positive;
    case 'pending':
    case 'verifying_onboarding':
    case 'verifying_activation':
      return AdminBadgeVariant.warning;
    case 'cancelled':
    case 'canceled':
    case 'expired':
    case 'failed':
      return AdminBadgeVariant.negative;
    default:
      return AdminBadgeVariant.neutral;
  }
}

String _short(Object? value) {
  final text = value?.toString() ?? '';
  if (text.length <= 14) return text;
  return '${text.substring(0, 6)}...${text.substring(text.length - 6)}';
}

String _date(BuildContext context, DateTime? value) {
  if (value == null) return context.tr.adminValueNotSet;
  return value.toIso8601String().replaceFirst('T', ' ').split('.').first;
}
