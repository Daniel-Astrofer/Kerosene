import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_typography.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/admin_data_table.dart';

/// Transactions module — full list with filters, sorting, and detail view.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(adminLedgerHistoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminTheme.spacingXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Transactions',
            subtitle: 'Complete history of all ledger operations',
          ),

          // Filters
          _buildFilters(),
          const SizedBox(height: AdminTheme.spacingLg),

          // Table
          historyAsync.when(
            data: (txs) {
              final filtered = _applyFilters(txs);
              return AdminDataTable<Transaction>(
                data: filtered,
                columns: _buildColumns(),
                emptyMessage: 'No transactions match the current filters',
              );
            },
            loading: () => const AdminDataTable<Transaction>(
              data: [],
              columns: [],
              isLoading: true,
            ),
            error: (e, _) => AdminErrorState(
              message: 'Failed to load transactions: $e',
              onRetry: () => ref.invalidate(adminLedgerHistoryProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: AdminTypography.bodyMedium.copyWith(
              color: AdminColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by ID, address, description...',
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AdminColors.textTertiary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AdminTheme.spacingLg,
                vertical: AdminTheme.spacingMd,
              ),
            ),
          ),
          const SizedBox(height: AdminTheme.spacingMd),

          // Type filter
          Row(
            children: [
              Text('TYPE', style: AdminTypography.label),
              const SizedBox(width: AdminTheme.spacingMd),
              ..._buildTypeFilters(),
              const SizedBox(width: AdminTheme.spacingXl),
              Text('STATUS', style: AdminTypography.label),
              const SizedBox(width: AdminTheme.spacingMd),
              ..._buildStatusFilters(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeFilters() {
    final types = {
      'all': 'All',
      'internal': 'Internal',
      'lightning': 'Lightning',
      'onchain': 'On-chain',
    };
    return types.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(right: AdminTheme.spacingSm),
        child: AdminFilterChip(
          label: e.value,
          isSelected: _typeFilter == e.key,
          onTap: () => setState(() => _typeFilter = e.key),
        ),
      );
    }).toList();
  }

  List<Widget> _buildStatusFilters() {
    final statuses = {
      'all': 'All',
      'confirmed': 'Confirmed',
      'pending': 'Pending',
      'failed': 'Failed',
    };
    return statuses.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(right: AdminTheme.spacingSm),
        child: AdminFilterChip(
          label: e.value,
          isSelected: _statusFilter == e.key,
          onTap: () => setState(() => _statusFilter = e.key),
        ),
      );
    }).toList();
  }

  List<Transaction> _applyFilters(List<Transaction> txs) {
    var result = txs;

    // Type filter
    if (_typeFilter == 'internal') {
      result = result.where((tx) => tx.isInternal).toList();
    } else if (_typeFilter == 'lightning') {
      result = result.where((tx) => tx.isLightning).toList();
    } else if (_typeFilter == 'onchain') {
      result =
          result.where((tx) => !tx.isInternal && !tx.isLightning).toList();
    }

    // Status filter
    if (_statusFilter == 'confirmed') {
      result = result
          .where((tx) => tx.status == TransactionStatus.confirmed)
          .toList();
    } else if (_statusFilter == 'pending') {
      result = result
          .where((tx) =>
              tx.status == TransactionStatus.pending ||
              tx.status == TransactionStatus.confirming)
          .toList();
    } else if (_statusFilter == 'failed') {
      result = result
          .where((tx) => tx.status == TransactionStatus.failed)
          .toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((tx) {
        return tx.id.toLowerCase().contains(q) ||
            tx.fromAddress.toLowerCase().contains(q) ||
            tx.toAddress.toLowerCase().contains(q) ||
            (tx.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  List<AdminColumn<Transaction>> _buildColumns() {
    return [
      AdminColumn<Transaction>(
        header: 'ID',
        cellBuilder: (tx) => SelectableText(
          tx.id.length > 12 ? '${tx.id.substring(0, 12)}...' : tx.id,
          style: AdminTypography.tableCellMono,
        ),
        sortKey: (tx) => tx.id,
      ),
      AdminColumn<Transaction>(
        header: 'Type',
        cellBuilder: (tx) {
          final label = tx.isLightning
              ? 'Lightning'
              : tx.isInternal
                  ? 'Internal'
                  : 'On-chain';
          return AdminStatusBadge(
            label: label,
            variant: tx.isLightning
                ? AdminBadgeVariant.info
                : tx.isInternal
                    ? AdminBadgeVariant.accent
                    : AdminBadgeVariant.neutral,
          );
        },
      ),
      AdminColumn<Transaction>(
        header: 'Direction',
        cellBuilder: (tx) {
          final isSend = tx.type == TransactionType.send ||
              tx.type == TransactionType.withdrawal;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSend ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isSend ? AdminColors.negative : AdminColors.positive,
              ),
              const SizedBox(width: 4),
              Text(
                tx.type.displayName,
                style: AdminTypography.tableCell,
              ),
            ],
          );
        },
      ),
      AdminColumn<Transaction>(
        header: 'Amount (BTC)',
        isNumeric: true,
        cellBuilder: (tx) => Text(
          tx.amountBTC.toStringAsFixed(8),
          style: AdminTypography.tableCellMono,
        ),
        sortKey: (tx) => tx.amountBTC,
      ),
      AdminColumn<Transaction>(
        header: 'Fee (BTC)',
        isNumeric: true,
        cellBuilder: (tx) => Text(
          tx.feeBTC.toStringAsFixed(8),
          style: AdminTypography.tableCellMono,
        ),
        sortKey: (tx) => tx.feeBTC,
      ),
      AdminColumn<Transaction>(
        header: 'Status',
        cellBuilder: (tx) => AdminStatusBadge(
          label: tx.status.displayName,
          variant: _statusVariant(tx.status),
        ),
      ),
      AdminColumn<Transaction>(
        header: 'Date',
        cellBuilder: (tx) => Text(
          _formatDate(tx.timestamp),
          style: AdminTypography.tableCell,
        ),
        sortKey: (tx) => tx.timestamp.millisecondsSinceEpoch,
      ),
      AdminColumn<Transaction>(
        header: 'From',
        cellBuilder: (tx) => SelectableText(
          tx.fromAddress.length > 16
              ? '${tx.fromAddress.substring(0, 16)}...'
              : tx.fromAddress,
          style: AdminTypography.tableCell,
        ),
      ),
      AdminColumn<Transaction>(
        header: 'To',
        cellBuilder: (tx) => SelectableText(
          tx.toAddress.length > 16
              ? '${tx.toAddress.substring(0, 16)}...'
              : tx.toAddress,
          style: AdminTypography.tableCell,
        ),
      ),
    ];
  }

  AdminBadgeVariant _statusVariant(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return AdminBadgeVariant.positive;
      case TransactionStatus.pending:
      case TransactionStatus.confirming:
        return AdminBadgeVariant.warning;
      case TransactionStatus.failed:
        return AdminBadgeVariant.negative;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
