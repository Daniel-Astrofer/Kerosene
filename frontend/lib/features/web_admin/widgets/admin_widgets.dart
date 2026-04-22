import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_theme.dart';

/// Enterprise KPI metric card for dashboard.
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
                Icon(icon, size: 16, color: accentColor ?? AdminColors.textTertiary),
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
          Text(
            value,
            style: AdminTypography.metric,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: AdminTheme.spacingSm),
            Row(
              children: [
                if (trend != null) ...[
                  Icon(
                    isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
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
                if (trend != null && subtitle != null)
                  const SizedBox(width: AdminTheme.spacingSm),
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AdminTypography.caption,
                      overflow: TextOverflow.ellipsis,
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

/// Status badge widget for transaction states.
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
        style: AdminTypography.caption.copyWith(
          color: variant.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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
  warning(
    AdminColors.warningSubtle,
    AdminColors.warning,
    AdminColors.warning,
  ),
  info(AdminColors.infoSubtle, AdminColors.info, AdminColors.info),
  neutral(AdminColors.surfaceElevated, AdminColors.border, AdminColors.textTertiary),
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

/// Section header with optional action button
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdminTypography.h2),
                if (subtitle != null) ...[
                  const SizedBox(height: AdminTheme.spacingXs),
                  Text(subtitle!, style: AdminTypography.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Enterprise loading skeleton for data cards
class AdminSkeleton extends StatefulWidget {
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
  State<AdminSkeleton> createState() => _AdminSkeletonState();
}

class _AdminSkeletonState extends State<AdminSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AdminColors.surfaceElevated.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? AdminTheme.borderRadiusSm,
          ),
        );
      },
    );
  }
}

/// Error state widget
class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AdminErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminTheme.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
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
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class AdminEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
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

/// Filter chip for table/dashboard filters
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
        duration: const Duration(milliseconds: 150),
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
          style: AdminTypography.buttonSmall.copyWith(
            color: isSelected ? AdminColors.accent : AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
