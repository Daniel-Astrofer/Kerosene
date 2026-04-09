import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/data/models/mempool_market_models.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';
import 'package:teste/features/mining/presentation/screens/mining_contract_screen.dart';

class MiningScreen extends ConsumerStatefulWidget {
  const MiningScreen({super.key});

  @override
  ConsumerState<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends ConsumerState<MiningScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await HapticFeedback.lightImpact();
    try {
      ref.invalidate(mempoolMiningDashboardProvider);
      await ref.read(mempoolMiningDashboardProvider.future);
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppNotice.showError(
        context,
        title: 'Falha ao atualizar',
        message: error.toString(),
      );
    }
  }

  Future<void> _openContract(MempoolMiningDashboardData data) async {
    await HapticFeedback.selectionClick();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MiningContractScreen(dashboardData: data),
      ),
    );

    if (mounted) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(mempoolMiningDashboardProvider);
    final operation = ref.watch(miningOperationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF04070A),
      bottomNavigationBar: const AppPrimaryNavigationBar(
        currentDestination: AppPrimaryDestination.mining,
      ),
      body: Stack(
        children: [
          const _MiningBackdrop(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF9FE870),
              backgroundColor: const Color(0xFF0A131B),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _MiningHeader(onRefresh: _refresh),
                        const SizedBox(height: AppSpacing.lg),
                        _OperationHeroCard(
                          operation: operation,
                          now: _now,
                          onMineTap: dashboardAsync.asData?.value != null
                              ? () => _openContract(dashboardAsync.asData!.value)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        dashboardAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, _) => _ErrorStateCard(
                            message: error.toString(),
                            onRetry: _refresh,
                          ),
                          data: (data) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeading(
                                title: 'Pulso da mempool',
                                subtitle:
                                    'Leitura real do mercado, filas, taxas e atividade recente de blocos.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MarketSummaryGrid(data: data),
                              const SizedBox(height: AppSpacing.lg),
                              _FeeRecommendationRow(fees: data.fees),
                              const SizedBox(height: AppSpacing.lg),
                              _HistogramCard(data: data.mempool),
                              const SizedBox(height: AppSpacing.lg),
                              _HashrateChartCard(
                                hashrate: data.hashrate,
                                rewardStats: data.rewardStats,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _DifficultyCard(difficulty: data.difficulty),
                              const SizedBox(height: AppSpacing.lg),
                              _RewardSnapshotCard(data: data),
                              const SizedBox(height: AppSpacing.lg),
                              _SectionHeading(
                                title: 'Blocos na fila',
                                subtitle:
                                    'Agrupamento de blocos estimados pela mempool com taxa mediana, volume virtual e total de taxas.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MempoolBlocksCard(feeBlocks: data.feeBlocks),
                              const SizedBox(height: AppSpacing.lg),
                              _SectionHeading(
                                title: 'Últimos blocos',
                                subtitle:
                                    'Confirmações recentes com altura, tamanho, peso e quantidade de transações.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _RecentBlocksCard(blocks: data.blocks),
                              const SizedBox(height: AppSpacing.lg),
                              _SectionHeading(
                                title: 'Pools dominantes',
                                subtitle:
                                    'Participação dos principais pools na última semana e aderência ao template esperado.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MiningPoolsCard(pools: data.pools),
                            ],
                          ),
                        ),
                      ]),
                    ),
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

class _MiningBackdrop extends StatelessWidget {
  const _MiningBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020407),
              Color(0xFF071019),
              Color(0xFF03060A),
            ],
          ),
        ),
        child: Stack(
          children: const [
            _BackdropGlow(
              alignment: Alignment(-0.95, -0.92),
              size: 250,
              colors: [Color(0x241AC8FF), Color(0x001AC8FF)],
            ),
            _BackdropGlow(
              alignment: Alignment(0.92, -0.70),
              size: 320,
              colors: [Color(0x226A11CB), Color(0x006A11CB)],
            ),
            _BackdropGlow(
              alignment: Alignment(0.12, 1.05),
              size: 360,
              colors: [Color(0x229FE870), Color(0x009FE870)],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final List<Color> colors;

  const _BackdropGlow({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _MiningHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _MiningHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mercado de mineração',
                style: AppTypography.h1.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Painel mobile da mempool com taxas, blocos, hashrate e leitura operacional em tempo real.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.64),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
          color: Colors.white,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _OperationHeroCard extends StatelessWidget {
  final MiningOperationState operation;
  final DateTime now;
  final VoidCallback? onMineTap;

  const _OperationHeroCard({
    required this.operation,
    required this.now,
    required this.onMineTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = operation.progressAt(now);
    final minedBalance = operation.minedBalanceAt(now);
    final remaining = operation.remainingAt(now);

    final statusText = switch (operation.status) {
      MiningOperationStatus.idle => 'Sem operação configurada',
      MiningOperationStatus.active =>
        'Acompanhando contrato e execução estimada',
      MiningOperationStatus.completed =>
        'Operação finalizada conforme alvo contratado',
    };

    final statusTitle = switch (operation.status) {
      MiningOperationStatus.idle => 'Operação inativa',
      MiningOperationStatus.active => 'Operação ativa',
      MiningOperationStatus.completed => 'Operação concluída',
    };

    final statusIcon = switch (operation.status) {
      MiningOperationStatus.idle => Icons.power_settings_new_rounded,
      MiningOperationStatus.active => Icons.bolt_rounded,
      MiningOperationStatus.completed => Icons.check_circle_rounded,
    };

    final statusColors = switch (operation.status) {
      MiningOperationStatus.idle => [Colors.white24, Colors.white12],
      MiningOperationStatus.active => [
          const Color(0xFF9FE870),
          const Color(0xFF47C77B)
        ],
      MiningOperationStatus.completed => [
          const Color(0xFF67B5FF),
          const Color(0xFF007BFF)
        ],
    };

    return GlassContainer(
      blur: 28,
      opacity: 0.08,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: statusColors,
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: operation.status == MiningOperationStatus.idle
                        ? Colors.white
                        : Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onMineTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9FE870),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Minerar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth < 400 ? 1 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.65,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _MetricTile(
                      label: 'Saldo minerado',
                      value: operation.status != MiningOperationStatus.idle
                          ? MiningFormatters.btc(minedBalance)
                          : '0.00000000 BTC',
                      accent: const Color(0xFF9FE870),
                    ),
                    _MetricTile(
                      label: 'Hashrate contratado',
                      value: operation.status != MiningOperationStatus.idle
                          ? MiningFormatters.hashrateFromTh(
                              operation.contractedHashrateTh,
                            )
                          : '--',
                      accent: const Color(0xFF67B5FF),
                    ),
                    _MetricTile(
                      label: 'Tempo restante',
                      value: operation.isActive
                          ? MiningFormatters.duration(remaining)
                          : '--',
                      accent: const Color(0xFFFFD166),
                    ),
                    _MetricTile(
                      label: 'Progresso',
                      value: operation.status != MiningOperationStatus.idle
                          ? MiningFormatters.percent(progress * 100)
                          : '0.0%',
                      accent: const Color(0xFFB388FF),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: operation.status != MiningOperationStatus.idle ? progress : 0,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                statusColors.first,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              operation.status != MiningOperationStatus.idle &&
                      operation.endsAt != null
                  ? (operation.isExpired
                      ? 'Encerrado em ${MiningFormatters.dateTimeFromEpochMillis(operation.endsAt!.millisecondsSinceEpoch)}'
                      : 'Encerramento previsto em ${MiningFormatters.dateTimeFromEpochMillis(operation.endsAt!.millisecondsSinceEpoch)}')
                  : 'Toque em Minerar para definir alvo em BTC e prazo estimado de operação.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
      ],
    );
  }
}

class _MarketSummaryGrid extends StatelessWidget {
  final MempoolMiningDashboardData data;

  const _MarketSummaryGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = <({String label, String value, String helper})>[
      (
        label: 'Transações na fila',
        value: MiningFormatters.compactInt(data.mempool.count),
        helper: 'tx aguardando inclusão',
      ),
      (
        label: 'Volume virtual',
        value: '${data.mempoolVsizeMb.toStringAsFixed(1)} MB',
        helper: 'ocupação da mempool',
      ),
      (
        label: 'Taxas totais',
        value: MiningFormatters.btc(data.totalFeesBtc),
        helper: 'recompensa disponível',
      ),
      (
        label: 'Próximo retarget',
        value: '#${data.difficulty.nextRetargetHeight}',
        helper: '${data.difficulty.remainingBlocks} blocos restantes',
      ),
    ];

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth < 400 ? 1 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 3.2 : 1.55,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return GlassContainer(
              blur: 16,
              opacity: 0.05,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.label,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.56),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      card.value,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.helper,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.54),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeeRecommendationRow extends StatelessWidget {
  final MempoolFees fees;

  const _FeeRecommendationRow({required this.fees});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Imediata', fees.fastestFee, const Color(0xFFFF6B6B)),
      ('30 min', fees.halfHourFee, const Color(0xFFFFA94D)),
      ('1 hora', fees.hourFee, const Color(0xFFFFD166)),
      ('Econômica', fees.economyFee, const Color(0xFF69DB7C)),
      ('Mínima', fees.minimumFee, const Color(0xFF67B5FF)),
    ];

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 128,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.56),
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.$2}',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'sat/vB',
                  style: AppTypography.bodySmall.copyWith(
                    color: item.$3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistogramCard extends StatelessWidget {
  final MempoolSnapshot data;

  const _HistogramCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bins = data.histogram.take(12).toList();
    final maxVsize = bins.isEmpty
        ? 1.0
        : bins.map((bin) => bin.vsize.toDouble()).reduce(math.max) * 1.15;

    return GlassContainer(
      blur: 20,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa de taxas',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Cada barra representa um degrau da fee histogram da mempool. Quanto maior a barra, maior o volume virtual naquela faixa.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 220,
              child: bins.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : BarChart(
                      BarChartData(
                        maxY: maxVsize,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxVsize / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= bins.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    bins[index].feeRate.toStringAsFixed(1),
                                    style: AppTypography.caption.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.46),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < bins.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: bins[i].vsize.toDouble(),
                                  width: 14,
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0xFF67B5FF),
                                      Color(0xFF9FE870),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Base: ${bins.length} faixas iniciais da fee histogram pública.',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.46),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HashrateChartCard extends StatelessWidget {
  final MiningHashrateSnapshot hashrate;
  final MiningRewardStats rewardStats;

  const _HashrateChartCard({
    required this.hashrate,
    required this.rewardStats,
  });

  @override
  Widget build(BuildContext context) {
    final points = hashrate.hashrates;
    final maxY = points.isEmpty
        ? 1.0
        : points
                .map((point) => point.avgHashrate / 1000000000000000000.0)
                .reduce(math.max) *
            1.15;

    return GlassContainer(
      blur: 20,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hashrate da rede',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Tendência dos últimos 3 dias com base no endpoint público de hashrate da mempool.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 220,
              child: points.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= points.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    DateFormat('dd/MM').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        points[index].timestamp * 1000,
                                      ),
                                    ),
                                    style: AppTypography.caption.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.46),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < points.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  points[i].avgHashrate / 1000000000000000000.0,
                                ),
                            ],
                            isCurved: true,
                            color: const Color(0xFF9FE870),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF9FE870)
                                      .withValues(alpha: 0.22),
                                  const Color(0xFF9FE870)
                                      .withValues(alpha: 0.00),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Hashrate atual',
                    value: MiningFormatters.hashrate(hashrate.currentHashrate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Recompensa 144 blocos',
                    value: MiningFormatters.btc(
                      rewardStats.totalRewardSat / 100000000.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final DifficultyAdjustmentInfo difficulty;

  const _DifficultyCard({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final changeColor = difficulty.difficultyChange >= 0
        ? const Color(0xFF69DB7C)
        : const Color(0xFFFF8787);

    return GlassContainer(
      blur: 18,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajuste de dificuldade',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: (difficulty.progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(changeColor),
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Progresso',
                    value: MiningFormatters.percent(difficulty.progressPercent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Variação estimada',
                    value:
                        '${difficulty.difficultyChange >= 0 ? '+' : ''}${difficulty.difficultyChange.toStringAsFixed(2)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Blocos restantes',
                    value: '${difficulty.remainingBlocks}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Retarget previsto',
                    value: MiningFormatters.dateTimeFromEpochMillis(
                      difficulty.estimatedRetargetDate,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardSnapshotCard extends StatelessWidget {
  final MempoolMiningDashboardData data;

  const _RewardSnapshotCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snapshot de recompensa',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumo das últimas 144 confirmações observado pela mempool.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Total recompensado',
                    value: MiningFormatters.btc(
                      data.rewardStats.totalRewardSat / 100000000.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Total em taxas',
                    value: MiningFormatters.btc(
                      data.rewardStats.totalFeeSat / 100000000.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Transações',
                    value:
                        MiningFormatters.compactInt(data.rewardStats.totalTx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniInfoTile(
                    label: 'Intervalo',
                    value:
                        '#${data.rewardStats.startBlock} - #${data.rewardStats.endBlock}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MempoolBlocksCard extends StatelessWidget {
  final List<MempoolFeeBlock> feeBlocks;

  const _MempoolBlocksCard({required this.feeBlocks});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < feeBlocks.take(6).length; i++) ...[
              _MempoolBlockTile(
                index: i,
                block: feeBlocks[i],
              ),
              if (i < math.min(feeBlocks.length, 6) - 1)
                Divider(color: Colors.white.withValues(alpha: 0.06)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MempoolBlockTile extends StatelessWidget {
  final int index;
  final MempoolFeeBlock block;

  const _MempoolBlockTile({
    required this.index,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final feeMin = block.feeRange.isEmpty ? 0 : block.feeRange.first;
    final feeMax = block.feeRange.isEmpty ? 0 : block.feeRange.last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF67B5FF).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloco estimado ${index + 1}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${block.txCount} tx • ${MiningFormatters.feeRate(block.medianFee)} mediana',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InlineTag(
                      label:
                          '${(block.blockVSize / 1000000).toStringAsFixed(2)} MVB',
                    ),
                    _InlineTag(
                      label:
                          'taxas ${MiningFormatters.btc(block.totalFees / 100000000.0)}',
                    ),
                    _InlineTag(
                      label:
                          '${feeMin.toStringAsFixed(2)}-${feeMax.toStringAsFixed(2)} sat/vB',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBlocksCard extends StatelessWidget {
  final List<MempoolBlock> blocks;

  const _RecentBlocksCard({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < blocks.take(8).length; i++) ...[
              _RecentBlockTile(block: blocks[i]),
              if (i < math.min(blocks.length, 8) - 1)
                Divider(color: Colors.white.withValues(alpha: 0.06)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentBlockTile extends StatelessWidget {
  final MempoolBlock block;

  const _RecentBlockTile({required this.block});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF9FE870),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bloco #${block.height}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${block.txCount} tx • ${(block.size / 1000000).toStringAsFixed(2)} MB • ${(block.weight / 1000000).toStringAsFixed(2)} MWU',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${MiningFormatters.dateTimeFromEpochSeconds(block.timestamp)} • ${block.id.substring(0, 18)}...',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiningPoolsCard extends StatelessWidget {
  final List<MiningPool> pools;

  const _MiningPoolsCard({required this.pools});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < pools.take(6).length; i++) ...[
              _PoolTile(pool: pools[i]),
              if (i < math.min(pools.length, 6) - 1)
                Divider(color: Colors.white.withValues(alpha: 0.06)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  final MiningPool pool;

  const _PoolTile({required this.pool});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '#${pool.rank}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pool.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pool.blockCount} blocos • match ${pool.avgMatchRate.toStringAsFixed(2)}% • vazios ${pool.emptyBlocks}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _InlineTag(label: pool.avgFeeDelta),
        ],
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String label;

  const _InlineTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.68),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorStateCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 18,
      opacity: 0.06,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Não foi possível carregar a mempool',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
