import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/mining/presentation/providers/mining_dashboard_provider.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';
import 'package:teste/features/mining/presentation/widgets/live_fee_grid.dart';
import 'package:teste/features/mining/presentation/widgets/mempool_blocks_visualizer.dart';
import 'package:teste/features/mining/presentation/widgets/mining_metrics.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';
import 'package:teste/features/mining/presentation/widgets/mining_transaction_context_card.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/l10n/l10n_extension.dart';

class MiningScreen extends ConsumerStatefulWidget {
  final Transaction? initialTransaction;

  const MiningScreen({
    super.key,
    this.initialTransaction,
  });

  @override
  ConsumerState<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends ConsumerState<MiningScreen> {
  Future<void> _refresh() async {
    await ref.read(miningDashboardControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hasSnapshot = ref.watch(
      miningDashboardControllerProvider
          .select((state) => state.snapshot != null),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _MiningBackdrop(
        child: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: miningBlue,
                backgroundColor: miningSurface,
                edgeOffset: 12,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppPrimaryNavigationBar.scaffoldBottomClearance(
                          context,
                        ),
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1420),
                            child: hasSnapshot
                                ? _MiningLoadedSections(
                                    onRefresh: _refresh,
                                    initialTransaction:
                                        widget.initialTransaction,
                                  )
                                : _MiningInitialState(onRetry: _refresh),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.mining,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiningBackdrop extends StatelessWidget {
  final Widget child;

  const _MiningBackdrop({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C0C0C),
            Color(0xFF050505),
            Color(0xFF020202),
          ],
          stops: [0.0, 0.34, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _MiningBackdropFrame(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MiningBackdropFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: const _MiningBackdropGridPainter(),
            isComplex: true,
            willChange: false,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.88),
                radius: 1.16,
                colors: [
                  Colors.white.withValues(alpha: 0.045),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 112,
          left: 20,
          right: 20,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.03),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: miningBorder.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _MiningBackdropGridPainter extends CustomPainter {
  const _MiningBackdropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.018)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = miningBorder.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    const minorStep = 96.0;
    const majorStep = 192.0;

    for (double y = 0; y <= size.height; y += minorStep) {
      final paint = (y % majorStep).abs() < 0.1 ? major : minor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x <= size.width; x += majorStep) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        minor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiningInitialState extends ConsumerWidget {
  final VoidCallback onRetry;

  const _MiningInitialState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMeta = ref.watch(miningSyncMetaProvider);

    if (syncMeta.phase == MiningSyncPhase.initialLoading ||
        syncMeta.phase == MiningSyncPhase.refreshing) {
      return const MiningLoadingColumn();
    }

    switch (syncMeta.phase) {
      case MiningSyncPhase.offline:
        return MiningStateCard(
          icon: Icons.portable_wifi_off_rounded,
          accent: miningRed,
          title: context.tr.miningStateOfflineTitle,
          description: context.tr.miningStateOfflineMessage,
          onRetry: onRetry,
        );
      case MiningSyncPhase.empty:
        return MiningStateCard(
          icon: Icons.inbox_outlined,
          accent: miningAmber,
          title: context.tr.miningStateEmptyTitle,
          description: context.tr.miningStateEmptyMessage,
          onRetry: onRetry,
        );
      case MiningSyncPhase.error:
      case MiningSyncPhase.stale:
      case MiningSyncPhase.degraded:
      case MiningSyncPhase.reconnecting:
      case MiningSyncPhase.live:
      case MiningSyncPhase.initialLoading:
      case MiningSyncPhase.refreshing:
        return MiningStateCard(
          icon: Icons.error_outline_rounded,
          accent: miningAmber,
          title: context.tr.miningStateErrorTitle,
          description: syncMeta.errorMessage == null
              ? context.tr.miningStateRetryLater
              : ErrorTranslator.translate(context.tr, syncMeta.errorMessage!),
          onRetry: onRetry,
        );
    }
  }
}

class _MiningLoadedSections extends StatelessWidget {
  final VoidCallback onRefresh;
  final Transaction? initialTransaction;

  const _MiningLoadedSections({
    required this.onRefresh,
    required this.initialTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverviewHeroSection(onRefresh: onRefresh),
        const SizedBox(height: AppSpacing.lg),
        const _SyncBannerSection(),
        if (initialTransaction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          MiningTransactionContextCard(transaction: initialTransaction!),
        ],
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1180) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    flex: 7,
                    child: _MiningPrimaryColumn(),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 5,
                    child: _MiningSecondaryColumn(),
                  ),
                ],
              );
            }

            if (constraints.maxWidth >= 780) {
              return Column(
                children: const [
                  _BlocksSection(),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _FeeSection()),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(child: _MempoolPressureSection()),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _NetworkHealthSection()),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(child: _HashrateTrendSection()),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _LocalMiningMonitorSection(),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _RecentBlocksSection()),
                      SizedBox(width: AppSpacing.lg),
                      Expanded(child: _PoolDistributionSection()),
                    ],
                  ),
                ],
              );
            }

            return const Column(
              children: [
                _BlocksSection(),
                SizedBox(height: AppSpacing.lg),
                _FeeSection(),
                SizedBox(height: AppSpacing.lg),
                _MempoolPressureSection(),
                SizedBox(height: AppSpacing.lg),
                _NetworkHealthSection(),
                SizedBox(height: AppSpacing.lg),
                _LocalMiningMonitorSection(),
                SizedBox(height: AppSpacing.lg),
                _HashrateTrendSection(),
                SizedBox(height: AppSpacing.lg),
                _RecentBlocksSection(),
                SizedBox(height: AppSpacing.lg),
                _PoolDistributionSection(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MiningPrimaryColumn extends StatelessWidget {
  const _MiningPrimaryColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BlocksSection(),
        SizedBox(height: AppSpacing.lg),
        _HashrateTrendSection(),
        SizedBox(height: AppSpacing.lg),
        _RecentBlocksSection(),
      ],
    );
  }
}

