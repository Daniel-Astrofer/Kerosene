// ignore_for_file: use_key_in_widget_constructors, unused_import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/bitcoin_account_models.dart';
import 'package:kerosene/features/financial_accounts/presentation/bitcoin_accounts_presentation_support.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'bitcoin_accounts_provider.dart';
import 'bitcoin_widgets/bottom_sheets.dart';
import 'bitcoin_accounts_internal_sections.dart';
import 'dart:convert';

import 'bitcoin_accounts_screen.dart';

class ColdWalletSection extends StatelessWidget {
  final List<BitcoinAccount> accounts;

  const ColdWalletSection({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsColdWalletSection,
                style: AppTypography.newsreader(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          MutedPanel(text: context.tr.bitcoinAccountsNoColdWallet)
        else ...[
          for (final account in accounts) ColdWalletTile(account: account),
        ],
      ],
    );
  }
}

class ColdWalletTile extends StatelessWidget {
  final BitcoinAccount account;

  const ColdWalletTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? context.tr.bitcoinAccountsColdWalletBadge
        : account.walletTypeDescription.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(KeroseneIcons.coldWallet, color: colors.text, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(text: typeDescription),
                        Pill(text: context.tr.bitcoinAccountsReviewBalance),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.bitcoinAccountsObservedBalance,
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatSats(account.observedBalanceSats),
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.bitcoinAccountsColdWalletNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                account.xpubFingerprint ?? account.coldWalletId ?? '',
                style: AppTypography.technicalMono(
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
            ],
          ),
          ColdWalletAdvancedPanel(account: account),
        ],
      ),
    );
  }
}

class ColdWalletAdvancedPanel extends ConsumerWidget {
  final BitcoinAccount account;

  const ColdWalletAdvancedPanel({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: MutedPanel(
        text: context.tr.bitcoinAdvancedPsbtsUnavailableMessage,
      ),
    );
  }
}

