import 'dart:async';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/features/bitcoin_accounts/data/bitcoin_accounts_service.dart';
import 'package:teste/features/bitcoin_accounts/data/cold_wallet_public_material.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_provider.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/transaction.dart';
import 'package:teste/l10n/l10n_extension.dart';

class BitcoinAccountsScreen extends ConsumerStatefulWidget {
  const BitcoinAccountsScreen({super.key});

  @override
  ConsumerState<BitcoinAccountsScreen> createState() =>
      _BitcoinAccountsScreenState();
}

class _BitcoinAccountsScreenState extends ConsumerState<BitcoinAccountsScreen> {
  int _selectedInternalIndex = 0;
  String? _managedAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(bitcoinAccountsProvider);
    final bottom = AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: monoBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: monoTextColor,
              backgroundColor: monoSurfaceColor,
              onRefresh: () =>
                  ref.read(bitcoinAccountsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  responsive.isTinyPhone ? 14 : 18,
                  responsive.horizontalPadding,
                  bottom,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsive.mobileContentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            onAdd: _openInternalAccountFlow,
                            managing: _managedAccountId != null,
                            onBack: _managedAccountId == null
                                ? null
                                : () =>
                                    setState(() => _managedAccountId = null),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          accounts.when(
                            loading: () => const _AccountsSkeleton(),
                            error: (_, __) => _StatePanel(
                              icon: LucideIcons.alertTriangle,
                              title: context.tr.bitcoinAccountsErrorTitle,
                              message: context.tr.bitcoinAccountsErrorMessage,
                              actionLabel: context.tr.tryAgain,
                              onAction: () => ref
                                  .read(bitcoinAccountsProvider.notifier)
                                  .refresh(),
                            ),
                            data: (items) => _AccountsContent(
                              accounts: items,
                              selectedInternalIndex: _selectedInternalIndex,
                              managedAccountId: _managedAccountId,
                              onInternalChanged: (index) => setState(() {
                                _selectedInternalIndex = index;
                                _managedAccountId = null;
                              }),
                              onManageAccount: (account) => setState(() {
                                _managedAccountId = account.id;
                              }),
                              onCreateColdWallet: _openColdWalletFlow,
                              onCreateInternalAccount: _openInternalAccountFlow,
                              onReceive: (account) =>
                                  _showReceiveSheet(context, account),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.card,
          ),
        ],
      ),
    );
  }

  void _openColdWalletFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _ColdWalletCreationScreen(),
      ),
    );
  }

  void _openInternalAccountFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _InternalAccountCreationFlow(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onBack;
  final bool managing;

  const _Header({
    required this.onAdd,
    required this.managing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          _RoundHeaderButton(icon: LucideIcons.chevronLeft, onTap: onBack!),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            'Carteira interna',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ebGaramond(
              color: Colors.white,
              fontSize: managing ? 32 : 36,
              fontWeight: FontWeight.w500,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RoundHeaderButton(icon: LucideIcons.plus, onTap: onAdd),
      ],
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _AccountsContent extends ConsumerWidget {
  final List<BitcoinAccount> accounts;
  final int selectedInternalIndex;
  final String? managedAccountId;
  final ValueChanged<int> onInternalChanged;
  final ValueChanged<BitcoinAccount> onManageAccount;
  final VoidCallback onCreateColdWallet;
  final VoidCallback onCreateInternalAccount;
  final ValueChanged<BitcoinAccount> onReceive;

  const _AccountsContent({
    required this.accounts,
    required this.selectedInternalIndex,
    required this.managedAccountId,
    required this.onInternalChanged,
    required this.onManageAccount,
    required this.onCreateColdWallet,
    required this.onCreateInternalAccount,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internal = accounts.where((account) => account.isInternal).toList();
    final watchOnly = accounts.where((account) => account.isWatchOnly).toList();
    final selectedIndex = internal.isEmpty
        ? 0
        : selectedInternalIndex.clamp(0, internal.length - 1);
    final selectedInternal = internal.isEmpty ? null : internal[selectedIndex];
    BitcoinAccount? managedAccount;
    if (managedAccountId != null) {
      for (final account in internal) {
        if (account.id == managedAccountId) {
          managedAccount = account;
          break;
        }
      }
    }

    if (accounts.isEmpty) {
      return _StatePanel(
        icon: LucideIcons.walletCards,
        title: context.tr.bitcoinAccountsEmptyTitle,
        message: context.tr.bitcoinAccountsEmptyMessage,
        actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
        onAction: onCreateInternalAccount,
      );
    }

    if (managedAccount != null) {
      final account = managedAccount;
      return _InternalAccountManagementView(
        account: account,
        onReceive: () => onReceive(account),
      );
    }

    final txAsync = ref.watch(transactionHistoryProvider);
    final requestsAsync = selectedInternal == null
        ? const AsyncValue<List<ReceivingRequestView>>.data(
            <ReceivingRequestView>[],
          )
        : ref.watch(bitcoinAccountReceiveRequestsProvider(selectedInternal.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedInternal == null)
          _StatePanel(
            icon: LucideIcons.creditCard,
            title: context.tr.bitcoinAccountsNoKeroseneCard,
            message: context.tr.bitcoinAccountsEmptyMessage,
            actionLabel: context.tr.bitcoinAccountsNewKeroseneCard,
            onAction: onCreateInternalAccount,
          )
        else ...[
          _InternalCardPager(
            accounts: internal,
            selectedIndex: selectedIndex,
            onChanged: onInternalChanged,
            onTapCard: () => onManageAccount(selectedInternal),
          ),
          const SizedBox(height: 30),
          _InternalBalanceSection(account: selectedInternal),
          const SizedBox(height: 30),
          _InternalTransactionsSection(
            account: selectedInternal,
            transactionsAsync: txAsync,
            requestsAsync: requestsAsync,
          ),
        ],
        const SizedBox(height: 32),
        _ColdWalletSection(
          accounts: watchOnly,
          onCreateColdWallet: onCreateColdWallet,
        ),
      ],
    );
  }
}

class _InternalCardPager extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onTapCard;

  const _InternalCardPager({
    required this.accounts,
    required this.selectedIndex,
    required this.onChanged,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
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
                child: _InternalWalletCard(
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
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.30),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InternalWalletCard extends StatelessWidget {
  final BitcoinAccount account;
  final VoidCallback onTap;

  const _InternalWalletCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();

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
                colors: [Color(0xFF1E1B38), Color(0xFF141414)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
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
                        style: GoogleFonts.ebGaramond(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      _cardExpiryLabel(account),
                      style: GoogleFonts.ebGaramond(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Kerosene',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ebGaramond(
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
                        _shortCardIdentifier(account),
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
                      _cardCode(account),
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

class _InternalBalanceSection extends StatelessWidget {
  final BitcoinAccount account;

  const _InternalBalanceSection({required this.account});

  @override
  Widget build(BuildContext context) {
    final limit = account.dailyLimitSats;
    final available = account.balanceAvailableSats;
    final progress =
        limit <= 0 ? 0.0 : (available / limit).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: context.tr.bitcoinAccountsKeroseneCardBadge),
            _Pill(text: _friendlyStatus(context, account.status)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsAvailableBalance,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              _formatSats(available),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 16,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.62),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatSats(available)} / ${_formatSats(limit)}',
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            color: const Color(0xFF888888),
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.bitcoinAccountsKeroseneCardNote,
          style: GoogleFonts.inter(
            color: const Color(0xFF888888),
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _InternalTransactionsSection extends StatelessWidget {
  final BitcoinAccount account;
  final AsyncValue<List<Transaction>> transactionsAsync;
  final AsyncValue<List<ReceivingRequestView>> requestsAsync;

  const _InternalTransactionsSection({
    required this.account,
    required this.transactionsAsync,
    required this.requestsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      loading: () => const _CompactLoadingPanel(),
      error: (_, __) => _TransactionsPanel(
        title: 'Transactions',
        children: [
          _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
        ],
      ),
      data: (requests) => transactionsAsync.when(
        loading: () => const _CompactLoadingPanel(),
        error: (_, __) => _TransactionsPanel(
          title: 'Transactions',
          children: [
            _DarkListMessage(text: context.tr.bitcoinAccountsErrorMessage),
          ],
        ),
        data: (transactions) {
          final rows = _transactionsForAccount(
            account: account,
            transactions: transactions,
            requests: requests,
          ).take(3).toList(growable: false);

          return _TransactionsPanel(
            title: 'Transactions',
            children: rows.isEmpty
                ? [_DarkListMessage(text: 'Sem transações desta carteira.')]
                : [
                    for (var index = 0; index < rows.length; index++)
                      _TransactionSummaryRow(
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

class _TransactionsPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _TransactionsPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.ebGaramond(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
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

class _TransactionSummaryRow extends StatelessWidget {
  final Transaction transaction;
  final bool showDivider;

  const _TransactionSummaryRow({
    required this.transaction,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final title = transaction.description?.trim().isNotEmpty == true
        ? transaction.description!.trim()
        : _transactionTitle(transaction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _relativeTransactionDate(transaction.timestamp),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF888888),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _signedSats(transaction),
            style: GoogleFonts.inter(
              color: Colors.white,
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

class _DarkListMessage extends StatelessWidget {
  final String text;

  const _DarkListMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFF888888),
          fontSize: 13,
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CompactLoadingPanel extends StatelessWidget {
  const _CompactLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 88,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }
}

class _ColdWalletSection extends StatelessWidget {
  final List<BitcoinAccount> accounts;
  final VoidCallback onCreateColdWallet;

  const _ColdWalletSection({
    required this.accounts,
    required this.onCreateColdWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.bitcoinAccountsColdWalletSection,
                style: GoogleFonts.ebGaramond(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            IconButton(
              onPressed: onCreateColdWallet,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (accounts.isEmpty)
          _MutedPanel(text: context.tr.bitcoinAccountsNoColdWallet)
        else
          for (final account in accounts) _ColdWalletTile(account: account),
      ],
    );
  }
}

class _ColdWalletTile extends StatelessWidget {
  final BitcoinAccount account;

  const _ColdWalletTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final label = account.label.trim().isEmpty
        ? context.tr.bitcoinAccountsUnnamedAccount
        : account.label.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.snowflake, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: context.tr.bitcoinAccountsColdWalletBadge),
                    _Pill(text: context.tr.bitcoinAccountsReviewBalance),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr.bitcoinAccountsObservedBalance,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF888888),
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatSats(account.observedBalanceSats),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF888888),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.bitcoinAccountsColdWalletNote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF888888),
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
                    color: const Color(0xFF888888),
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalAccountManagementView extends StatefulWidget {
  final BitcoinAccount account;
  final VoidCallback onReceive;

  const _InternalAccountManagementView({
    required this.account,
    required this.onReceive,
  });

  @override
  State<_InternalAccountManagementView> createState() =>
      _InternalAccountManagementViewState();
}

class _InternalAccountManagementViewState
    extends State<_InternalAccountManagementView> {
  String? _expandedKey = 'limit';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InternalWalletCard(account: widget.account, onTap: () {}),
        const SizedBox(height: 18),
        _ManagementItem(
          title: 'Limite disponível',
          expanded: _expandedKey == 'limit',
          onTap: () => _toggle('limit'),
          rows: [
            ('Seu limite', _formatSats(widget.account.balanceAvailableSats)),
          ],
        ),
        _ManagementItem(
          title: 'Endereço de recebimento',
          expanded: _expandedKey == 'receive',
          onTap: () {
            _toggle('receive');
            widget.onReceive();
          },
          rows: const [
            ('Ação', 'Gerar ou visualizar endereço'),
          ],
        ),
        _ManagementItem(
          title: 'Limite de gastos diário',
          expanded: _expandedKey == 'daily',
          onTap: () => _toggle('daily'),
          rows: [
            ('Limite diário', _formatSats(widget.account.dailyLimitSats)),
          ],
        ),
        _ManagementItem(
          title: 'Senha do cartão',
          expanded: _expandedKey == 'password',
          onTap: () => _toggle('password'),
          rows: const [
            ('Status', 'Protegida'),
          ],
        ),
        _ManagementItem(
          title: 'Data de validade',
          expanded: _expandedKey == 'expiry',
          onTap: () => _toggle('expiry'),
          rows: [
            ('Validade', _cardExpiryLabel(widget.account)),
          ],
        ),
      ],
    );
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() => _expandedKey = _expandedKey == key ? null : key);
  }
}

class _ManagementItem extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<(String, String)> rows;

  const _ManagementItem({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1F),
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
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: expanded ? 0.5 : 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.chevronDown,
                          color: Colors.white,
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
                  Divider(color: Colors.white.withValues(alpha: 0.05)),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.$1,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8E8E93),
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Text(
                            row.$2,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E8E93),
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
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ColdWalletCreationScreen extends ConsumerStatefulWidget {
  const _ColdWalletCreationScreen();

  @override
  ConsumerState<_ColdWalletCreationScreen> createState() =>
      _ColdWalletCreationScreenState();
}

class _ColdWalletCreationScreenState
    extends ConsumerState<_ColdWalletCreationScreen> {
  final TextEditingController _labelController = TextEditingController(
    text: 'Cold Wallet',
  );
  final TextEditingController _extraWordController = TextEditingController();
  final List<TextEditingController> _verificationControllers = [];
  final _deriver = const ColdWalletPublicMaterialDeriver();

  _ColdWalletLevel _level = _ColdWalletLevel.recommended;
  _ColdWalletStep _step = _ColdWalletStep.prepare;
  ColdWalletPublicMaterial? _publicMaterial;
  List<int> _verificationIndexes = const [];
  String _mnemonic = '';
  bool _paperReady = false;
  bool _privatePlace = false;
  bool _offlineReady = false;
  bool _noPhotos = false;
  bool _showWords = false;
  bool _busy = false;

  bool get _canGenerate =>
      _labelController.text.trim().isNotEmpty &&
      _paperReady &&
      _privatePlace &&
      _offlineReady &&
      _noPhotos;

  List<String> get _words =>
      _mnemonic.trim().isEmpty ? const [] : _mnemonic.split(' ');

  @override
  void dispose() {
    _labelController.dispose();
    _extraWordController.dispose();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _mnemonic = '';
    super.dispose();
  }

  void _generateColdWallet() {
    if (!_canGenerate) {
      return;
    }
    final strength = _level.wordCount == 12 ? 128 : 256;
    final mnemonic = bip39.generateMnemonic(strength: strength);
    final publicMaterial = _deriver.derive(
      mnemonic: mnemonic,
      extraWord: _level.usesExtraWord ? _extraWordController.text : '',
    );
    setState(() {
      _mnemonic = mnemonic;
      _publicMaterial = publicMaterial;
      _showWords = false;
      _step = _ColdWalletStep.backup;
    });
    HapticFeedback.mediumImpact();
  }

  void _startVerification() {
    final words = _words;
    final indexes = <int>{
      0,
      words.length ~/ 2,
      max(0, words.length - 1),
    }.toList()
      ..sort();
    for (final controller in _verificationControllers) {
      controller.dispose();
    }
    _verificationControllers
      ..clear()
      ..addAll(List.generate(indexes.length, (_) => TextEditingController()));
    setState(() {
      _verificationIndexes = indexes;
      _step = _ColdWalletStep.verify;
      _showWords = false;
    });
  }

  bool _verificationMatches() {
    final words = _words;
    if (words.isEmpty ||
        _verificationControllers.length != _verificationIndexes.length) {
      return false;
    }
    for (var index = 0; index < _verificationIndexes.length; index++) {
      final wordIndex = _verificationIndexes[index];
      final typed = _verificationControllers[index].text.trim().toLowerCase();
      if (typed != words[wordIndex].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  Future<void> _importWatchOnly() async {
    final material = _publicMaterial;
    if (material == null || !_verificationMatches()) {
      AppNotice.showWarning(
        context,
        title: context.tr.coldWalletVerifyFailedTitle,
        message: context.tr.coldWalletVerifyFailedMessage,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final notifier = ref.read(bitcoinAccountsProvider.notifier);
      await notifier.importColdWallet(
        label: _labelController.text.trim(),
        xpub: material.xpub,
        fingerprint: material.fingerprint,
        derivationPath: material.derivationPath,
        scriptPolicy: material.scriptPolicy,
      );
      final state = ref.read(bitcoinAccountsProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Import failed');
      }
      _mnemonic = '';
      _extraWordController.clear();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.coldWalletImportedTitle,
        message: context.tr.coldWalletImportedMessage,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.coldWalletImportErrorTitle,
        message: context.tr.coldWalletImportErrorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: monoBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                responsive.horizontalPadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.maybePop(context),
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: monoTextColor,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr.coldWalletCreateTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: monoTextColor,
                            fontSize: responsive.compactFontSize(
                              tiny: 19,
                              compact: 21,
                              regular: 22,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  AppSpacing.sm,
                  responsive.horizontalPadding,
                  AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.mobileContentMaxWidth,
                    ),
                    child: switch (_step) {
                      _ColdWalletStep.prepare => _buildPrepare(),
                      _ColdWalletStep.backup => _buildBackup(),
                      _ColdWalletStep.verify => _buildVerify(),
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.tr.coldWalletCreateSubtitle),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _labelController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: monoTextColor),
          decoration: monochromeInputDecoration(
            label: context.tr.coldWalletNameLabel,
            hintText: context.tr.coldWalletNameHint,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(context.tr.coldWalletSecurityLevelTitle),
        for (final level in _ColdWalletLevel.values)
          _ColdWalletLevelTile(
            level: level,
            selected: _level == level,
            onTap: () => setState(() => _level = level),
          ),
        if (_level.usesExtraWord) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _extraWordController,
            obscureText: true,
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.tr.coldWalletExtraWordLabel,
              hintText: context.tr.coldWalletExtraWordHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MutedPanel(text: context.tr.coldWalletExtraWordWarning),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(context.tr.coldWalletChecklistTitle),
        _ChecklistTile(
          value: _paperReady,
          text: context.tr.coldWalletChecklistPaper,
          onChanged: (value) => setState(() => _paperReady = value),
        ),
        _ChecklistTile(
          value: _privatePlace,
          text: context.tr.coldWalletChecklistPrivate,
          onChanged: (value) => setState(() => _privatePlace = value),
        ),
        _ChecklistTile(
          value: _offlineReady,
          text: context.tr.coldWalletChecklistOffline,
          onChanged: (value) => setState(() => _offlineReady = value),
        ),
        _ChecklistTile(
          value: _noPhotos,
          text: context.tr.coldWalletChecklistNoPhotos,
          onChanged: (value) => setState(() => _noPhotos = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _canGenerate ? _generateColdWallet : null,
          icon: const Icon(LucideIcons.keyRound, size: 18),
          label: Text(context.tr.coldWalletGenerateAction),
        ),
      ],
    );
  }

  Widget _buildBackup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.tr.coldWalletBackupSubtitle),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: monochromePanelDecoration(color: monoSurfaceAltColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _IconFrame(icon: LucideIcons.eyeOff),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.tr.coldWalletBackupTitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: monoTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_showWords)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _words
                        .asMap()
                        .entries
                        .map(
                          (entry) => _SeedWordBadge(
                            index: entry.key + 1,
                            word: entry.value,
                          ),
                        )
                        .toList(),
                  )
                else
                  _MutedPanel(text: context.tr.coldWalletWordsHidden),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: monochromeOutlinedButtonStyle(),
                  onPressed: () => setState(() => _showWords = !_showWords),
                  icon: Icon(_showWords ? LucideIcons.eyeOff : LucideIcons.eye),
                  label: Text(
                    _showWords
                        ? context.tr.coldWalletHideWords
                        : context.tr.coldWalletShowWords,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _showWords ? _startVerification : null,
          icon: const Icon(LucideIcons.checkCircle, size: 18),
          label: Text(context.tr.coldWalletBackupDoneAction),
        ),
      ],
    );
  }

  Widget _buildVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MutedPanel(text: context.tr.coldWalletVerifySubtitle),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < _verificationIndexes.length; index++) ...[
          TextField(
            controller: _verificationControllers[index],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: monoTextColor),
            decoration: monochromeInputDecoration(
              label: context.tr.coldWalletVerifyWordLabel(
                _verificationIndexes[index] + 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.icon(
          style: monochromeFilledButtonStyle(),
          onPressed: _busy || !_verificationMatches() ? null : _importWatchOnly,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.shieldCheck, size: 18),
          label: Text(
            _busy
                ? context.tr.coldWalletImportingAction
                : context.tr.coldWalletImportAction,
          ),
        ),
      ],
    );
  }
}

class _ColdWalletLevelTile extends StatelessWidget {
  final _ColdWalletLevel level;
  final bool selected;
  final VoidCallback onTap;

  const _ColdWalletLevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? monoSurfaceRaisedColor : monoSurfaceColor,
            border: Border.all(
              color: selected ? monoTextColor : monoBorderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? LucideIcons.checkCircle : LucideIcons.circle,
                color: selected ? monoTextColor : monoMutedTextColor,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: monoTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.body(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: monoMutedTextColor,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final bool value;
  final String text;
  final ValueChanged<bool> onChanged;

  const _ChecklistTile({
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (next) => onChanged(next ?? false),
      activeColor: monoTextColor,
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: monoMutedTextColor,
              height: 1.35,
            ),
      ),
    );
  }
}

class _SeedWordBadge extends StatelessWidget {
  final int index;
  final String word;

  const _SeedWordBadge({required this.index, required this.word});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: monoBackgroundColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              index.toString().padLeft(2, '0'),
              style: AppTypography.technicalMono(
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: monoFaintTextColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              word,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternalAccountCreationFlow extends ConsumerStatefulWidget {
  const _InternalAccountCreationFlow();

  @override
  ConsumerState<_InternalAccountCreationFlow> createState() =>
      _InternalAccountCreationFlowState();
}

class _InternalAccountCreationFlowState
    extends ConsumerState<_InternalAccountCreationFlow> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dailyLimitController = TextEditingController();

  _InternalAccountStep _step = _InternalAccountStep.custody;
  _InternalAccountPurpose? _purpose;
  bool _busy = false;

  static const _purposes = [
    _InternalAccountPurpose('Investimento', LucideIcons.trendingUp),
    _InternalAccountPurpose('Casa', LucideIcons.home),
    _InternalAccountPurpose('Reserva', LucideIcons.building2),
    _InternalAccountPurpose('Veículo', LucideIcons.car),
    _InternalAccountPurpose('Gastos mensais', LucideIcons.receipt),
    _InternalAccountPurpose('Dia a Dia', LucideIcons.calendarDays),
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_busy) return;
    if (_step == _InternalAccountStep.custody) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      _step = _step == _InternalAccountStep.security
          ? _InternalAccountStep.purpose
          : _InternalAccountStep.custody;
    });
  }

  void _continueFromCustody() {
    if (_busy) return;
    setState(() => _step = _InternalAccountStep.purpose);
  }

  void _continueFromPurpose() {
    if (_busy) return;
    if (_purpose == null) {
      AppNotice.showWarning(
        context,
        title: 'Selecione a finalidade',
        message: 'Escolha para que essa conta interna será usada.',
      );
      return;
    }
    setState(() => _step = _InternalAccountStep.security);
  }

  Future<void> _createInternalAccount() async {
    if (_busy) return;
    final password = _passwordController.text.trim();
    final dailyLimit = _parseDailyLimit();

    if (password.isEmpty) {
      AppNotice.showWarning(
        context,
        title: 'Senha obrigatória',
        message: 'Defina uma senha para proteger alterações nessa carteira.',
      );
      return;
    }

    if (dailyLimit <= 0) {
      AppNotice.showWarning(
        context,
        title: 'Limite obrigatório',
        message: 'Informe um limite diário maior que zero.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(bitcoinAccountsProvider.notifier).createInternalCard(
            label: _purpose?.label ?? 'Kerosene BTC Card',
            dailyLimitSats: dailyLimit,
          );
      final state = ref.read(bitcoinAccountsProvider);
      if (state.hasError) {
        throw state.error ?? Exception('Create internal account failed');
      }
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      AppNotice.showSuccess(
        context,
        title: context.tr.bitcoinAccountsCreateCardTitle,
        message: 'Carteira interna criada com sucesso.',
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinAccountsCreateCardErrorTitle,
        message: context.tr.bitcoinAccountsCreateCardErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _parseDailyLimit() {
    final raw = _dailyLimitController.text.trim();
    final normalized = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                _step == _InternalAccountStep.purpose ? 14 : 24,
                16,
                _step == _InternalAccountStep.purpose ? 2 : 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _goBack,
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_step) {
                  _InternalAccountStep.custody => _buildCustodyStep(),
                  _InternalAccountStep.purpose => _buildPurposeStep(),
                  _InternalAccountStep.security => _buildSecurityStep(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustodyStep() {
    return _CreationStepFrame(
      key: const ValueKey('custody'),
      footer: _CreationPrimaryButton(
        label: 'Continuar',
        onPressed: _continueFromCustody,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationTitle('Nova Carteira.'),
          const SizedBox(height: 16),
          const _CreationBodyText(
            'Selecione o modelo de custódia preferido para prosseguir. Cada opção define como seus ativos serão gerenciados e armazenados.',
          ),
          const SizedBox(height: 32),
          _CustodyOptionCard(
            selected: true,
            icon: LucideIcons.wallet,
            title: 'Carteira Interna Kerosene',
            subtitle:
                'Saldo custodiado, transferências instantâneas, menor responsabilidade.',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _CustodyOptionCard(
            selected: false,
            icon: LucideIcons.keyRound,
            title: 'Carteira Fria / On-chain',
            subtitle:
                'Controle total do usuário, backup necessário, maior responsabilidade.',
            onTap: () {
              AppNotice.showWarning(
                context,
                title: 'Em breve',
                message:
                    'Este fluxo agora está disponível somente para a carteira interna Kerosene.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeStep() {
    return _CreationStepFrame(
      key: const ValueKey('purpose'),
      footer: _CreationPrimaryButton(
        label: 'Gerar Carteira',
        onPressed: _continueFromPurpose,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationTitle(
            'Para Que Finalidade Deseja Derivar essa Carteira?',
          ),
          const SizedBox(height: 40),
          for (final purpose in _purposes)
            _PurposeTile(
              purpose: purpose,
              selected: _purpose == purpose,
              onTap: () => setState(() => _purpose = purpose),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return _CreationStepFrame(
      key: const ValueKey('security'),
      footer: _CreationPrimaryButton(
        label: _busy ? 'Gerando...' : 'Gerar Carteira',
        onPressed: _busy ? null : _createInternalAccount,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreationTitle('Digite uma senha e um limite de gasto diário.'),
          const SizedBox(height: 24),
          const _CreationBodyText(
            'O limite diário serve para a segurança da sua conta depois de inserido só pode ser alterado uma unica vez, após a segunda alteração é necessário a criação de uma nova carteira.',
          ),
          const SizedBox(height: 18),
          const _CreationBodyText(
            'Esta senha é obrigatória para fazer quaisquer alteração na carteira.',
          ),
          const SizedBox(height: 48),
          _CreationTextField(
            controller: _passwordController,
            label: 'Digite uma senha para a carteira.',
            hintText: 'Senha',
            obscureText: true,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _CreationTextField(
            controller: _dailyLimitController,
            label: 'Limite diário.',
            hintText: 'Limite',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

class _CreationStepFrame extends StatelessWidget {
  final Widget child;
  final Widget footer;

  const _CreationStepFrame({
    super.key,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.viewInsetsOf(context).bottom > 0 ? 20 : 40,
          ),
          child: footer,
        ),
      ],
    );
  }
}

class _CreationTitle extends StatelessWidget {
  final String text;

  const _CreationTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.ebGaramond(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w500,
        height: 1.05,
        letterSpacing: 0,
      ),
    );
  }
}

class _CreationBodyText extends StatelessWidget {
  final String text;

  const _CreationBodyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: Color(0xFF888888),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
      ),
    );
  }
}

class _CreationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _CreationPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF2A2A2A),
          disabledForegroundColor: const Color(0xFF777777),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _CustodyOptionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CustodyOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.transparent : const Color(0xFF111111),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreationCircleIcon(icon: icon, outlined: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurposeTile extends StatelessWidget {
  final _InternalAccountPurpose purpose;
  final bool selected;
  final VoidCallback onTap;

  const _PurposeTile({
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF222222)),
            ),
          ),
          child: Row(
            children: [
              _CreationCircleIcon(icon: purpose.icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  purpose.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? LucideIcons.check : LucideIcons.chevronRight,
                  color: selected ? Colors.black : const Color(0xFF888888),
                  size: selected ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationCircleIcon extends StatelessWidget {
  final IconData icon;
  final bool outlined;

  const _CreationCircleIcon({
    required this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : const Color(0xFF1A1A1A),
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: const Color(0xFF333333)) : null,
      ),
      child: Icon(icon, color: Colors.white, size: outlined ? 24 : 20),
    );
  }
}

class _CreationTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _CreationTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ebGaramond(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
          cursorColor: Colors.white,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 16,
              letterSpacing: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _InternalAccountPurpose {
  final String label;
  final IconData icon;

  const _InternalAccountPurpose(this.label, this.icon);
}

enum _InternalAccountStep { custody, purpose, security }

String _friendlyStatus(BuildContext context, String status) {
  return switch (status.trim().toUpperCase()) {
    'ACTIVE' => context.tr.bitcoinAccountsStatusActive,
    'PENDING' => context.tr.bitcoinAccountsStatusPending,
    'DISABLED' => context.tr.bitcoinAccountsStatusDisabled,
    _ => context.tr.bitcoinAccountsStatusReady,
  };
}

void _showReceiveSheet(BuildContext context, BitcoinAccount account) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: monoSurfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: monoRadius),
    builder: (context) => _ReceiveSheet(account: account),
  );
}

class _ReceiveSheet extends ConsumerStatefulWidget {
  final BitcoinAccount account;

  const _ReceiveSheet({required this.account});

  @override
  ConsumerState<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends ConsumerState<_ReceiveSheet> {
  final TextEditingController _amount = TextEditingController();
  String _expiry = '1H';
  bool _oneTime = true;
  bool _busy = false;
  ReceivingRequestView? _result;
  Timer? _poller;

  @override
  void dispose() {
    _poller?.cancel();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: context.tr.bitcoinReceiveTitle,
      child: _result == null ? _buildForm(context) : _buildLiveRequest(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: monoTextColor),
          decoration: monochromeInputDecoration(
            label: context.tr.bitcoinReceiveAmountOptional,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in const ['15M', '1H', '24H', 'PERMANENT'])
              ChoiceChip(
                label: Text(_expiryLabel(context, option)),
                selected: _expiry == option,
                onSelected: (_) => setState(() => _expiry = option),
              ),
          ],
        ),
        SwitchListTile.adaptive(
          value: _oneTime,
          onChanged: (value) => setState(() => _oneTime = value),
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr.bitcoinReceiveOneTime,
            style: const TextStyle(color: monoTextColor),
          ),
          subtitle: Text(
            context.tr.bitcoinReceiveOneTimeSubtitle,
            style: const TextStyle(color: monoMutedTextColor),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: monochromeFilledButtonStyle(),
            onPressed: _busy ? null : _createReceiveRequest,
            icon: const Icon(LucideIcons.qrCode, size: 18),
            label: Text(
              _busy
                  ? context.tr.bitcoinReceiveGenerating
                  : context.tr.bitcoinReceiveGenerateAddress,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRequest(BuildContext context) {
    final result = _result!;
    final qrSize =
        context.responsive.clampWidth(210).clamp(168.0, 210.0).toDouble();

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: monoTextColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: QrImageView(
              data: result.bip21.trim().isNotEmpty
                  ? result.bip21
                  : 'bitcoin:${result.address}',
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BitcoinAddressBlocks(
          address: result.address,
          style: AppTypography.technicalMono(
            textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(text: _receiveStatusLabel(context, result.status)),
            if (result.amountSats != null)
              _Pill(text: _formatSats(result.amountSats!)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MutedPanel(text: _receiveStatusMessage(context, result)),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = constraints.maxWidth < 360;
            final buttons = [
              OutlinedButton.icon(
                style: monochromeOutlinedButtonStyle(),
                onPressed: _busy ? null : _copyAddress,
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(context.tr.copyAddress),
              ),
              OutlinedButton.icon(
                style: monochromeOutlinedButtonStyle(),
                onPressed: _busy ? null : () => _refreshStatus(silent: false),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(context.tr.bitcoinReceiveRefresh),
              ),
            ];

            if (shouldStack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buttons[0],
                  const SizedBox(height: AppSpacing.sm),
                  buttons[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: buttons[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createReceiveRequest() async {
    setState(() => _busy = true);
    try {
      final parsed = int.tryParse(_amount.text.trim());
      final service = ref.read(bitcoinAccountsServiceProvider);
      final created = await service.createReceiveRequest(
        accountId: widget.account.id,
        amountSats: parsed != null && parsed > 0 ? parsed : null,
        expiry: _expiry,
        oneTime: _oneTime,
      );
      if (!mounted) return;
      setState(() => _result = created);
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      AppNotice.showError(
        context,
        title: context.tr.bitcoinReceiveCreateErrorTitle,
        message: context.tr.bitcoinReceiveCreateErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshStatus({required bool silent}) async {
    final current = _result;
    if (current == null || _busy) return;
    if (!silent) setState(() => _busy = true);
    try {
      final service = ref.read(bitcoinAccountsServiceProvider);
      final updated = await service.getReceiveStatus(current.id);
      if (!mounted) return;
      setState(() => _result = updated);
      if (_isTerminal(updated.status)) {
        _poller?.cancel();
      }
    } catch (_) {
      if (!silent && mounted) {
        AppNotice.showError(
          context,
          title: context.tr.bitcoinReceiveStatusErrorTitle,
          message: context.tr.bitcoinReceiveStatusErrorMessage,
        );
      }
    } finally {
      if (!silent && mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyAddress() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.address));
    if (!mounted) return;
    AppNotice.showSuccess(
      context,
      title: context.tr.bitcoinReceiveCopiedTitle,
      message: context.tr.bitcoinReceiveCopiedMessage,
    );
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshStatus(silent: true),
    );
  }

  bool _isTerminal(String status) =>
      status == 'PAID' || status == 'HIDDEN' || status == 'FAILED_SAFE';
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          18,
          responsive.horizontalPadding,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.sheetMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: monoTextColor,
                        fontSize: responsive.compactFontSize(
                          tiny: 18,
                          compact: 19,
                          regular: 20,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: monoTextColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: monoSurfaceRaisedColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: monoMutedTextColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  final String text;

  const _MutedPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        showShadow: false,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: monoMutedTextColor, height: 1.4),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: monochromePanelDecoration(),
      child: Column(
        children: [
          _IconFrame(icon: icon),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: monoTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: monoMutedTextColor,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: monochromeFilledButtonStyle(),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  final IconData icon;

  const _IconFrame({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: monoSurfaceRaisedColor,
        border: Border.all(color: monoBorderStrongColor),
      ),
      child: Icon(icon, color: monoTextColor, size: 19),
    );
  }
}

class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: monochromePanelDecoration(),
          ),
      ],
    );
  }
}

enum _ColdWalletStep { prepare, backup, verify }

enum _ColdWalletLevel {
  essential,
  recommended,
  maximum;

  int get wordCount => this == essential ? 12 : 24;
  bool get usesExtraWord => this == maximum;

  String title(BuildContext context) {
    return switch (this) {
      essential => context.tr.coldWalletLevelEssentialTitle,
      recommended => context.tr.coldWalletLevelRecommendedTitle,
      maximum => context.tr.coldWalletLevelMaximumTitle,
    };
  }

  String body(BuildContext context) {
    return switch (this) {
      essential => context.tr.coldWalletLevelEssentialBody,
      recommended => context.tr.coldWalletLevelRecommendedBody,
      maximum => context.tr.coldWalletLevelMaximumBody,
    };
  }
}

String _expiryLabel(BuildContext context, String value) {
  return switch (value) {
    '15M' => context.tr.receive15Min,
    '1H' => context.tr.receive1Hour,
    '24H' => context.tr.receive24Hours,
    'PERMANENT' => context.tr.receiveNoExpiration,
    _ => value,
  };
}

String _receiveStatusLabel(BuildContext context, String status) {
  return switch (status) {
    'ACTIVE' => context.tr.bitcoinReceiveStatusActive,
    'MEMPOOL_SEEN' => context.tr.bitcoinReceiveStatusDetected,
    'CONFIRMING' => context.tr.bitcoinReceiveStatusConfirming,
    'PAID' => context.tr.bitcoinReceiveStatusPaid,
    'EXPIRED' => context.tr.bitcoinReceiveStatusExpired,
    'EXPIRED_RECEIVED' => context.tr.bitcoinReceiveStatusLate,
    'AUTO_RESOLUTION_PENDING' => context.tr.bitcoinReceiveStatusReview,
    'USER_ACTION_REQUIRED' => context.tr.bitcoinReceiveStatusAction,
    'FAILED_SAFE' => context.tr.bitcoinReceiveStatusProtected,
    _ => context.tr.bitcoinReceiveStatusWaiting,
  };
}

String _receiveStatusMessage(
  BuildContext context,
  ReceivingRequestView request,
) {
  return switch (request.status) {
    'ACTIVE' => context.tr.bitcoinReceiveMessageActive,
    'MEMPOOL_SEEN' => context.tr.bitcoinReceiveMessageDetected,
    'CONFIRMING' => context.tr.bitcoinReceiveMessageConfirming,
    'PAID' => context.tr.bitcoinReceiveMessagePaid,
    'EXPIRED' => context.tr.bitcoinReceiveMessageExpired,
    'EXPIRED_RECEIVED' => context.tr.bitcoinReceiveMessageLate,
    'AUTO_RESOLUTION_PENDING' => context.tr.bitcoinReceiveMessageReview,
    'USER_ACTION_REQUIRED' => context.tr.bitcoinReceiveMessageAction,
    'FAILED_SAFE' => context.tr.bitcoinReceiveMessageProtected,
    _ => context.tr.bitcoinReceiveMessageWaiting,
  };
}

List<Transaction> _transactionsForAccount({
  required BitcoinAccount account,
  required List<Transaction> transactions,
  required List<ReceivingRequestView> requests,
}) {
  final keys = <String>{
    account.id,
    account.cardId ?? '',
    account.coldWalletId ?? '',
    account.label,
    account.xpubFingerprint ?? '',
    for (final request in requests) request.address,
    for (final request in requests) request.bip21,
  }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();

  if (keys.isEmpty) return const [];

  bool matches(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return keys.any((key) => normalized == key || normalized.contains(key));
  }

  final rows = transactions.where((tx) {
    return matches(tx.fromAddress) ||
        matches(tx.toAddress) ||
        matches(tx.description ?? '') ||
        matches(tx.externalReference ?? '') ||
        matches(tx.invoiceId ?? '') ||
        matches(tx.paymentHash ?? '');
  }).toList();
  rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return rows;
}

String _cardExpiryLabel(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.codeUnits.fold<int>(0, (value, unit) => value + unit);
  final month = (hash % 12) + 1;
  final year = 29 + (hash % 5);
  return '${month.toString().padLeft(2, '0')}/$year';
}

String _cardCode(BitcoinAccount account) {
  final source = account.cardId ?? account.id;
  final hash = source.hashCode.abs() % 1000;
  return hash.toString().padLeft(3, '0');
}

String _shortCardIdentifier(BitcoinAccount account) {
  final source = (account.cardId ?? account.id).replaceAll('-', '');
  if (source.length <= 20) return source;
  return source.substring(0, 20);
}

String _transactionTitle(Transaction transaction) {
  if (transaction.isLightning) return 'Lightning';
  if (transaction.isInternal) return 'Kerosene';
  return switch (transaction.type) {
    TransactionType.receive || TransactionType.deposit => 'Recebimento',
    TransactionType.send || TransactionType.withdrawal => 'Envio',
    TransactionType.fee => 'Taxa',
    TransactionType.swap => 'Swap',
  };
}

String _relativeTransactionDate(DateTime timestamp) {
  final now = DateTime.now();
  final local = timestamp.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';
  if (difference < 7) {
    return switch (local.weekday) {
      DateTime.monday => 'Segunda',
      DateTime.tuesday => 'Terça',
      DateTime.wednesday => 'Quarta',
      DateTime.thursday => 'Quinta',
      DateTime.friday => 'Sexta',
      DateTime.saturday => 'Sábado',
      _ => 'Domingo',
    };
  }
  final year = local.year.toString().substring(2);
  final month = local.month.toString().padLeft(2, '0');
  return '${local.day}/$month/$year';
}

String _signedSats(Transaction transaction) {
  final isIncoming = transaction.type == TransactionType.receive ||
      transaction.type == TransactionType.deposit;
  final sign = isIncoming ? '+' : '-';
  return '$sign${_formatSats(transaction.amountSatoshis)}';
}

String _formatSats(int sats) {
  final btc = sats / 100000000;
  return '${btc.toStringAsFixed(8)} BTC';
}
