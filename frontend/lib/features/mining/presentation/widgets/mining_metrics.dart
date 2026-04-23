import 'dart:math' as math;
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/animated_number_display.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/models/mining_dashboard_view_data.dart';
import 'package:teste/features/mining/presentation/providers/mining_dashboard_provider.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';

class MiningOverviewHero extends StatelessWidget {
  final MiningDashboardSnapshot snapshot;
  final MiningDashboardViewData viewData;
  final MiningSyncMeta syncMeta;
  final VoidCallback onRefresh;

  const MiningOverviewHero({
    super.key,
    required this.snapshot,
    required this.viewData,
    required this.syncMeta,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final blockTimeMinutes = snapshot.averageBlockIntervalSeconds / 60;

    return MiningPanel(
      accent: miningBlue,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NETWORK MINING',
                      style: AppTypography.caption.copyWith(
                        color: miningBlue,
                        fontFamily: 'HubotSansCondensed',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Leitura operacional da rede Bitcoin.',
                      style: AppTypography.h1.copyWith(
                        fontFamily: 'HubotSansCondensed',
                        fontWeight: FontWeight.w700,
                        fontSize: 34,
                        height: 0.98,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      viewData.liveNarrative,
                      style: AppTypography.bodyMedium.copyWith(
                        color: miningMuted,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MiningStatusBadge(
                    label: _statusLabel(syncMeta.phase),
                    tone: _statusTone(syncMeta.phase),
                    pulse: syncMeta.phase == MiningSyncPhase.live,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconButton(
                    onPressed: onRefresh,
                    style: IconButton.styleFrom(
                      backgroundColor: miningSurface,
                      side: BorderSide(
                        color: miningAccentBorder(miningBlue, emphasis: 0.2),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: miningInnerBorderRadius,
                      ),
                    ),
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 900;

              return Flex(
                direction: isCompact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isCompact ? 0 : 4,
                    child: _PrimaryHeroStat(
                      label: 'Altura atual',
                      value: snapshot.currentHeight.toDouble(),
                      helper:
                          'retarget em ${snapshot.network.remainingBlocks} blocos',
                    ),
                  ),
                  SizedBox(
                    width: isCompact ? 0 : AppSpacing.lg,
                    height: isCompact ? AppSpacing.lg : 0,
                  ),
                  Expanded(
                    flex: isCompact ? 0 : 6,
                    child: LayoutBuilder(
                      builder: (context, metricConstraints) {
                        final compactWidth = metricConstraints.maxWidth < 420
                            ? double.infinity
                            : (metricConstraints.maxWidth - AppSpacing.sm) / 2;
                        final cardWidth = isCompact
                            ? compactWidth
                            : math.max(
                                180.0,
                                (metricConstraints.maxWidth -
                                        (AppSpacing.sm * 3)) /
                                    4,
                              );

                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: MiningMetricCard(
                                label: 'MRR',
                                value:
                                    '${MiningFormatters.btc(viewData.miningRevenueRunRateBtcPerDay)}/dia',
                                helper:
                                    '${MiningFormatters.btc(viewData.averageRewardPerBlockBtc)} por bloco observado',
                                accent: miningBlue,
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MiningMetricCard(
                                label: 'Hashrate',
                                value: MiningFormatters.hashrate(
                                  snapshot.network.currentHashrate,
                                ),
                                helper:
                                    'delta ${MiningFormatters.signedPercent(viewData.latestHashrateDeltaPercent)}',
                                accent: miningTeal,
                                icon: Icons.bolt_rounded,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MiningMetricCard(
                                label: 'Dificuldade',
                                value: MiningFormatters.largeNumber(
                                  snapshot.network.currentDifficulty,
                                ),
                                helper:
                                    '${MiningFormatters.signedPercent(snapshot.network.difficultyChangePercent)} no próximo ajuste',
                                accent: miningAmber,
                                icon: Icons.tune_rounded,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: MiningMetricCard(
                                label: 'Ritmo',
                                value:
                                    '${blockTimeMinutes.toStringAsFixed(1)} min/bloco',
                                helper:
                                    '${MiningFormatters.compactInt(snapshot.mempool.pendingTransactions)} pendentes',
                                accent: miningBlue,
                                icon: Icons.timer_outlined,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoPill(
                label: 'Última atualização',
                value: syncMeta.lastUpdatedAt == null
                    ? 'agora'
                    : MiningFormatters.timeOfDay(syncMeta.lastUpdatedAt!),
              ),
              _InfoPill(
                label: 'Mempool',
                value:
                    '${snapshot.mempool.loadInBlocks.toStringAsFixed(1)} blocos virtuais',
              ),
              _InfoPill(
                label: 'Taxa prioritária',
                value: '${snapshot.feeMarket.priorityFee} sat/vB',
              ),
              _InfoPill(
                label: 'TPS estimado',
                value:
                    '${snapshot.throughputTransactionsPerSecond.toStringAsFixed(1)} tx/s',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiningSyncStatusBanner extends StatelessWidget {
  final MiningSyncMeta syncMeta;

  const MiningSyncStatusBanner({
    super.key,
    required this.syncMeta,
  });

  @override
  Widget build(BuildContext context) {
    if (!syncMeta.hasWarning) {
      return const SizedBox.shrink();
    }

    final tone = _statusTone(syncMeta.phase);
    final color = _toneColor(tone);

    return MiningPanel(
      accent: color,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            _statusIcon(syncMeta.phase),
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusHeadline(syncMeta.phase),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  syncMeta.errorMessage ?? _statusDescription(syncMeta.phase),
                  style: AppTypography.bodySmall.copyWith(color: miningMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiningMempoolPressureCard extends StatelessWidget {
  final MiningDashboardSnapshot snapshot;
  final MiningDashboardViewData viewData;

  const MiningMempoolPressureCard({
    super.key,
    required this.snapshot,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    final histogram =
        snapshot.mempool.histogram.take(18).toList(growable: false);
    final maxSize = histogram.isEmpty
        ? 1
        : histogram
            .map((bin) => bin.virtualSize)
            .reduce((a, b) => a > b ? a : b);

    return MiningPanel(
      accent: miningAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: 'Pressão da mempool',
            subtitle: 'Faixa de taxa, volume pendente e disputa por inclusão.',
            trailing: MiningStatusBadge(
              label: viewData.congestionLabel.toUpperCase(),
              tone: _toneForCongestion(viewData.congestionLevel),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: histogram.map((bin) {
                final barHeight =
                    maxSize == 0 ? 0.0 : bin.virtualSize / maxSize;
                final color = _feeColor(bin.feeRate);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 10 + (92 * barHeight),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: color.withValues(alpha: 0.16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withValues(alpha: 0.92),
                                color.withValues(alpha: 0.38),
                              ],
                            ),
                            borderRadius: miningInnerBorderRadius,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bin.feeRate.toStringAsFixed(0),
                          style: miningMonoStyle(
                            AppTypography.caption,
                            color: miningMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoPill(
                label: 'Pendentes',
                value: MiningFormatters.compactInt(
                  snapshot.mempool.pendingTransactions,
                ),
              ),
              _InfoPill(
                label: 'vBytes',
                value:
                    '${MiningFormatters.compactInt(snapshot.mempool.virtualSize)} vB',
              ),
              _InfoPill(
                label: 'Volume MB',
                value:
                    MiningFormatters.megabytes(snapshot.mempool.virtualSizeMb),
              ),
              _InfoPill(
                label: 'Taxas agregadas',
                value: MiningFormatters.btc(snapshot.mempool.totalFeesBtc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiningNetworkHealthCard extends StatelessWidget {
  final MiningDashboardSnapshot snapshot;
  final MiningDashboardViewData viewData;

  const MiningNetworkHealthCard({
    super.key,
    required this.snapshot,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (snapshot.network.retargetProgressPercent / 100).clamp(0.0, 1.0);

    return MiningPanel(
      accent: miningTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: 'Saúde da rede',
            subtitle: 'Dificuldade, retarget e throughput recente.',
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: miningInnerBorderRadius,
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(miningBlue),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Retarget ${snapshot.network.retargetProgressPercent.toStringAsFixed(1)}%',
                  style: miningMonoStyle(
                    AppTypography.bodySmall,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${snapshot.network.remainingBlocks} blocos restantes',
                style: miningMonoStyle(
                  AppTypography.bodySmall,
                  color: miningMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : double.infinity;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Throughput',
                      value:
                          '${snapshot.throughputTransactionsPerSecond.toStringAsFixed(1)} tx/s',
                      helper: 'média observada nos blocos visíveis',
                      accent: miningBlue,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Ocupação',
                      value: MiningFormatters.blockFill(
                        snapshot.recentAverageWeightRatio,
                      ),
                      helper: 'peso médio dos blocos recentes',
                      accent: miningAmber,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Taxas no reward',
                      value:
                          '${snapshot.rewardWindow.feeSharePercent.toStringAsFixed(1)}%',
                      helper:
                          'janela ${snapshot.rewardWindow.startBlock}-${snapshot.rewardWindow.endBlock}',
                      accent: miningTeal,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Próximo ajuste',
                      value: snapshot.network.estimatedRetargetAt == null
                          ? 'estimando'
                          : MiningFormatters.shortDateTime(
                              snapshot.network.estimatedRetargetAt!,
                            ),
                      helper:
                          '${MiningFormatters.signedPercent(snapshot.network.difficultyChangePercent)} projetado',
                      accent: miningBlue,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class MiningLocalMonitorCard extends StatefulWidget {
  final MiningOperationState operation;

  const MiningLocalMonitorCard({
    super.key,
    required this.operation,
  });

  @override
  State<MiningLocalMonitorCard> createState() => _MiningLocalMonitorCardState();
}

class _MiningLocalMonitorCardState extends State<MiningLocalMonitorCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant MiningLocalMonitorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.operation.isActive != widget.operation.isActive ||
        oldWidget.operation.startedAtEpochMs !=
            widget.operation.startedAtEpochMs ||
        oldWidget.operation.durationHours != widget.operation.durationHours ||
        oldWidget.operation.contractedHashrateTh !=
            widget.operation.contractedHashrateTh) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _now = DateTime.now();

    if (!widget.operation.isActive) {
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final operation = widget.operation;
    final isActive = operation.isActive;
    final now = isActive ? _now : DateTime.now();
    final progress = operation.progressAt(now);
    final acceptedShares = isActive
        ? math.max(
            0,
            (progress *
                    math.max(1, operation.durationHours) *
                    math.max(1.0, operation.contractedHashrateTh) *
                    84)
                .round(),
          )
        : 0;
    final rejectedShares =
        isActive ? math.max(0, (acceptedShares * 0.012).round()) : 0;
    final temperatureC = isActive
        ? 58 +
            math.min(19, operation.contractedHashrateTh / 8) +
            (math.sin(now.second / 60 * math.pi * 2) * 2.2)
        : 0.0;

    return MiningPanel(
      accent: isActive ? miningTeal : miningMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: 'Monitor local',
            subtitle: isActive
                ? 'Telemetria local estimada da operação ativa.'
                : 'Nenhum worker local ativo.',
            trailing: MiningStatusBadge(
              label: isActive ? 'MINERANDO' : 'OFFLINE',
              tone: isActive ? MiningStatusTone.live : MiningStatusTone.neutral,
              pulse: isActive,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 560
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : double.infinity;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Hashrate local',
                      value: isActive
                          ? MiningFormatters.hashrateFromTh(
                              operation.contractedHashrateTh,
                            )
                          : '0 H/s',
                      helper: isActive
                          ? 'worker contratado em execução'
                          : 'aguardando operação',
                      accent: miningTeal,
                      icon: Icons.memory_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Shares aceitos',
                      value: MiningFormatters.compactInt(acceptedShares),
                      helper:
                          '${MiningFormatters.percent(progress * 100)} do ciclo',
                      accent: miningBlue,
                      icon: Icons.done_all_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Shares rejeitados',
                      value: MiningFormatters.compactInt(rejectedShares),
                      helper: isActive
                          ? 'taxa estimada ${(acceptedShares == 0 ? 0 : (rejectedShares / math.max(1, acceptedShares)) * 100).toStringAsFixed(2)}%'
                          : 'sem rejeições',
                      accent: isActive && rejectedShares > 0
                          ? miningAmber
                          : miningMuted,
                      icon: Icons.block_rounded,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: MiningMetricCard(
                      label: 'Temperatura',
                      value: isActive
                          ? '${temperatureC.toStringAsFixed(1)} °C'
                          : 'n/d',
                      helper: isActive
                          ? 'estimativa térmica do worker'
                          : 'sem sensor local conectado',
                      accent: temperatureC >= 76 ? miningRed : miningAmber,
                      icon: Icons.thermostat_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class MiningHashrateTrendCard extends StatelessWidget {
  final MiningDashboardSnapshot snapshot;

  const MiningHashrateTrendCard({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final points = snapshot.hashrateTimeline;
    final maxHashrate = points.isEmpty
        ? 1.0
        : points
            .map((point) => point.hashrate)
            .reduce((left, right) => left > right ? left : right);
    final minHashrate = points.isEmpty
        ? 0.0
        : points
            .map((point) => point.hashrate)
            .reduce((left, right) => left < right ? left : right);

    return MiningPanel(
      accent: miningBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: 'Tendência de hashrate',
            subtitle: 'Curva recente da potência computacional da rede.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (points.isEmpty)
            Text(
              'Sem série temporal suficiente para traçar a curva.',
              style: AppTypography.bodySmall.copyWith(color: miningMuted),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                duration: Duration.zero,
                LineChartData(
                  minY: minHashrate * 0.98,
                  maxY: maxHashrate * 1.02,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        interval: (maxHashrate - minHashrate) == 0
                            ? 1
                            : (maxHashrate - minHashrate) / 3,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            MiningFormatters.hashrate(value),
                            style: miningMonoStyle(
                              AppTypography.caption,
                              color: miningMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: points.length <= 1
                            ? 1
                            : math
                                .max(1, (points.length / 4).floor())
                                .toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              MiningFormatters.timeOfDay(
                                  points[index].timestamp),
                              style: miningMonoStyle(
                                AppTypography.caption,
                                color: miningMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: false,
                      barWidth: 2,
                      color: miningTeal,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            miningTeal.withValues(alpha: 0.12),
                            miningTeal.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                      spots: [
                        for (var index = 0; index < points.length; index++)
                          FlSpot(index.toDouble(), points[index].hashrate),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MiningRecentBlocksCard extends StatelessWidget {
  final List<MiningBlockSnapshot> blocks;
  final Set<int> highlightedHeights;

  const MiningRecentBlocksCard({
    super.key,
    required this.blocks,
    required this.highlightedHeights,
  });

  @override
  Widget build(BuildContext context) {
    final visible = blocks.take(7).toList(growable: false);

    return MiningPanel(
      accent: miningTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MiningSectionHeading(
            title: 'Blocos recentes',
            subtitle: 'Cadência, volume e ocupação em leitura curta.',
          ),
          const SizedBox(height: AppSpacing.lg),
          ...visible.map((block) {
            final highlight = highlightedHeights.contains(block.height);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecentBlockTile(
                block: block,
                highlight: highlight,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class MiningPoolDistributionCard extends StatelessWidget {
  final List<MiningPoolSnapshot> pools;
  final MiningDashboardViewData viewData;

  const MiningPoolDistributionCard({
    super.key,
    required this.pools,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    final visible = pools.take(5).toList(growable: false);
    final totalBlocks =
        visible.fold<int>(0, (sum, pool) => sum + pool.blockCount);

    return MiningPanel(
      accent: miningAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: 'Pools dominantes',
            subtitle: 'Participação recente, matching médio e blocos vazios.',
            trailing: MiningStatusBadge(
              label:
                  '${viewData.leadingPoolSharePercent.toStringAsFixed(0)}% líder',
              tone: MiningStatusTone.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...visible.map((pool) {
            final share =
                totalBlocks == 0 ? 0.0 : pool.blockCount / totalBlocks;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pool.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(share * 100).toStringAsFixed(1)}%',
                        style: miningMonoStyle(
                          AppTypography.bodySmall,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: miningInnerBorderRadius,
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        share >= 0.35 ? miningTeal : miningBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${pool.blockCount} blocos • match ${pool.averageMatchRate.toStringAsFixed(1)}% • ${pool.emptyBlocks} vazios',
                    style: AppTypography.bodySmall.copyWith(color: miningMuted),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class MiningLoadingColumn extends StatelessWidget {
  const MiningLoadingColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        MiningSkeletonBlock(height: 240),
        SizedBox(height: AppSpacing.lg),
        MiningSkeletonBlock(height: 220),
        SizedBox(height: AppSpacing.lg),
        MiningSkeletonBlock(height: 280),
      ],
    );
  }
}

class MiningStateCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback? onRetry;

  const MiningStateCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MiningPanel(
      accent: accent,
      child: Column(
        children: [
          Icon(icon, color: accent, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(color: miningMuted),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: miningSurface,
                foregroundColor: Colors.white,
                side: BorderSide(color: accent.withValues(alpha: 0.24)),
                shape: const RoundedRectangleBorder(
                  borderRadius: miningInnerBorderRadius,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryHeroStat extends StatelessWidget {
  final String label;
  final double value;
  final String helper;

  const _PrimaryHeroStat({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: miningInsetDecoration(
        accent: miningBlue,
        emphasized: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: miningBlue,
                fontFamily: 'HubotSansCondensed',
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedNumberDisplay(
              value: value,
              prefix: '#',
              decimalPlaces: 0,
              enableFlash: false,
              style: miningMonoStyle(
                AppTypography.h1,
                fontWeight: FontWeight.w700,
                fontSize: 42,
                height: 1.0,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              helper,
              style: AppTypography.bodySmall.copyWith(color: miningMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: miningInsetDecoration(accent: miningBorderStrong),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              color: miningMuted,
              fontFamily: 'HubotSansCondensed',
              letterSpacing: 0.9,
            ),
          ),
          Text(
            value,
            style: miningMonoStyle(
              AppTypography.bodySmall,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBlockTile extends StatelessWidget {
  final MiningBlockSnapshot block;
  final bool highlight;

  const _RecentBlockTile({
    required this.block,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: miningInsetDecoration(
        accent: highlight ? miningBlue : miningTeal,
        emphasized: highlight,
        color: highlight ? miningSurfaceElevated : miningSurfaceRaised,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: miningInsetDecoration(
              accent: highlight ? miningBlue : miningTeal,
              color: miningSurface,
            ),
            child: Center(
              child: Text(
                '${block.height % 1000}',
                style: miningMonoStyle(
                  AppTypography.bodyMedium,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${block.height}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${block.txCount} tx • ${MiningFormatters.blockFill(block.weightRatio)}',
                  style: AppTypography.bodySmall.copyWith(color: miningMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeago.format(block.timestamp, locale: 'en_short'),
                style: miningMonoStyle(
                  AppTypography.bodySmall,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                block.medianFeeRate == null
                    ? 'taxa n/d'
                    : MiningFormatters.feeRate(block.medianFeeRate!),
                style: miningMonoStyle(
                  AppTypography.caption,
                  color: miningMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _statusLabel(MiningSyncPhase phase) {
  switch (phase) {
    case MiningSyncPhase.initialLoading:
      return 'INICIANDO';
    case MiningSyncPhase.live:
      return 'AO VIVO';
    case MiningSyncPhase.refreshing:
      return 'ATUALIZANDO';
    case MiningSyncPhase.stale:
      return 'ATRASADO';
    case MiningSyncPhase.degraded:
      return 'DEGRADADO';
    case MiningSyncPhase.reconnecting:
      return 'RECONECTANDO';
    case MiningSyncPhase.offline:
      return 'OFFLINE';
    case MiningSyncPhase.error:
      return 'ERRO';
    case MiningSyncPhase.empty:
      return 'SEM DADOS';
  }
}

String _statusHeadline(MiningSyncPhase phase) {
  switch (phase) {
    case MiningSyncPhase.stale:
      return 'Snapshot defasado.';
    case MiningSyncPhase.degraded:
      return 'Atualização parcial.';
    case MiningSyncPhase.reconnecting:
      return 'Reconectando.';
    case MiningSyncPhase.offline:
      return 'Sem conectividade.';
    case MiningSyncPhase.error:
      return 'Falha ao carregar o painel.';
    case MiningSyncPhase.initialLoading:
    case MiningSyncPhase.live:
    case MiningSyncPhase.refreshing:
    case MiningSyncPhase.empty:
      return _statusLabel(phase);
  }
}

String _statusDescription(MiningSyncPhase phase) {
  switch (phase) {
    case MiningSyncPhase.stale:
      return 'A UI segue com o último snapshot válido.';
    case MiningSyncPhase.degraded:
      return 'Parte da telemetria falhou, mas a leitura principal segue ativa.';
    case MiningSyncPhase.reconnecting:
      return 'O polling está restabelecendo o fluxo.';
    case MiningSyncPhase.offline:
      return 'Quando a rede voltar, o painel sincroniza sozinho.';
    case MiningSyncPhase.error:
      return 'Nenhum snapshot confiável foi carregado nesta tentativa.';
    case MiningSyncPhase.initialLoading:
    case MiningSyncPhase.live:
    case MiningSyncPhase.refreshing:
    case MiningSyncPhase.empty:
      return '';
  }
}

IconData _statusIcon(MiningSyncPhase phase) {
  switch (phase) {
    case MiningSyncPhase.stale:
      return Icons.schedule_rounded;
    case MiningSyncPhase.degraded:
      return Icons.warning_amber_rounded;
    case MiningSyncPhase.reconnecting:
      return Icons.sync_problem_rounded;
    case MiningSyncPhase.offline:
      return Icons.portable_wifi_off_rounded;
    case MiningSyncPhase.error:
      return Icons.error_outline_rounded;
    case MiningSyncPhase.initialLoading:
      return Icons.hourglass_bottom_rounded;
    case MiningSyncPhase.live:
      return Icons.podcasts_rounded;
    case MiningSyncPhase.refreshing:
      return Icons.sync_rounded;
    case MiningSyncPhase.empty:
      return Icons.inbox_outlined;
  }
}

MiningStatusTone _statusTone(MiningSyncPhase phase) {
  switch (phase) {
    case MiningSyncPhase.live:
      return MiningStatusTone.live;
    case MiningSyncPhase.refreshing:
    case MiningSyncPhase.initialLoading:
      return MiningStatusTone.info;
    case MiningSyncPhase.stale:
    case MiningSyncPhase.degraded:
    case MiningSyncPhase.reconnecting:
      return MiningStatusTone.warning;
    case MiningSyncPhase.offline:
    case MiningSyncPhase.error:
      return MiningStatusTone.danger;
    case MiningSyncPhase.empty:
      return MiningStatusTone.neutral;
  }
}

MiningStatusTone _toneForCongestion(MiningCongestionLevel level) {
  switch (level) {
    case MiningCongestionLevel.calm:
      return MiningStatusTone.live;
    case MiningCongestionLevel.elevated:
      return MiningStatusTone.info;
    case MiningCongestionLevel.busy:
      return MiningStatusTone.warning;
    case MiningCongestionLevel.saturated:
      return MiningStatusTone.danger;
  }
}

Color _toneColor(MiningStatusTone tone) {
  return miningToneColor(tone);
}

Color _feeColor(double feeRate) {
  final normalized = (feeRate / 90).clamp(0.0, 1.0);
  return Color.lerp(miningRed, miningTeal, normalized) ?? miningBlue;
}