class AdvancedSubsection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const AdvancedSubsection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return DecoratedBox(
      decoration: colors.panelDecoration(
        color: colors.surface,
        showShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.text, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class UtxoPreviewList extends StatelessWidget {
  final List<ColdWalletUtxoView> utxos;

  const UtxoPreviewList({required this.utxos});

  @override
  Widget build(BuildContext context) {
    if (utxos.isEmpty) {
      return MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoUtxos,
      );
    }

    final visible = utxos.take(4).toList(growable: false);
    final spendable = utxos.where((utxo) => utxo.isSpendable).fold<int>(
          0,
          (total, utxo) => total + utxo.amountSats,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiniMetricRow(
          label: context.tr.bitcoinAdvancedSpendableForPsbt,
          value: formatSats(spendable),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < visible.length; index++)
          UtxoRow(
            utxo: visible[index],
            showDivider: index != visible.length - 1,
          ),
        if (utxos.length > visible.length)
          MiniHint(
            text: context.tr.bitcoinAdvancedHiddenUtxos(
              utxos.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class UtxoRow extends StatelessWidget {
  final ColdWalletUtxoView utxo;
  final bool showDivider;

  const UtxoRow({
    required this.utxo,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final outpointLabel = '${utxo.txidRef}:${utxo.vout}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              outpointLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.mutedText,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatSats(utxo.amountSats),
            style: AppTypography.inter(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          Pill(text: utxoStatusLabel(context, utxo.status)),
        ],
      ),
    );
  }
}

class PsbtPreviewList extends StatelessWidget {
  final List<PsbtWorkflowView> workflows;
  final ValueChanged<PsbtWorkflowView> onSubmitSigned;
  final ValueChanged<PsbtWorkflowView> onCopyUnsigned;

  const PsbtPreviewList({
    required this.workflows,
    required this.onSubmitSigned,
    required this.onCopyUnsigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workflows.isEmpty) {
      return MiniEmptyState(
        text: context.tr.bitcoinAdvancedNoPsbts,
      );
    }

    final visible = workflows.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visible.length; index++)
          PsbtWorkflowRow(
            workflow: visible[index],
            showDivider: index != visible.length - 1,
            onCopyUnsigned: () => onCopyUnsigned(visible[index]),
            onSubmitSigned: visible[index].awaitsSignature
                ? () => onSubmitSigned(visible[index])
                : null,
          ),
        if (workflows.length > visible.length)
          MiniHint(
            text: context.tr.bitcoinAdvancedHiddenPsbts(
              workflows.length - visible.length,
            ),
          ),
      ],
    );
  }
}

class PsbtWorkflowRow extends StatelessWidget {
  final PsbtWorkflowView workflow;
  final bool showDivider;
  final VoidCallback onCopyUnsigned;
  final VoidCallback? onSubmitSigned;

  const PsbtWorkflowRow({
    required this.workflow,
    required this.showDivider,
    required this.onCopyUnsigned,
    this.onSubmitSigned,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shortText(workflow.destinationAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(text: psbtStatusLabel(context, workflow.status)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(text: formatSats(workflow.amountSats)),
              Pill(
                text:
                    '${context.tr.bitcoinAdvancedFeePrefix} ${formatSats(workflow.estimatedFeeSats)}',
              ),
              if ((workflow.broadcastTxidRef ?? '').isNotEmpty)
                Pill(text: workflow.broadcastTxidRef!),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: colors.outlinedButtonStyle(minHeight: 38),
                onPressed: onCopyUnsigned,
                icon: const Icon(KeroseneIcons.copy, size: 15),
                label: Text(context.tr.bitcoinAdvancedCopyUnsignedAction),
              ),
              if (onSubmitSigned != null)
                OutlinedButton.icon(
                  style: colors.outlinedButtonStyle(minHeight: 38),
                  onPressed: onSubmitSigned,
                  icon: const Icon(KeroseneIcons.send, size: 15),
                  label: Text(context.tr.bitcoinAdvancedSubmitSignatureAction),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TaxEventsSection extends ConsumerWidget {
  const TaxEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(kfeTaxEventsProvider);
    return TransactionsPanel(
      title: context.tr.bitcoinTaxReportsTitle,
      children: eventsAsync.when(
        loading: () => const [
          DarkSkeletonRow(),
          DarkSkeletonRow(),
        ],
        error: (_, __) => [
          DarkActionMessage(
            icon: KeroseneIcons.error,
            title: context.tr.taxEventsUnavailableTitle,
            message: context.tr.taxEventsUnavailableMessage,
            actionLabel: context.tr.retry,
            onAction: () => ref.invalidate(kfeTaxEventsProvider),
          ),
        ],
        data: (events) {
          if (events.isEmpty) {
            return [
              DarkActionMessage(
                icon: KeroseneIcons.history,
                title: context.tr.bitcoinTaxNoEventsTitle,
                message: context.tr.bitcoinTaxNoEventsMessage,
              ),
              TaxExportActions(),
            ];
          }

          final visible = events.take(4).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              TaxEventRow(
                event: visible[index],
                showDivider: index != visible.length - 1,
              ),
            if (events.length > visible.length)
              DarkListMessage(
                text: context.tr.bitcoinTaxHiddenEvents(
                  events.length - visible.length,
                ),
              ),
            TaxExportActions(),
          ];
        },
      ),
    );
  }
}

class TaxEventRow extends ConsumerWidget {
  final TaxEventView event;
  final bool showDivider;

  const TaxEventRow({
    required this.event,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BitcoinAccountsColors.of(context);
    final transferLabel =
        '${formatSats(event.quantitySats)} | ${event.sourceRef.isEmpty ? event.asset : event.sourceRef}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.rowDivider,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(KeroseneIcons.history, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taxEventTypeLabel(context, event.eventType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transferLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.technicalMono(
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: context.tr.bitcoinTaxClassifyTooltip,
            color: colors.surfaceRaised,
            icon: Icon(
              KeroseneIcons.chevronDown,
              color: colors.text,
              size: 18,
            ),
            onSelected: (classification) async {
              try {
                final service = ref.read(bitcoinAccountsServiceProvider);
                await service.classifyTaxEvent(
                  eventId: event.id,
                  classification: classification,
                );
                ref.invalidate(kfeTaxEventsProvider);
                if (!context.mounted) return;
                AppNotice.showSuccess(
                  context,
                  title: context.tr.bitcoinTaxClassificationUpdatedTitle,
                  message: taxClassificationLabel(context, classification),
                );
              } catch (_) {
                if (!context.mounted) return;
                AppNotice.showError(
                  context,
                  title: context.tr.bitcoinTaxClassificationNotSavedTitle,
                  message: context.tr.bitcoinTaxRetryLaterMessage,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'SELF_TRANSFER',
                child: Text(context.tr.bitcoinTaxClassSelfTransfer),
              ),
              PopupMenuItem(
                value: 'THIRD_PARTY_DEPOSIT',
                child: Text(context.tr.bitcoinTaxClassThirdPartyDeposit),
              ),
              PopupMenuItem(
                value: 'SPEND',
                child: Text(context.tr.bitcoinTaxClassSpend),
              ),
              PopupMenuItem(
                value: 'FEE',
                child: Text(context.tr.bitcoinTaxClassFee),
              ),
              PopupMenuItem(
                value: 'UNKNOWN',
                child: Text(context.tr.bitcoinTaxClassUnknown),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TaxExportActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => exportTaxEvents(context, ref, 'json'),
            icon: const Icon(KeroseneIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportJsonAction),
          ),
          OutlinedButton.icon(
            onPressed: () => exportTaxEvents(context, ref, 'csv'),
            icon: const Icon(KeroseneIcons.download, size: 15),
            label: Text(context.tr.bitcoinTaxExportCsvAction),
          ),
        ],
      ),
    );
  }

  Future<void> exportTaxEvents(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final exported = await service.exportTaxEvents(format: format);
      final content = exported.content ??
          const JsonEncoder.withIndent('  ').convert(
            exported.toJson(),
          );
      await Clipboard.setData(ClipboardData(text: content));
      if (!context.mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinTaxReportCopiedTitle,
        message: exported.filename,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinTaxExportUnavailableTitle,
        message: context.tr.bitcoinTaxExportUnavailableMessage,
      );
    }
  }
}

class MiniLoadingRows extends StatelessWidget {
  const MiniLoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        DarkSkeletonRow(),
        DarkSkeletonRow(),
      ],
    );
  }
}

class MiniActionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const MiniActionState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DarkActionMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: context.tr.retry,
      onAction: onRetry,
    );
  }
}

