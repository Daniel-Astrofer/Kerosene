import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

enum AuthActionIllustrationMode {
  connectingServer,
  keyTransfer,
  fingerprintScan,
  recoveryCodes,
  shieldSuccess,
  userMissing,
  warning,
  keyRejected,
  sessionExpired,
}

class AuthActionIllustration extends StatefulWidget {
  final AuthActionIllustrationMode mode;
  final double size;
  final Color color;
  final Duration duration;

  const AuthActionIllustration({
    super.key,
    required this.mode,
    required this.color,
    this.size = 172,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<AuthActionIllustration> createState() => _AuthActionIllustrationState();
}

class _AuthActionIllustrationState extends State<AuthActionIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _repeats {
    switch (widget.mode) {
      case AuthActionIllustrationMode.connectingServer:
      case AuthActionIllustrationMode.keyTransfer:
      case AuthActionIllustrationMode.fingerprintScan:
      case AuthActionIllustrationMode.recoveryCodes:
        return true;
      case AuthActionIllustrationMode.shieldSuccess:
      case AuthActionIllustrationMode.userMissing:
      case AuthActionIllustrationMode.warning:
      case AuthActionIllustrationMode.keyRejected:
      case AuthActionIllustrationMode.sessionExpired:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant AuthActionIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.duration != widget.duration ||
        oldWidget.color != widget.color) {
      _controller.duration = widget.duration;
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    _controller.stop();
    _controller.reset();
    if (_repeats) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _AuthActionIllustrationPainter(
              mode: widget.mode,
              progress: Curves.easeInOutCubic.transform(_controller.value),
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _AuthActionIllustrationPainter extends CustomPainter {
  final AuthActionIllustrationMode mode;
  final double progress;
  final Color color;

  _AuthActionIllustrationPainter({
    required this.mode,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.16);
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);

    switch (mode) {
      case AuthActionIllustrationMode.connectingServer:
        _paintConnecting(canvas, size);
        break;
      case AuthActionIllustrationMode.keyTransfer:
        _paintKeyTransfer(canvas, size);
        break;
      case AuthActionIllustrationMode.fingerprintScan:
        _paintFingerprintScan(canvas, size);
        break;
      case AuthActionIllustrationMode.recoveryCodes:
        _paintRecoveryCodes(canvas, size);
        break;
      case AuthActionIllustrationMode.shieldSuccess:
        _paintShieldSuccess(canvas, size);
        break;
      case AuthActionIllustrationMode.userMissing:
        _paintUserMissing(canvas, size);
        break;
      case AuthActionIllustrationMode.warning:
        _paintWarning(canvas, size);
        break;
      case AuthActionIllustrationMode.keyRejected:
        _paintKeyRejected(canvas, size);
        break;
      case AuthActionIllustrationMode.sessionExpired:
        _paintSessionExpired(canvas, size);
        break;
    }
  }

  Paint _strokePaint({
    double alpha = 1,
    double strokeWidth = 2.8,
  }) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: alpha);
  }

  Paint _fillPaint({double alpha = 0.08}) {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: alpha);
  }

  void _drawPathProgress(Canvas canvas, Path path, Paint paint, double value) {
    final clamped = value.clamp(0.0, 1.0);
    for (final metric in path.computeMetrics()) {
      final partial = metric.extractPath(0, metric.length * clamped);
      canvas.drawPath(partial, paint);
    }
  }

  void _paintConnecting(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final serverRect = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.50),
      width: size.width * 0.34,
      height: size.height * 0.36,
    );
    final serverRRect =
        RRect.fromRectAndRadius(serverRect, const Radius.circular(18));
    canvas.drawRRect(serverRRect, _fillPaint(alpha: 0.03));

    final serverPath = Path()
      ..addRRect(serverRRect)
      ..moveTo(serverRect.left + 18, serverRect.top + 18)
      ..lineTo(serverRect.right - 18, serverRect.top + 18)
      ..moveTo(serverRect.left + 18, serverRect.center.dy)
      ..lineTo(serverRect.right - 18, serverRect.center.dy)
      ..moveTo(serverRect.left + 18, serverRect.bottom - 18)
      ..lineTo(serverRect.right - 18, serverRect.bottom - 18);
    _drawPathProgress(canvas, serverPath, paint, progress);

