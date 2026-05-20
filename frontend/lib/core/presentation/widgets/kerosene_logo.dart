import 'package:flutter/material.dart';

class KeroseneLogo extends StatelessWidget {
  static const assetPath = 'assets/logo/kerosene-logo.png';

  final double size;
  final bool showText;
  final Color color;
  final FilterQuality filterQuality;

  const KeroseneLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.color = Colors.white,
    this.filterQuality = FilterQuality.high,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_luminanceMaskMatrix(color)),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: filterQuality,
      ),
    );
  }

  List<double> _luminanceMaskMatrix(Color color) {
    final red = color.r * 255;
    final green = color.g * 255;
    final blue = color.b * 255;
    final alpha = color.a;

    return <double>[
      0,
      0,
      0,
      0,
      red,
      0,
      0,
      0,
      0,
      green,
      0,
      0,
      0,
      0,
      blue,
      0.2126 * alpha,
      0.7152 * alpha,
      0.0722 * alpha,
      0,
      0,
    ];
  }
}
