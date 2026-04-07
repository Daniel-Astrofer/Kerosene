import 'package:flutter/material.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

/// 6-digit TOTP input using absolute CustomPaint fidelity and a hidden TextField.
/// All styling uses AppColors, AppTypography, AppSpacing tokens strictly.
class TotpInputContainer extends StatefulWidget {
  final ValueChanged<String> onCompleted;

  const TotpInputContainer({
    super.key,
    required this.onCompleted,
  });

  @override
  State<TotpInputContainer> createState() => _TotpInputContainerState();
}

class _TotpInputContainerState extends State<TotpInputContainer>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _controller.addListener(() {
      setState(() {});
      if (_controller.text.length == 6) {
        widget.onCompleted(_controller.text);
        _focusNode.unfocus();
      }
    });

    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visual Grid
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return SizedBox(
              width: double.infinity,
              height: 60,
              child: CustomPaint(
                painter: _TotpGridPainter(
                  text: _controller.text,
                  isFocused: _focusNode.hasFocus,
                  pulseValue: _pulseController.value,
                ),
              ),
            );
          },
        ),
        
        // Hidden TextField over the grid
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
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              showCursor: false,
              enableInteractiveSelection: false,
              enableSuggestions: false,
              autocorrect: false,
              cursorWidth: 0,
              cursorHeight: 0,
              contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
              style: const TextStyle(
                color: Colors.transparent, 
                fontSize: 0, 
                height: 0,
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
    final double cellWidth = (size.width - (spacing * (numCells - 1))) / numCells;
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
