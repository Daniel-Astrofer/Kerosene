import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

enum StatementInsightPeriod { monthly, weekly, annual }

const _background = Colors.black;
const _primary = Colors.white;
const _onSurfaceVariant = AppColors.hexFFC4C7C8;
const _surfaceVariant = AppColors.hexFF353534;
const _outlineVariant = AppColors.hexFF444748;
const _surfaceContainerLow = AppColors.hexFF1C1B1B;
const _chartMinimumFraction = 0.055;

class TransactionStatementInsights extends StatelessWidget {
  final List<Transaction> transactions;
  final StatementInsightPeriod period;
  final ValueChanged<StatementInsightPeriod> onPeriodChanged;

  const TransactionStatementInsights({
    super.key,
    required this.transactions,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final report = _StatementReport.from(transactions, period);
    return TweenAnimationBuilder<double>(
      key: ValueKey('statement-report-${period.name}-${transactions.length}'),
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.slow,
      curve: KeroseneMotion.standard,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final volume = _MovementVolumePanel(
              report: report,
              period: period,
              onPeriodChanged: onPeriodChanged,
            );
            final monthly = _MonthlyMovementPanel(
              report: report,
              selected: period,
              onChanged: onPeriodChanged,
            );
            final distribution = _FundDistributionPanel(report: report);

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  volume,
                  const SizedBox(height: 18),
                  monthly,
                  const SizedBox(height: 18),
                  distribution,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: volume),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: distribution),
                  ],
                ),
                const SizedBox(height: 18),
                monthly,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MovementVolumePanel extends StatelessWidget {
  final _StatementReport report;
  final StatementInsightPeriod period;
  final ValueChanged<StatementInsightPeriod> onPeriodChanged;

  const _MovementVolumePanel({
    required this.report,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      minHeight: 400,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Movement Volume',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: _primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
              _RangeSelector(selected: period, onChanged: onPeriodChanged),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: _MovementBarChart(report: report)),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final StatementInsightPeriod selected;
  final ValueChanged<StatementInsightPeriod> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StatementInsightPeriod>(
      initialValue: selected,
      color: _surfaceContainerLow,
      elevation: 10,
      tooltip: 'Periodo',
      onSelected: onChanged,
      itemBuilder: (context) {
        return StatementInsightPeriod.values
            .map(
              (value) => PopupMenuItem(
                value: value,
                child: Text(
                  _rangeLabel(value),
                  style: AppTypography.inter(
                    color: value == selected ? _primary : _onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _rangeLabel(selected),
            style: AppTypography.inter(
              color: _onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(KeroseneIcons.chevronDown,
              color: _onSurfaceVariant, size: 14),
        ],
      ),
    );
  }
}

class _MovementBarChart extends StatelessWidget {
  final _StatementReport report;

  const _MovementBarChart({required this.report});

  @override
  Widget build(BuildContext context) {
    final axisValues = _axisValues(report.axisMaxSats);
    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'movement-volume-${report.buckets.map((bucket) => '${bucket.incomingSats}:${bucket.outgoingSats}').join('|')}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.slow,
      curve: KeroseneMotion.standard,
      builder: (context, progress, _) {
        return Stack(
          children: [
            Positioned.fill(
              bottom: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: axisValues
                          .map(
                            (value) => Text(
                              _formatCompactSats(value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.financial(
                                color: _onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        axisValues.length,
                        (_) => Container(
                          height: 1,
                          color: _surfaceVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              left: 52,
              bottom: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in report.buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _MovementBarPair(
                          bucket: bucket,
                          axisMaxSats: report.axisMaxSats,
                          progress: progress,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 52,
              right: 0,
              bottom: 0,
              height: 22,
              child: Row(
                children: [
                  for (final bucket in report.buckets)
                    Expanded(
                      child: Text(
                        bucket.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.financial(
                          color: _onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MovementBarPair extends StatelessWidget {
  final _MovementBucket bucket;
  final int axisMaxSats;
  final double progress;

  const _MovementBarPair({
    required this.bucket,
    required this.axisMaxSats,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final incoming = _barFraction(bucket.incomingSats, axisMaxSats) * progress;
    final outgoing = _barFraction(bucket.outgoingSats, axisMaxSats) * progress;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: FractionallySizedBox(
            heightFactor: incoming.clamp(0.0, 1.0),
            alignment: Alignment.bottomCenter,
            child: _GradientBar(
              topColor: _primary,
              bottomColor: _primary.withValues(alpha: 0.10),
            ),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: FractionallySizedBox(
            heightFactor: outgoing.clamp(0.0, 1.0),
            alignment: Alignment.bottomCenter,
            child: _GradientBar(
              topColor: _outlineVariant,
              bottomColor: _outlineVariant.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientBar extends StatelessWidget {
  final Color topColor;
  final Color bottomColor;

  const _GradientBar({required this.topColor, required this.bottomColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [bottomColor, topColor],
        ),
      ),
    );
  }
}

class _MonthlyMovementPanel extends StatelessWidget {
  final _StatementReport report;
  final StatementInsightPeriod selected;
  final ValueChanged<StatementInsightPeriod> onChanged;

  const _MonthlyMovementPanel({
    required this.report,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      child: Column(
        children: [
          Text(
            'Movimentação mensal',
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _primary,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 13),
          _PeriodTabs(selected: selected, onChanged: onChanged),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 52,
            runSpacing: 20,
            children: [
              _MonthlyMetric(
                icon: KeroseneIcons.up,
                label: 'Saídas',
                value: _formatBtc(report.outgoingSats),
              ),
              _MonthlyMetric(
                icon: KeroseneIcons.down,
                label: 'Entradas',
                value: _formatBtc(report.incomingSats),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final StatementInsightPeriod selected;
  final ValueChanged<StatementInsightPeriod> onChanged;

  const _PeriodTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: StatementInsightPeriod.values.map((period) {
        final active = selected == period;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(period),
          child: AnimatedOpacity(
            opacity: active ? 1 : 0.5,
            duration: KeroseneMotion.short,
            child: Text(
              _periodTabLabel(period),
              style: AppTypography.inter(
                color: active ? _primary : _onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MonthlyMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _onSurfaceVariant, size: 14),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTypography.inter(
                  color: _onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.financial(
              color: _primary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundDistributionPanel extends StatelessWidget {
  final _StatementReport report;

  const _FundDistributionPanel({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      minHeight: 400,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fund Distribution',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: _DistributionDonut(report: report),
            ),
          ),
          const SizedBox(height: 16),
          for (final segment in report.distribution)
            _DistributionLegend(segment),
        ],
      ),
    );
  }
}

class _DistributionDonut extends StatelessWidget {
  final _StatementReport report;

  const _DistributionDonut({required this.report});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'fund-distribution-${report.distribution.map((segment) => segment.visualSats).join('|')}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.slow,
      curve: KeroseneMotion.standard,
      builder: (context, progress, _) {
        return AnimatedScale(
          scale: 1 + (math.sin(progress * math.pi) * 0.03),
          duration: KeroseneMotion.short,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(214),
                painter: _DistributionDonutPainter(
                  segments: report.distribution,
                  progress: progress,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    report.hasMovements ? '100%' : '0%',
                    style: AppTypography.financial(
                      color: _primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'ALLOCATED',
                    style: AppTypography.inter(
                      color: _onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DistributionDonutPainter extends CustomPainter {
  final List<_DistributionSegment> segments;
  final double progress;

  const _DistributionDonutPainter({
    required this.segments,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(22);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..color = _surfaceVariant.withValues(alpha: 0.22);

    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, basePaint);

    final total = segments.fold<int>(
      0,
      (sum, segment) => sum + segment.visualSats,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.visualSats / total) * math.pi * 2 * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt
        ..color = segment.color;
      canvas.drawArc(arcRect, start, math.max(0.01, sweep), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionDonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}

class _DistributionLegend extends StatelessWidget {
  final _DistributionSegment segment;

  const _DistributionLegend(this.segment);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: segment.color,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: _onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            '${segment.percent.toStringAsFixed(1)}%',
            style: AppTypography.financial(
              color: _primary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? minHeight;

  const _SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _background,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (minHeight != null) {
      return SizedBox(
        height: minHeight,
        child: panel,
      );
    }
    return panel;
  }
}

class _StatementReport {
  final List<_MovementBucket> buckets;
  final List<_DistributionSegment> distribution;
  final int incomingSats;
  final int outgoingSats;
  final int axisMaxSats;
  final bool hasMovements;

  const _StatementReport({
    required this.buckets,
    required this.distribution,
    required this.incomingSats,
    required this.outgoingSats,
    required this.axisMaxSats,
    required this.hasMovements,
  });

  factory _StatementReport.from(
    List<Transaction> transactions,
    StatementInsightPeriod period,
  ) {
    final buckets = _buildMovementBuckets(transactions, period);
    final incoming = transactions.where((tx) => tx.isCredit).fold<int>(
          0,
          (sum, tx) => sum + tx.amountSatoshis.abs(),
        );
    final outgoing = transactions.where((tx) => tx.isDebit).fold<int>(
          0,
          (sum, tx) => sum + tx.amountSatoshis.abs(),
        );
    final onChain = _sumWhere(
      transactions,
      (tx) => !tx.isInternal && !tx.isLightning,
    );
    final internal = _sumWhere(transactions, (tx) => tx.isInternal);
    final exchange = _sumWhere(
      transactions,
      (tx) => tx.isLightning && !tx.isInternal,
    );
    final movementTotal = incoming + outgoing;
    final distributionTotal = onChain + internal + exchange;
    final axisMax = _niceAxisMax(
      buckets.fold<int>(
        0,
        (maxValue, bucket) => math.max(
          maxValue,
          math.max(bucket.incomingSats, bucket.outgoingSats),
        ),
      ),
    );

    final hasMovements = movementTotal > 0 || distributionTotal > 0;
    final distribution = [
      _DistributionSegment.fromActual(
        label: 'On-chain',
        sats: onChain,
        visualSats: hasMovements ? onChain : 654,
        totalSats: distributionTotal,
        color: _primary,
      ),
      _DistributionSegment.fromActual(
        label: 'Internal',
        sats: internal,
        visualSats: hasMovements ? internal : 221,
        totalSats: distributionTotal,
        color: _outlineVariant,
      ),
      _DistributionSegment.fromActual(
        label: 'Exchange',
        sats: exchange,
        visualSats: hasMovements ? exchange : 125,
        totalSats: distributionTotal,
        color: _surfaceVariant,
      ),
    ];

    return _StatementReport(
      buckets: buckets,
      distribution: distribution,
      incomingSats: incoming,
      outgoingSats: outgoing,
      axisMaxSats: axisMax,
      hasMovements: hasMovements,
    );
  }
}

class _MovementBucket {
  final String label;
  final int incomingSats;
  final int outgoingSats;

  const _MovementBucket(this.label, this.incomingSats, this.outgoingSats);
}

class _DistributionSegment {
  final String label;
  final int sats;
  final int visualSats;
  final double percent;
  final Color color;

  const _DistributionSegment({
    required this.label,
    required this.sats,
    required this.visualSats,
    required this.percent,
    required this.color,
  });

  factory _DistributionSegment.fromActual({
    required String label,
    required int sats,
    required int visualSats,
    required int totalSats,
    required Color color,
  }) {
    return _DistributionSegment(
      label: label,
      sats: sats,
      visualSats: math.max(1, visualSats),
      percent: totalSats <= 0 ? 0 : sats / totalSats * 100,
      color: color,
    );
  }
}

List<_MovementBucket> _buildMovementBuckets(
  List<Transaction> transactions,
  StatementInsightPeriod period,
) {
  final now = DateTime.now();
  final buckets = <_MovementBucket>[];
  for (var index = 5; index >= 0; index--) {
    final range = _bucketRange(now, period, index);
    var incoming = 0;
    var outgoing = 0;
    for (final tx in transactions) {
      final local = tx.timestamp.toLocal();
      if (local.isBefore(range.start) || !local.isBefore(range.end)) continue;
      if (tx.isCredit) incoming += tx.amountSatoshis.abs();
      if (tx.isDebit) outgoing += tx.amountSatoshis.abs();
    }
    buckets.add(_MovementBucket(range.label, incoming, outgoing));
  }
  return buckets;
}

({DateTime start, DateTime end, String label}) _bucketRange(
  DateTime now,
  StatementInsightPeriod period,
  int offset,
) {
  return switch (period) {
    StatementInsightPeriod.weekly => () {
        final currentWeekStart = DateTime(
          now.year,
          now.month,
          now.day - now.weekday + 1,
        );
        final start = currentWeekStart.subtract(Duration(days: 7 * offset));
        return (
          start: start,
          end: start.add(const Duration(days: 7)),
          label: 'S${_weekOfYear(start)}',
        );
      }(),
    StatementInsightPeriod.annual => () {
        final year = now.year - offset;
        return (
          start: DateTime(year),
          end: DateTime(year + 1),
          label: year.toString(),
        );
      }(),
    StatementInsightPeriod.monthly => () {
        final month = DateTime(now.year, now.month - offset);
        return (
          start: month,
          end: DateTime(month.year, month.month + 1),
          label: _monthLabel(month.month),
        );
      }(),
  };
}

List<int> _axisValues(int maxSats) {
  final step = math.max(1, (maxSats / 5).ceil());
  return List.generate(6, (index) => math.max(0, maxSats - (step * index)));
}

double _barFraction(int sats, int axisMaxSats) {
  if (sats <= 0) return _chartMinimumFraction;
  return math.max(_chartMinimumFraction, sats / math.max(1, axisMaxSats));
}

int _niceAxisMax(int rawMax) {
  if (rawMax <= 0) return 250000;
  final magnitude = math.pow(10, rawMax.toString().length - 1).toInt();
  final normalized = rawMax / magnitude;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
          ? 2
          : normalized <= 5
              ? 5
              : 10;
  return nice * magnitude;
}

int _weekOfYear(DateTime date) {
  final firstDay = DateTime(date.year);
  return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return labels[(month - 1).clamp(0, 11)];
}

String _rangeLabel(StatementInsightPeriod period) {
  return switch (period) {
    StatementInsightPeriod.monthly => 'Last 6 Months',
    StatementInsightPeriod.weekly => 'YTD',
    StatementInsightPeriod.annual => '1 Year',
  };
}

String _periodTabLabel(StatementInsightPeriod period) {
  return switch (period) {
    StatementInsightPeriod.monthly => 'MENSAL',
    StatementInsightPeriod.weekly => 'SEMANAL',
    StatementInsightPeriod.annual => 'ANUAL',
  };
}

int _sumWhere(List<Transaction> transactions, bool Function(Transaction) test) {
  return transactions
      .where(test)
      .fold<int>(0, (sum, tx) => sum + tx.amountSatoshis.abs());
}

String _formatCompactSats(int sats) {
  if (sats >= 100000000) {
    final btc = sats / 100000000.0;
    return '${btc.toStringAsFixed(btc >= 10 ? 0 : 1)} BTC';
  }
  if (sats >= 1000) {
    return '${(sats / 1000).round()}k';
  }
  return '$sats';
}

String _formatBtc(int sats) {
  final btc = sats / 100000000.0;
  if (sats == 0) return '0 BTC';
  if (sats < 10000) return '$sats sats';
  return '${btc.toStringAsFixed(btc >= 1 ? 4 : 6)} BTC';
}
