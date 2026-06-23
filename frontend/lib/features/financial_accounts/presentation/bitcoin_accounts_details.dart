// ignore_for_file: use_key_in_widget_constructors, unused_import
import 'package:flutter/material.dart';
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
import 'bitcoin_accounts_advanced_sections.dart';
import 'bitcoin_screens/internal_account_creation_screen.dart';

import 'bitcoin_accounts_screen.dart';

class _BitcoinAccountsDetailsCopy {
  const _BitcoinAccountsDetailsCopy._();

  static const renameWallet = 'Trocar nome';
  static const filter = 'Filtrar';
}

class ReceiveMaterialDetails extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final ReceivingRequestView? receiveAddressOverride;
  final VoidCallback? onRotate;
  final bool rotating;

  const ReceiveMaterialDetails({
    required this.account,
    required this.requestsAsync,
    required this.receiveAddressOverride,
    this.onRotate,
    this.rotating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (account.isWatchOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccountDetailRows(
            rows: [
              AccountDetail(
                'Fingerprint',
                bitcoinAccountDisplayValue(account.xpubFingerprint),
                copyable: (account.xpubFingerprint ?? '').trim().isNotEmpty,
              ),
              AccountDetail(
                'Cold wallet',
                coldWalletIdForAccount(account),
                copyable: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AccountOptionNote(
            text: 'Carteiras watch-only não emitem endereço pelo app.',
          ),
        ],
      );
    }

    return requestsAsync.when(
      loading: () => const InlineLoadingState(),
      error: (_, __) => MiniEmptyState(
        text: context.tr.bitcoinReceiveRequestsLoadErrorMessage,
      ),
      data: (requests) {
        final request = receiveAddressOverride ??
            (requests.isEmpty ? null : requests.first);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountDetailRows(
              rows: [
                AccountDetail(
                  'Endereço',
                  bitcoinAccountDisplayValue(request?.address),
                  copyable: (request?.address ?? '').trim().isNotEmpty,
                ),
                AccountDetail(
                  'BIP21',
                  bitcoinAccountDisplayValue(request?.bip21),
                  copyable: (request?.bip21 ?? '').trim().isNotEmpty,
                ),
                if (request?.amountSats != null)
                  AccountDetail('Valor', formatSats(request!.amountSats!)),
                if (request != null)
                  AccountDetail(
                    'Expiração',
                    request.expiry.isEmpty
                        ? context.tr.bitcoinReceiveRequestsNoExpiry
                        : request.expiry,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AccountOptionActionButton(
              label: 'Rotacionar endereço',
              icon: KeroseneIcons.refresh,
              busy: rotating,
              onPressed: onRotate,
            ),
          ],
        );
      },
    );
  }
}

class AccountOptionActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool destructive;

  const AccountOptionActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    return OutlinedButton.icon(
      style: colors.outlinedButtonStyle(
        minHeight: 42,
        foregroundColor: destructive
            ? KeroseneBrandTokens.error
            : KeroseneBrandTokens.textPrimary,
      ),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class AccountOptionNote extends StatelessWidget {
  final String text;

  const AccountOptionNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.inter(
        color: KeroseneBrandTokens.textMuted,
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

Future<String?> askWalletName(
  BuildContext context,
  BitcoinAccount account,
) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return WalletNameDialog(initialName: account.label.trim());
    },
  );
}

class WalletNameDialog extends StatefulWidget {
  final String initialName;

  const WalletNameDialog({required this.initialName});

  @override
  State<WalletNameDialog> createState() => WalletNameDialogState();
}

class WalletNameDialogState extends State<WalletNameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(_BitcoinAccountsDetailsCopy.renameWallet),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 96,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nome da carteira'),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr.cancel),
        ),
        FilledButton(
          onPressed: submit,
          child: Text(context.tr.save),
        ),
      ],
    );
  }
}

Future<bool> confirmWalletArchive(
  BuildContext context,
  BitcoinAccount account,
) async {
  final title = account.isWatchOnly
      ? 'Arquivar acompanhamento'
      : account.isCustodialOnchain
          ? 'Bloquear carteira'
          : 'Bloquear cartão';
  final message = account.isWatchOnly
      ? 'Esta carteira deixará de aparecer como acompanhamento ativo.'
      : 'Esta carteira deixará de aparecer como ativa para movimentação.';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr.confirm),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

class AccountExpansionItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const AccountExpansionItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return AnimatedContainer(
      duration: KeroseneMotion.medium,
      curve: KeroseneMotion.standard,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      accountOptionIcon(title),
                      color: colors.text,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: colors.text.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: KeroseneMotion.medium,
                      turns: expanded ? 0.5 : 0,
                      child: Icon(
                        KeroseneIcons.chevronDown,
                        color: colors.mutedText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: KeroseneMotion.medium,
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

IconData accountOptionIcon(String title) {
  return switch (title) {
    'STATUS DA CARTEIRA' => KeroseneIcons.security,
    'ENDEREÇO DE RECEBIMENTO' => KeroseneIcons.download,
    'NOME DA CARTEIRA' => KeroseneIcons.user,
    'MATERIAL PÚBLICO' => KeroseneIcons.settings,
    'UTXOS MONITORADOS' => KeroseneIcons.database,
    'PSBT WORKFLOWS' => KeroseneIcons.document,
    _ => KeroseneIcons.settings,
  };
}

class AccountDetail {
  final String label;
  final String value;
  final bool copyable;

  const AccountDetail(
    this.label,
    this.value, {
    this.copyable = false,
  });
}

class AccountDetailRows extends StatelessWidget {
  final List<AccountDetail> rows;

  const AccountDetailRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < rows.length; index++)
          AccountDetailRow(
            row: rows[index],
            showDivider: index != rows.length - 1,
          ),
      ],
    );
  }
}

class AccountDetailRow extends StatelessWidget {
  final AccountDetail row;
  final bool showDivider;

  const AccountDetailRow({
    required this.row,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: KeroseneBrandTokens.borderSubtle,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: AppTypography.inter(
                color: KeroseneBrandTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              maxLines: row.copyable ? 5 : 2,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: AppTypography.technicalMono(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: KeroseneBrandTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          if (row.copyable) ...[
            const SizedBox(width: 4),
            InlineCopyButton(
              value: row.value,
              semanticLabel: 'Copiar ${row.label}',
            ),
          ],
        ],
      ),
    );
  }
}

class InlineLoadingState extends StatelessWidget {
  const InlineLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class FocusedAccountHistory extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const FocusedAccountHistory({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final requests =
        requestsAsync.asData?.value ?? const <ReceivingRequestView>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.primaryNavHistory,
                style: AppTypography.newsreader(
                  color: colors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              KeroseneIcons.moveHorizontal,
              color: colors.mutedText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _BitcoinAccountsDetailsCopy.filter.toUpperCase(),
              style: AppTypography.inter(
                color: colors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        transactionsAsync.when(
          loading: () => const CompactLoadingPanel(),
          error: (_, __) => BareHistoryMessage(
            text: context.tr.bitcoinAccountsErrorMessage,
          ),
          data: (transactions) {
            final rows = transactionsForAccount(
              account: account,
              transactions: transactions,
              requests: requests,
            ).take(8).toList(growable: false);

            if (rows.isEmpty) {
              return const BareHistoryMessage(
                text: 'Sem transações neste cartão.',
              );
            }

            return Column(
              children: [
                for (var index = 0; index < rows.length; index++)
                  FocusedHistoryRow(
                    transaction: rows[index],
                    showDivider: index != rows.length - 1,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class BareHistoryMessage extends StatelessWidget {
  final String text;

  const BareHistoryMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text,
        style: AppTypography.inter(
          color: KeroseneBrandTokens.textMuted,
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class FocusedHistoryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const FocusedHistoryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : transactionTitle(transaction);
    final detail = bitcoinAccountHistoryDetail(transaction);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.text.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.isInternal
                      ? KeroseneIcons.wallet
                      : KeroseneIcons.history,
                  color: colors.text,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.mutedText,
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                bitcoinAccountHistoryTimestampLabel(transaction.timestamp),
                textAlign: TextAlign.right,
                style: AppTypography.inter(
                  color: colors.mutedText,
                  fontSize: 10,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            signedSats(transaction),
            style: AppTypography.technicalMono(
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TransparentStatusPill(
              text: bitcoinAccountTransactionStatusLabel(
                  context, transaction.status),
            ),
          ),
        ],
      ),
    );
  }
}

class TransparentStatusPill extends StatelessWidget {
  final String text;

  const TransparentStatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = KeroseneBrandTokens.bitcoinOrange;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.inter(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
