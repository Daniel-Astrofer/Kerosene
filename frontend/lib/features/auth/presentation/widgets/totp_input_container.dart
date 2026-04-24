import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

/// 6-digit TOTP input using absolute CustomPaint fidelity and a hidden TextField.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class TotpInputContainer extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool hasError;
  final bool enabled;
  final bool autofocus;
  final Color? accentColor;
  final int errorPulseKey;

  const TotpInputContainer({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
    this.accentColor,
    this.errorPulseKey = 0,
  });

  @override
  State<TotpInputContainer> createState() => _TotpInputContainerState();
}

class _TotpInputContainerState extends State<TotpInputContainer>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;
  late final AnimationController _focusController;
  late final AnimationController _shakeController;
  String _lastCompletedCode = '';

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    _syncFocusAnimation();
  }

  @override
  void didUpdateWidget(covariant TotpInputContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError &&
        (!oldWidget.hasError ||
            oldWidget.errorPulseKey != widget.errorPulseKey)) {
      _shakeController.forward(from: 0);
    }

    if (oldWidget.enabled != widget.enabled) {
      _syncFocusAnimation();
      if (!widget.enabled) {
        _focusNode.unfocus();
      }
    }
  }

  void _handleTextChanged() {
    final text = _controller.text;
    setState(() {});
    widget.onChanged?.call(text);

    if (text.length == 6) {
      if (_lastCompletedCode != text) {
        _lastCompletedCode = text;
        widget.onCompleted(text);
      }
      _focusNode.unfocus();
      return;
    }

    _lastCompletedCode = '';
  }

  void _handleFocusChanged() {
    _syncFocusAnimation();
    setState(() {});
  }

  void _syncFocusAnimation() {
    if (_focusNode.hasFocus && widget.enabled) {
      if (!_focusController.isAnimating) {
        _focusController.repeat(reverse: true);
      }
    } else {
      _focusController.stop();
      _focusController.value = 0;
    }
  }

  double _shakeOffset() {
    if (!_shakeController.isAnimating) {
      return 0;
    }
    final wave = math.sin(_shakeController.value * math.pi * 5);
    return wave * 10 * (1 - _shakeController.value);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _focusController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.hasError
        ? const Color(0xFFD6D6D0)
        : (widget.accentColor ?? const Color(0xFFF1F1ED));
    final text = _controller.text;
    final activeIndex = text.length.clamp(0, 5);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_focusController, _shakeController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeOffset(), 0),
            child: Stack(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    final isFilled = index < text.length;
                    final isActive = widget.enabled &&
                        _focusNode.hasFocus &&
                        index == activeIndex;
                    final isComplete = text.length == 6;
                    final borderColor = widget.hasError
                        ? accent.withValues(alpha: isActive ? 0.95 : 0.50)
                        : isActive
                            ? accent.withValues(
                                alpha: 0.70 + (_focusController.value * 0.30),
                              )
                            : isFilled
                                ? accent.withValues(alpha: 0.28)
                                : Colors.white.withValues(alpha: 0.10);
                    final glowColor = widget.hasError
                        ? accent.withValues(alpha: 0.18)
                        : accent.withValues(
                            alpha: isActive
                                ? 0.22 + (_focusController.value * 0.08)
                                : 0,
                          );

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 5 ? 0 : 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          curve: Curves.easeOutCubic,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: isFilled || isActive ? 0.065 : 0.035,
                            ),
                            borderRadius: BorderRadius.circular(0),
                            border: Border.all(
                              color: borderColor,
                              width: isActive || widget.hasError ? 1.5 : 1,
                            ),
                            boxShadow: glowColor.a > 0
                                ? [
                                    BoxShadow(
                                      color: glowColor,
                                      blurRadius: 20,
                                      spreadRadius: -4,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isActive && !isComplete && !widget.hasError)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 22,
                                    height: 3,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: 0.68 +
                                            (_focusController.value * 0.22),
                                      ),
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                ),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                style: AppTypography.number.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isFilled
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Colors.white.withValues(alpha: 0.16),
                                ),
                                child: Text(isFilled ? text[index] : '•'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: const TextSelectionThemeData(
                        selectionColor: Colors.transparent,
                        cursorColor: Colors.transparent,
                        selectionHandleColor: Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      readOnly: !widget.enabled,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      enableSuggestions: false,
                      autocorrect: false,
                      cursorWidth: 0,
                      cursorHeight: 0,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      contextMenuBuilder: (context, editableTextState) =>
                          const SizedBox.shrink(),
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                        height: 1,
                        decorationColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TotpGridPainter extends CustomPainter {
  final String text;
  final bool isFocused;
  final double pulseValue;

  _TotpGridPainter({
    required this.text,
    required this.isFocused,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int numCells = 6;
    const double spacing = 12.0;

    // Calculate dynamic cell width to fit available width perfectly
    final double cellWidth =
        (size.width - (spacing * (numCells - 1))) / numCells;
    final double cellHeight = size.height;

    final Paint bgPaint = Paint()..color = AppColors.surfaceLight;
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint focusedBorderPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5 + (pulseValue * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < numCells; i++) {
      final double left = i * (cellWidth + spacing);
      final Rect cellRect = Rect.fromLTWH(left, 0, cellWidth, cellHeight);
      final RRect roundedRect = RRect.fromRectAndRadius(
        cellRect,
        Radius.circular(AppSpacing.sm + 2),
      );

      // Draw background
      canvas.drawRRect(roundedRect, bgPaint);

      // Draw border
      final bool isCurrentFocus = isFocused && text.length == i;
      if (isCurrentFocus) {
        canvas.drawRRect(roundedRect, focusedBorderPaint);

        // Glow effect
        final Paint glowPaint = Paint()
          ..color = AppColors.primary.withOpacity(0.15 * pulseValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(roundedRect, glowPaint);
      } else {
        canvas.drawRRect(roundedRect, borderPaint);
      }

      // Draw Text
      if (i < text.length) {
        textPainter.text = TextSpan(
          text: text[i],
          style: AppTypography.h2.copyWith(
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        );
        textPainter.layout();

        final Offset textOffset = Offset(
          left + (cellWidth - textPainter.width) / 2,
          (cellHeight - textPainter.height) / 2,
        );

        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TotpGridPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.isFocused != isFocused ||
        oldDelegate.pulseValue != pulseValue;
  }
}
