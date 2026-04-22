import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';

/// Companies / Corporate Accounts module.
class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(adminWalletsProvider);
    final userAsync = ref.watch(adminCurrentUserProvider);
    final totalBalance = ref.watch(adminTotalBalanceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Corporate Accounts',
            subtitle: 'Manage wallets, profiles, and organizational settings',
          ),

          // User profile card
          userAsync.when(
            data: (user) => _ProfileCard(user: user, totalBalance: totalBalance),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AdminTheme.spacingXl),

          // Wallets list
          walletsAsync.when(
            data: (wallets) {
              if (wallets.isEmpty) {
                return const AdminEmptyState(
                  title: 'No wallets found',
                  subtitle: 'Create a wallet to get started with corporate operations',
                  icon: Icons.account_balance_wallet_outlined,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WALLETS (${wallets.length})', style: AdminTypography.label),
                  const SizedBox(height: AdminTheme.spacingLg),
                  ...wallets.map((w) => Container(
                    margin: const EdgeInsets.only(bottom: AdminTheme.spacingSm),
                    padding: const EdgeInsets.all(AdminTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      border: Border.all(color: AdminColors.border),
                      borderRadius: AdminTheme.borderRadiusSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceElevated,
                            borderRadius: AdminTheme.borderRadiusSm,
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: const Center(
                            child: Icon(Icons.account_balance_wallet_outlined, size: 20, color: AdminColors.textTertiary),
                          ),
                        ),
                        const SizedBox(width: AdminTheme.spacingLg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name, style: AdminTypography.h4),
                              const SizedBox(height: 2),
                              Text(w.address.isNotEmpty ? '${w.address.substring(0, (w.address.length).clamp(0, 20))}...' : 'No address', style: AdminTypography.mono.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${w.balance.toStringAsFixed(8)} BTC', style: AdminTypography.metricSmall.copyWith(fontSize: 16)),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdminStatusBadge(label: w.isActive ? 'Active' : 'Inactive', variant: w.isActive ? AdminBadgeVariant.positive : AdminBadgeVariant.neutral),
                                const SizedBox(width: AdminTheme.spacingSm),
                                AdminStatusBadge(label: w.cardType.label, variant: AdminBadgeVariant.info),
                                const SizedBox(width: AdminTheme.spacingSm),
                                AdminStatusBadge(label: w.accountSecurity, variant: AdminBadgeVariant.neutral),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AdminColors.textTertiary)),
            error: (e, _) => AdminErrorState(message: 'Failed to load wallets: $e', onRetry: () => ref.invalidate(adminWalletsProvider)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final double totalBalance;

  const _ProfileCard({required this.user, required this.totalBalance});

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AdminColors.surfaceElevated,
              borderRadius: AdminTheme.borderRadiusSm,
              border: Border.all(color: AdminColors.border),
            ),
            child: const Center(child: Icon(Icons.person_outline, size: 28, color: AdminColors.textTertiary)),
          ),
          const SizedBox(width: AdminTheme.spacingXl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name']?.toString() ?? user['username']?.toString() ?? 'User', style: AdminTypography.h3),
                const SizedBox(height: AdminTheme.spacingXs),
                Text('Account ID: ${user['id']?.toString() ?? '—'}', style: AdminTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${totalBalance.toStringAsFixed(8)} BTC', style: AdminTypography.metric),
              const SizedBox(height: AdminTheme.spacingXs),
              Text('Consolidated Balance', style: AdminTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}
