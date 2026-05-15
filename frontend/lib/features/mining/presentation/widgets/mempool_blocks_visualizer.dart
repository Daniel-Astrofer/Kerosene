import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';
import 'package:teste/l10n/l10n_extension.dart';

class MempoolBlocksVisualizer extends StatelessWidget {
  final List<MiningProjectedBlockSnapshot> projectedBlocks;
  final List<MiningBlockSnapshot> confirmedBlocks;
  final Set<int> highlightedHeights;

  const MempoolBlocksVisualizer({
    super.key,
    required this.projectedBlocks,
    required this.confirmedBlocks,
    required this.highlightedHeights,
  });

  @override
  Widget build(BuildContext context) {
    final visibleProjected = projectedBlocks.take(4).toList(growable: false);
    final visibleConfirmed = confirmedBlocks.take(6).toList(growable: false);

    return MiningPanel(
      accent: miningBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: context.l10n.miningBlocksTitle,
            subtitle: context.l10n.miningBlocksSubtitle,
            trailing: MiningStatusBadge(
              label: context.l10n.miningBlocksQueued(
                visibleProjected.length,
              ),
              tone: MiningStatusTone.info,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _LegendChip(
                label: context.l10n.miningBlocksQueue,
                color: miningAmber,
              ),
              _LegendChip(
                label: context.l10n.miningBlocksConfirmed,
                color: miningTeal,
              ),
              _LegendChip(
                label: context.l10n.miningBlocksNew,
                color: miningBlue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 282,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                ...visibleProjected.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: _ProjectedBlockCard(
                      block: entry.value,
                      blockNumber: entry.key + 1,
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _TimelineDivider(
                    confirmedLabel: visibleConfirmed.isEmpty
                        ? context.l10n.miningBlocksNoBlocks
                        : '#${visibleConfirmed.first.height}',
                  ),
                ),
                ...visibleConfirmed.map((block) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: _ConfirmedBlockCard(
                      block: block,
                      highlight: highlightedHeights.contains(block.height),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectedBlockCard extends StatelessWidget {
  final MiningProjectedBlockSnapshot block;
  final int blockNumber;

  const _ProjectedBlockCard({required this.block, required this.blockNumber});

  @override
  Widget build(BuildContext context) {
    final fillColor = _feeAccent(block.medianFeeRate);
    final fillRatio = block.utilization.clamp(0.0, 1.0);

    return Container(
      width: 156,
      decoration: miningInsetDecoration(accent: fillColor, emphasized: true),
      child: ClipRRect(
        borderRadius: miningInnerBorderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fillRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          fillColor.withValues(alpha: 0.08),
                          fillColor.withValues(alpha: 0.26),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 2,
                    color: fillColor.withValues(alpha: 0.78),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MiningStatusBadge(
                    label: context.l10n.miningBlocksNext(blockNumber),
                    tone: MiningStatusTone.warning,
                  ),
                  const Spacer(),
                  Text(
                    MiningFormatters.feeRate(block.medianFeeRate),
                    style: miningMonoStyle(
                      AppTypography.h2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${block.txCount} tx • ${MiningFormatters.blockFill(fillRatio)}',
                    style: AppTypography.bodySmall.copyWith(color: miningMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MetricLine(
                    label: context.l10n.miningBlocksRange,
                    value:
                        '${MiningFormatters.feeRate(block.minFeeRate)} - ${MiningFormatters.feeRate(block.maxFeeRate)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MetricLine(
                    label: context.l10n.miningBlocksFees,
                    value: MiningFormatters.btcFromSats(block.totalFeesSat),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmedBlockCard extends StatelessWidget {
  final MiningBlockSnapshot block;
  final bool highlight;

  const _ConfirmedBlockCard({required this.block, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? miningBlue : miningTeal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      width: 208,
      decoration: miningInsetDecoration(
        accent: accent,
        emphasized: highlight,
        color: highlight ? miningSurfaceElevated : miningSurfaceRaised,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 2,
              color: accent.withValues(alpha: highlight ? 0.82 : 0.54),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                MiningStatusBadge(
                  label: highlight
                      ? context.l10n.miningBlocksNewHeight(block.height)
                      : '#${block.height}',
                  tone:
                      highlight ? MiningStatusTone.info : MiningStatusTone.live,
                  pulse: highlight,
                ),
                const Spacer(),
                Text(
                  timeago.format(block.timestamp, locale: 'en_short'),
                  style: miningMonoStyle(
                    AppTypography.caption,
                    color: miningMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              block.poolName ?? context.l10n.miningBlocksBitcoinNetwork,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.miningBlocksTransactions(block.txCount),
              style: AppTypography.bodySmall.copyWith(color: miningMuted),
            ),
            const Spacer(),
            _MetricLine(
              label: context.l10n.miningBlocksHash,
              value: _shortHash(block.id),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: context.l10n.miningBlocksWeight,
              value: MiningFormatters.blockFill(block.weightRatio),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: context.l10n.miningBlocksTimestamp,
              value: MiningFormatters.timeOfDay(block.timestamp),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: context.l10n.miningBlocksSize,
              value: MiningFormatters.megabytes(block.sizeMb),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: context.l10n.miningBlocksFee,
              value: block.medianFeeRate == null
                  ? context.l10n.miningBlocksUnavailable
                  : MiningFormatters.feeRate(block.medianFeeRate!),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  final String confirmedLabel;

  const _TimelineDivider({required this.confirmedLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    miningAmber.withValues(alpha: 0.65),
                    miningBlue.withValues(alpha: 0.65),
                    miningTeal.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'REDE',
            style: AppTypography.caption.copyWith(
              color: miningMuted,
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            confirmedLabel,
            style: miningMonoStyle(
              AppTypography.bodySmall,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Container(
              width: 2,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: miningSurface,
        borderRadius: miningInnerBorderRadius,
        border: Border.all(color: miningAccentBorder(color, emphasis: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: miningInnerBorderRadius,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetricLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: miningMuted,
              fontFamily: 'IBM Plex Sans',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: miningMonoStyle(
              AppTypography.bodySmall,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Color _feeAccent(double feeRate) {
  final normalized = (feeRate / 90).clamp(0.0, 1.0);
  return Color.lerp(miningRed, miningTeal, normalized) ?? miningBlue;
}

String _shortHash(String hash) {
  if (hash.length <= 16) {
    return hash;
  }
  return '${hash.substring(0, 8)}…${hash.substring(hash.length - 6)}';
}
