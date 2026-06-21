import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
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
    final compactWidth = size.width < 380;
    final compactHeight = size.height < 720;
    final horizontalPadding = compactWidth ? 20.0 : 24.0;
    final maxWidth = compactWidth ? 360.0 : 390.0;
    final topSpacing = compactHeight ? 20.0 : 54.0;
    final instructionFontSize = compactWidth ? 17.0 : 19.0;
    final dotSize = compactWidth ? 48.0 : 56.0;
    final padKeySize = compactHeight ? 68.0 : 76.0;
    final digitFontSize = compactWidth ? 30.0 : 32.0;
    final contentGap = compactHeight ? 22.0 : 28.0;
    const tapToEnterLabel = 'Toque para digitar';

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                  child: SizedBox(
                    height: constraints.maxHeight - 12 - (20 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacing),
                        const Spacer(flex: 1),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openPad,
                          child: Column(
                            children: [
                              Text(
                                widget.instruction,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: monoMutedTextColor,
                                  fontFamily: AppTypography.serifFontFamily,
                                  fontSize: instructionFontSize,
                                  height: 1.22,
                                  letterSpacing: 0,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              SizedBox(height: contentGap),
                              PinEntryDots(
                                length: widget.valueLength,
                                maxLength: widget.maxLength,
                                dotSize: dotSize,
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
                                          textAlign: TextAlign.center,
                                          style: AppTypography.caption.copyWith(
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
                                  textAlign: TextAlign.center,
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
                          child: _showPad
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
    this.dotSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final total = maxLength.clamp(4, 8);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final filled = index < length;
        return AnimatedContainer(
          duration: KeroseneMotion.short,
          curve: KeroseneMotion.standard,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: dotSize,
          height: dotSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: monoSurfaceAltColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: monoBorderStrongColor),
          ),
          child: AnimatedContainer(
            duration: KeroseneMotion.short,
            width: filled ? dotSize * 0.28 : 0,
            height: filled ? dotSize * 0.28 : 0,
            decoration: const BoxDecoration(
              color: monoTextColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
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
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkResponse(
                      onTap: !enabled
                          ? null
                          : () {
                              if (isSpecial) {
                                onDelete();
                                return;
                              }
                              onDigit(key);
                            },
                      child: SizedBox(
                        height: keySize,
                        child: Center(
                          child: isSpecial
                              ? Icon(
                                  KeroseneIcons.backspace,
                                  size: keySize * 0.37,
                                  color: enabled
                                      ? monoMutedTextColor
                                      : monoFaintTextColor,
                                )
                              : Text(
                                  key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontFamily:
                                            AppTypography.displayFontFamily,
                                        color: enabled
                                            ? monoTextColor
                                            : monoFaintTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: digitFontSize,
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
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
