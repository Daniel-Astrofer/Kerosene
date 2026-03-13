import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shader_provider.dart';

/// Performance-optimized Brushed Metal Container using GPU Shaders.
/// Replaces the CPU-heavy CustomPainter with a high-fidelity FragmentShader.
class BrushedMetalContainer extends ConsumerStatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color baseColor;

  const BrushedMetalContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.baseColor = const Color(0xFF1E1E1E),
  });

  @override
  ConsumerState<BrushedMetalContainer> createState() => _BrushedMetalContainerState();
}

class _BrushedMetalContainerState extends ConsumerState<BrushedMetalContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shaderAsync = ref.watch(metalShaderProvider);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: shaderAsync.when(
          data: (program) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _MetalShaderPainter(
                  program: program,
                  time: _controller.value * 6.28318,
                  baseColor: widget.baseColor,
                ),
                child: widget.child,
              );
            },
          ),
          loading: () => Container(color: widget.baseColor, child: widget.child),
          error: (e, s) => Container(color: widget.baseColor, child: widget.child),
        ),
      ),
    );
  }
}

class _MetalShaderPainter extends CustomPainter {
  final FragmentProgram program;
  final double time;
  final Color baseColor;

  _MetalShaderPainter({
    required this.program,
    required this.time,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // uniforms: 
    // 0: iResolution (vec2)
    // 2: iTime (float)
    // 3: iTilt (vec2)
    // 5: iColor (vec4)

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    
    // Simulate tilt with time-based oscillation for now
    // In a real device, we could use accelerometer data here
    shader.setFloat(3, 0.15 * math.sin(time)); // iTilt.x
    shader.setFloat(4, 0.08 * math.cos(time * 0.5)); // iTilt.y

    shader.setFloat(5, baseColor.r);
    shader.setFloat(6, baseColor.g);
    shader.setFloat(7, baseColor.b);
    shader.setFloat(8, baseColor.a);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _MetalShaderPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.baseColor != baseColor;
  }
}
