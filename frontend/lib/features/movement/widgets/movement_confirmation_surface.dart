import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';

class MovementConfirmationRow {
  final String label;
  final String value;
  final bool numeric;
  final bool technical;

  const MovementConfirmationRow({
    required this.label,
    required this.value,
    this.numeric = false,
    this.technical = false,
  });
}

class MovementConfirmationSurface extends StatelessWidget {
  final String title;
  final String amountLabel;
  final String supportingLabel;
  final List<MovementConfirmationRow> rows;
  final Widget? leading;
  final bool compactRows;

  const MovementConfirmationSurface({
    super.key,
    required this.title,
    required this.amountLabel,
    this.supportingLabel = '',
    required this.rows,
    this.leading,
    this.compactRows = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final titleFontSize = width < 360 ? 32.0 : 38.0;
        final amountFontSize = width < 360 ? 42.0 : 52.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.newsreader(
                color: AppColors.hexFFFFFFFF,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w300,
                height: 1.08,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 38),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amountLabel,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: AppColors.hexFFFFFFFF,
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.02,
                  letterSpacing: 3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (supportingLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                supportingLabel,
                textAlign: TextAlign.right,
                style: AppTypography.inter(
                  color: AppColors.hexFFA3A3A3,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ],
            const SizedBox(height: 38),
            for (final row in rows)
              _MovementConfirmationDetailRow(
                row: row,
                compact: compactRows,
              ),
          ],
        );
      },
    );
  }
}

class _MovementConfirmationDetailRow extends StatelessWidget {
  final MovementConfirmationRow row;
  final bool compact;

  const _MovementConfirmationDetailRow({
    required this.row,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.inter(
      color: AppColors.hexFFFFFFFF,
      fontSize: compact ? 13.5 : 14,
      fontWeight: row.numeric ? FontWeight.w600 : FontWeight.w300,
      height: 1.3,
      letterSpacing: row.numeric && !row.technical ? 1.4 : 0,
      fontFeatures: row.numeric ? const [FontFeature.tabularFigures()] : null,
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 11 : 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hexFF2A2A2A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 118 : 132,
            child: Text(
              row.label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: AppColors.hexFFA3A3A3,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w300,
                height: 1.2,
                letterSpacing: compact ? 1.1 : 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                row.value,
                maxLines: row.technical ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
