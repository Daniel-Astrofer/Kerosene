import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/domain/entities/mining_dashboard_snapshot.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';

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
            title: 'Blocos em formação',
            subtitle:
                'Fila projetada da mempool ao lado das confirmações mais recentes.',
            trailing: MiningStatusBadge(
              label: '${visibleProjected.length} NA FILA',
              tone: MiningStatusTone.info,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _LegendChip(label: 'Projeção', color: miningAmber),
              _LegendChip(label: 'Confirmado', color: miningTeal),
              _LegendChip(label: 'Novo bloco', color: miningBlue),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: _TimelineDivider(
                    confirmedLabel: visibleConfirmed.isEmpty
                        ? 'sem blocos'
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

  const _ProjectedBlockCard({
    required this.block,
    required this.blockNumber,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = _feeAccent(block.medianFeeRate);
    final fillRatio = block.utilization.clamp(0.0, 1.0);

    return Container(
      width: 164,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: miningBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF15110B),
            Color(0xFF110F0C),
            Color(0xFF0A0D12),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
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
                          fillColor.withValues(alpha: 0.14),
                          fillColor.withValues(alpha: 0.36),
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
                  MiningStatusBadge(
                    label: 'NEXT $blockNumber',
                    tone: MiningStatusTone.warning,
                  ),
                  const Spacer(),
                  Text(
                    MiningFormatters.feeRate(block.medianFeeRate),
                    style:
                        AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${block.txCount} tx • ${MiningFormatters.blockFill(fillRatio)}',
                    style: AppTypography.bodySmall.copyWith(color: miningMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MetricLine(
                    label: 'Faixa',
                    value:
                        '${MiningFormatters.feeRate(block.minFeeRate)} - ${MiningFormatters.feeRate(block.maxFeeRate)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MetricLine(
                    label: 'Taxas',
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

  const _ConfirmedBlockCard({
    required this.block,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? miningBlue : miningTeal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      width: 208,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: highlight ? 0.52 : 0.20),
          width: highlight ? 1.3 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight ? const Color(0xFF12213A) : miningSurfaceRaised,
            highlight ? const Color(0xFF0B1627) : miningSurface,
            miningInk,
          ],
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: miningBlue.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MiningStatusBadge(
                  label:
                      highlight ? 'NOVO #${block.height}' : '#${block.height}',
                  tone:
                      highlight ? MiningStatusTone.info : MiningStatusTone.live,
                  pulse: highlight,
                ),
                const Spacer(),
                Text(
                  timeago.format(block.timestamp, locale: 'en_short'),
                  style: AppTypography.caption.copyWith(color: miningMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              block.poolName ?? 'Rede Bitcoin',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${block.txCount} transações',
              style: AppTypography.bodySmall.copyWith(color: miningMuted),
            ),
            const Spacer(),
            _MetricLine(
              label: 'Hash',
              value: _shortHash(block.id),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: 'Peso',
              value: MiningFormatters.blockFill(block.weightRatio),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: 'Timestamp',
              value: MiningFormatters.timeOfDay(block.timestamp),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: 'Tamanho',
              value: MiningFormatters.megabytes(block.sizeMb),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricLine(
              label: 'Taxa',
              value: block.medianFeeRate == null
                  ? 'indisponivel'
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
                    miningAmber.withValues(alpha: 0.70),
                    miningBlue.withValues(alpha: 0.70),
                    miningTeal.withValues(alpha: 0.70),
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
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            confirmedLabel,
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
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

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
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

  const _MetricLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: miningMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Color _feeAccent(double feeRate) {
  if (feeRate >= 80) {
    return miningRed;
  }
  if (feeRate >= 40) {
    return miningAmber;
  }
  if (feeRate >= 15) {
    return miningBlue;
  }
  return miningTeal;
}

String _shortHash(String hash) {
  if (hash.length <= 16) {
    return hash;
  }
  return '${hash.substring(0, 8)}…${hash.substring(hash.length - 6)}';
}
