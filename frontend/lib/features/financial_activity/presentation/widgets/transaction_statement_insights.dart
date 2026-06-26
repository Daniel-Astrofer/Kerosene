import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';

enum StatementInsightPeriod { monthly, weekly, annual }

const _background = AppColors.hexFF000000;
const _primary = AppColors.hexFFFFFFFF;
const _onSurfaceVariant = AppColors.hexFFC4C7C8;
const _surfaceVariant = AppColors.hexFF353534;
const _surfaceContainerLow = AppColors.hexFF1C1B1B;
const _singleWalletColor = AppColors.hexFF444748;
const _chartMinimumFraction = 0.055;

class TransactionStatementInsights extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Wallet> wallets;

  const TransactionStatementInsights({
    super.key,
    required this.transactions,
    required this.wallets,
  });

  @override
  State<TransactionStatementInsights> createState() =>
      _TransactionStatementInsightsState();
}

class _TransactionStatementInsightsState
    extends State<TransactionStatementInsights> {
  StatementInsightPeriod _period = StatementInsightPeriod.monthly;

  void _setPeriod(StatementInsightPeriod period) {
    if (_period == period) return;
    HapticFeedback.selectionClick();
    setState(() => _period = period);
  }

  @override
  Widget build(BuildContext context) {
    final report = _StatementReport.from(
      context: context,
      transactions: widget.transactions,
      wallets: widget.wallets,
      period: _period,
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey(
        'statement-report-${widget.wallets.length}-${widget.transactions.length}',
      ),
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
              period: _period,
              onPeriodChanged: _setPeriod,
            );
            final monthly = _MonthlyMovementPanel(
              report: report,
              selected: _period,
              onChanged: _setPeriod,
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
                  context.tr.financialStatementMovementVolume,
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
      tooltip: context.tr.financialStatementPeriodTooltip,
      onSelected: onChanged,
      itemBuilder: (context) {
        return StatementInsightPeriod.values
            .map(
              (value) => PopupMenuItem(
                value: value,
                child: Text(
                  _rangeLabel(context, value),
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _rangeLabel(context, selected),
                style: AppTypography.inter(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                KeroseneIcons.chevronDown,
                color: _onSurfaceVariant,
                size: 14,
              ),
            ],
          ),
        ),
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
        'movement-volume-${report.buckets.map((bucket) => bucket.values.map((value) => value.sats).join(':')).join('|')}',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.slow,
      curve: KeroseneMotion.standard,
      builder: (context, progress, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = math.max<double>(
              constraints.maxWidth - 48,
              report.buckets.length *
                  math.max(44.0, report.wallets.length * 18),
            );
            return Stack(
              children: [
                Positioned.fill(
                  right: 0,
                  bottom: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: axisValues
                              .map(
                                (value) => Text(
                                  _formatCompactSats(value),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.financial(
                                    color: _onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  right: 48,
                  bottom: 28,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final bucket in report.buckets)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _WalletBarGroup(
                                  bucket: bucket,
                                  axisMaxSats: report.axisMaxSats,
                                  progress: progress,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 48,
                  bottom: 0,
                  height: 22,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WalletBarGroup extends StatelessWidget {
  final _MovementBucket bucket;
  final int axisMaxSats;
  final double progress;

  const _WalletBarGroup({
    required this.bucket,
    required this.axisMaxSats,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < bucket.values.length; index++) ...[
          if (index > 0) const SizedBox(width: 3),
          Expanded(
            child: FractionallySizedBox(
              heightFactor: _barFraction(
                    bucket.values[index].sats,
                    axisMaxSats,
                  ) *
                  progress,
              alignment: Alignment.bottomCenter,
              child: _GradientBar(
                topColor: bucket.values[index].color,
                bottomColor: bucket.values[index].color.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
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
            context.tr.financialStatementMonthlyMovement,
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
                label: context.tr.financialStatementOutflows,
                value: _formatBtc(report.outgoingSats),
              ),
              _MonthlyMetric(
                icon: KeroseneIcons.down,
                label: context.tr.financialStatementInflows,
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
              _periodTabLabel(context, period).toUpperCase(),
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
            context.tr.financialStatementFundDistribution,
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
              SizedBox(
                width: 132,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.totalBalanceSats > 0 ? '100%' : '0%',
                      style: AppTypography.financial(
                        color: _primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      report.dominantWalletName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.inter(
                        color: _onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
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
  final List<_WalletInsight> wallets;
  final List<_MovementBucket> buckets;
  final List<_DistributionSegment> distribution;
  final int incomingSats;
  final int outgoingSats;
  final int axisMaxSats;
  final int totalBalanceSats;
  final String dominantWalletName;

  const _StatementReport({
    required this.wallets,
    required this.buckets,
    required this.distribution,
    required this.incomingSats,
    required this.outgoingSats,
    required this.axisMaxSats,
    required this.totalBalanceSats,
    required this.dominantWalletName,
  });

  factory _StatementReport.from({
    required BuildContext context,
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required StatementInsightPeriod period,
  }) {
    final insights = _walletInsights(context, wallets);
    final ranges = _bucketRanges(
      context: context,
      wallets: wallets,
      period: period,
    );
    final fallbackToOnlyWallet = wallets.length == 1;
    final buckets = ranges.map((range) {
      return _MovementBucket(
        label: range.label,
        values: [
          for (final wallet in insights)
            _WalletBucketValue(
              color: wallet.color,
              sats: _walletBalanceAt(
                wallet,
                transactions,
                range.end,
                fallbackToOnlyWallet: fallbackToOnlyWallet,
              ),
            ),
        ],
      );
    }).toList();
    final incoming = _periodDeltaTotal(
      insights,
      transactions,
      ranges.first.start,
      ranges.last.end,
      positive: true,
      fallbackToOnlyWallet: fallbackToOnlyWallet,
    );
    final outgoing = _periodDeltaTotal(
      insights,
      transactions,
      ranges.first.start,
      ranges.last.end,
      positive: false,
      fallbackToOnlyWallet: fallbackToOnlyWallet,
    );
    final totalBalance = insights.fold<int>(
      0,
      (sum, wallet) => sum + math.max(0, wallet.balanceSats),
    );
    final dominant = insights.reduce((a, b) {
      if (b.balanceSats != a.balanceSats) {
        return b.balanceSats > a.balanceSats ? b : a;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase()) <= 0 ? a : b;
    });
    final distribution = [
      for (final wallet in insights)
        _DistributionSegment.fromActual(
          label: wallet.name,
          sats: wallet.balanceSats,
          visualSats: totalBalance > 0 ? wallet.balanceSats : 1,
          totalSats: totalBalance,
          color: wallet.color,
        ),
    ];
    final rawAxisMax = buckets.fold<int>(
      totalBalance,
      (maxValue, bucket) => math.max(
        maxValue,
        bucket.values.fold<int>(
          0,
          (bucketMax, value) => math.max(bucketMax, value.sats),
        ),
      ),
    );

    return _StatementReport(
      wallets: insights,
      buckets: buckets,
      distribution: distribution,
      incomingSats: incoming,
      outgoingSats: outgoing,
      axisMaxSats: _niceAxisMax(rawAxisMax),
      totalBalanceSats: totalBalance,
      dominantWalletName: dominant.name,
    );
  }
}

class _WalletInsight {
  final String id;
  final String name;
  final Set<String> matchKeys;
  final int balanceSats;
  final Color color;

  const _WalletInsight({
    required this.id,
    required this.name,
    required this.matchKeys,
    required this.balanceSats,
    required this.color,
  });
}

class _MovementBucket {
  final String label;
  final List<_WalletBucketValue> values;

  const _MovementBucket({
    required this.label,
    required this.values,
  });
}

class _WalletBucketValue {
  final int sats;
  final Color color;

  const _WalletBucketValue({
    required this.sats,
    required this.color,
  });
}

class _DistributionSegment {
  final String label;
  final int visualSats;
  final double percent;
  final Color color;

  const _DistributionSegment({
    required this.label,
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
      visualSats: math.max(1, visualSats),
      percent: totalSats <= 0 ? 0 : sats / totalSats * 100,
      color: color,
    );
  }
}

List<_WalletInsight> _walletInsights(
    BuildContext context, List<Wallet> source) {
  final wallets = source.where((wallet) => wallet.isActive).toList();
  final displayWallets =
      wallets.isNotEmpty ? wallets : List<Wallet>.from(source);
  displayWallets.sort((a, b) {
    final balance = b.balance.compareTo(a.balance);
    if (balance != 0) return balance;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  if (displayWallets.isEmpty) {
    return [
      _WalletInsight(
        id: 'empty',
        name: context.tr.noWalletsFound,
        matchKeys: const {},
        balanceSats: 0,
        color: _singleWalletColor,
      ),
    ];
  }

  return [
    for (var index = 0; index < displayWallets.length; index++)
      _WalletInsight(
        id: displayWallets[index].id,
        name: displayWallets[index].name,
        matchKeys: _walletMatchKeys(displayWallets[index]),
        balanceSats: _btcToSats(displayWallets[index].balance),
        color: displayWallets.length == 1
            ? _singleWalletColor
            : _walletColor(index),
      ),
  ];
}

Set<String> _walletMatchKeys(Wallet wallet) {
  return {
    wallet.id,
    wallet.name,
    wallet.address,
    wallet.cardHolderName,
    wallet.cardNumberSuffix,
  }
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
}

List<({DateTime start, DateTime end, String label})> _bucketRanges({
  required BuildContext context,
  required List<Wallet> wallets,
  required StatementInsightPeriod period,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  final createdAt = wallets.isEmpty
      ? DateTime(now.year, now.month)
      : wallets
          .map((wallet) => wallet.createdAt.toLocal())
          .reduce((a, b) => a.isBefore(b) ? a : b);

  switch (period) {
    case StatementInsightPeriod.weekly:
      final currentWeek = _weekStart(now);
      final firstWeek = _weekStart(createdAt);
      final ytdWeek = _weekStart(DateTime(now.year));
      final start = firstWeek.isAfter(ytdWeek) ? firstWeek : ytdWeek;
      final ranges = <({DateTime start, DateTime end, String label})>[];
      for (var week = start;
          !week.isAfter(currentWeek);
          week = week.add(const Duration(days: 7))) {
        ranges.add((
          start: week,
          end: week.add(const Duration(days: 7)),
          label: DateFormat.MMMd(locale).format(week),
        ));
      }
      return ranges.isEmpty
          ? [
              (
                start: currentWeek,
                end: currentWeek.add(const Duration(days: 7)),
                label: DateFormat.MMMd(locale).format(currentWeek),
              )
            ]
          : ranges;
    case StatementInsightPeriod.annual:
      final currentMonth = DateTime(now.year, now.month);
      final firstMonth = DateTime(createdAt.year, createdAt.month);
      final start = _maxDate(
        firstMonth,
        DateTime(currentMonth.year, currentMonth.month - 11),
      );
      return _monthRanges(start, currentMonth, locale);
    case StatementInsightPeriod.monthly:
      final currentMonth = DateTime(now.year, now.month);
      final firstMonth = DateTime(createdAt.year, createdAt.month);
      final start = _maxDate(
        firstMonth,
        DateTime(currentMonth.year, currentMonth.month - 5),
      );
      return _monthRanges(start, currentMonth, locale);
  }
}

List<({DateTime start, DateTime end, String label})> _monthRanges(
  DateTime start,
  DateTime currentMonth,
  String locale,
) {
  final ranges = <({DateTime start, DateTime end, String label})>[];
  for (var month = DateTime(start.year, start.month);
      !month.isAfter(currentMonth);
      month = DateTime(month.year, month.month + 1)) {
    ranges.add((
      start: month,
      end: DateTime(month.year, month.month + 1),
      label: DateFormat.MMM(locale).format(month),
    ));
  }
  return ranges;
}

DateTime _weekStart(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day - local.weekday + 1);
}

DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

int _walletBalanceAt(
  _WalletInsight wallet,
  List<Transaction> transactions,
  DateTime end, {
  required bool fallbackToOnlyWallet,
}) {
  var balance = wallet.balanceSats;
  for (final tx in transactions) {
    final local = tx.timestamp.toLocal();
    if (local.isBefore(end)) continue;
    balance -= _walletDelta(
      wallet,
      tx,
      fallbackToWallet: fallbackToOnlyWallet,
    );
  }
  return math.max(0, balance);
}

int _periodDeltaTotal(
  List<_WalletInsight> wallets,
  List<Transaction> transactions,
  DateTime start,
  DateTime end, {
  required bool positive,
  required bool fallbackToOnlyWallet,
}) {
  var total = 0;
  for (final tx in transactions) {
    final local = tx.timestamp.toLocal();
    if (local.isBefore(start) || !local.isBefore(end)) continue;
    for (final wallet in wallets) {
      final delta = _walletDelta(
        wallet,
        tx,
        fallbackToWallet: fallbackToOnlyWallet,
      );
      if (positive && delta > 0) total += delta;
      if (!positive && delta < 0) total += delta.abs();
    }
  }
  return total;
}

int _walletDelta(
  _WalletInsight wallet,
  Transaction tx, {
  required bool fallbackToWallet,
}) {
  final amount = tx.amountSatoshis.abs();
  final debitAmount = amount + tx.feeSatoshis.abs();
  final walletMatches = _matchesWallet(wallet, [tx.walletId]);
  final sourceMatches = _matchesWallet(wallet, [
    tx.sourceWalletId,
    tx.fromAddress,
  ]);
  final destinationMatches = _matchesWallet(wallet, [
    tx.destinationWalletId,
    tx.toAddress,
  ]);
  final matched = walletMatches || sourceMatches || destinationMatches;

  if (!matched && !fallbackToWallet) return 0;
  if (tx.isInternal) {
    if (sourceMatches && !destinationMatches) return -debitAmount;
    if (destinationMatches && !sourceMatches) return amount;
  }
  if (tx.isCredit &&
      (destinationMatches || walletMatches || fallbackToWallet)) {
    return amount;
  }
  if (tx.isDebit && (sourceMatches || walletMatches || fallbackToWallet)) {
    return -debitAmount;
  }
  return 0;
}

bool _matchesWallet(_WalletInsight wallet, List<String?> candidates) {
  for (final candidate in candidates) {
    final normalized = candidate?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) continue;
    if (wallet.matchKeys.contains(normalized)) return true;
  }
  return false;
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

Color _walletColor(int index) {
  return switch (index % 6) {
    0 => _primary,
    1 => AppColors.hexFF63FEA7,
    2 => const Color(0xFFFFB874),
    3 => const Color(0xFF8E9192),
    4 => const Color(0xFFC6C6C6),
    _ => const Color(0xFF454747),
  };
}

String _rangeLabel(BuildContext context, StatementInsightPeriod period) {
  return switch (period) {
    StatementInsightPeriod.monthly =>
      context.tr.financialStatementPeriodLastSixMonths,
    StatementInsightPeriod.weekly =>
      context.tr.financialStatementPeriodYearToDate,
    StatementInsightPeriod.annual => context.tr.financialStatementPeriodOneYear,
  };
}

String _periodTabLabel(BuildContext context, StatementInsightPeriod period) {
  return switch (period) {
    StatementInsightPeriod.monthly =>
      context.tr.financialStatementPeriodMonthly,
    StatementInsightPeriod.weekly => context.tr.financialStatementPeriodWeekly,
    StatementInsightPeriod.annual => context.tr.financialStatementPeriodAnnual,
  };
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
  if (sats == 0) return '0 BTC';
  if (sats < 10000) return '$sats sats';
  final btc = sats / 100000000.0;
  return '${btc.toStringAsFixed(btc >= 1 ? 4 : 6)} BTC';
}

int _btcToSats(double btc) => math.max(0, (btc * 100000000).round());
