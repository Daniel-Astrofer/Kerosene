import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedNumberDisplay extends StatefulWidget {
  final double value;
  final TextStyle style;
  final int decimalPlaces;
  final String? prefix;
  final String? suffix;
  final bool enableFlash;

  const AnimatedNumberDisplay({
    super.key,
    required this.value,
    required this.style,
    this.decimalPlaces = 2,
    this.prefix,
    this.suffix,
    this.enableFlash = true,
  });

  @override
  State<AnimatedNumberDisplay> createState() => _AnimatedNumberDisplayState();
}

class _AnimatedNumberDisplayState extends State<AnimatedNumberDisplay> {
  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: widget.decimalPlaces,
    ).format(widget.value).trim();

    final fullString = '${widget.prefix ?? ''}$formatted${widget.suffix ?? ''}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: List.generate(fullString.length, (index) {
        final char = fullString[index];
        final isDigit = RegExp(r'[0-9]').hasMatch(char);

        if (!isDigit) {
          return Text(char, style: widget.style);
        }

        return _RollingDigit(
          key: ValueKey(
            'rolling_${fullString.length - index}',
          ), // Stable key from right
          digit: char,
          style: widget.style,
        );
      }),
    );
  }
}

class _RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;

  const _RollingDigit({super.key, required this.digit, required this.style});

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _targetDigit = 0;
  int _previousDigit = 0;

  @override
  void initState() {
    super.initState();
    _targetDigit = int.tryParse(widget.digit) ?? 0;
    _previousDigit = _targetDigit;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDigit = int.tryParse(widget.digit) ?? 0;
    if (newDigit != _targetDigit) {
      _previousDigit = _targetDigit;
      _targetDigit = newDigit;
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        // Simple vertical slide effect or crossfade
        // For distinct rolling, we can interpolate numbers.
        // Or simpler: stack two numbers and slide.
        return Stack(
          children: [
            Opacity(
              opacity: 1.0 - value,
              child: Text('$_previousDigit', style: widget.style),
            ),
            Opacity(
              opacity: value,
              child: Text('$_targetDigit', style: widget.style),
            ),
            // Optional: Slide transform here
          ],
        );
      },
    );
  }
}
