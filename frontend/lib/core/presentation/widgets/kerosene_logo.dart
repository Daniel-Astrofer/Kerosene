import 'package:flutter/material.dart';

class KeroseneLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const KeroseneLogo({
    super.key,
    this.size = 120,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/kerosene-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
