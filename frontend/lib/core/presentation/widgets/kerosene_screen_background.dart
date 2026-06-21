import 'package:flutter/material.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

class KeroseneScreenBackground extends StatelessWidget {
  final Widget child;
  final bool useScroll;
  final EdgeInsetsGeometry padding;

  const KeroseneScreenBackground({
    super.key,
    required this.child,
    this.useScroll = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            KeroseneBrandTokens.backgroundSoft,
            KeroseneBrandTokens.background,
          ],
        ),
      ),
      child: useScroll
          ? SingleChildScrollView(child: content)
          : SizedBox.expand(child: content),
    );
  }
}
