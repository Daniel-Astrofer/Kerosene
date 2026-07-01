import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/design_system/icons.dart';

class TransactionValueEntrySurface extends StatelessWidget {
  final VoidCallback onBack;
  final String amountInput;
  final String unitLabel;
  final Currency currency;
  final String fiatReference;
  final Widget? configuration;
  final bool showKeypad;
  final ValueChanged<String>? onAmountChanged;
  final VoidCallback? onFiatReferenceTap;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isBusy;
  final VoidCallback onCta;

  const TransactionValueEntrySurface({
    super.key,
    required this.onBack,
    this.amountInput = '0',
    this.unitLabel = '₿',
    this.currency = Currency.btc,
    required this.fiatReference,
    this.configuration,
    this.showKeypad = true,
    this.onAmountChanged,
    this.onFiatReferenceTap,
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
            _AmountEntryHeader(onBack: onBack),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl2,
                            AppSpacing.none,
                            AppSpacing.xl2,
                            AppSpacing.xl2,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AmountEntryDisplay(
                                  amountInput: amountInput,
                                  unitLabel: unitLabel,
                                  currency: currency,
                                  fiatReference: fiatReference,
                                  editable: showKeypad,
                                  onAmountChanged: onAmountChanged,
                                  onFiatReferenceTap: onFiatReferenceTap,
                                  onSubmitted: () {
                                    if (ctaEnabled && !isBusy) {
                                      onCta();
                                    }
                                  },
                                ),
                                if (configuration != null) configuration!,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _AmountEntryBottom(
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.xl2,
        AppSpacing.xl2,
        AppSpacing.none,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(KeroseneIcons.back, size: 24),
              style: IconButton.styleFrom(
                foregroundColor: _AmountEntryColors.text,
                minimumSize: const Size.square(48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AmountEntryDisplay extends StatefulWidget {
  final String amountInput;
  final String unitLabel;
  final Currency currency;
  final String fiatReference;
  final bool editable;
  final ValueChanged<String>? onAmountChanged;
  final VoidCallback? onFiatReferenceTap;
  final VoidCallback? onSubmitted;

  const _AmountEntryDisplay({
    required this.amountInput,
    required this.unitLabel,
    required this.currency,
    required this.fiatReference,
    required this.editable,
    required this.onAmountChanged,
    required this.onFiatReferenceTap,
    required this.onSubmitted,
  });

  @override
  State<_AmountEntryDisplay> createState() => _AmountEntryDisplayState();
}

class _AmountEntryDisplayState extends State<_AmountEntryDisplay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _digitsFromRawInput(widget.amountInput, widget.currency),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _AmountEntryDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency ||
        oldWidget.amountInput != widget.amountInput) {
      final synced = _digitsFromRawInput(widget.amountInput, widget.currency);
      if (_controller.text == synced) {
        return;
      }
      _controller.text = synced;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final synced = _digitsFromRawInput(widget.amountInput, widget.currency);
      if (_controller.text != synced) {
        _controller.text = synced;
      }
    }
  }

  void _handleChanged(String value) {
    final digits = _normalizeDigitBuffer(value);
    if (digits != _controller.text) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    widget.onAmountChanged?.call(
      _rawInputFromDigits(digits, widget.currency),
    );
  }

  String _normalizeDigitBuffer(String value) {
    final digits = StringBuffer();
    final maxDigits = widget.currency == Currency.btc ? 16 : 14;

    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 48 && codeUnit <= 57) {
        digits.write(character);
      }
    }

    final withoutLeadingZeros = digits.toString().replaceFirst(
          RegExp(r'^0+'),
          '',
        );
    if (withoutLeadingZeros.length <= maxDigits) {
      return withoutLeadingZeros;
    }
    return withoutLeadingZeros.substring(
      withoutLeadingZeros.length - maxDigits,
    );
  }

  String _rawInputFromDigits(String digits, Currency currency) {
    final decimals = MoneyDisplay.decimalsFor(currency);
    final sanitized = _normalizeDigitBuffer(digits);
    final padded = sanitized.padLeft(decimals + 1, '0');
    final integerEnd = padded.length - decimals;
    final integerPart = padded.substring(0, integerEnd);
    final decimalPart = padded.substring(integerEnd);
    final normalizedInteger =
        int.tryParse(integerPart)?.toString() ?? integerPart;

    if (decimals == 0) {
      return normalizedInteger;
    }
    return '$normalizedInteger.$decimalPart';
  }

  String _digitsFromRawInput(String rawInput, Currency currency) {
    final decimals = MoneyDisplay.decimalsFor(currency);
    final normalized = rawInput.replaceAll(',', '.').trim();
    final parts = normalized.split('.');
    final integerDigits = _digitsOnly(parts.isEmpty ? '0' : parts.first);
    final decimalDigits = parts.length > 1 ? _digitsOnly(parts[1]) : '';
    final fixedDecimal = decimalDigits.padRight(decimals, '0').substring(
          0,
          decimals,
        );
    final combined = '$integerDigits$fixedDecimal'.replaceFirst(
      RegExp(r'^0+'),
      '',
    );
    return combined;
  }

  String _digitsOnly(String value) {
    final digits = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 48 && codeUnit <= 57) {
        digits.write(character);
      }
    }
    return digits.toString();
  }

  String _displayAmountLabel() {
    final amount = MoneyDisplay.parseEditableInput(widget.amountInput);
    return MoneyDisplay.format(
      amount: amount,
      currency: widget.currency,
      withSymbol: false,
      decimalPlaces: MoneyDisplay.decimalsFor(widget.currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = '${widget.unitLabel}${_displayAmountLabel()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.none,
        AppSpacing.none,
        AppSpacing.none,
        AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0,
                  child: TextField(
                    key: const ValueKey('movement-amount-input'),
                    controller: _controller,
                    focusNode: _focusNode,
                    readOnly: !widget.editable,
                    canRequestFocus: widget.editable,
                    enableInteractiveSelection: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _handleChanged,
                    onSubmitted: (_) => widget.onSubmitted?.call(),
                    maxLines: 1,
                    showCursor: false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        displayValue,
                        key: const ValueKey('movement-amount-display'),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          color: _AmountEntryColors.text,
                          fontSize: 72,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          letterSpacing: 3,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onFiatReferenceTap,
            child: AnimatedSwitcher(
              duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
              child: Text(
                widget.fiatReference,
                key: ValueKey(widget.fiatReference),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: widget.onFiatReferenceTap == null
                      ? _AmountEntryColors.muted
                      : _AmountEntryColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountEntryBottom extends StatelessWidget {
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isBusy;
  final VoidCallback onCta;

  const _AmountEntryBottom({
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.isBusy,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl2,
              AppSpacing.sm,
              AppSpacing.xl2,
              AppSpacing.none,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
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
          backgroundColor: _AmountEntryColors.text,
          foregroundColor: _AmountEntryColors.background,
          disabledBackgroundColor: _AmountEntryColors.button,
          disabledForegroundColor: _AmountEntryColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
          ),
        ),
        child: AnimatedSwitcher(
          duration: KeroseneMotion.duration(context, KeroseneMotion.fast),
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

  static const background = AppColors.hexFF000000;
  static const text = AppColors.hexFFFFFFFF;
  static const muted = AppColors.hexFFA0A09B;
  static const button = AppColors.hexFF333333;
}
