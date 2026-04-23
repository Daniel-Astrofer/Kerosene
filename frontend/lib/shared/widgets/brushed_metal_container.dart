import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shader_provider.dart';

/// A premium container that applies a brushed metal shader.
class BrushedMetalContainer extends ConsumerStatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final Color baseColor;
  final double borderRadius;
  final double materialId;
  final double tiltX;
  final double tiltY;
  final ui.Image? textTexture;
  final bool animate;

  const BrushedMetalContainer({
    super.key,
    this.child,
    required this.width,
    required this.height,
    required this.baseColor,
    this.borderRadius = 12.0,
    this.materialId = 0.0,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.textTexture,
    this.animate = false,
  });

  @override
  ConsumerState<BrushedMetalContainer> createState() =>
      _BrushedMetalContainerState();
}

class _BrushedMetalContainerState extends ConsumerState<BrushedMetalContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _fallbackTexture;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 24));
    _syncAnimationState();
    _initFallback();
  }

  @override
  void didUpdateWidget(covariant BrushedMetalContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    if (widget.animate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }

    _controller
      ..stop()
      ..value = 0;
  }

  Future<void> _initFallback() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.transparent, BlendMode.clear);
    final picture = recorder.endRecording();
    final img = await picture.toImage(1, 1);
    if (mounted) setState(() => _fallbackTexture = img);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shaderAsync = ref.watch(metalShaderProvider);
    final ui.Image? activeTexture = widget.textTexture ?? _fallbackTexture;
    final borderColor = widget.baseColor.computeLuminance() > 0.52
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.12);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: shaderAsync.when(
          loading: () => _MetalFallback(
            baseColor: widget.baseColor,
            materialId: widget.materialId,
            child: widget.child,
          ),
          error: (err, stack) {
            debugPrint('❌ Shader Error: $err');
            return _MetalFallback(
              baseColor: widget.baseColor,
              materialId: widget.materialId,
              child: widget.child,
            );
          },
          data: (program) {
            if (activeTexture == null) {
              return _MetalFallback(
                baseColor: widget.baseColor,
                materialId: widget.materialId,
                child: widget.child,
              );
            }

            if (!widget.animate) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  isComplex: true,
                  willChange: false,
                  painter: _MetalShaderPainter(
                    program: program,
                    time: 0,
                    baseColor: widget.baseColor,
                    materialId: widget.materialId,
                    tiltX: widget.tiltX,
                    tiltY: widget.tiltY,
                    texture: activeTexture,
                  ),
                  child: widget.child,
                ),
              );
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  isComplex: true,
                  willChange: true,
                  painter: _MetalShaderPainter(
                    program: program,
                    time: _controller.value * 12.0,
                    baseColor: widget.baseColor,
                    materialId: widget.materialId,
                    tiltX: widget.tiltX,
                    tiltY: widget.tiltY,
                    texture: activeTexture,
                  ),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetalFallback extends StatelessWidget {
  final Color baseColor;
  final double materialId;
  final Widget? child;

  const _MetalFallback({
    required this.baseColor,
    required this.materialId,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(baseColor);
    final highlight = hsl
        .withLightness(
            (hsl.lightness + (materialId >= 2 ? 0.08 : 0.12)).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.04).clamp(0.0, 1.0))
        .toColor();
    final shadow = hsl
        .withLightness(
            (hsl.lightness - (materialId >= 2 ? 0.06 : 0.12)).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.02).clamp(0.0, 1.0))
        .toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, baseColor, shadow],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
      child: child,
    );
  }
}

class _MetalShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Color baseColor;
  final double materialId;
  final double tiltX;
  final double tiltY;
  final ui.Image texture;

  _MetalShaderPainter({
    required this.program,
    required this.time,
    required this.baseColor,
    required this.materialId,
    required this.tiltX,
    required this.tiltY,
    required this.texture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final shader = program.fragmentShader();

    // 0, 1: iResolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // 2: iTime
    shader.setFloat(2, time);
    // 3, 4: iTilt
    shader.setFloat(3, tiltX);
    shader.setFloat(4, tiltY);
    // 5, 6, 7, 8: iColor
    shader.setFloat(5, baseColor.r);
    shader.setFloat(6, baseColor.g);
    shader.setFloat(7, baseColor.b);
    shader.setFloat(8, baseColor.a);
    // 9: iMaterialId
    shader.setFloat(9, materialId);
    // 10, 11: iTextureResolution
    shader.setFloat(10, texture.width.toDouble());
    shader.setFloat(11, texture.height.toDouble());
    // Sampler 0: uTexture
    shader.setImageSampler(0, texture);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _MetalShaderPainter old) =>
      old.time != time ||
      old.tiltX != tiltX ||
      old.tiltY != tiltY ||
      old.baseColor != baseColor ||
      old.materialId != materialId ||
      old.texture != texture;
}
