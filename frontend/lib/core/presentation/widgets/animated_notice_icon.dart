import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AnimatedNoticeIconKind { success, error, info, warning }

class AnimatedNoticeIcon extends StatefulWidget {
  final AnimatedNoticeIconKind kind;
  final Color color;
  final double size;
  final double strokeWidth;
  final Duration duration;

  const AnimatedNoticeIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2.4,
    this.duration = const Duration(milliseconds: 850),
  });

  @override
  State<AnimatedNoticeIcon> createState() => _AnimatedNoticeIconState();
}

class _AnimatedNoticeIconState extends State<AnimatedNoticeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedNoticeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind || oldWidget.color != widget.color) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AnimatedNoticeIconPainter(
              kind: widget.kind,
              progress: _animation.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedNoticeIconPainter extends CustomPainter {
  final AnimatedNoticeIconKind kind;
  final double progress;
  final Color color;
  final double strokeWidth;

  const _AnimatedNoticeIconPainter({
    required this.kind,
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    final paths = _pathsFor(kind, size);
    final lengths = <double>[];
    double totalLength = 0;

    for (final path in paths) {
      double pathLength = 0;
      for (final metric in path.computeMetrics()) {
        pathLength += metric.length;
      }
      lengths.add(pathLength);
      totalLength += pathLength;
    }

    double remaining = totalLength * progress;

    for (var i = 0; i < paths.length; i++) {
      if (remaining <= 0) {
        break;
      }

      final path = paths[i];
      final targetLength = math.min(lengths[i], remaining);
      double consumed = 0;
      final partialPath = Path();

      for (final metric in path.computeMetrics()) {
        final available = targetLength - consumed;
        if (available <= 0) {
          break;
        }

        final extractLength = math.min(metric.length, available);
        partialPath.addPath(metric.extractPath(0, extractLength), Offset.zero);
        consumed += extractLength;
      }

      canvas.drawPath(partialPath, paint);
      remaining -= lengths[i];
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedNoticeIconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }

  List<Path> _pathsFor(AnimatedNoticeIconKind kind, Size size) {
    return switch (kind) {
      AnimatedNoticeIconKind.success => _successPaths(size),
      AnimatedNoticeIconKind.error => _errorPaths(size),
      AnimatedNoticeIconKind.info => _infoPaths(size),
      AnimatedNoticeIconKind.warning => _warningPaths(size),
    };
  }

  List<Path> _successPaths(Size size) {
    final circle = Path()
      ..addOval(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.1,
          size.width * 0.8,
          size.height * 0.8,
        ),
      );

    final check = Path()
      ..moveTo(size.width * 0.30, size.height * 0.54)
      ..lineTo(size.width * 0.45, size.height * 0.69)
      ..lineTo(size.width * 0.73, size.height * 0.38);

    return [circle, check];
  }

  List<Path> _errorPaths(Size size) {
    final circle = Path()
      ..addOval(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.1,
          size.width * 0.8,
          size.height * 0.8,
        ),
      );

    final crossA = Path()
      ..moveTo(size.width * 0.34, size.height * 0.34)
      ..lineTo(size.width * 0.66, size.height * 0.66);

    final crossB = Path()
      ..moveTo(size.width * 0.66, size.height * 0.34)
      ..lineTo(size.width * 0.34, size.height * 0.66);

    return [circle, crossA, crossB];
  }

  List<Path> _infoPaths(Size size) {
    final circle = Path()
      ..addOval(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.1,
          size.width * 0.8,
          size.height * 0.8,
        ),
      );

    final stem = Path()
      ..moveTo(size.width * 0.5, size.height * 0.42)
      ..lineTo(size.width * 0.5, size.height * 0.68);

    final dot = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.28),
          radius: size.width * 0.03,
        ),
      );

    return [circle, stem, dot];
  }

  List<Path> _warningPaths(Size size) {
    final triangle = Path()
      ..moveTo(size.width * 0.50, size.height * 0.14)
      ..lineTo(size.width * 0.84, size.height * 0.76)
      ..lineTo(size.width * 0.16, size.height * 0.76)
      ..close();

    final stem = Path()
      ..moveTo(size.width * 0.50, size.height * 0.34)
      ..lineTo(size.width * 0.50, size.height * 0.56);

    final dot = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.66),
          radius: size.width * 0.03,
        ),
      );

    return [triangle, stem, dot];
  }
}