class MiniEmptyState extends StatelessWidget {
  final String text;

  const MiniEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return MiniHint(text: text);
  }
}

class MiniHint extends StatelessWidget {
  final String text;

  const MiniHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: AppTypography.inter(
          color: colors.mutedText,
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class MiniMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const MiniMetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.inter(
              color: colors.mutedText,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.inter(
            color: colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class InternalAccountManagementView extends StatefulWidget {
  final BitcoinAccount account;
  final VoidCallback onReceive;

  const InternalAccountManagementView({
    required this.account,
    required this.onReceive,
  });

  @override
  State<InternalAccountManagementView> createState() =>
      InternalAccountManagementViewState();
}

class InternalAccountManagementViewState
    extends State<InternalAccountManagementView> {
  String? expandedKey = 'balance';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InternalWalletCard(account: widget.account, onTap: () {}),
        const SizedBox(height: 18),
        ManagementItem(
          title: 'Saldo disponível',
          expanded: expandedKey == 'balance',
          onTap: () => toggle('balance'),
          rows: [
            ('Disponível', formatSats(widget.account.balanceAvailableSats)),
          ],
        ),
        ManagementItem(
          title: 'Endereço de recebimento',
          expanded: expandedKey == 'receive',
          onTap: () {
            toggle('receive');
            widget.onReceive();
          },
          rows: const [
            ('Ação', 'Gerar ou visualizar endereço'),
          ],
        ),
        ManagementItem(
          title: 'Data de validade',
          expanded: expandedKey == 'expiry',
          onTap: () => toggle('expiry'),
          rows: [
            ('Validade', cardExpiryLabel(widget.account)),
          ],
        ),
      ],
    );
  }

  void toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => expandedKey = expandedKey == key ? null : key);
  }
}

class ManagementItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<(String, String)> rows;

  const ManagementItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return AnimatedContainer(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.inter(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: KeroseneMotion.medium,
                      turns: expanded ? 0.5 : 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          KeroseneIcons.chevronDown,
                          color: colors.text,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                children: [
                  Divider(color: colors.rowDivider),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: AppTypography.inter(
                                color: colors.mutedText,
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Text(
                            row.$2,
                            style: AppTypography.inter(
                              color: colors.mutedText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: KeroseneMotion.medium,
            sizeCurve: KeroseneMotion.standard,
          ),
        ],
      ),
    );
  }
}
