import 'package:flutter/material.dart';

class AnimatedTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration typingDuration;

  const AnimatedTypewriterText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.typingDuration = const Duration(milliseconds: 30),
  });

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.text.length * widget.typingDuration.inMilliseconds,
      ),
    );

    _characterCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.duration = Duration(
        milliseconds: widget.text.length * widget.typingDuration.inMilliseconds,
      );
      _characterCount = StepTween(
        begin: 0,
        end: widget.text.length,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
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
      animation: _characterCount,
      builder: (BuildContext context, Widget? child) {
        String visibleString = widget.text.substring(0, _characterCount.value);
        return Text(
          visibleString,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
