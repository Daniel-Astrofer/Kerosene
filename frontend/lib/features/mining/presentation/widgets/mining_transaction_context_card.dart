import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/mining/data/models/mempool_transaction_models.dart';
import 'package:teste/features/mining/presentation/mining_explorer.dart';
import 'package:teste/features/mining/presentation/mining_formatters.dart';
import 'package:teste/features/mining/presentation/providers/mining_providers.dart';
import 'package:teste/features/mining/presentation/widgets/mining_panel.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/core/l10n/l10n_extension.dart';

class MiningTransactionContextCard extends ConsumerWidget {
  final Transaction transaction;

  const MiningTransactionContextCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = MiningExplorerDescriptor.fromTransaction(transaction);

    if (descriptor.rail == MiningExplorerRail.internal) {
      return _ContextShell(
        title: context.tr.miningTxInternalTitle,
        subtitle: context.tr.miningTxInternalSubtitle,
        accent: miningTeal,
        children: [
          _ContextFact(
            label: context.tr.miningTxReference,
            value: descriptor.reference,
          ),
          _ContextFact(
            label: context.tr.status,
            value: transaction.status.name.toUpperCase(),
          ),
          _ContextFact(
            label: context.tr.miningTxConfirmations,
            value: '${transaction.confirmations}',
          ),
        ],
      );
    }

    if (descriptor.rail == MiningExplorerRail.lightning ||
        !descriptor.canLookupOnchain) {
      return _ContextShell(
        title: context.tr.miningTxLightningTitle,
        subtitle: context.tr.miningTxLightningSubtitle,
        accent: miningAmber,
        children: [
          _ContextFact(
            label: context.tr.miningTxChannel,
            value: descriptor.reference,
          ),
          _ContextFact(
            label: context.tr.status,
            value: transaction.status.name.toUpperCase(),
          ),
          _ContextFact(
            label: context.tr.miningTxRecord,
            value: MiningFormatters.shortDateTime(transaction.timestamp),
          ),
        ],
      );
    }

    final summaryAsync = ref.watch(
      mempoolTransactionSummaryProvider(descriptor.txid!),
    );

    return summaryAsync.when(
      data: (summary) {
        if (summary == null) {
          return _fallbackCard(
            context: context,
            title: context.tr.miningTxNoPublicSummaryTitle,
            description: context.tr.miningTxNoPublicSummaryMessage,
          );
        }
        return _OnchainContextCard(summary: summary);
      },
      loading: () => const _ContextLoadingCard(),
      error: (error, _) => _fallbackCard(
        context: context,
        title: context.tr.miningTxLookupUnavailableTitle,
        description: error.toString(),
      ),
    );
  }

  Widget _fallbackCard({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return _ContextShell(
      title: title,
      subtitle: description,
      accent: miningBlue,
      children: [
        _ContextFact(
          label: context.tr.miningTxLocalStatus,
          value: transaction.status.name.toUpperCase(),
        ),
        _ContextFact(
          label: context.tr.miningTxConfirmations,
          value: '${transaction.confirmations}',
        ),
        _ContextFact(
          label: context.tr.miningTxRecord,
          value: MiningFormatters.shortDateTime(transaction.timestamp),
        ),
      ],
    );
  }
}

class _OnchainContextCard extends StatelessWidget {
  final MempoolTransactionSummary summary;

  const _OnchainContextCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final statusTone =
        summary.confirmed ? MiningStatusTone.live : MiningStatusTone.warning;

    return _ContextShell(
      title: context.tr.miningTxOnchainTitle,
      subtitle: context.tr.miningTxOnchainSubtitle,
      accent: miningBlue,
      trailing: MiningStatusBadge(
        label: summary.confirmed
            ? context.tr.miningTxConfirmed
            : context.tr.miningTxPending,
        tone: statusTone,
        pulse: !summary.confirmed,
      ),
      children: [
        _ContextFact(
          label: context.tr.miningTxTxid,
          value: shortHash(summary.txid, leading: 12, trailing: 10),
        ),
        _ContextFact(
          label: context.tr.miningTxFeeRate,
          value: MiningFormatters.feeRate(summary.effectiveFeeRate),
        ),
        _ContextFact(
          label: context.tr.miningTxBlock,
          value: summary.blockHeight == null
              ? context.tr.miningTxAwaiting
              : '#${summary.blockHeight}',
        ),
        _ContextFact(
          label: context.tr.miningTxPosition,
          value: summary.positionInBlock == null || summary.blockTxCount == null
              ? context.tr.miningTxNotAvailable
              : '${summary.positionInBlock}/${summary.blockTxCount}',
        ),
      ],
    );
  }
}

class _ContextLoadingCard extends StatelessWidget {
  const _ContextLoadingCard();

  @override
  Widget build(BuildContext context) {
    return MiningPanel(
      accent: miningBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: context.tr.miningTxLoadingTitle,
            subtitle: context.tr.miningTxLoadingSubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          const MiningSkeletonBlock(height: 18),
          const SizedBox(height: AppSpacing.sm),
          const MiningSkeletonBlock(height: 18),
          const SizedBox(height: AppSpacing.sm),
          const MiningSkeletonBlock(height: 18),
        ],
      ),
    );
  }
}

class _ContextShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final Widget? trailing;
  final List<Widget> children;

  const _ContextShell({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return MiningPanel(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiningSectionHeading(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                  : constraints.maxWidth < 420
                      ? double.infinity
                      : (constraints.maxWidth - AppSpacing.sm) / 2;

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: children
                    .map(
                      (child) => SizedBox(
                        width: constraints.maxWidth < 420
                            ? double.infinity
                            : width,
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContextFact extends StatelessWidget {
  final String label;
  final String value;

  const _ContextFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: miningInsetDecoration(accent: miningBlue),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: miningMuted,
                fontFamily: 'HubotSansCondensed',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: miningMonoStyle(
                AppTypography.bodyMedium,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
