import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/movement/domain/entities/transaction.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/utils/transaction_address_display.dart';
import 'package:kerosene/features/movement/widgets/statement_transaction_card.dart';
import 'package:kerosene/features/movement/widgets/transaction_statement_insights.dart';
import 'package:kerosene/shared/widgets/bitcoin_refresh_indicator.dart';

enum _StatementTab { statement, insights }

enum _StatementFilter {
  all,
  incoming,
  outgoing,
  pending,
  failed,
  onchain,
  lightning,
  internal,
}

class TransactionStatementScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const TransactionStatementScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<TransactionStatementScreen> createState() =>
      _TransactionStatementScreenState();
}

class _TransactionStatementScreenState
    extends ConsumerState<TransactionStatementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  _StatementTab _selectedTab = _StatementTab.statement;
  _StatementFilter _selectedFilter = _StatementFilter.all;
  String? _expandedTransactionId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _expandedTransactionId = widget.initialTransactionId;
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(walletProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    ref.invalidate(transactionHistoryProvider);
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(transactionHistoryProvider.future),
    ]);
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
  }

  void _selectTab(_StatementTab tab) {
    if (_selectedTab == tab) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = tab);
  }

  void _selectFilter(_StatementFilter filter) {
    if (_selectedFilter == filter) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedFilter = filter);
  }

  void _toggleTransaction(Transaction transaction) {
    HapticFeedback.selectionClick();
    setState(() {
      _expandedTransactionId =
          _expandedTransactionId == transaction.id ? null : transaction.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final walletState = ref.watch(walletProvider);
    final wallets =
        walletState is WalletLoaded ? walletState.wallets : const <Wallet>[];
    final bottomPadding =
        AppPrimaryNavigationBar.scaffoldBottomClearance(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth >= 900 ? 980.0 : 430.0;

    if (historyAsync.isLoading && !historyAsync.hasValue) {
      return const KeroseneLogoLoadingView();
    }

    return Scaffold(
      backgroundColor: _StatementColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    BitcoinRefreshIndicator(onRefresh: _refreshData),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl2,
                          AppSpacing.xl,
                          AppSpacing.xl2,
                          0,
                        ),
                        child: _StatementTopBar(onBack: _handleBack),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl2,
                          18,
                          AppSpacing.xl2,
                          0,
                        ),
                        child: _StatementHeader(
                          selectedTab: _selectedTab,
                          onTabSelected: _selectTab,
                        ),
                      ),
                    ),
                    historyAsync.when(
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: SizedBox.shrink(),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StatementMessage(
                          icon: KeroseneIcons.warning,
                          title: context.tr.financialStatementLoadErrorTitle,
                          message: ErrorTranslator.translate(
                            context.tr,
                            error.toString(),
                          ),
                        ),
                      ),
                      data: (transactions) {
                        if (_selectedTab == _StatementTab.insights) {
                          return SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.xl2,
                              AppSpacing.xl2,
                              AppSpacing.xl2,
                              bottomPadding,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: TransactionStatementInsights(
                                transactions: transactions,
                                wallets: wallets,
                              ),
                            ),
                          );
                        }

                        final filtered = _filteredTransactions(transactions);
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.xl2,
                            AppSpacing.xl2,
                            AppSpacing.xl2,
                            bottomPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _StatementListSurface(
                              queryController: _searchController,
                              selectedFilter: _selectedFilter,
                              onFilterSelected: _selectFilter,
                              allTransactions: transactions,
                              transactions: filtered,
                              expandedTransactionId: _expandedTransactionId,
                              onTransactionTap: _toggleTransaction,
                              onClearFilters: _clearFilters,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppPrimaryNavigationBar.overlay(
            currentDestination: AppPrimaryDestination.history,
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = _StatementFilter.all;
      _searchController.clear();
      _query = '';
    });
  }

  List<Transaction> _filteredTransactions(List<Transaction> transactions) {
    final normalizedQuery = _query.toLowerCase();
    final filtered = transactions.where((transaction) {
      if (!_matchesFilter(transaction, _selectedFilter)) return false;
      if (normalizedQuery.isEmpty) return true;
      return _searchText(transaction).contains(normalizedQuery);
    }).toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  bool _matchesFilter(Transaction transaction, _StatementFilter filter) {
    return switch (filter) {
      _StatementFilter.all => true,
      _StatementFilter.incoming => transaction.isCredit,
      _StatementFilter.outgoing => transaction.isDebit,
      _StatementFilter.pending =>
        transaction.status == TransactionStatus.pending ||
            transaction.status == TransactionStatus.confirming,
      _StatementFilter.failed => transaction.status == TransactionStatus.failed,
      _StatementFilter.onchain =>
        !transaction.isLightning && !transaction.isInternal,
      _StatementFilter.lightning => transaction.isLightning,
      _StatementFilter.internal => transaction.isInternal,
    };
  }

  String _searchText(Transaction transaction) {
    return [
      transaction.id,
      transaction.fromAddress,
      transaction.toAddress,
      transaction.walletId,
      transaction.sourceWalletId,
      transaction.destinationWalletId,
      transaction.senderDisplayName,
      transaction.receiverDisplayName,
      transaction.description,
      transaction.blockchainTxid,
      transaction.paymentHash,
      transaction.externalReference,
      _transactionTitle(transaction),
      _transactionRailLabel(transaction),
      _transactionStatusLabel(transaction),
      resolvePrimaryTransactionAddress(transaction),
    ].whereType<String>().join(' ').toLowerCase();
  }
}

