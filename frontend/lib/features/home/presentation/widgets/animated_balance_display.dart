import 'dart:math' as math;

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
  final bool isHidden;
  final String locale;
  final double decimalScaleFactor;
  final double separatorScaleFactor;
  final double digitWidthFactor;
  final double characterSpacing;
  final VoidCallback? onDecimalTap;
  final bool animateInitialValue;

  const AnimatedBalanceDisplay({
    super.key,
    required this.balance,
    required this.style,
    this.decimalPlaces = 8,
    this.enableFlash = false,
    this.prefix,
    this.isHidden = false,
    this.locale = 'en_US',
    this.decimalScaleFactor = 0.5,
    this.separatorScaleFactor = 0.7,
    this.digitWidthFactor = 0.64,
    this.characterSpacing = 0.8,
    this.onDecimalTap,
    this.animateInitialValue = true,
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
    final formatter = NumberFormat.decimalPattern(widget.locale);
    formatter.minimumFractionDigits = widget.decimalPlaces;
    formatter.maximumFractionDigits = widget.decimalPlaces;

    final balanceStr = formatter.format(widget.balance);
    final fullString = (widget.prefix ?? '') + balanceStr;

    if (widget.isHidden) {
      final hiddenPrefix = widget.prefix ?? '';
      return _buildRow('$hiddenPrefix••••••••', widget.style);
    }

    if (!widget.enableFlash) {
      return _buildRow(fullString, widget.style);
    }

    return AnimatedBuilder(
      animation: _flashOpacity,
      builder: (context, _) {
        final alpha = _flashOpacity.value;
        final Color textColor = alpha > 0.01
            ? Color.lerp(
                widget.style.color ?? Theme.of(context).colorScheme.onPrimary,
                _flashColor,
                alpha,
              )!
            : (widget.style.color ?? Theme.of(context).colorScheme.onPrimary);
        return _buildRow(fullString, widget.style.copyWith(color: textColor));
      },
    );
  }

  Widget _buildRow(String fullString, TextStyle style) {
    if (widget.isHidden) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(fullString.length, (index) {
          return Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.characterSpacing * 0.5),
            child: Text(
              fullString[index],
              style: style.copyWith(
                fontSize: (style.fontSize ?? 40) * 0.8,
                letterSpacing: 2,
              ),
            ),
          );
        }),
      );
    }
    final dotIndex = fullString.lastIndexOf('.');
    final commaIndex = fullString.lastIndexOf(',');
    final separatorIndex = dotIndex != -1 ? dotIndex : commaIndex;
    final leadingChars = separatorIndex == -1
        ? _buildCharacters(
            fullString: fullString,
            style: style,
            separatorIndex: separatorIndex,
            start: 0,
            end: fullString.length,
          )
        : _buildCharacters(
            fullString: fullString,
            style: style,
            separatorIndex: separatorIndex,
            start: 0,
            end: separatorIndex,
          );
    final decimalChars = separatorIndex == -1
        ? const <Widget>[]
        : _buildCharacters(
            fullString: fullString,
            style: style,
            separatorIndex: separatorIndex,
            start: separatorIndex,
            end: fullString.length,
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...leadingChars,
        if (decimalChars.isNotEmpty)
          GestureDetector(
            onTap: widget.onDecimalTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: decimalChars,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCharacters({
    required String fullString,
    required TextStyle style,
    required int separatorIndex,
    required int start,
    required int end,
  }) {
    return List.generate(end - start, (offset) {
      final index = start + offset;
      final char = fullString[index];
      final isDigit = RegExp(r'[0-9]').hasMatch(char);
      final isDecimalPart = separatorIndex != -1 && index > separatorIndex;
      final currentStyle = isDecimalPart
          ? style.copyWith(
              fontSize: (style.fontSize ?? 40) * widget.decimalScaleFactor,
              color: style.color?.withValues(alpha: 0.8),
            )
          : style;

      late final Widget child;

      if (!isDigit) {
        child = Text(
          char,
          style: char == '.' || char == ','
              ? style.copyWith(
                  fontSize:
                      (style.fontSize ?? 40) * widget.separatorScaleFactor,
                  color: style.color?.withValues(alpha: 0.5),
                )
              : currentStyle,
          key: ValueKey('static_$index'),
        );
      } else {
        final delay = Duration(milliseconds: index * 50);

        child = _RollingDigit(
          key: ValueKey('rolling_${fullString.length - index}'),
          digit: char,
          style: currentStyle,
          delay: delay,
          widthFactor: widget.digitWidthFactor,
          animateInitialValue: widget.animateInitialValue,
        );
      }

      return Padding(
        padding:
            EdgeInsets.symmetric(horizontal: widget.characterSpacing * 0.5),
        child: child,
      );
    });
  }
}

class _RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;
  final Duration delay;
  final double widthFactor;
  final bool animateInitialValue;

  const _RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    this.delay = Duration.zero,
    this.widthFactor = 0.64,
    this.animateInitialValue = true,
  });

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  static const double _visibleExtent = 1.35;
  static const double _edgeOpacity = 0.16;
  static const double _edgeScale = 0.82;
  static const double _maxTiltRadians = 0.78;
  static const double _perspective = 0.0024;

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
        milliseconds: 3000,
      ), // Slightly longer for the multi-spin
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart, // Smoother deceleration for odometer
    );

    if (widget.animateInitialValue) {
      // Initial "spin up" effect.
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() {
            // Determine rotations only ONCE at start.
            _rotations = 1;
            _previousDigit = (_targetDigit + 7) % 10;
          });
          _controller.forward(from: 0.0);
        }
      });
    } else {
      _controller.value = 1.0;
    }
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
    final double height = fontSize * 1.32;

    return SizedBox(
      height: height,
      width: fontSize * widget.widthFactor,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;
            if (t >= 0.999) {
              return _StaticDigit(
                digit: widget.digit,
                style: widget.style,
              );
            }

            int diff = _targetDigit - _previousDigit;
            if (diff < 0) diff += 10;

            final totalSteps = (_rotations * 10) + diff;
            final baseColor =
                widget.style.color ?? Theme.of(context).colorScheme.onPrimary;
            final visibleDigits = <({double distance, Widget child})>[];

            for (int i = 0; i <= totalSteps; i++) {
              final rawOffset = (i - (t * totalSteps)) * height;
              final normalizedOffset = rawOffset / height;
              final distance = normalizedOffset.abs();

              if (distance > _visibleExtent) {
                continue;
              }

              final centerProgress =
                  (1 - (distance / _visibleExtent)).clamp(0.0, 1.0).toDouble();
              final easedCenter = Curves.easeOutCubic.transform(centerProgress);
              final opacity = _edgeOpacity + ((1 - _edgeOpacity) * easedCenter);
              final scale = _edgeScale + ((1 - _edgeScale) * easedCenter);
              final tilt = normalizedOffset * _maxTiltRadians;
              final curvedOffset = math.sin(
                      (normalizedOffset / _visibleExtent) * (math.pi / 2)) *
                  height *
                  _visibleExtent;

              visibleDigits.add((
                distance: distance,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..translateByDouble(0.0, curvedOffset, 0.0, 1.0)
                    ..rotateX(tilt)
                    ..scaleByDouble(scale, scale, 1.0, 1.0),
                  child: Center(
                    child: Text(
                      ((_previousDigit + i) % 10).toString(),
                      style: widget.style.copyWith(
                        color: baseColor.withValues(
                          alpha: (baseColor.a * opacity).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ));
            }

            visibleDigits.sort(
              (a, b) => b.distance.compareTo(a.distance),
            );

            return RepaintBoundary(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final digit in visibleDigits) digit.child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StaticDigit extends StatelessWidget {
  final String digit;
  final TextStyle style;

  const _StaticDigit({
    required this.digit,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        digit,
        style: style,
      ),
    );
  }
}
