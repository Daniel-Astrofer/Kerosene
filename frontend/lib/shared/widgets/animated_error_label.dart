import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'interaction_utils.dart';

/// A smart error label that reveals itself smoothly and shakes to alert the user.
/// Uses AnimatedSize for layout and flutter_animate for the shake effect.
class AnimatedErrorLabel extends StatefulWidget {
  final String? errorText;
  final TextAlign textAlign;
  final EdgeInsets padding;

  const AnimatedErrorLabel({
    super.key,
    this.errorText,
    this.textAlign = TextAlign.start,
    this.padding = const EdgeInsets.only(top: 8.0),
  });

  @override
  State<AnimatedErrorLabel> createState() => _AnimatedErrorLabelState();
}

class _AnimatedErrorLabelState extends State<AnimatedErrorLabel> {
  String? _lastError;

  @override
  void didUpdateWidget(AnimatedErrorLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null && widget.errorText != _lastError) {
      // Trigger haptic on new error
      KeroseneFeedback.error();
    }
    _lastError = widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: widget.errorText == null || widget.errorText!.isEmpty
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: widget.padding,
              child: Text(
                widget.errorText!,
                textAlign: widget.textAlign,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate(key: ValueKey(widget.errorText))
                  .fadeIn(duration: 200.ms)
                  .shakeX(hz: 4, amount: 3, duration: 400.ms),
            ),
    );
  }
}
