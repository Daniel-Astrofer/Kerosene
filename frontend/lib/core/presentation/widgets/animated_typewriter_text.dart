import 'package:flutter/material.dart';

class AnimatedTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration durationPerChar;
  final VoidCallback? onComplete;

  const AnimatedTypewriterText({
    super.key,
    required this.text,
    this.style,
    this.durationPerChar = const Duration(milliseconds: 50),
    this.onComplete,
  });

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText> {
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    while (_charIndex < widget.text.length) {
      if (!mounted) return;
      setState(() {
        _displayedText += widget.text[_charIndex];
        _charIndex++;
      });
      await Future.delayed(widget.durationPerChar);
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}
