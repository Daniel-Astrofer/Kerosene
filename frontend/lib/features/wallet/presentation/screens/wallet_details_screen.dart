import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';

class WalletDetailsScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  ConsumerState<WalletDetailsScreen> createState() =>
      _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends ConsumerState<WalletDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync =
        ref.watch(transactionsByWalletProvider(widget.wallet.address));

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: CyberBackground.authenticated(
        useScroll: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            _buildBalanceCard(),
                            const SizedBox(height: AppSpacing.xl),
                            _buildActionSection(),
                            const SizedBox(height: AppSpacing.xxl),
                            _buildSectionHeader(
                                context.tr.recentTransactions.toUpperCase()),
                          ],
                        ),
                      ),
                    ),
                    transactionsAsync.when(
                      data: (txs) => txs.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg),
                                  child: TransactionListItem(
                                      transaction: txs[index]),
                                ),
                                childCount: txs.length,
                              ),
                            ),
                      loading: () => SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                      error: (err, _) => SliverFillRemaining(
                          child: _buildErrorState(err.toString())),
                    ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxl)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary),
            style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05)),
          ),
          Text(
            widget.wallet.name.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(LucideIcons.settings,
                color: Theme.of(context).colorScheme.onPrimary),
            style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            context.tr.totalBalanceGeneric.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "₿ ${widget.wallet.balance.toStringAsFixed(8)}",
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'JetBrainsMono',
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "≈ \$ ${(widget.wallet.balance * 65000).toStringAsFixed(2)} USD",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.4)),
          ),
        ],
      ),
    ).animate().fade().scale(curve: Curves.easeOutBack);
  }

  Widget _buildActionSection() {
    return Row(
      children: [
        Expanded(
            child: _buildActionButton(
                context.tr.send.toUpperCase(), LucideIcons.arrowUpRight)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _buildActionButton(
                context.tr.receive.toUpperCase(), LucideIcons.arrowDownLeft)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.4),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        Icon(LucideIcons.listFilter,
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            size: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.ghost,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              size: 80),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr.noTransactions.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          "${context.tr.errorLoadingData.toUpperCase()}: $error",
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
