import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_theme.dart';

/// Enterprise data table with sorting, pagination and status display.
class AdminDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<AdminColumn<T>> columns;
  final int rowsPerPage;
  final String? emptyMessage;
  final bool isLoading;

  const AdminDataTable({
    super.key,
    required this.data,
    required this.columns,
    this.rowsPerPage = 25,
    this.emptyMessage,
    this.isLoading = false,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late List<T> _sortedData;

  @override
  void initState() {
    super.initState();
    _sortedData = List.of(widget.data);
  }

  @override
  void didUpdateWidget(covariant AdminDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _sortedData = List.of(widget.data);
      _currentPage = 0;
    }
  }

  int get _totalPages =>
      (_sortedData.length / widget.rowsPerPage).ceil().clamp(1, 9999);

  List<T> get _pageData {
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, _sortedData.length);
    if (start >= _sortedData.length) return [];
    return _sortedData.sublist(start, end);
  }

  void _sort(int columnIndex, bool ascending) {
    final col = widget.columns[columnIndex];
    if (col.sortKey == null) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortedData.sort((a, b) {
        final va = col.sortKey!(a);
        final vb = col.sortKey!(b);
        return ascending ? va.compareTo(vb) : vb.compareTo(va);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          border: Border.all(color: AdminColors.border),
          borderRadius: AdminTheme.borderRadiusSm,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AdminColors.textTertiary,
            ),
          ),
        ),
      );
    }

    if (_sortedData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          border: Border.all(color: AdminColors.border),
          borderRadius: AdminTheme.borderRadiusSm,
        ),
        child: Center(
          child: Text(
            widget.emptyMessage ?? 'No data available',
            style: AdminTypography.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AdminColors.border),
            borderRadius: AdminTheme.borderRadiusSm,
          ),
          child: ClipRRect(
            borderRadius: AdminTheme.borderRadiusSm,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowHeight: 44,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 64,
                      horizontalMargin: AdminTheme.spacingLg,
                      columnSpacing: AdminTheme.spacingXl,
                      headingRowColor: WidgetStateProperty.all(
                        AdminColors.tableHeader,
                      ),
                      columns: widget.columns.asMap().entries.map((entry) {
                        return DataColumn(
                          label: Text(
                            entry.value.header.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminTypography.tableHeader,
                          ),
                          onSort: entry.value.sortKey != null ? _sort : null,
                          numeric: entry.value.isNumeric,
                        );
                      }).toList(),
                      rows: _pageData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return AdminColors.tableRowHover;
                            }
                            return index.isOdd
                                ? AdminColors.tableRowAlt
                                : Colors.transparent;
                          }),
                          cells: widget.columns.map((col) {
                            return DataCell(col.cellBuilder(item));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: AdminTheme.spacingMd),
          _Pagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _sortedData.length,
            rowsPerPage: widget.rowsPerPage,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),
        ],
      ],
    );
  }
}

class AdminColumn<T> {
  final String header;
  final Widget Function(T item) cellBuilder;
  final Comparable Function(T item)? sortKey;
  final bool isNumeric;

  const AdminColumn({
    required this.header,
    required this.cellBuilder,
    this.sortKey,
    this.isNumeric = false,
  });
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = currentPage * rowsPerPage + 1;
    final end = ((currentPage + 1) * rowsPerPage).clamp(0, totalItems);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AdminTheme.spacingLg,
      runSpacing: AdminTheme.spacingSm,
      children: [
        Text(
          'Showing $start–$end of $totalItems',
          style: AdminTypography.caption,
        ),
        Row(
          children: [
            _PageButton(
              icon: Icons.chevron_left,
              enabled: currentPage > 0,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            const SizedBox(width: AdminTheme.spacingSm),
            Text(
              '${currentPage + 1} / $totalPages',
              style: AdminTypography.caption,
            ),
            const SizedBox(width: AdminTheme.spacingSm),
            _PageButton(
              icon: Icons.chevron_right,
              enabled: currentPage < totalPages - 1,
              onTap: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AdminTheme.borderRadiusXs,
      child: Container(
        padding: const EdgeInsets.all(AdminTheme.spacingXs),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? AdminColors.border : AdminColors.borderSubtle,
          ),
          borderRadius: AdminTheme.borderRadiusXs,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AdminColors.textSecondary : AdminColors.textDisabled,
        ),
      ),
    );
  }
}
