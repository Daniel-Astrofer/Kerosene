import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kerosene_logo.dart';

class KeroseneLogoLoadingView extends StatefulWidget {
  final String status;
  final String detail;
  final bool isDelayed;
  final bool isError;
  final String? errorMessage;
  final double logoSize;

  const KeroseneLogoLoadingView({
    super.key,
    this.status = '',
    this.detail = '',
    this.isDelayed = false,
    this.isError = false,
    this.errorMessage,
    this.logoSize = 230,
  });

  @override
  State<KeroseneLogoLoadingView> createState() =>
      _KeroseneLogoLoadingViewState();
}

class _KeroseneLogoLoadingViewState extends State<KeroseneLogoLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(KeroseneLogo.assetPath), context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width;
    final logoSize = math.min(
      widget.logoSize,
      math.max(148.0, availableWidth * 0.58),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: logoSize,
            height: logoSize,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                final reveal = _revealProgress(progress);
                final erase = _eraseProgress(progress);
                final glow = _glowOpacity(progress);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.10,
                      child: KeroseneLogo(
                        size: logoSize,
                        color: Colors.white,
                      ),
                    ),
                    ClipPath(
                      clipper: _DiagonalLogoClipper(
                        revealProgress: reveal,
                        eraseProgress: erase,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!widget.isError)
                            Opacity(
                              opacity: glow,
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: KeroseneLogo(
                                  size: logoSize,
                                  color: const Color(0xFF00E5BC),
                                ),
                              ),
                            ),
                          KeroseneLogo(
                            size: logoSize,
                            color: widget.isError
                                ? const Color(0xFFFF5A5F)
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _revealProgress(double value) {
    if (value < 0.56) {
      return Curves.easeInOutCubic.transform(value / 0.56);
    }
    return 1.0;
  }

  double _eraseProgress(double value) {
    if (value < 0.74) return 0.0;
    return Curves.easeInOutCubic.transform((value - 0.74) / 0.26);
  }

  double _glowOpacity(double value) {
    final pulse = math.sin(value * math.pi * 2);
    return widget.isError ? 0.0 : 0.12 + (pulse + 1) * 0.10;
  }
}

class _DiagonalLogoClipper extends CustomClipper<Path> {
  final double revealProgress;
  final double eraseProgress;

  const _DiagonalLogoClipper({
    required this.revealProgress,
    required this.eraseProgress,
  });

  @override
  Path getClip(Size size) {
    final diagonal = size.width + size.height;
    final revealEdge = diagonal * revealProgress;
    final eraseEdge = diagonal * eraseProgress;
    const softness = 28.0;

    final bounds = Offset.zero & size;
    final revealed = _diagonalHalfPlane(size, revealEdge + softness);
    final erased = eraseProgress <= 0
        ? Path()
        : _diagonalHalfPlane(size, eraseEdge - softness);
    final visible = Path.combine(PathOperation.difference, revealed, erased);

    return Path.combine(
        PathOperation.intersect, Path()..addRect(bounds), visible);
  }

  Path _diagonalHalfPlane(Size size, double edge) {
    return Path()
      ..moveTo(-size.width, -size.height)
      ..lineTo(edge + size.width, -size.height)
      ..lineTo(-size.width, edge + size.height)
      ..close();
  }

  @override
  bool shouldReclip(_DiagonalLogoClipper oldClipper) {
    return oldClipper.revealProgress != revealProgress ||
        oldClipper.eraseProgress != eraseProgress;
  }
}
