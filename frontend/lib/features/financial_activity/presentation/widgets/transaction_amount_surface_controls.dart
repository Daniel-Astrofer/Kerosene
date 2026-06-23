import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';

import 'transaction_amount_surface.dart';

Duration _surfaceDuration(bool disabled, Duration duration) =>
    disabled ? Duration.zero : duration;

class TransactionDetailRows extends StatelessWidget {
  final List<TransactionDetailRowData> details;
  final int loadingRows;
  final Color textColor;
  final Color mutedTextColor;
  final Color tertiaryTextColor;
  final bool disableAnimations;

  const TransactionDetailRows({
    super.key,
    required this.details,
    this.loadingRows = 0,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < details.length; index++) ...[
          TransactionDetailRow(
            detail: details[index],
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            tertiaryTextColor: tertiaryTextColor,
            disableAnimations: disableAnimations,
          ),
          if (index != details.length - 1 || loadingRows > 0)
            const SizedBox(height: 16),
        ],
        for (var index = 0; index < loadingRows; index++) ...[
          TransactionDetailSkeletonRow(
            key: ValueKey('transaction-detail-loading-$index'),
            mutedTextColor: mutedTextColor,
            tertiaryTextColor: tertiaryTextColor,
          ),
          if (index != loadingRows - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class TransactionDetailRow extends StatelessWidget {
  final TransactionDetailRowData detail;
  final Color textColor;
  final Color mutedTextColor;
  final Color tertiaryTextColor;
  final bool disableAnimations;

  const TransactionDetailRow({
    super.key,
    required this.detail,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.25,
          letterSpacing: 0,
        );

    return Row(
      crossAxisAlignment: detail.secondaryValue == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            detail.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedTextColor,
                  fontSize: 15,
                  height: 1.3,
                  letterSpacing: 0,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration:
                      _surfaceDuration(disableAnimations, KeroseneMotion.short),
                  child: detail.loading
                      ? const _TransactionSkeletonLine(
                          key: ValueKey('transaction-row-value-loading'),
                          width: 76,
                          height: 13,
                        )
                      : Text(
                          detail.value,
                          key: ValueKey('${detail.label}:${detail.value}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: valueStyle,
                        ),
                ),
                if (!detail.loading && detail.secondaryValue != null) ...[
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: _surfaceDuration(
                        disableAnimations, KeroseneMotion.short),
                    child: Text(
                      detail.secondaryValue!,
                      key: ValueKey('${detail.label}:${detail.secondaryValue}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tertiaryTextColor,
                            fontSize: 13,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TransactionDetailSkeletonRow extends StatelessWidget {
  final Color mutedTextColor;
  final Color tertiaryTextColor;

  const TransactionDetailSkeletonRow({
    super.key,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TransactionSkeletonLine(
          width: 92,
          height: 13,
          color: tertiaryTextColor.withValues(alpha: 0.32),
        ),
        const SizedBox(width: 16),
        const Spacer(),
        _TransactionSkeletonLine(
          width: 82,
          height: 13,
          color: mutedTextColor.withValues(alpha: 0.34),
        ),
      ],
    );
  }
}

class _TransactionSkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const _TransactionSkeletonLine({
    super.key,
    required this.width,
    required this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.hexFF2C2C2E,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class TransactionKeypad extends StatelessWidget {
  final TransactionKeypadMode mode;
  final ValueChanged<String> onKeyTap;
  final Color textColor;
  final Color mutedTextColor;
  final Color pressedColor;

  const TransactionKeypad({
    super.key,
    required this.mode,
    required this.onKeyTap,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.pressedColor = AppColors.hexFF111111,
  });

  @override
  Widget build(BuildContext context) {
    final compactHeight = MediaQuery.sizeOf(context).height < 720;
    final keyHeight = compactHeight ? 50.0 : 56.0;
    final rows = mode == TransactionKeypadMode.integer
        ? const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', '←'],
          ]
        : const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.', '0', '←'],
          ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          children: [
            for (final row in rows)
              Row(
                children: [
                  for (final key in row)
                    key.isEmpty
                        ? Expanded(child: SizedBox(height: keyHeight))
                        : Expanded(
                            child: _TransactionKeyButton(
                              key: ValueKey('transaction-keypad-$key'),
                              keyValue: key,
                              height: keyHeight,
                              textColor: textColor,
                              mutedTextColor: mutedTextColor,
                              pressedColor: pressedColor,
                              onTap: onKeyTap,
                            ),
                          ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionKeyButton extends StatelessWidget {
  final String keyValue;
  final double height;
  final Color textColor;
  final Color mutedTextColor;
  final Color pressedColor;
  final ValueChanged<String> onTap;

  const _TransactionKeyButton({
    super.key,
    required this.keyValue,
    required this.height,
    required this.textColor,
    required this.mutedTextColor,
    required this.pressedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isBackspace = keyValue == '←';
    final label = keyValue == '.' ? ',' : keyValue;
    final backspaceTooltip =
        MaterialLocalizations.of(context).deleteButtonTooltip;
    final foregroundColor = isBackspace ? mutedTextColor : textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: SizedBox(
        height: height,
        child: TextButton(
          onPressed: () => onTap(keyValue),
          style: ButtonStyle(
            animationDuration:
                _surfaceDuration(disableAnimations, KeroseneMotion.fast),
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return pressedColor;
              }
              if (states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.hovered)) {
                return pressedColor.withValues(alpha: 0.56);
              }
              return Colors.transparent;
            }),
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(height)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              AppTypography.inter(
                textStyle: AppTypography.h3,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          child: isBackspace
              ? Tooltip(
                  message: backspaceTooltip,
                  child: ExcludeSemantics(
                    child: Icon(
                      KeroseneIcons.backspace,
                      color: mutedTextColor,
                      size: 22,
                    ),
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class TransactionPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool disableAnimations;

  const TransactionPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    final onPressed = enabled && !isLoading ? onTap : null;

    return AnimatedOpacity(
      duration: _surfaceDuration(disableAnimations, KeroseneMotion.short),
      opacity: enabled ? 1 : 0.72,
      child: AnimatedContainer(
        duration: _surfaceDuration(disableAnimations, KeroseneMotion.short),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (enabled && !isLoading)
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: FilledButton(
          key: const ValueKey('transaction-amount-surface-cta'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.22),
            disabledForegroundColor: backgroundColor.withValues(alpha: 0.42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
          ),
          child: AnimatedSwitcher(
            duration: _surfaceDuration(disableAnimations, KeroseneMotion.short),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  )
                : Text(
                    label.toUpperCase(),
                    key: ValueKey(label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}

class TransactionNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  const TransactionNotice({
    super.key,
    required this.text,
    this.icon = KeroseneIcons.info,
    this.textColor = AppColors.hexFFFFE6B0,
    this.borderColor = AppColors.hexFF5A4217,
    this.backgroundColor = AppColors.hexFF211A0D,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
