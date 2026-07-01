import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/design_system/icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/monochrome_theme.dart';

class PinEntryScaffold extends StatefulWidget {
  final String instruction;
  final int valueLength;
  final int maxLength;
  final String? error;
  final bool busy;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onConfirm;
  final String? confirmLabel;
  final Widget? footer;

  const PinEntryScaffold({
    super.key,
    required this.instruction,
    required this.valueLength,
    required this.maxLength,
    required this.error,
    required this.busy,
    required this.onDigit,
    required this.onDelete,
    required this.onConfirm,
    this.confirmLabel,
    this.footer,
    this.enabled = true,
  });

  @override
  State<PinEntryScaffold> createState() => _PinEntryScaffoldState();
}

class _PinEntryScaffoldState extends State<PinEntryScaffold> {
  bool _showPad = false;

  void _openPad() {
    if (!widget.enabled || widget.busy) {
      return;
    }
    if (_showPad) {
      return;
    }
    setState(() {
      _showPad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final availableHeight = size.height - 12 - (20 + bottomInset);
    final compactWidth = size.width < 380;
    final compactHeight = size.height < 720;
    final horizontalPadding = compactWidth ? 20.0 : 24.0;
    final maxWidth = compactWidth ? 360.0 : 420.0;
    final topSpacing = compactHeight ? 18.0 : 38.0;
    final instructionFontSize = compactWidth ? 31.0 : 36.0;
    final dotSize = compactWidth ? 8.0 : 9.0;
    final padKeySize = compactHeight ? 66.0 : 74.0;
    final digitFontSize = compactWidth ? 28.0 : 31.0;
    final contentGap = compactHeight ? 24.0 : 30.0;
    const tapToEnterLabel = 'Toque para digitar';

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                20 + bottomInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight > 0 ? availableHeight : 0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: topSpacing),
                          const Spacer(flex: 1),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openPad,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.instruction,
                                  textAlign: TextAlign.left,
                                  style: AppTypography.newsreader(
                                    color: monoTextColor,
                                    fontSize: instructionFontSize,
                                    fontWeight: FontWeight.w500,
                                    height: 1.04,
                                    letterSpacing: -0.35,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                SizedBox(height: contentGap),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: PinEntryDots(
                                    length: widget.valueLength,
                                    maxLength: widget.maxLength,
                                    dotSize: dotSize,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 42,
                                  child: AnimatedSwitcher(
                                    duration: KeroseneMotion.short,
                                    child: widget.error == null
                                        ? const SizedBox.shrink()
                                        : Text(
                                            widget.error!,
                                            key: ValueKey(widget.error),
                                            textAlign: TextAlign.left,
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: monoMutedTextColor,
                                              height: 1.28,
                                              letterSpacing: 0,
                                              fontSize: 12.5,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                  ),
                                ),
                                if (!_showPad) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    tapToEnterLabel,
                                    textAlign: TextAlign.left,
                                    style: AppTypography.caption.copyWith(
                                      color: monoFaintTextColor,
                                      height: 1.2,
                                      letterSpacing: 0,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(flex: 2),
                          AnimatedSwitcher(
                            duration: KeroseneMotion.short,
                            child: widget.busy
                                ? const SizedBox(
                                    key: ValueKey('pin_pad_loading'),
                                    height: 180,
                                    child: Center(
                                      child: TorLoadingDots(
                                        dotSize: 8,
                                        spacing: 10,
                                        travel: 14,
                                      ),
                                    ),
                                  )
                                : _showPad
                                    ? PinNumericPad(
                                        key: const ValueKey('pin_pad_visible'),
                                        enabled: widget.enabled && !widget.busy,
                                        onDigit: widget.onDigit,
                                        onDelete: widget.onDelete,
                                        keySize: padKeySize,
                                        digitFontSize: digitFontSize,
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('pin_pad_hidden'),
                                      ),
                          ),
                          if (widget.confirmLabel != null) ...[
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: widget.enabled && !widget.busy
                                    ? widget.onConfirm
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: monoTextColor,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor:
                                      monoTextColor.withValues(alpha: 0.20),
                                  disabledForegroundColor:
                                      monoTextColor.withValues(alpha: 0.42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  textStyle: AppTypography.buttonText.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                child: widget.busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(widget.confirmLabel!),
                              ),
                            ),
                          ],
                          if (widget.footer != null) ...[
                            const SizedBox(height: 12),
                            Center(child: widget.footer!),
                          ],
                          const Spacer(flex: 1),
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
    );
  }
}

class PinEntryDots extends StatelessWidget {
  final int length;
  final int maxLength;
  final double dotSize;

  const PinEntryDots({
    super.key,
    required this.length,
    required this.maxLength,
    this.dotSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    final total = maxLength.clamp(4, 8);
    return Semantics(
      label: '$length de $total dígitos preenchidos',
      child: AnimatedContainer(
        duration: KeroseneMotion.short,
        curve: KeroseneMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: monoSurfaceAltColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: monoBorderStrongColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (index) {
            final filled = index < length;
            return AnimatedContainer(
              duration: KeroseneMotion.short,
              curve: KeroseneMotion.standard,
              margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
              width: filled ? dotSize * 2.55 : dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: filled
                    ? monoTextColor
                    : monoFaintTextColor.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PinPadKey extends StatefulWidget {
  final String value;
  final bool isSpecial;
  final bool enabled;
  final double keySize;
  final double digitFontSize;
  final VoidCallback onTap;

  const _PinPadKey({
    required this.value,
    required this.isSpecial,
    required this.enabled,
    required this.keySize,
    required this.digitFontSize,
    required this.onTap,
  });

  @override
  State<_PinPadKey> createState() => _PinPadKeyState();
}

class _PinPadKeyState extends State<_PinPadKey> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.enabled ? monoTextColor : monoFaintTextColor;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: KeroseneMotion.fast,
        curve: KeroseneMotion.standard,
        child: AnimatedContainer(
          duration: KeroseneMotion.short,
          curve: KeroseneMotion.standard,
          height: widget.keySize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? monoSurfaceAltColor.withValues(alpha: 0.88)
                : Colors.transparent,
            border: Border.all(
              color: _pressed ? monoBorderStrongColor : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkResponse(
              enableFeedback: true,
              onTap: widget.enabled ? widget.onTap : null,
              containedInkWell: true,
              customBorder: const CircleBorder(),
              child: Center(
                child: widget.isSpecial
                    ? Icon(
                        KeroseneIcons.backspace,
                        size: widget.keySize * 0.34,
                        color: widget.enabled
                            ? monoMutedTextColor
                            : monoFaintTextColor,
                      )
                    : Text(
                        widget.value,
                        style: AppTypography.financial(
                          color: foreground,
                          fontWeight: FontWeight.w500,
                          fontSize: widget.digitFontSize,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinNumericPad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final double keySize;
  final double digitFontSize;

  const PinNumericPad({
    super.key,
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    this.keySize = 76,
    this.digitFontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((key) {
              final isSpecial = key == '<';
              if (key.isEmpty) {
                return Expanded(child: SizedBox(height: keySize));
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _PinPadKey(
                    value: key,
                    isSpecial: isSpecial,
                    enabled: enabled,
                    keySize: keySize,
                    digitFontSize: digitFontSize,
                    onTap: () {
                      if (isSpecial) {
                        onDelete();
                        return;
                      }
                      onDigit(key);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
