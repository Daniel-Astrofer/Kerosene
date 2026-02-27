import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays a BTC balance with rolling digit animations.
///
/// When [enableFlash] is true, the text briefly tints green (increase) or red (decrease).
/// The widget always renders at a consistent height equal to fontSize * 1.4.
class AnimatedBalanceDisplay extends StatefulWidget {
  final double balance;
  final TextStyle style;
  final int decimalPlaces;
  final bool enableFlash;
  final String? prefix;

  const AnimatedBalanceDisplay({
    super.key,
    required this.balance,
    required this.style,
    this.decimalPlaces = 8,
    this.enableFlash = false,
    this.prefix,
  });

  @override
  State<AnimatedBalanceDisplay> createState() => _AnimatedBalanceDisplayState();
}

class _AnimatedBalanceDisplayState extends State<AnimatedBalanceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;
  Color _flashColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      value: 1.0,
    );
    _flashOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedBalanceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableFlash && widget.balance != oldWidget.balance) {
      _flashColor = widget.balance > oldWidget.balance
          ? const Color(0xFF00FF94)
          : const Color(0xFFFF0055);
      _flashController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a simple fixed format for now, or we could pass a custom string.
    // For universal use, let's support commas if balance is large.
    final formatter = NumberFormat.decimalPattern();
    formatter.minimumFractionDigits = widget.decimalPlaces;
    formatter.maximumFractionDigits = widget.decimalPlaces;

    final balanceStr = formatter.format(widget.balance);
    final fullString = (widget.prefix ?? '') + balanceStr;

    if (!widget.enableFlash) {
      return _buildRow(fullString, widget.style);
    }

    return AnimatedBuilder(
      animation: _flashOpacity,
      builder: (context, _) {
        final alpha = _flashOpacity.value;
        final Color textColor = alpha > 0.01
            ? Color.lerp(
                widget.style.color ?? Colors.white,
                _flashColor,
                alpha,
              )!
            : (widget.style.color ?? Colors.white);
        return _buildRow(fullString, widget.style.copyWith(color: textColor));
      },
    );
  }

  Widget _buildRow(String fullString, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(fullString.length, (index) {
        final char = fullString[index];
        final isDigit = RegExp(r'[0-9]').hasMatch(char);

        if (!isDigit) {
          return Text(
            char,
            style: char == '.' || char == ','
                ? style.copyWith(color: style.color?.withValues(alpha: 0.5))
                : style,
            key: ValueKey('static_$index'),
          );
        }

        // Staggered delay: 30ms per digit
        final delay = Duration(milliseconds: index * 30);

        return _RollingDigit(
          key: ValueKey('rolling_${fullString.length - index}'),
          digit: char,
          style: style,
          delay: delay,
        );
      }),
    );
  }
}

class _RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;
  final Duration delay;

  const _RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    this.delay = Duration.zero,
  });

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _targetDigit;
  late int _previousDigit;
  int _rotations = 0;

  @override
  void initState() {
    super.initState();
    _targetDigit = int.tryParse(widget.digit) ?? 0;
    _previousDigit = _targetDigit;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Slightly longer for the multi-spin
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart, // Smoother deceleration for odometer
    );

    // Initial "spin up" effect
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          // Determine rotations only ONCE at start
          _rotations = 2;
          _previousDigit = (_targetDigit + 7) % 10;
        });
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void didUpdateWidget(_RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDigit = int.tryParse(widget.digit) ?? 0;
    if (newDigit != _targetDigit) {
      setState(() {
        _previousDigit = _targetDigit;
        _targetDigit = newDigit;
        _rotations = 0; // Simple transition for updates
      });
      _controller.duration = const Duration(
        milliseconds: 1000,
      ); // Shorter for updates
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = widget.style.fontSize ?? 40;
    final double height = fontSize * 1.25;

    return SizedBox(
      height: height,
      width: fontSize * 0.55,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;

            int diff = _targetDigit - _previousDigit;
            if (diff < 0) diff += 10;

            final totalSteps = (_rotations * 10) + diff;

            return RepaintBoundary(
              child: Stack(
                children: [
                  for (int i = 0; i <= totalSteps; i++)
                    Transform.translate(
                      offset: Offset(0, (i - (t * totalSteps)) * height),
                      child: Center(
                        child: Text(
                          ((_previousDigit + i) % 10).toString(),
                          style: widget.style,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
