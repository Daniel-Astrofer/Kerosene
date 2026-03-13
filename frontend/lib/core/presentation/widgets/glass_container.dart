import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color = Colors.black, // Default to black for dark mode safety
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    // When blur is disabled, slightly increase opacity to maintain visibility
    final double effectiveOpacity = enableBlur
        ? opacity
        : (opacity + 0.05).clamp(0.0, 1.0);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: effectiveOpacity),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border:
            border ??
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: child,
    );

    if (!enableBlur) {
      return RepaintBoundary(
        child: Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            clipBehavior: Clip.hardEdge,
            child: content,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          clipBehavior: Clip.hardEdge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: content,
          ),
        ),
      ),
    );
  }
}
