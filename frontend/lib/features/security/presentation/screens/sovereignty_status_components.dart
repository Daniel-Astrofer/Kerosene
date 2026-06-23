// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';

class SecurityInfoRow {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isMono;

  const SecurityInfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isMono = false,
  });
}

class SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const SummaryPill({
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color? accentColor;

  const SecurityMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent =
        accentColor ?? Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white50,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: resolvedAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class KfeReserveDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const KfeReserveDetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white70,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: highlight
                  ? AppColors.success
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class SecurityStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool statusOk;
  final String statusLabel;
  final List<SecurityInfoRow> rows;
  final Widget? extraWidget;

  const SecurityStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusOk,
    required this.statusLabel,
    required this.rows,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        statusOk ? AppColors.success : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: statusOk ? 0.16 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: (row.isMono
                            ? AppTypography.technicalMono(
                                textStyle: AppTypography.caption,
                              )
                            : AppTypography.bodySmall)
                        .copyWith(
                      color: row.isHighlight
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (rows.last != row) const SizedBox(height: 10),
          ],
          if (extraWidget != null) extraWidget!,
        ],
      ),
    );
  }
}