class _StatementHeader extends StatelessWidget {
  final _StatementTab selectedTab;
  final ValueChanged<_StatementTab> onTabSelected;

  const _StatementHeader({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _copy(context, pt: 'Extrato', en: 'Statement', es: 'Extracto'),
          style: AppTypography.newsreader(
            color: _StatementColors.textPrimary,
            fontSize: MediaQuery.sizeOf(context).width >= 720 ? 36 : 32,
            fontWeight: FontWeight.w500,
            height: 1.12,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        _StatementTabSwitcher(
          selected: selectedTab,
          onSelected: onTabSelected,
        ),
      ],
    );
  }
}

class _StatementTabSwitcher extends StatelessWidget {
  final _StatementTab selected;
  final ValueChanged<_StatementTab> onSelected;

  const _StatementTabSwitcher({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _StatementColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatementTabButton(
              label: _copy(context,
                  pt: 'Extrato', en: 'Statement', es: 'Extracto'),
              selected: selected == _StatementTab.statement,
              onTap: () => onSelected(_StatementTab.statement),
            ),
          ),
          Expanded(
            child: _StatementTabButton(
              label: _copy(context,
                  pt: 'Insights', en: 'Insights', es: 'Insights'),
              selected: selected == _StatementTab.insights,
              onTap: () => onSelected(_StatementTab.insights),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatementTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _StatementColors.surfaceHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Center(
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected
                  ? _StatementColors.textPrimary
                  : _StatementColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatementListSurface extends StatelessWidget {
  final TextEditingController queryController;
  final _StatementFilter selectedFilter;
  final ValueChanged<_StatementFilter> onFilterSelected;
  final List<Transaction> allTransactions;
  final List<Transaction> transactions;
  final String? expandedTransactionId;
  final ValueChanged<Transaction> onTransactionTap;
  final VoidCallback onClearFilters;

  const _StatementListSurface({
    required this.queryController,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.allTransactions,
    required this.transactions,
    required this.expandedTransactionId,
    required this.onTransactionTap,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatementSearchField(controller: queryController),
        const SizedBox(height: AppSpacing.base),
        _StatementFilterBar(
          selected: selectedFilter,
          onSelected: onFilterSelected,
        ),
        const SizedBox(height: AppSpacing.xl2),
        if (allTransactions.isEmpty)
          _StatementMessage(
            icon: KeroseneIcons.document,
            title: context.tr.financialStatementEmptyTitle,
            message: context.tr.financialStatementEmptyMessage,
          )
        else if (transactions.isEmpty)
          _StatementNoResults(onClearFilters: onClearFilters)
        else
          _GroupedTransactionList(
            transactions: transactions,
            expandedTransactionId: expandedTransactionId,
            onTransactionTap: onTransactionTap,
          ),
      ],
    );
  }
}

class _StatementSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _StatementSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(
          color: _StatementColors.textPrimary,
        ),
        cursorColor: _StatementColors.textPrimary,
        decoration: InputDecoration(
          hintText: context.tr.financialStatementSearchHint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: _StatementColors.textMuted,
          ),
          prefixIcon: const Icon(
            KeroseneIcons.search,
            color: _StatementColors.textMuted,
            size: 20,
          ),
          filled: true,
          fillColor: _StatementColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _StatementColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _StatementColors.borderHigh),
          ),
        ),
      ),
    );
  }
}

