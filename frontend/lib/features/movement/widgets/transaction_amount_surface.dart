import 'package:kerosene/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'transaction_amount_surface_controls.dart';

export 'transaction_amount_surface_controls.dart';

enum TransactionAmountDirection { send, receive, neutral }

enum TransactionKeypadMode { decimal, integer }

Duration _surfaceDuration(bool disabled, Duration duration) =>
    disabled ? Duration.zero : duration;

class TransactionPartyData {
  final String prefix;
  final String title;
  final String subtitle;
  final IconData icon;

  const TransactionPartyData({
    required this.prefix,
    required this.title,
    required this.subtitle,
    this.icon = KeroseneIcons.user,
  });
}

class TransactionDetailRowData {
  final String label;
  final String value;
  final String? secondaryValue;
  final bool loading;

  const TransactionDetailRowData({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.loading = false,
  });
}

class TransactionKeypadConfig {
  final TransactionKeypadMode mode;
  final bool visible;
  final ValueChanged<String>? onKeyTap;

  const TransactionKeypadConfig({
    this.mode = TransactionKeypadMode.decimal,
    this.visible = true,
    this.onKeyTap,
  });
}

class TransactionAmountSurface extends StatelessWidget {
  final String? title;
  final TransactionAmountDirection direction;
  final String? rail;
  final String? connectionLabel;
  final List<TransactionPartyData> parties;
  final TransactionPartyData? sourceParty;
  final TransactionPartyData? destinationParty;
  final String amountLabel;
  final String unitLabel;
  final String? fiatReference;
  final List<TransactionDetailRowData> details;
  final int loadingRows;
  final bool editable;
  final bool showKeypad;
  final bool amountMuted;
  final bool isBusy;
  final bool ctaEnabled;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final ValueChanged<String>? onKeyTap;
  final TransactionKeypadMode keypadMode;
  final TransactionKeypadConfig? keypadConfig;
  final Widget? topContent;
  final Widget? bottomContent;
  final List<Widget> notices;
  final List<String> warnings;
  final VoidCallback? onAmountTap;
  final VoidCallback? onFiatReferenceTap;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool fillAvailableHeight;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color tertiaryTextColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryButtonColor;
  final Color primaryButtonTextColor;

