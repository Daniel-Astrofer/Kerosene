import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_amount_surface.dart';

class TransactionValueEntryDetail {
  final String label;
  final String value;
  final bool numeric;

  const TransactionValueEntryDetail({
    required this.label,
    required this.value,
    this.numeric = false,
  });
}

class TransactionValueEntrySurface extends StatelessWidget {
  final VoidCallback onBack;
  final String amountLabel;
  final String unitLabel;
  final String fiatReference;
  final List<TransactionValueEntryDetail> details;
  final bool showKeypad;
  final ValueChanged<String> onKeyTap;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isBusy;
  final VoidCallback onCta;

  const TransactionValueEntrySurface({
    super.key,
    required this.onBack,
    required this.amountLabel,
    this.unitLabel = 'BTC',
    required this.fiatReference,
    this.details = const [],
    this.showKeypad = true,
    required this.onKeyTap,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.isBusy,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _AmountEntryColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AmountEntryHeader(onBack: onBack),
                    _AmountEntryDisplay(
                      amountLabel: amountLabel,
                      unitLabel: unitLabel,
                      fiatReference: fiatReference,
                    ),
                    if (details.isNotEmpty)
                      _AmountEntryDetails(details: details),
                  ],
                ),
              ),
            ),
            _AmountEntryBottom(
              showKeypad: showKeypad,
              onKeyTap: onKeyTap,
              ctaLabel: ctaLabel,
              ctaEnabled: ctaEnabled,
              isBusy: isBusy,
              onCta: onCta,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountEntryHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _AmountEntryHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 32, 3, 32),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(KeroseneIcons.back, size: 24),
            style: IconButton.styleFrom(
              foregroundColor: _AmountEntryColors.text,
              minimumSize: const Size.square(40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _AmountEntryDisplay extends StatelessWidget {
  final String amountLabel;
  final String unitLabel;
  final String fiatReference;

  const _AmountEntryDisplay({
    required this.amountLabel,
    required this.unitLabel,
    required this.fiatReference,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 32, 3, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: Text(
                      amountLabel,
                      key: ValueKey(amountLabel),
                      maxLines: 1,
                      style: AppTypography.inter(
                        color: _AmountEntryColors.text,
                        fontSize: 72,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: 2.16,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unitLabel,
                style: AppTypography.inter(
                  color: _AmountEntryColors.muted,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: Text(
              fiatReference,
              key: ValueKey(fiatReference),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: _AmountEntryColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountEntryDetails extends StatelessWidget {
  final List<TransactionValueEntryDetail> details;

  const _AmountEntryDetails({required this.details});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 0, 3, 24),
      child: Column(
        children: [
          for (final detail in details) _AmountEntryDetailRow(detail: detail),
        ],
      ),
    );
  }
}

class _AmountEntryDetailRow extends StatelessWidget {
  final TransactionValueEntryDetail detail;

  const _AmountEntryDetailRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _AmountEntryColors.divider),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  detail.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: _AmountEntryColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                flex: 2,
                child: Text(
                  detail.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.inter(
                    color: _AmountEntryColors.text,
                    fontSize: 14,
                    fontWeight:
                        detail.numeric ? FontWeight.w600 : FontWeight.w300,
                    height: 1.2,
                    letterSpacing: detail.numeric ? 0.42 : 0,
                    fontFeatures: detail.numeric
                        ? const [FontFeature.tabularFigures()]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountEntryBottom extends StatelessWidget {
  final bool showKeypad;
  final ValueChanged<String> onKeyTap;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isBusy;
  final VoidCallback onCta;

  const _AmountEntryBottom({
    required this.showKeypad,
    required this.onKeyTap,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.isBusy,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showKeypad)
            RepaintBoundary(
              child: TransactionKeypad(
                mode: TransactionKeypadMode.decimal,
                onKeyTap: onKeyTap,
                textColor: _AmountEntryColors.text,
                mutedTextColor: _AmountEntryColors.muted,
                pressedColor: _AmountEntryColors.darkGray,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(3, showKeypad ? 8 : 0, 3, 0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: _AmountEntryButton(
                label: ctaLabel,
                enabled: ctaEnabled,
                isBusy: isBusy,
                onPressed: onCta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountEntryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isBusy;
  final VoidCallback onPressed;

  const _AmountEntryButton({
    required this.label,
    required this.enabled,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: FilledButton(
        onPressed: enabled && !isBusy ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: _AmountEntryColors.button,
          foregroundColor: _AmountEntryColors.muted,
          disabledBackgroundColor: _AmountEntryColors.button,
          disabledForegroundColor: _AmountEntryColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: isBusy
              ? const SizedBox(
                  key: ValueKey('busy'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _AmountEntryColors.muted,
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
    );
  }
}

class _AmountEntryColors {
  const _AmountEntryColors._();

  static const background = Color(0xFF000000);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA0A0A0);
  static const darkGray = Color(0xFF1A1A1A);
  static const button = Color(0xFF333333);
  static const divider = Color(0xFF333333);
}