class _StatementFilterBar extends StatelessWidget {
  final _StatementFilter selected;
  final ValueChanged<_StatementFilter> onSelected;

  const _StatementFilterBar({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in _StatementFilter.values) ...[
            _StatementFilterChip(
              label: _filterLabel(context, filter),
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != _StatementFilter.values.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatementFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatementFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _StatementColors.surfaceHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _StatementColors.borderHigh
                  : _StatementColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected
                  ? _StatementColors.textPrimary
                  : _StatementColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupedTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final String? expandedTransactionId;
  final ValueChanged<Transaction> onTransactionTap;

  const _GroupedTransactionList({
    required this.transactions,
    required this.expandedTransactionId,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? currentDay;

    for (final transaction in transactions) {
      final local = transaction.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (currentDay != day) {
        currentDay = day;
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: AppSpacing.xl2));
        }
        children.add(_StatementDateHeader(label: _dateGroupLabel(day)));
        children.add(const SizedBox(height: AppSpacing.sm));
      } else {
        children.add(const SizedBox(height: AppSpacing.xs));
      }

      children.add(
        StatementTransactionCard(
          transaction: transaction,
          expanded: expandedTransactionId == transaction.id,
          mode: StatementTransactionCardMode.separated,
          onTap: () => onTransactionTap(transaction),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _StatementDateHeader extends StatelessWidget {
  final String label;

  const _StatementDateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: _StatementColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _StatementNoResults extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _StatementNoResults({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return _StatementMessage(
      icon: KeroseneIcons.searchUnavailable,
      title: context.tr.financialStatementNoResultsTitle,
      message: context.tr.financialStatementNoResultsMessage,
      action: OutlinedButton(
        onPressed: onClearFilters,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _StatementColors.textPrimary,
          side: const BorderSide(color: _StatementColors.borderHigh),
        ),
        child: Text(context.tr.financialStatementClearFilters),
      ),
    );
  }
}

class _StatementTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _StatementTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: KeroseneIcons.back, onPressed: onBack),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: _StatementColors.textPrimary, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: _StatementColors.surface,
          shape: const CircleBorder(),
          minimumSize: const Size.square(48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _StatementMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _StatementColors.textMuted, size: 30),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3Small.copyWith(
                color: _StatementColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: _StatementColors.textMuted,
                height: 1.35,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.base),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatementColors {
  static const background = AppColors.hexFF050505;
  static const surface = AppColors.hexFF0D0D0D;
  static const surfaceHigh = AppColors.hexFF161616;
  static const border = AppColors.hexFF222222;
  static const borderHigh = AppColors.hexFF525252;
  static const textPrimary = AppColors.hexFFFFFFFF;
  static const textSecondary = AppColors.hexFFB8BCC2;
  static const textMuted = AppColors.hexFF8A8A8E;
}

String _filterLabel(BuildContext context, _StatementFilter filter) {
  return switch (filter) {
    _StatementFilter.all => _copy(context, pt: 'Todos', en: 'All', es: 'Todos'),
    _StatementFilter.incoming =>
      _copy(context, pt: 'Recebidos', en: 'Received', es: 'Recibidos'),
    _StatementFilter.outgoing =>
      _copy(context, pt: 'Enviados', en: 'Sent', es: 'Enviados'),
    _StatementFilter.pending =>
      _copy(context, pt: 'Pendentes', en: 'Pending', es: 'Pendientes'),
    _StatementFilter.failed =>
      _copy(context, pt: 'Falhas', en: 'Failed', es: 'Fallidas'),
    _StatementFilter.onchain => 'On-chain',
    _StatementFilter.lightning => 'Lightning',
    _StatementFilter.internal =>
      _copy(context, pt: 'Internas', en: 'Internal', es: 'Internas'),
  };
}

String _transactionTitle(Transaction transaction) {
  if (transaction.isInternal) return 'Transferência interna';
  if (transaction.isLightning) return 'Pagamento Lightning';
  if (transaction.type == TransactionType.deposit) return 'Recebido';
  if (transaction.type == TransactionType.receive) return 'Recebido';
  if (transaction.type == TransactionType.withdrawal) return 'Saque on-chain';
  if (transaction.type == TransactionType.send) return 'Enviado';
  if (transaction.type == TransactionType.fee) return 'Taxa de rede';
  return 'Transação';
}

String _transactionRailLabel(Transaction transaction) {
  if (transaction.isInternal) return 'Transferência interna';
  if (transaction.isLightning) return 'Lightning';
  if (transaction.type == TransactionType.deposit) return 'Depósito on-chain';
  if (transaction.type == TransactionType.withdrawal) return 'Saque on-chain';
  return 'On-chain';
}

String _transactionStatusLabel(Transaction transaction) {
  return switch (transaction.status) {
    TransactionStatus.confirmed => 'Confirmado',
    TransactionStatus.confirming => '${transaction.confirmations} confirmações',
    TransactionStatus.pending => 'Pendente',
    TransactionStatus.failed => 'Falhou',
  };
}

String _dateGroupLabel(DateTime day) {
  final months = const [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  return '${day.day} de ${months[day.month - 1]} de ${day.year}';
}

String _copy(
  BuildContext context, {
  required String pt,
  required String en,
  required String es,
}) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
}

String statementTransactionTitle(Transaction transaction) {
  return _transactionTitle(transaction);
}

String statementTransactionRailLabel(Transaction transaction) {
  return _transactionRailLabel(transaction);
}

String statementTransactionStatusLabel(Transaction transaction) {
  return _transactionStatusLabel(transaction);
}

String statementTransactionSubtitle(Transaction transaction) {
  final local = transaction.timestamp.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute · ${_transactionRailLabel(transaction)} · '
      '${_transactionStatusLabel(transaction)}';
}

String statementTransactionCounterparty(Transaction transaction) {
  final displayName = transaction.isDebit
      ? transaction.receiverDisplayName
      : transaction.senderDisplayName;
  final address = resolvePrimaryTransactionAddress(transaction);
  final fallback = transaction.description?.trim() ?? '';
  final value = [
    displayName,
    address,
    fallback,
    'Carteira Kerosene',
  ].firstWhere((value) => (value ?? '').trim().isNotEmpty)!;
  return _shorten(value, head: transaction.isInternal ? 22 : 16, tail: 8);
}

String statementTransactionSignedBtc(Transaction transaction) {
  return MoneyDisplay.formatAmountFromBtc(
    btcAmount: transaction.signedAmountBTC,
    currency: Currency.btc,
    btcUsd: null,
    btcEur: null,
    btcBrl: null,
    signed: true,
  );
}

String _shorten(String value, {int head = 12, int tail = 6}) {
  final normalized = value.trim();
  if (normalized.length <= head + tail + 3) return normalized;
  return '${normalized.substring(0, head)}...'
      '${normalized.substring(normalized.length - tail)}';
}
