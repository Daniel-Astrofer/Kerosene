import 'package:flutter/material.dart';

import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/models/mining_dashboard_view_data.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';
import 'package:teste/l10n/l10n_extension.dart';

class LiveFeeGrid extends StatelessWidget {
  final MiningFeeMarketSnapshot feeMarket;
  final MiningDashboardViewData viewData;

  const LiveFeeGrid({
    super.key,
    required this.feeMarket,
    required this.viewData,
  });

  @override
  Widget build(BuildContext context) {
    return MiningPanel(
      accent: miningAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: context.l10n.miningFeesTitle,
            subtitle: context.l10n.miningFeesSubtitle,
            trailing: MiningTrendChip(
              label: '${viewData.projectedFastLaneWindowMinutes} min',
              positive: viewData.congestionLevel == MiningCongestionLevel.calm,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SignalChip(
                label: viewData.congestionLabel,
                tone: _toneForCongestion(viewData.congestionLevel),
              ),
              _SignalChip(
                label: viewData.hasWideFeeSpread
                    ? context.l10n.miningFeesWideSpread
                    : context.l10n.miningFeesControlledSpread,
                tone: viewData.hasWideFeeSpread
                    ? MiningStatusTone.warning
                    : MiningStatusTone.live,
              ),
              _SignalChip(
                label: context.l10n.miningFeesWindow(
                  MiningFormatters.feeRate(viewData.nextBlockMinimumFee),
                ),
                tone: MiningStatusTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                  : constraints.maxWidth < 420
                      ? double.infinity
                      : (constraints.maxWidth - AppSpacing.sm) / 2;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _FeeTile(
                    width: cardWidth,
                    label: context.l10n.miningFeesPriority,
                    value: feeMarket.priorityFee,
                    helper: 'Entrada em 1 bloco',
                    accent: miningRed,
                  ),
                  _FeeTile(
                    width: cardWidth,
                    label: context.l10n.miningFeesExpress,
                    value: feeMarket.expressFee,
                    helper: 'Janela 30 min',
                    accent: miningAmber,
                  ),
                  _FeeTile(
                    width: cardWidth,
                    label: context.l10n.miningFeesStandard,
                    value: feeMarket.standardFee,
                    helper: 'Ritmo normal',
                    accent: miningBlue,
                  ),
                  _FeeTile(
                    width: cardWidth,
                    label: context.l10n.miningFeesEconomy,
                    value: feeMarket.economyFee,
                    helper: 'Sem urgencia',
                    accent: miningTeal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: miningInsetDecoration(
              accent: miningBlue,
              emphasized: true,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faixa de inclusão imediata',
                    style: AppTypography.caption.copyWith(
                      color: miningMuted,
                      fontFamily: 'HubotSansCondensed',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FeeBand(
                    minFee: viewData.nextBlockMinimumFee,
                    medianFee: viewData.nextBlockMedianFee,
                    maxFee: viewData.nextBlockMaximumFee,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    viewData.congestionSupportLabel,
                    style: AppTypography.bodySmall.copyWith(color: miningMuted),
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

class _FeeTile extends StatelessWidget {
  final double width;
  final String label;
  final int value;
  final String helper;
  final Color accent;

  const _FeeTile({
    required this.width,
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: miningInsetDecoration(accent: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 2,
            color: accent.withValues(alpha: 0.72),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: accent,
              fontFamily: 'HubotSansCondensed',
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value sat/vB',
            style: miningMonoStyle(
              AppTypography.h3,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper,
            style: AppTypography.bodySmall.copyWith(color: miningMuted),
          ),
        ],
      ),
    );
  }
}

class _FeeBand extends StatelessWidget {
  final double minFee;
  final double medianFee;
  final double maxFee;

  const _FeeBand({
    required this.minFee,
    required this.medianFee,
    required this.maxFee,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = maxFee <= 0 ? 1.0 : maxFee;
    final medianStop = (medianFee / safeMax).clamp(0.1, 0.95);
    final minStop = (minFee / safeMax).clamp(0.0, medianStop - 0.05);

    return Column(
      children: [
        SizedBox(
          height: 12,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: miningInnerBorderRadius,
                    border: Border.all(color: miningBorder),
                    gradient: const LinearGradient(
                      colors: [miningRed, miningAmber, miningBlue, miningTeal],
                      stops: [0.0, 0.34, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-1 + (medianStop * 2), 0),
                child: Container(width: 3, height: 18, color: Colors.white),
              ),
              Align(
                alignment: Alignment(-1 + (minStop * 2), 0),
                child: Container(
                  width: 2,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _BandLabel(
                label: context.l10n.miningFeesMinimum,
                value: MiningFormatters.feeRate(minFee),
              ),
            ),
            Expanded(
              child: _BandLabel(
                label: context.l10n.miningFeesMedian,
                value: MiningFormatters.feeRate(medianFee),
                alignEnd: true,
              ),
            ),
            Expanded(
              child: _BandLabel(
                label: context.l10n.miningFeesMaximum,
                value: MiningFormatters.feeRate(maxFee),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BandLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _BandLabel({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: miningMuted,
            fontFamily: 'HubotSansCondensed',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: miningMonoStyle(
            AppTypography.bodySmall,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final MiningStatusTone tone;

  const _SignalChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return MiningStatusBadge(label: label.toUpperCase(), tone: tone);
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
