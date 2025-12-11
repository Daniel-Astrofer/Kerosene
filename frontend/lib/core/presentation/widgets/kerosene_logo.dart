import 'package:flutter/material.dart';

class KeroseneLogo extends StatelessWidget {
  final double size;

  const KeroseneLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/kerosenelogo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
