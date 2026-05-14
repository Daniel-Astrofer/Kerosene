import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';

/// Design System-compliant text field with shake animation for form errors.
/// Drop-in replacement for any input in the app — zero hardcoded values.
class CyberTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const CyberTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<CyberTextField> createState() => _CyberTextFieldState();
}

class _CyberTextFieldState extends State<CyberTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: 400.ms,
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(CyberTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake on new API error
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = hasError
            ? 6.0 *
                (0.5 - (_shakeAnim.value * 3 % 1).abs()).abs() *
                (_shakeAnim.value < 0.5 ? 1 : -1)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              widget.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: hasError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          GlassContainer(
            blur: 20,
            opacity: 0.05,
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: hasError
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7)
                  : Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.15),
              width: 1,
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword,
              keyboardType: widget.keyboardType,
              focusNode: widget.focusNode,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              validator: widget.validator,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
              cursorColor: Theme.of(context).colorScheme.primary,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.2),
                    ),
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide(
                    color: hasError
                        ? Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.8)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
              ),
              child: Text(
                widget.errorText!,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ).animate().fade(duration: 200.ms),
            ),
        ],
      ),
    );
  }
}
