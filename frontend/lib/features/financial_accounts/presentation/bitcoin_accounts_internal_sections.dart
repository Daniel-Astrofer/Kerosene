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
import 'bitcoin_screens/internal_account_creation_screen.dart';
import 'bitcoin_accounts_internal_sections.dart';

import 'bitcoin_accounts_screen.dart';

class InternalCardPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapCard;

  const InternalCardPager({
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            controller: PageController(
              viewportFraction: 0.96,
              initialPage: selectedIndex,
            ),
            onPageChanged: onChanged,
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InternalWalletCard(
                  account: accounts[index],
                  onTap: onTapCard,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < accounts.length; index++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == selectedIndex
                      ? colors.selectedDot
                      : colors.idleDot,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class InternalWalletCard extends StatelessWidget {
  final BitcoinAccount account;
  final VoidCallback onTap;

  const InternalWalletCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();
    final typeDescription = account.walletTypeDescription.trim().isEmpty
        ? 'Carteira Global'
        : account.walletTypeDescription.trim();
    final colors = BitcoinAccountsColors.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 224,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.hexFF1E1B38, AppColors.hexFF141414],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.newsreader(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      cardExpiryLabel(account),
                      style: AppTypography.newsreader(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill(text: typeDescription),
                ),
                const Spacer(),
                Text(
                  kKeroseneBrandLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.newsreader(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shortCardIdentifier(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.technicalMono(
                          textStyle:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cardCode(account),
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InternalBalanceSection extends StatelessWidget {
  final BitcoinAccount account;

  const InternalBalanceSection({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final available = account.balanceAvailableSats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Pill(text: context.tr.bitcoinAccountsKeroseneCardBadge),
            Pill(text: friendlyStatus(context, account.status)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsAvailableBalance,
                style: AppTypography.inter(
                  color: colors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              formatSats(available),
              style: AppTypography.inter(
                color: colors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.bitcoinAccountsKeroseneCardNote,
          style: AppTypography.inter(
            color: colors.mutedText,
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class ReceiveRequestsSection extends ConsumerWidget {
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;
  final VoidCallback onRetry;

  const ReceiveRequestsSection({
    required this.requestsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return TransactionsPanel(
      title: context.tr.bitcoinReceiveRequestsTitle,
      children: requestsAsync.when(
        loading: () => const [
          DarkSkeletonRow(),
          DarkSkeletonRow(),
        ],
        error: (_, __) => [
          DarkActionMessage(
            icon: KeroseneIcons.error,
            title: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorTitle
                : context.tr.bitcoinReceiveRequestsOfflineTitle,
            message: isOnline
                ? context.tr.bitcoinReceiveRequestsLoadErrorMessage
                : context.tr.bitcoinReceiveRequestsOfflineMessage,
            actionLabel: context.tr.retry,
            onAction: onRetry,
          ),
        ],
        data: (requests) {
          if (requests.isEmpty) {
            return [
              DarkActionMessage(
                icon: KeroseneIcons.inbox,
                title: context.tr.bitcoinReceiveRequestsEmptyTitle,
                message: context.tr.bitcoinReceiveRequestsEmptyMessage,
              ),
            ];
          }

          final visible = requests.take(5).toList(growable: false);
          return [
            for (var index = 0; index < visible.length; index++)
              ReceiveRequestRow(
                request: visible[index],
                showDivider: index != visible.length - 1,
              ),
          ];
        },
      ),
    );
  }
}

class ReceiveRequestRow extends StatelessWidget {
  final ReceivingRequestView request;
  final bool showDivider;

  const ReceiveRequestRow({
    required this.request,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = request.amountSats == null
        ? context.tr.bitcoinReceiveRequestsFlexibleAmount
        : formatSats(request.amountSats!);
    final subtitle = request.address.isEmpty
        ? request.id
        : '${shortText(request.address)} | ${request.expiry.isEmpty ? context.tr.bitcoinReceiveRequestsNoExpiry : request.expiry}';

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
        children: [
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
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
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
          const SizedBox(width: 12),
          Pill(text: receiveStatusLabel(context, request.status)),
        ],
      ),
    );
  }
}

class InternalTransactionsSection extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const InternalTransactionsSection({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      loading: () => const CompactLoadingPanel(),
      error: (_, __) => TransactionsPanel(
        title: 'Transactions',
        children: [
          DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
        ],
      ),
      data: (requests) => transactionsAsync.when(
        loading: () => const CompactLoadingPanel(),
        error: (_, __) => TransactionsPanel(
          title: 'Transactions',
          children: [
            DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
          ],
        ),
        data: (transactions) {
          final rows = transactionsForAccount(
            account: account,
            transactions: transactions,
            requests: requests,
          ).take(3).toList(growable: false);

          return TransactionsPanel(
            title: 'Transactions',
            children: rows.isEmpty
                ? [DarkListMessage(text: 'Sem transações desta carteira.')]
                : [
                    for (var index = 0; index < rows.length; index++)
                      TransactionSummaryRow(
                        transaction: rows[index],
                        showDivider: index != rows.length - 1,
                      ),
                  ],
          );
        },
      ),
    );
  }
}

class TransactionsPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const TransactionsPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.newsreader(
            color: colors.text,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class TransactionSummaryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const TransactionSummaryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : transactionTitle(transaction);

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
        children: [
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
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  relativeTransactionDate(transaction.timestamp),
                  style: AppTypography.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            signedSats(transaction),
            style: AppTypography.inter(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class DarkListMessage extends StatelessWidget {
  final String text;

  const DarkListMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: AppTypography.inter(
          color: colors.mutedText,
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class DarkActionMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DarkActionMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.mutedText, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: AppTypography.inter(
                    color: colors.mutedText,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(KeroseneIcons.refresh, size: 15),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DarkSkeletonRow extends StatelessWidget {
  const DarkSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return Container(
      height: 58,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class CompactLoadingPanel extends StatelessWidget {
  const CompactLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final colors = BitcoinAccountsColors.of(context);

    return SizedBox(
      height: 88,
      child: Center(
        child: CircularProgressIndicator(color: colors.text, strokeWidth: 2),
      ),
    );
  }
}
