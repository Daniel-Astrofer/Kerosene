import 'package:flutter/material.dart';

/// Placeholder vazio — o background preto AMOLED é definido pelo
/// tema global (AppTheme.darkTheme scaffoldBackgroundColor: Colors.black).
/// Este widget existe apenas para não quebrar imports existentes.
class CameraBackground extends StatelessWidget {
  const CameraBackground({super.key, double blur = 5, double opacity = 0.3});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
