import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/app_primary_navigation.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_activity/domain/entities/transaction.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/statement_transaction_card.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_visuals.dart';
import 'package:kerosene/shared/widgets/bitcoin_refresh_indicator.dart';

enum _StatementFilter { all, incoming, outgoing, pending, failed }

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
  final GlobalKey<_StatementTopBarState> _topBarKey =
      GlobalKey<_StatementTopBarState>();
  _StatementFilter _filter = _StatementFilter.all;
  String _query = '';
  String? _expandedTransactionId;

  @override
  void initState() {
    super.initState();
    _expandedTransactionId = widget.initialTransactionId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await HapticFeedback.lightImpact();
    ref.invalidate(transactionHistoryProvider);
    await ref.read(transactionHistoryProvider.future);
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

  void _updateFilter(_StatementFilter value) {
    if (value == _filter) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filter = value;
      _expandedTransactionId = null;
    });
    _scrollToTop();
  }

  void _updateQuery(String value) {
    if (value == _query) return;
    setState(() {
      _query = value;
      _expandedTransactionId = null;
    });
    _scrollToTop();
  }

  void _clearStatementFilters() {
    if (_filter == _StatementFilter.all && _query.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    _topBarKey.currentState?.clearSearch();
    setState(() {
      _filter = _StatementFilter.all;
      _query = '';
      _expandedTransactionId = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: KeroseneMotion.short,
      curve: KeroseneMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 132.0;

    if (historyAsync.isLoading && !historyAsync.hasValue) {
      return const KeroseneLogoLoadingView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    BitcoinRefreshIndicator(onRefresh: _refreshData),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: _StatementTopBar(
                          key: _topBarKey,
                          onBack: _handleBack,
                          onSearchChanged: _updateQuery,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Text(
                          context.tr.financialStatementTitle,
                          style: AppTypography.newsreader(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: _StatementTabs(
                          selected: _filter,
                          onChanged: _updateFilter,
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
                        final rows = _filtered(context, transactions);
                        if (rows.isEmpty) {
                          final hasActiveNarrowing = transactions.isNotEmpty &&
                              (_filter != _StatementFilter.all ||
                                  _query.trim().isNotEmpty);
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _StatementMessage(
                              icon: hasActiveNarrowing
                                  ? KeroseneIcons.searchUnavailable
                                  : KeroseneIcons.history,
                              title: hasActiveNarrowing
                                  ? context.tr.financialStatementNoResultsTitle
                                  : context.tr.financialStatementEmptyTitle,
                              message: hasActiveNarrowing
                                  ? context
                                      .tr.financialStatementNoResultsMessage
                                  : context.tr.financialStatementEmptyMessage,
                              actionLabel: hasActiveNarrowing
                                  ? context.tr.financialStatementClearFilters
                                  : null,
                              onAction: hasActiveNarrowing
                                  ? _clearStatementFilters
                                  : null,
                            ),
                          );
                        }

                        final expandedIndex = _expandedTransactionId == null
                            ? -1
                            : rows.indexWhere(
                                (tx) => tx.id == _expandedTransactionId,
                              );

                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            bottomPadding,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: StatementTransactionScrollStack(
                              key: ValueKey(
                                'statement-stack-${_filter.name}-${_query.trim()}-${rows.length}',
                              ),
                              itemCount: rows.length,
                              itemExtent: 174,
                              expandedItemExtent: 376,
                              expandedIndex:
                                  expandedIndex >= 0 ? expandedIndex : null,
                              itemGap: 12,
                              stackGap: 114,
                              topAnchorOffset: 12,
                              collapseStartFraction: 0.75,
                              itemBuilder: (context, index) =>
                                  _buildTransactionCard(rows[index]),
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

  Widget _buildTransactionCard(
    Transaction tx, {
    bool forceExpanded = false,
  }) {
    final expanded = forceExpanded || tx.id == _expandedTransactionId;
    return StatementTransactionCard(
      transaction: tx,
      expanded: expanded,
      mode: StatementTransactionCardMode.stacked,
      onTap: () {
        HapticFeedback.selectionClick();
        if (forceExpanded) return;
        setState(() {
          _expandedTransactionId = expanded ? null : tx.id;
        });
      },
    );
  }

  List<Transaction> _filtered(BuildContext context, List<Transaction> source) {
    final query = _normalizeStatementSearchText(_query);
    final rows = source.where((tx) {
      final directionMatches = switch (_filter) {
        _StatementFilter.all => true,
        _StatementFilter.incoming => tx.isCredit,
        _StatementFilter.outgoing => tx.isDebit,
        _StatementFilter.pending => tx.status == TransactionStatus.pending ||
            tx.status == TransactionStatus.confirming,
        _StatementFilter.failed => tx.status == TransactionStatus.failed,
      };
      if (!directionMatches) return false;
      if (query.isEmpty) return true;
      final haystack = _statementSearchText(context, tx);
      return haystack.contains(query);
    }).toList();
    rows.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return rows;
  }

  String _statementSearchText(BuildContext context, Transaction tx) {
    final visual = TransactionVisualSpec.fromTransaction(tx);
    final l10n = context.tr;
    final timestamp = tx.timestamp.toLocal();
    final status = switch (tx.status) {
      TransactionStatus.confirmed => l10n.confirmed,
      TransactionStatus.confirming => l10n.confirming,
      TransactionStatus.pending => l10n.pending,
      TransactionStatus.failed => l10n.failed,
    };
    final visibleRail = tx.isInternal
        ? 'Transação Interna Internal transfer Kerosene'
        : tx.isLightning
            ? 'Lightning'
            : _statementOnchainTitleMatches(visual)
                ? 'Onchain On-chain Bitcoin'
                : visual.localizedLabel(context);
    final directionLabel = tx.isDebit
        ? l10n.financialStatementFilterOutgoing
        : l10n.financialStatementFilterIncoming;
    final signedBtc = tx.signedAmountBTC.toStringAsFixed(8);
    final unsignedBtc = tx.amountBTC.toStringAsFixed(8);
    final dateTokens = [
      timestamp.toIso8601String(),
      '${timestamp.day.toString().padLeft(2, '0')}/'
          '${timestamp.month.toString().padLeft(2, '0')}/'
          '${timestamp.year}',
      '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}',
    ];

    return _normalizeStatementSearchText(
      [
        tx.id,
        tx.fromAddress,
        tx.toAddress,
        tx.description,
        tx.blockchainTxid,
        tx.externalReference,
        tx.invoiceId,
        tx.paymentHash,
        visual.localizedLabel(context),
        visibleRail,
        directionLabel,
        status,
        signedBtc,
        unsignedBtc,
        tx.amountSatoshis.toString(),
        tx.feeSatoshis.toString(),
        '${tx.amountSatoshis} sats',
        '${tx.feeSatoshis} sats',
        ...dateTokens,
      ].whereType<String>().join(' '),
    );
  }

  bool _statementOnchainTitleMatches(TransactionVisualSpec visual) {
    return visual.family == TransactionVisualFamily.onChain ||
        visual.family == TransactionVisualFamily.deposit ||
        visual.family == TransactionVisualFamily.withdrawal;
  }
}

String _normalizeStatementSearchText(String value) {
  var normalized = value.trim().toLowerCase();
  const replacements = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }
  return normalized;
}

class _StatementTopBar extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;

  const _StatementTopBar({
    super.key,
    required this.onBack,
    required this.onSearchChanged,
  });

  @override
  State<_StatementTopBar> createState() => _StatementTopBarState();
}

class _StatementTopBarState extends State<_StatementTopBar> {
  final TextEditingController _controller = TextEditingController();
  bool _searching = false;
  String _searchText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void clearSearch() {
    _controller.clear();
    if (!_searching && _searchText.isEmpty) return;
    setState(() {
      _searchText = '';
      _searching = false;
    });
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchText = value);
    widget.onSearchChanged(value);
  }

  void _clearSearchText() {
    if (_controller.text.isEmpty && _searchText.isEmpty) return;
    _controller.clear();
    widget.onSearchChanged('');
    setState(() => _searchText = '');
  }

  void _closeSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    setState(() {
      _searchText = '';
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return Row(
        children: [
          _RoundIconButton(
            icon: KeroseneIcons.chevronLeft,
            onPressed: _closeSearch,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _handleSearchChanged,
              style: AppTypography.inter(color: Colors.white, fontSize: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                isDense: true,
                hintText: context.tr.financialStatementSearchHint,
                hintStyle: AppTypography.inter(
                  color: AppColors.hexFF8A8A8E,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.hexFF1C1C1E,
                suffixIcon: _searchText.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        onPressed: _clearSearchText,
                        icon: const Icon(
                          KeroseneIcons.close,
                          color: AppColors.hexFFB8B8BC,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundIconButton(icon: KeroseneIcons.back, onPressed: widget.onBack),
        _RoundIconButton(
          icon: KeroseneIcons.search,
          onPressed: () => setState(() => _searching = true),
        ),
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
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.hexFF1C1C1E,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _StatementTabs extends StatelessWidget {
  final _StatementFilter selected;
  final ValueChanged<_StatementFilter> onChanged;

  const _StatementTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.hexFF1C1C1E,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _StatementTab(
              label: context.tr.financialStatementFilterAll,
              selected: selected == _StatementFilter.all,
              onTap: () => onChanged(_StatementFilter.all),
            ),
            _StatementTab(
              label: context.tr.financialStatementFilterIncoming,
              selected: selected == _StatementFilter.incoming,
              onTap: () => onChanged(_StatementFilter.incoming),
            ),
            _StatementTab(
              label: context.tr.financialStatementFilterOutgoing,
              selected: selected == _StatementFilter.outgoing,
              onTap: () => onChanged(_StatementFilter.outgoing),
            ),
            _StatementTab(
              label: context.tr.financialStatementFilterPending,
              selected: selected == _StatementFilter.pending,
              onTap: () => onChanged(_StatementFilter.pending),
            ),
            _StatementTab(
              label: context.tr.financialStatementFilterFailed,
              selected: selected == _StatementFilter.failed,
              onTap: () => onChanged(_StatementFilter.failed),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatementTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: KeroseneMotion.short,
        curve: KeroseneMotion.standard,
        constraints: const BoxConstraints(minWidth: 76),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.hexFF2C2C2E : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.inter(
            color: selected ? Colors.white : AppColors.hexFF8A8A8E,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatementMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.64), size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: AppColors.hexFF8A8A8E,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(KeroseneIcons.closeCircle, size: 16),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  textStyle: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
