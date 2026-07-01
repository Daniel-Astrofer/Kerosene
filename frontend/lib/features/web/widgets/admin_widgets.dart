import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';

import 'package:kerosene/core/l10n/l10n_extension.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../theme/admin_typography.dart';
import 'package:kerosene/design_system/icons.dart';

class AdminResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const AdminResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 260,
    this.spacing = AdminTheme.spacingLg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / minItemWidth)
            .floor()
            .clamp(1, children.isEmpty ? 1 : children.length)
            .toInt();
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth.isFinite ? itemWidth : width,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final String? trend;
  final bool isPositiveTrend;
  final double? width;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.trend,
    this.isPositiveTrend = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: accentColor ?? AdminColors.textTertiary,
                ),
                const SizedBox(width: AdminTheme.spacingSm),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AdminTypography.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.spacingMd),
          Tooltip(
            message: value,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: AdminTypography.metric,
              ),
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: AdminTheme.spacingSm),
            Wrap(
              spacing: AdminTheme.spacingSm,
              runSpacing: AdminTheme.spacingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (trend != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend ? KeroseneIcons.up : KeroseneIcons.down,
                        size: 12,
                        color: isPositiveTrend
                            ? AdminColors.positive
                            : AdminColors.negative,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: AdminTypography.caption.copyWith(
                          color: isPositiveTrend
                              ? AdminColors.positive
                              : AdminColors.negative,
                        ),
                      ),
                    ],
                  ),
                if (subtitle != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      subtitle!,
                      style: AdminTypography.caption,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final AdminBadgeVariant variant;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.variant = AdminBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.spacingSm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: variant.backgroundColor,
        borderRadius: AdminTheme.borderRadiusXs,
        border: Border.all(color: variant.borderColor, width: 0.5),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AdminTypography.caption.copyWith(
          color: variant.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

enum AdminBadgeVariant {
  positive(
    AdminColors.positiveSubtle,
    AdminColors.positive,
    AdminColors.positive,
  ),
  negative(
    AdminColors.negativeSubtle,
    AdminColors.negative,
    AdminColors.negative,
  ),
  warning(AdminColors.warningSubtle, AdminColors.warning, AdminColors.warning),
  info(AdminColors.infoSubtle, AdminColors.info, AdminColors.info),
  neutral(
    AdminColors.surfaceElevated,
    AdminColors.border,
    AdminColors.textSecondary,
  ),
  accent(AdminColors.accentSubtle, AdminColors.accent, AdminColors.accent);

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const AdminBadgeVariant(
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  );
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminTheme.spacingLg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTypography.h2),
              if (subtitle != null) ...[
                const SizedBox(height: AdminTheme.spacingXs),
                Text(
                  subtitle!,
                  style: AdminTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 560 && trailing != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: AdminTheme.spacingMd),
                trailing!,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: titleBlock),
              if (trailing != null) trailing!,
            ],
          );
        },
      ),
    );
  }
}

class AdminSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AdminSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AdminColors.surfaceElevated,
        borderRadius: borderRadius ?? AdminTheme.borderRadiusSm,
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AdminErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              KeroseneIcons.error,
              size: 48,
              color: AdminColors.negative,
            ),
            const SizedBox(height: AdminTheme.spacingLg),
            Text(
              message,
              style: AdminTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AdminTheme.spacingLg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(KeroseneIcons.refresh, size: 16),
                label: Text(context.tr.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = KeroseneIcons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AdminColors.textDisabled),
            const SizedBox(height: AdminTheme.spacingLg),
            Text(title, style: AdminTypography.h4),
            if (subtitle != null) ...[
              const SizedBox(height: AdminTheme.spacingSm),
              Text(
                subtitle!,
                style: AdminTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: KeroseneMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminTheme.spacingMd,
          vertical: AdminTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.accentSubtle : Colors.transparent,
          border: Border.all(
            color: isSelected ? AdminColors.accent : AdminColors.border,
          ),
          borderRadius: AdminTheme.borderRadiusXs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AdminTypography.buttonSmall.copyWith(
            color: isSelected
                ? AdminColors.textPrimary
                : AdminColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const AdminPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.spacingLg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border.all(color: AdminColors.border),
        borderRadius: AdminTheme.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AdminColors.textTertiary),
                const SizedBox(width: AdminTheme.spacingSm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTypography.h4),
                    if (subtitle != null) ...[
                      const SizedBox(height: AdminTheme.spacingXs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AdminTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AdminTheme.spacingMd),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AdminTheme.spacingLg),
          child,
        ],
      ),
    );
  }
}

class AdminKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const AdminKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminTheme.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AdminTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AdminTheme.spacingMd),
          Flexible(
            flex: 2,
            child: Tooltip(
              message: value,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: (monospace
                        ? AdminTypography.mono
                        : AdminTypography.tableCell)
                    .copyWith(color: AdminColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminColors.backgroundElevated,
        border: Border.all(color: AdminColors.borderSubtle),
        borderRadius: AdminTheme.borderRadiusXs,
      ),
      child: ClipRRect(
        borderRadius: AdminTheme.borderRadiusXs,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AdminColors.tableHeader),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AdminColors.tableRowHover;
              }
              return null;
            }),
            headingRowHeight: 34,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 58,
            horizontalMargin: AdminTheme.spacingMd,
            columnSpacing: AdminTheme.spacingXl,
            columns: [
              for (final column in columns)
                DataColumn(
                  label: Text(column.toUpperCase(),
                      style: AdminTypography.tableHeader),
                ),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    for (final cell in row)
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: cell,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