    final linkPaint = _strokePaint(alpha: 0.8, strokeWidth: 2.2);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.34 + i * 0.16);
      final startX = size.width * 0.18;
      final endX = size.width * 0.42;
      final path = Path()
        ..moveTo(startX, y)
        ..lineTo(endX, y);
      _drawPathProgress(canvas, path, linkPaint, progress);

      final pulseOffset = (progress + i * 0.18) % 1;
      final pulseX = lerpDouble(startX, endX, pulseOffset)!;
      canvas.drawCircle(
        Offset(pulseX, y),
        3.3,
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }
  }

  void _paintKeyTransfer(Canvas canvas, Size size) {
    final serverPaint = _strokePaint(alpha: 0.9);
    final serverRect = Rect.fromCenter(
      center: Offset(size.width * 0.73, size.height * 0.50),
      width: size.width * 0.22,
      height: size.height * 0.28,
    );
    final serverPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(serverRect, const Radius.circular(16)),
      )
      ..moveTo(serverRect.left + 14, serverRect.center.dy)
      ..lineTo(serverRect.right - 14, serverRect.center.dy);
    _drawPathProgress(canvas, serverPath, serverPaint, 1);

    final keyTravel = Curves.easeInOut.transform(progress);
    final keyCenter = Offset(
      lerpDouble(size.width * 0.24, size.width * 0.52, keyTravel)!,
      size.height * 0.50,
    );

    final trailPaint = _strokePaint(alpha: 0.55, strokeWidth: 2.0);
    final trail = Path()
      ..moveTo(size.width * 0.18, size.height * 0.50)
      ..lineTo(serverRect.left - 8, size.height * 0.50);
    _drawPathProgress(canvas, trail, trailPaint, progress);

    canvas.drawCircle(
      Offset(
        lerpDouble(size.width * 0.18, serverRect.left - 8, keyTravel)!,
        size.height * 0.50,
      ),
      3.2,
      Paint()..color = color.withValues(alpha: 0.9),
    );

    canvas.save();
    canvas.translate(keyCenter.dx, keyCenter.dy);
    final keyPath = Path()
      ..addOval(
        Rect.fromCircle(center: const Offset(-12, 0), radius: 12),
      )
      ..moveTo(0, 0)
      ..lineTo(30, 0)
      ..moveTo(18, 0)
      ..lineTo(18, 10)
      ..moveTo(26, 0)
      ..lineTo(26, 8);
    _drawPathProgress(canvas, keyPath, _strokePaint(), progress);
    canvas.restore();
  }

  void _paintFingerprintScan(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final center = Offset(size.width * 0.5, size.height * 0.54);
    final w = size.width * 0.38;
    final h = size.height * 0.48;

    final curves = <Path>[
      Path()
        ..moveTo(center.dx, center.dy - h * 0.44)
        ..cubicTo(
          center.dx - w * 0.26,
          center.dy - h * 0.36,
          center.dx - w * 0.30,
          center.dy - h * 0.10,
          center.dx - w * 0.12,
          center.dy + h * 0.08,
        )
        ..cubicTo(
          center.dx - w * 0.03,
          center.dy + h * 0.17,
          center.dx - w * 0.02,
          center.dy + h * 0.28,
          center.dx - w * 0.12,
          center.dy + h * 0.38,
        ),
      Path()
        ..moveTo(center.dx, center.dy - h * 0.34)
        ..cubicTo(
          center.dx - w * 0.16,
          center.dy - h * 0.28,
          center.dx - w * 0.18,
          center.dy - h * 0.08,
          center.dx - w * 0.04,
          center.dy + h * 0.05,
        )
        ..cubicTo(
          center.dx + w * 0.05,
          center.dy + h * 0.14,
          center.dx + w * 0.07,
          center.dy + h * 0.27,
          center.dx - w * 0.01,
          center.dy + h * 0.36,
        ),
      Path()
        ..moveTo(center.dx, center.dy - h * 0.24)
        ..cubicTo(
          center.dx + w * 0.14,
          center.dy - h * 0.20,
          center.dx + w * 0.18,
          center.dy - h * 0.02,
          center.dx + w * 0.07,
          center.dy + h * 0.11,
        )
        ..cubicTo(
          center.dx - w * 0.01,
          center.dy + h * 0.18,
          center.dx - w * 0.03,
          center.dy + h * 0.28,
          center.dx + w * 0.04,
          center.dy + h * 0.38,
        ),
      Path()
        ..moveTo(center.dx, center.dy - h * 0.40)
        ..cubicTo(
          center.dx + w * 0.30,
          center.dy - h * 0.30,
          center.dx + w * 0.32,
          center.dy + h * 0.08,
          center.dx + w * 0.12,
          center.dy + h * 0.26,
        ),
    ];

    for (var i = 0; i < curves.length; i++) {
      final localProgress = ((progress - i * 0.08) / 0.92).clamp(0.0, 1.0);
      _drawPathProgress(canvas, curves[i], paint, localProgress);
    }

    final scanY = lerpDouble(
      center.dy - h * 0.42,
      center.dy + h * 0.40,
      progress,
    )!;
    canvas.drawLine(
      Offset(center.dx - w * 0.30, scanY),
      Offset(center.dx + w * 0.30, scanY),
      _strokePaint(alpha: 0.8, strokeWidth: 1.6),
    );
  }

  void _paintRecoveryCodes(Canvas canvas, Size size) {
    final stroke = _strokePaint();
    final fill = _fillPaint(alpha: 0.04);
    final cards = [
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.28,
        size.width * 0.44,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.27,
        size.height * 0.43,
        size.width * 0.44,
        size.height * 0.14,
      ),
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.58,
        size.width * 0.44,
        size.height * 0.14,
      ),
    ];

    for (var i = 0; i < cards.length; i++) {
      final reveal = ((progress - i * 0.12) / 0.88).clamp(0.0, 1.0);
      final rrect =
          RRect.fromRectAndRadius(cards[i], const Radius.circular(16));
      canvas.drawRRect(rrect, fill);
      _drawPathProgress(canvas, Path()..addRRect(rrect), stroke, reveal);
      for (var line = 0; line < 3; line++) {
        final y = cards[i].top + 16 + (line * 12);
        final path = Path()
          ..moveTo(cards[i].left + 16, y)
          ..lineTo(cards[i].right - 16, y);
        _drawPathProgress(
            canvas, path, _strokePaint(alpha: 0.75, strokeWidth: 1.8), reveal);
      }
    }

    final checkPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.61)
      ..lineTo(size.width * 0.49, size.height * 0.68)
      ..lineTo(size.width * 0.63, size.height * 0.49);
    _drawPathProgress(
        canvas, checkPath, _strokePaint(strokeWidth: 3), progress);
  }

  void _paintShieldSuccess(Canvas canvas, Size size) {
    final shield = Path()
      ..moveTo(size.width * 0.5, size.height * 0.20)
      ..lineTo(size.width * 0.72, size.height * 0.28)
      ..lineTo(size.width * 0.68, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.76,
        size.width * 0.50,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.38,
        size.height * 0.76,
        size.width * 0.32,
        size.height * 0.58,
      )
      ..lineTo(size.width * 0.28, size.height * 0.28)
      ..close();
    canvas.drawPath(shield, _fillPaint(alpha: 0.05));
    _drawPathProgress(canvas, shield, _strokePaint(), progress);

    final check = Path()
      ..moveTo(size.width * 0.38, size.height * 0.51)
      ..lineTo(size.width * 0.47, size.height * 0.60)
      ..lineTo(size.width * 0.63, size.height * 0.42);
    _drawPathProgress(
      canvas,
      check,
      _strokePaint(strokeWidth: 3.2),
      ((progress - 0.28) / 0.72).clamp(0.0, 1.0),
    );
  }

  void _paintUserMissing(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final head = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.50, size.height * 0.33),
          radius: size.width * 0.10,
        ),
      );
    final body = Path()
      ..moveTo(size.width * 0.30, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.52,
        size.width * 0.70,
        size.height * 0.72,
      );

    _drawPathProgress(canvas, head, paint, progress);
    _drawPathProgress(canvas, body, paint, progress);

    final slash = Path()
      ..moveTo(size.width * 0.28, size.height * 0.24)
      ..lineTo(size.width * 0.74, size.height * 0.78);
    _drawPathProgress(
      canvas,
      slash,
      _strokePaint(strokeWidth: 3.4),
      ((progress - 0.2) / 0.8).clamp(0.0, 1.0),
    );
  }

  void _paintWarning(Canvas canvas, Size size) {
    final triangle = Path()
      ..moveTo(size.width * 0.50, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..close();
    canvas.drawPath(triangle, _fillPaint(alpha: 0.04));
    _drawPathProgress(canvas, triangle, _strokePaint(), progress);

    final exclamation = Path()
      ..moveTo(size.width * 0.50, size.height * 0.34)
      ..lineTo(size.width * 0.50, size.height * 0.54)
      ..moveTo(size.width * 0.50, size.height * 0.62)
      ..lineTo(size.width * 0.50, size.height * 0.64);
    _drawPathProgress(
      canvas,
      exclamation,
      _strokePaint(strokeWidth: 3.2),
      ((progress - 0.22) / 0.78).clamp(0.0, 1.0),
    );
  }

  void _paintKeyRejected(Canvas canvas, Size size) {
    final keyPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.38, size.height * 0.46),
          radius: size.width * 0.10,
        ),
      )
      ..moveTo(size.width * 0.48, size.height * 0.46)
      ..lineTo(size.width * 0.72, size.height * 0.46)
      ..moveTo(size.width * 0.60, size.height * 0.46)
      ..lineTo(size.width * 0.60, size.height * 0.56)
      ..moveTo(size.width * 0.68, size.height * 0.46)
      ..lineTo(size.width * 0.68, size.height * 0.54);
    _drawPathProgress(canvas, keyPath, _strokePaint(), progress);

    final slash = Path()
      ..moveTo(size.width * 0.24, size.height * 0.25)
      ..lineTo(size.width * 0.78, size.height * 0.76);
    _drawPathProgress(
      canvas,
      slash,
      _strokePaint(strokeWidth: 3.2),
      ((progress - 0.16) / 0.84).clamp(0.0, 1.0),
    );
  }

  void _paintSessionExpired(Canvas canvas, Size size) {
    final framePaint = _strokePaint();
    final top = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.28),
        width: size.width * 0.34,
        height: size.height * 0.12,
      ),
      const Radius.circular(10),
    );
    final bottom = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.72),
        width: size.width * 0.34,
        height: size.height * 0.12,
      ),
      const Radius.circular(10),
    );
    final body = Path()
      ..moveTo(size.width * 0.34, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.46,
        size.width * 0.34,
        size.height * 0.66,
      )
      ..moveTo(size.width * 0.66, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.46,
        size.width * 0.66,
        size.height * 0.66,
      );

    _drawPathProgress(canvas, Path()..addRRect(top), framePaint, progress);
    _drawPathProgress(canvas, Path()..addRRect(bottom), framePaint, progress);
    _drawPathProgress(canvas, body, framePaint, progress);

    final sandProgress = ((progress - 0.24) / 0.76).clamp(0.0, 1.0);
    final topSand = Rect.fromCenter(
      center:
          Offset(size.width * 0.50, size.height * (0.40 + sandProgress * 0.08)),
      width: size.width * 0.12 * (1 - sandProgress * 0.5),
      height: size.height * 0.06 * (1 - sandProgress * 0.4),
    );
    final bottomSand = Rect.fromCenter(
      center:
          Offset(size.width * 0.50, size.height * (0.62 + sandProgress * 0.04)),
      width: size.width * 0.14 * (0.55 + sandProgress * 0.4),
      height: size.height * 0.05 * (0.5 + sandProgress * 0.5),
    );
    canvas.drawOval(topSand, _fillPaint(alpha: 0.10));
    canvas.drawOval(bottomSand, _fillPaint(alpha: 0.10));
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.48),
      Offset(size.width * 0.50,
          lerpDouble(size.height * 0.52, size.height * 0.60, sandProgress)!),
      _strokePaint(alpha: 0.7, strokeWidth: 1.8),
    );
  }

  @override
  bool shouldRepaint(covariant _AuthActionIllustrationPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
