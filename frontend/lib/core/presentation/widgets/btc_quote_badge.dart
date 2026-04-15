import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

class BtcQuoteBadge extends StatelessWidget {
  final String value;
  final bool compact;

  const BtcQuoteBadge({
    super.key,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'BTC',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: AppTypography.fontFamily,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1.2 : 1.6,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: AppTypography.numericFontFamily,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
              fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
              fontSize: compact ? 13 : 14,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