class _MiningSecondaryColumn extends StatelessWidget {
  const _MiningSecondaryColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FeeSection(),
        SizedBox(height: AppSpacing.lg),
        _MempoolPressureSection(),
        SizedBox(height: AppSpacing.lg),
        _NetworkHealthSection(),
        SizedBox(height: AppSpacing.lg),
        _LocalMiningMonitorSection(),
        SizedBox(height: AppSpacing.lg),
        _PoolDistributionSection(),
      ],
    );
  }
}

class _OverviewHeroSection extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _OverviewHeroSection({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final viewData = ref.watch(miningDashboardViewDataProvider);
    final syncMeta = ref.watch(miningSyncMetaProvider);

    if (snapshot == null || viewData == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningOverviewHero(
        snapshot: snapshot,
        viewData: viewData,
        syncMeta: syncMeta,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _SyncBannerSection extends ConsumerWidget {
  const _SyncBannerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncMeta = ref.watch(miningSyncMetaProvider);
    return MiningSyncStatusBanner(syncMeta: syncMeta);
  }
}

class _BlocksSection extends ConsumerWidget {
  const _BlocksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final highlightedHeights = ref.watch(miningHighlightedHeightsProvider);

    if (snapshot == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MempoolBlocksVisualizer(
        projectedBlocks: snapshot.projectedBlocks,
        confirmedBlocks: snapshot.recentBlocks,
        highlightedHeights: highlightedHeights,
      ),
    );
  }
}

class _FeeSection extends ConsumerWidget {
  const _FeeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final viewData = ref.watch(miningDashboardViewDataProvider);

    if (snapshot == null || viewData == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: LiveFeeGrid(
        feeMarket: snapshot.feeMarket,
        viewData: viewData,
      ),
    );
  }
}

class _MempoolPressureSection extends ConsumerWidget {
  const _MempoolPressureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final viewData = ref.watch(miningDashboardViewDataProvider);

    if (snapshot == null || viewData == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningMempoolPressureCard(
        snapshot: snapshot,
        viewData: viewData,
      ),
    );
  }
}

class _NetworkHealthSection extends ConsumerWidget {
  const _NetworkHealthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final viewData = ref.watch(miningDashboardViewDataProvider);

    if (snapshot == null || viewData == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningNetworkHealthCard(
        snapshot: snapshot,
        viewData: viewData,
      ),
    );
  }
}

class _LocalMiningMonitorSection extends ConsumerWidget {
  const _LocalMiningMonitorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operation = ref.watch(miningOperationProvider);
    return RepaintBoundary(
      child: MiningLocalMonitorCard(operation: operation),
    );
  }
}

class _HashrateTrendSection extends ConsumerWidget {
  const _HashrateTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);

    if (snapshot == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningHashrateTrendCard(snapshot: snapshot),
    );
  }
}

class _RecentBlocksSection extends ConsumerWidget {
  const _RecentBlocksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final highlightedHeights = ref.watch(miningHighlightedHeightsProvider);

    if (snapshot == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningRecentBlocksCard(
        blocks: snapshot.recentBlocks,
        highlightedHeights: highlightedHeights,
      ),
    );
  }
}

class _PoolDistributionSection extends ConsumerWidget {
  const _PoolDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(miningSnapshotProvider);
    final viewData = ref.watch(miningDashboardViewDataProvider);

    if (snapshot == null || viewData == null) {
      return const MiningLoadingColumn();
    }

    return RepaintBoundary(
      child: MiningPoolDistributionCard(
        pools: snapshot.dominantPools,
        viewData: viewData,
      ),
    );
  }
}