  const TransactionAmountSurface({
    super.key,
    this.title,
    this.direction = TransactionAmountDirection.neutral,
    this.rail,
    this.connectionLabel,
    List<TransactionPartyData>? parties,
    this.sourceParty,
    this.destinationParty,
    required this.amountLabel,
    required this.unitLabel,
    this.fiatReference,
    List<TransactionDetailRowData>? details,
    List<TransactionDetailRowData>? detailRows,
    this.loadingRows = 0,
    this.editable = true,
    this.showKeypad = true,
    this.amountMuted = false,
    this.isBusy = false,
    this.ctaEnabled = true,
    this.ctaLabel,
    VoidCallback? onCta,
    VoidCallback? onContinue,
    this.onKeyTap,
    this.keypadMode = TransactionKeypadMode.decimal,
    this.keypadConfig,
    this.topContent,
    this.bottomContent,
    this.notices = const [],
    this.warnings = const [],
    this.onAmountTap,
    this.onFiatReferenceTap,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 28),
    this.maxWidth = 620,
    this.fillAvailableHeight = true,
    this.backgroundColor = AppColors.hexFF000000,
    this.textColor = AppColors.hexFFFFFFFF,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
    this.surfaceColor = AppColors.hexFF111111,
    this.borderColor = AppColors.hexFF2C2C2E,
    this.primaryButtonColor = AppColors.hexFFFFFFFF,
    this.primaryButtonTextColor = AppColors.hexFF000000,
  })  : parties = parties ?? const [],
        details = detailRows ?? details ?? const [],
        onCta = onContinue ?? onCta;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.maxHeight.isFinite;
          final minHeight = fillAvailableHeight && hasBoundedHeight
              ? constraints.maxHeight
              : 0.0;

          final content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: _buildContent(context, disableAnimations),
                ),
              ),
            ),
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: padding,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool disableAnimations) {
    final height = MediaQuery.sizeOf(context).height;
    final compactHeight = height < 720;
    final amountGap = compactHeight ? 24.0 : 34.0;
    final detailGap = compactHeight ? 20.0 : 28.0;
    final keypadGap = compactHeight ? 18.0 : 24.0;
    final resolvedParties = <TransactionPartyData>[
      if (sourceParty != null) sourceParty!,
      if (destinationParty != null) destinationParty!,
      ...parties,
    ];
    final resolvedConnectionLabel = _resolvedConnectionLabel();
    final resolvedKeypad = keypadConfig;
    final effectiveOnKeyTap = resolvedKeypad?.onKeyTap ?? onKeyTap;
    final effectiveKeypadMode = resolvedKeypad?.mode ?? keypadMode;
    final effectiveShowKeypad = editable &&
        showKeypad &&
        (resolvedKeypad?.visible ?? true) &&
        effectiveOnKeyTap != null;
    final hasHeader = (title != null && title!.trim().isNotEmpty) ||
        (rail != null && rail!.trim().isNotEmpty);
    final hasDetails = details.isNotEmpty || loadingRows > 0;

    final children = <Widget>[
      if (hasHeader) ...[
        _AnimatedEntrance(
          disabled: disableAnimations,
          delay: Duration.zero,
          child: TransactionSurfaceHeader(
            title: title,
            direction: direction,
            rail: rail,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(height: 18),
      ],
      if (topContent != null) ...[
        topContent!,
        const SizedBox(height: 18),
      ],
      for (var index = 0; index < resolvedParties.length; index++) ...[
        _AnimatedEntrance(
          disabled: disableAnimations,
          delay: KeroseneMotion.stagger(
            index,
            step: KeroseneMotion.surfaceStagger,
          ),
          child: TransactionPartyRow(
            data: resolvedParties[index],
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            tertiaryTextColor: tertiaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
        ),
        if (index != resolvedParties.length - 1) ...[
          const SizedBox(height: 10),
          _AnimatedEntrance(
            disabled: disableAnimations,
            delay: KeroseneMotion.stagger(
              index + 1,
              step: KeroseneMotion.surfaceStagger,
            ),
            child: TransactionRailConnector(
              label: resolvedConnectionLabel,
              textColor: textColor,
              mutedTextColor: mutedTextColor,
              tertiaryTextColor: tertiaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
      if (warnings.isNotEmpty || notices.isNotEmpty) ...[
        const SizedBox(height: 18),
        for (final warning in warnings) ...[
          TransactionNotice(
            text: warning,
            icon: KeroseneIcons.error,
          ),
          const SizedBox(height: 10),
        ],
        for (final notice in notices) ...[
          notice,
          const SizedBox(height: 10),
        ],
      ],
      SizedBox(height: amountGap),
      if (fillAvailableHeight) const Spacer(),
      TransactionAmountDisplay(
        amountLabel: amountLabel,
        unitLabel: unitLabel,
        fiatReference: fiatReference,
        muted: amountMuted || !editable,
        textColor: textColor,
        mutedTextColor: mutedTextColor,
        borderColor: borderColor,
        onTap: onAmountTap,
        onFiatReferenceTap: onFiatReferenceTap,
        disableAnimations: disableAnimations,
      ),
      if (hasDetails) ...[
        SizedBox(height: detailGap),
        TransactionDetailRows(
          details: details,
          loadingRows: loadingRows,
          textColor: textColor,
          mutedTextColor: mutedTextColor,
          tertiaryTextColor: tertiaryTextColor,
          disableAnimations: disableAnimations,
        ),
      ],
      if (bottomContent != null) ...[
        const SizedBox(height: 20),
        bottomContent!,
      ],
      if (effectiveShowKeypad) ...[
        SizedBox(height: keypadGap),
        RepaintBoundary(
          child: TransactionKeypad(
            mode: effectiveKeypadMode,
            onKeyTap: effectiveOnKeyTap,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            pressedColor: surfaceColor,
          ),
        ),
      ],
      if (ctaLabel != null) ...[
        const SizedBox(height: 18),
        TransactionPrimaryButton(
          label: ctaLabel!,
          enabled: ctaEnabled,
          isLoading: isBusy,
          onTap: onCta,
          backgroundColor: primaryButtonColor,
          foregroundColor: primaryButtonTextColor,
          disableAnimations: disableAnimations,
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  String _resolvedConnectionLabel() {
    final explicit = connectionLabel?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final fallback = rail?.trim() ?? '';
    return fallback.isEmpty ? 'Rede' : fallback;
  }
}

class TransactionSurfaceHeader extends StatelessWidget {
  final String? title;
  final TransactionAmountDirection direction;
  final String? rail;
  final Color textColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color borderColor;

  const TransactionSurfaceHeader({
    super.key,
    required this.title,
    required this.direction,
    required this.rail,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.surfaceColor = AppColors.hexFF111111,
    this.borderColor = AppColors.hexFF2C2C2E,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title?.trim() ?? '';
    final trimmedRail = rail?.trim() ?? '';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surfaceColor,
            border: Border.all(color: borderColor.withValues(alpha: 0.72)),
          ),
          child: Icon(_iconForDirection(), color: mutedTextColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trimmedTitle.isNotEmpty)
                Text(
                  trimmedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              if (trimmedRail.isNotEmpty) ...[
                if (trimmedTitle.isNotEmpty) const SizedBox(height: 3),
                Text(
                  trimmedRail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedTextColor,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconForDirection() {
    return switch (direction) {
      TransactionAmountDirection.send => KeroseneIcons.send,
      TransactionAmountDirection.receive => KeroseneIcons.receive,
      TransactionAmountDirection.neutral => KeroseneIcons.moveHorizontal,
    };
  }
}

class TransactionPartyRow extends StatelessWidget {
  final TransactionPartyData data;
  final Color textColor;
  final Color mutedTextColor;
  final Color tertiaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  const TransactionPartyRow({
    super.key,
    required this.data,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
    this.surfaceColor = AppColors.hexFF111111,
    this.borderColor = AppColors.hexFF2C2C2E,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surfaceColor,
            border: Border.all(color: borderColor.withValues(alpha: 0.72)),
          ),
          child: Icon(data.icon, color: mutedTextColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${data.prefix} ',
                      style: TextStyle(color: mutedTextColor),
                    ),
                    TextSpan(text: data.title),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontSize: 15,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle.trim().isEmpty ? '--' : data.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.technicalMono(
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tertiaryTextColor,
                        fontSize: 13,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TransactionRailConnector extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color mutedTextColor;
  final Color tertiaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  const TransactionRailConnector({
    super.key,
    required this.label,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.tertiaryTextColor = AppColors.hexFF7D838A,
    this.surfaceColor = AppColors.hexFF111111,
    this.borderColor = AppColors.hexFF2C2C2E,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label.trim().isEmpty ? 'Rede' : label.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor.withValues(alpha: 0.86)),
              ),
              child: Icon(
                _iconForRail(resolvedLabel),
                color: mutedTextColor,
                size: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withValues(alpha: 0.72)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    resolvedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 1,
                  color: tertiaryTextColor.withValues(alpha: 0.54),
                ),
                const SizedBox(width: 8),
                Icon(
                  KeroseneIcons.moveHorizontal,
                  color: tertiaryTextColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForRail(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('lightning')) {
      return KeroseneIcons.lightning;
    }
    if (normalized.contains('chain') || normalized.contains('bitcoin')) {
      return KeroseneIcons.onchain;
    }
    if (normalized.contains('kerosene') ||
        normalized.contains('intern') ||
        normalized.contains('interna')) {
      return KeroseneIcons.internalTransfer;
    }
    return KeroseneIcons.route;
  }
}

class TransactionAmountDisplay extends StatelessWidget {
  final String amountLabel;
  final String unitLabel;
  final String? fiatReference;
  final bool muted;
  final Color textColor;
  final Color mutedTextColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onFiatReferenceTap;
  final bool disableAnimations;

  const TransactionAmountDisplay({
    super.key,
    required this.amountLabel,
    required this.unitLabel,
    this.fiatReference,
    this.muted = false,
    this.textColor = Colors.white,
    this.mutedTextColor = AppColors.hexFFB8BCC2,
    this.borderColor = AppColors.hexFF2C2C2E,
    this.onTap,
    this.onFiatReferenceTap,
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    final reference = fiatReference?.trim();
    final amountStyle = AppTypography.amountInput(
      isBtc: unitLabel.toUpperCase() == 'BTC',
      color: textColor,
    ).copyWith(
      fontSize: unitLabel.toLowerCase() == 'sats' ? 44 : 48,
      fontWeight: FontWeight.w600,
      height: 1.04,
      letterSpacing: 0,
    );

    final content = Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: AnimatedSwitcher(
              duration:
                  _surfaceDuration(disableAnimations, KeroseneMotion.pageIn),
              switchInCurve: KeroseneMotion.standard,
              switchOutCurve: KeroseneMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.045),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: FittedBox(
                key: ValueKey('$amountLabel $unitLabel'),
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: TransactionAmountLine(
                  amountLabel: amountLabel,
                  unitLabel: unitLabel,
                  amountStyle: amountStyle,
                  unitStyle: AppTypography.captionLarge.copyWith(
                    color: mutedTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (reference != null && reference.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: _AmountReferenceAction(
              reference: reference,
              enabled: onFiatReferenceTap != null,
              onTap: onFiatReferenceTap,
              disableAnimations: disableAnimations,
              child: AnimatedSwitcher(
                duration:
                    _surfaceDuration(disableAnimations, KeroseneMotion.pageIn),
                switchInCurve: KeroseneMotion.standard,
                switchOutCurve: KeroseneMotion.exit,
                child: Text(
                  reference,
                  key: ValueKey(reference),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.captionLarge.copyWith(
                    color: muted ? mutedTextColor : textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    letterSpacing: 0,
                    decoration: onFiatReferenceTap == null
                        ? TextDecoration.none
                        : TextDecoration.underline,
                    decorationColor: textColor.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        AnimatedContainer(
          duration: _surfaceDuration(disableAnimations, KeroseneMotion.short),
          height: 1,
          color: muted
              ? borderColor.withValues(alpha: 0.78)
              : textColor.withValues(alpha: 0.20),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class TransactionAmountLine extends StatelessWidget {
  final String amountLabel;
  final String unitLabel;
  final TextStyle amountStyle;
  final TextStyle unitStyle;

  const TransactionAmountLine({
    super.key,
    required this.amountLabel,
    required this.unitLabel,
    required this.amountStyle,
    required this.unitStyle,
  });

  @override
  Widget build(BuildContext context) {
    final parts = _TransactionAmountParts.from(amountLabel);
    final fractionalStyle = amountStyle.copyWith(
      color: amountStyle.color?.withValues(alpha: 0.58),
      fontSize: (amountStyle.fontSize ?? 48) * 0.68,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: parts.integer, style: amountStyle),
              if (parts.fraction.isNotEmpty) ...[
                TextSpan(text: parts.separator, style: fractionalStyle),
                TextSpan(text: parts.fraction, style: fractionalStyle),
              ],
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            unitLabel,
            maxLines: 1,
            softWrap: false,
            style: unitStyle,
          ),
        ),
      ],
    );
  }
}

class _TransactionAmountParts {
  final String integer;
  final String separator;
  final String fraction;

  const _TransactionAmountParts({
    required this.integer,
    required this.separator,
    required this.fraction,
  });

  factory _TransactionAmountParts.from(String value) {
    final trimmed = value.trim();
    final dot = trimmed.lastIndexOf('.');
    final comma = trimmed.lastIndexOf(',');
    final separatorIndex = dot > comma ? dot : comma;
    if (separatorIndex < 0) {
      return _TransactionAmountParts(
        integer: trimmed.isEmpty ? '0' : trimmed,
        separator: '',
        fraction: '',
      );
    }

    final integer = trimmed.substring(0, separatorIndex);
    final rawFraction = trimmed.substring(separatorIndex + 1);
    final fraction = rawFraction.replaceFirst(RegExp(r'0+$'), '');
    return _TransactionAmountParts(
      integer: integer.isEmpty ? '0' : integer,
      separator: fraction.isEmpty ? '' : trimmed[separatorIndex],
      fraction: fraction,
    );
  }
}

class _AmountReferenceAction extends StatelessWidget {
  final String reference;
  final bool enabled;
  final VoidCallback? onTap;
  final bool disableAnimations;
  final Widget child;

  const _AmountReferenceAction({
    required this.reference,
    required this.enabled,
    required this.onTap,
    required this.disableAnimations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Semantics(
      button: true,
      label: reference,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: _surfaceDuration(disableAnimations, KeroseneMotion.fast),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final bool disabled;
  final Duration delay;

  const _AnimatedEntrance({
    required this.child,
    required this.disabled,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: KeroseneMotion.medium + delay,
      curve: KeroseneMotion.standard,
      builder: (context, value, child) {
        final delayed = delay == Duration.zero
            ? value
            : ((value * (220 + delay.inMilliseconds) - delay.inMilliseconds) /
                    220)
                .clamp(0.0, 1.0)
                .toDouble();
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - delayed)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
