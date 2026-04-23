import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Animated Transaction Icon — factory per type + method
// Each icon is a StatefulWidget drawing pure vector paths with CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

enum TxIconKind {
  send,
  receive,
  deposit,
  withdrawal,
  swap,
  fee,
  qrCode,
  nfc,
  pending,
  confirmed,
  failed,
  clock,
  address,
  network,
  card,
  sendLightning,
  receiveLightning,
}

class AnimatedTxIcon extends StatefulWidget {
  final TxIconKind kind;
  final Color color;
  final double size;

  const AnimatedTxIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 44,
  });

  @override
  State<AnimatedTxIcon> createState() => _AnimatedTxIconState();
}

class _AnimatedTxIconState extends State<AnimatedTxIcon>
    with TickerProviderStateMixin {
  late AnimationController _primary;
  late AnimationController _secondary;

  @override
  void initState() {
    super.initState();

    _primary = AnimationController(
      vsync: this,
      duration: _primaryDuration(widget.kind),
    );
    _secondary = AnimationController(
      vsync: this,
      duration: _secondaryDuration(widget.kind),
    );

    switch (widget.kind) {
      case TxIconKind.nfc:
      case TxIconKind.pending:
      case TxIconKind.swap:
        _primary.repeat();
        _secondary.repeat(reverse: true);
        break;
      case TxIconKind.send:
      case TxIconKind.receive:
      case TxIconKind.deposit:
      case TxIconKind.withdrawal:
        _primary.repeat(reverse: false);
        _secondary.repeat(reverse: true);
        break;
      case TxIconKind.qrCode:
        _primary.repeat(reverse: false);
        break;
      case TxIconKind.confirmed:
        _primary.forward();
        break;
      case TxIconKind.failed:
        _primary.forward();
        break;
      case TxIconKind.sendLightning:
      case TxIconKind.receiveLightning:
        _primary.repeat();
        _secondary.repeat(reverse: true);
        break;
      case TxIconKind.fee:
      case TxIconKind.clock:
      case TxIconKind.address:
      case TxIconKind.network:
      case TxIconKind.card:
        _primary.repeat(reverse: true);
        break;
    }
  }

  Duration _primaryDuration(TxIconKind k) {
    switch (k) {
      case TxIconKind.nfc:
        return const Duration(milliseconds: 1600);
      case TxIconKind.pending:
        return const Duration(seconds: 2);
      case TxIconKind.swap:
        return const Duration(milliseconds: 1800);
      case TxIconKind.qrCode:
        return const Duration(milliseconds: 2400);
      case TxIconKind.confirmed:
        return const Duration(milliseconds: 700);
      case TxIconKind.failed:
        return const Duration(milliseconds: 500);
      default:
        return const Duration(milliseconds: 1400);
    }
  }

  Duration _secondaryDuration(TxIconKind k) {
    switch (k) {
      case TxIconKind.send:
      case TxIconKind.receive:
      case TxIconKind.deposit:
      case TxIconKind.withdrawal:
        return const Duration(milliseconds: 800);
      default:
        return const Duration(seconds: 1);
    }
  }

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_primary, _secondary]),
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _painterFor(
            widget.kind,
            widget.color,
            _primary.value,
            _secondary.value,
          ),
        );
      },
    );
  }

  CustomPainter _painterFor(
    TxIconKind kind,
    Color color,
    double t,
    double t2,
  ) {
    switch (kind) {
      case TxIconKind.send:
        return _SendPainter(color: color, t: t, t2: t2);
      case TxIconKind.receive:
        return _ReceivePainter(color: color, t: t, t2: t2);
      case TxIconKind.deposit:
        return _DepositPainter(color: color, t: t, t2: t2);
      case TxIconKind.withdrawal:
        return _WithdrawalPainter(color: color, t: t, t2: t2);
      case TxIconKind.swap:
        return _SwapPainter(color: color, t: t);
      case TxIconKind.fee:
        return _FeePainter(color: color, t: t);
      case TxIconKind.qrCode:
        return _QrPainter(color: color, t: t);
      case TxIconKind.nfc:
        return _NfcPainter(color: color, t: t);
      case TxIconKind.pending:
        return _PendingPainter(color: color, t: t);
      case TxIconKind.confirmed:
        return _ConfirmedPainter(color: color, t: t);
      case TxIconKind.failed:
        return _FailedPainter(color: color, t: t);
      case TxIconKind.clock:
        return _ClockPainter(color: color, t: t);
      case TxIconKind.address:
        return _AddressPainter(color: color, t: t);
      case TxIconKind.network:
        return _NetworkPainter(color: color, t: t);
      case TxIconKind.card:
        return _CardPainter(color: color, t: t);
      case TxIconKind.sendLightning:
        return _SendLightningPainter(color: color, t: t, t2: t2);
      case TxIconKind.receiveLightning:
        return _ReceiveLightningPainter(color: color, t: t, t2: t2);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND — arrow shoot upward, dot slides up

class _SendPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 movement
  final double t2; // 0..1 pulse

  _SendPainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.44;
    final cy = h * 0.52;
    final radius = w * 0.32;

    _drawCyberCoin(canvas, Offset(cx, cy), radius, const Color(0xFFF7931A), t2);
    _drawBitcoinLogo(canvas, Offset(cx, cy), radius * 0.7, Colors.white);

    // Premium Animated Arrow (Up-Right)
    final arrowOffset = Curves.easeOutCubic.transform(t) * (w * 0.12);
    final arrowBase = Offset(w * 0.7 + arrowOffset, h * 0.32 - arrowOffset);
    _drawCyberArrow(canvas, arrowBase, w * 0.28, color, 1);
  }

  @override
  bool shouldRepaint(covariant _SendPainter o) => o.t != t || o.t2 != t2;
}

class _ReceivePainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _ReceivePainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.56;
    final cy = h * 0.48;
    final radius = w * 0.32;

    _drawCyberCoin(canvas, Offset(cx, cy), radius, const Color(0xFFF7931A), t2);
    _drawBitcoinLogo(canvas, Offset(cx, cy), radius * 0.7, Colors.white);

    // Premium Animated Arrow (Down-Left)
    final arrowOffset = Curves.easeOutCubic.transform(t) * (w * 0.12);
    final arrowBase = Offset(w * 0.3 - arrowOffset, h * 0.68 + arrowOffset);
    _drawCyberArrow(canvas, arrowBase, w * 0.28, color, -1);
  }

  @override
  bool shouldRepaint(covariant _ReceivePainter o) => o.t != t || o.t2 != t2;
}

// ─────────────────────────────────────────────────────────────────────────────
// DEPOSIT — arrow down, tray/floor line at bottom

class _DepositPainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _DepositPainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.62;
    final radius = w * 0.32;

    _drawCyberCoin(canvas, Offset(cx, cy), radius, const Color(0xFFF7931A), t2);
    _drawBitcoinLogo(canvas, Offset(cx, cy), radius * 0.7, Colors.white);

    // Arrow dropping into coin
    final arrowB = Curves.easeOut.transform(t) * (h * 0.1);
    _drawCyberArrow(canvas, Offset(cx, h * 0.36 + arrowB), w * 0.28, color, 0);
  }

  @override
  bool shouldRepaint(covariant _DepositPainter o) => o.t != t || o.t2 != t2;
}

// ─────────────────────────────────────────────────────────────────────────────
// WITHDRAWAL — arrow up, tray at bottom

class _WithdrawalPainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _WithdrawalPainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.38;
    final radius = w * 0.32;

    _drawCyberCoin(canvas, Offset(cx, cy), radius, const Color(0xFFF7931A), t2);
    _drawBitcoinLogo(canvas, Offset(cx, cy), radius * 0.7, Colors.white);

    // Arrow shooting up from coin
    final arrowB = Curves.easeOut.transform(t) * (h * 0.1);
    final tip = Offset(cx, h * 0.22 - arrowB);

    // Custom Up Arrow
    final p = Paint()
      ..color = color
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, Offset(cx, tip.dy + w * 0.2), p);
    canvas.drawLine(tip, Offset(cx - w * 0.1, tip.dy + w * 0.1), p);
    canvas.drawLine(tip, Offset(cx + w * 0.1, tip.dy + w * 0.1), p);
  }

  @override
  bool shouldRepaint(covariant _WithdrawalPainter o) => o.t != t || o.t2 != t2;
}

// ─────────────────────────────────────────────────────────────────────────────
// SWAP — two circular arrows rotating in opposite directions

class _SwapPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 movement

  _SwapPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    // Two rotating arcs with neon pulse
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final angle = t * 2 * pi;

    // Arc 1
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.35),
        angle, pi * 0.7, false, p);
    // Arc 2
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.35),
        angle + pi, pi * 0.7, false, p);

    // Bitcoin Logo Center
    _drawBitcoinLogo(
        canvas, Offset(cx, cy), w * 0.3, color.withValues(alpha: 0.8));

    // Glow pulse
    canvas.drawCircle(
        Offset(cx, cy),
        w * 0.45,
        Paint()
          ..color = color.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(covariant _SwapPainter o) => o.t != t;
}

class _FeePainter extends CustomPainter {
  final Color color;
  final double t;

  _FeePainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawNeonBolt(
        canvas, Offset(w * 0.5, h * 0.5), w * 0.8, const Color(0xFFFFC107), t);
  }

  @override
  bool shouldRepaint(covariant _FeePainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// QR CODE — pixel matrix + animated scanning line

class _QrPainter extends CustomPainter {
  final Color color;
  final double t;

  _QrPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Matrix Glow
    final rect = Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w * 0.1)),
      Paint()
        ..color = color.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Draw stylized Corners
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 0.2;
    canvas.drawLine(
        Offset(rect.left, rect.top + w * len), Offset(rect.left, rect.top), p);
    canvas.drawLine(
        Offset(rect.left, rect.top), Offset(rect.left + w * len, rect.top), p);
    canvas.drawLine(Offset(rect.right - w * len, rect.top),
        Offset(rect.right, rect.top), p);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + w * len), p);
    canvas.drawLine(Offset(rect.left, rect.bottom - w * len),
        Offset(rect.left, rect.bottom), p);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + w * len, rect.bottom), p);
    canvas.drawLine(Offset(rect.right - w * len, rect.bottom),
        Offset(rect.right, rect.bottom), p);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - w * len), p);

    _drawBitcoinLogo(canvas, Offset(w * 0.5, h * 0.5), w * 0.3,
        color.withValues(alpha: 0.3));

    final scanY = rect.top + (rect.height * t);
    canvas.drawLine(
      Offset(rect.left, scanY),
      Offset(rect.right, scanY),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter o) => o.t != t;
}

class _NfcPainter extends CustomPainter {
  final Color color;
  final double t;

  _NfcPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    _drawBitcoinLogo(canvas, Offset(cx, cy), w * 0.3, color);

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final waveT = (t + (i * 0.33)) % 1.0;
      p.strokeWidth = (1 - waveT) * 4;
      p.color = color.withValues(alpha: 1 - waveT);
      canvas.drawCircle(Offset(cx, cy), w * 0.3 + (waveT * w * 0.3), p);
    }
  }

  @override
  bool shouldRepaint(covariant _NfcPainter o) => o.t != t;
}

class _PendingPainter extends CustomPainter {
  final Color color;
  final double t;

  _PendingPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    final p = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), w * 0.42, p);

    final p2 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.42),
        t * 2 * pi, pi * 0.6, false, p2);

    _drawBitcoinLogo(
        canvas, Offset(cx, cy), w * 0.35, color.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _PendingPainter o) => o.t != t;
}

class _ConfirmedPainter extends CustomPainter {
  final Color color;
  final double t;

  _ConfirmedPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, cy)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    final metrics = path.computeMetrics().first;
    canvas.drawPath(metrics.extractPath(0, metrics.length * t), p);
  }

  @override
  bool shouldRepaint(covariant _ConfirmedPainter o) => o.t != t;
}

class _FailedPainter extends CustomPainter {
  final Color color;
  final double t;

  _FailedPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final p1 = Path()
      ..moveTo(w * 0.2, h * 0.2)
      ..lineTo(w * 0.8, h * 0.8);
    final p2 = Path()
      ..moveTo(w * 0.8, h * 0.2)
      ..lineTo(w * 0.2, h * 0.8);

    for (var path in [p1, p2]) {
      final m = path.computeMetrics().first;
      canvas.drawPath(m.extractPath(0, m.length * t), p);
    }
  }

  @override
  bool shouldRepaint(covariant _FailedPainter o) => o.t != t;
}

class _ClockPainter extends CustomPainter {
  final Color color;
  final double t;
  _ClockPainter({required this.color, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * 0.6 * cos(t * 2 * pi), cy + r * 0.6 * sin(t * 2 * pi)),
        p);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter o) => o.t != t;
}

class _AddressPainter extends CustomPainter {
  final Color color;
  final double t;

  _AddressPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.055;
    final cy = h * 0.5;

    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final leftCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.26, w * 0.22, h * 0.48),
      Radius.circular(w * 0.07),
    );
    final rightCard = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.66, h * 0.26, w * 0.22, h * 0.48),
      Radius.circular(w * 0.07),
    );

    canvas.drawRRect(leftCard, glowPaint);
    canvas.drawRRect(rightCard, glowPaint);
    canvas.drawRRect(leftCard, framePaint);
    canvas.drawRRect(rightCard, framePaint);

    final leftTextPaint = Paint()
      ..color = color.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.52
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.16, h * 0.42),
      Offset(w * 0.28, h * 0.42),
      leftTextPaint,
    );
    canvas.drawLine(
      Offset(w * 0.16, h * 0.52),
      Offset(w * 0.26, h * 0.52),
      leftTextPaint,
    );
    canvas.drawLine(
      Offset(w * 0.72, h * 0.42),
      Offset(w * 0.84, h * 0.42),
      leftTextPaint,
    );
    canvas.drawLine(
      Offset(w * 0.72, h * 0.52),
      Offset(w * 0.82, h * 0.52),
      leftTextPaint,
    );

    final connectorStart = Offset(w * 0.38, cy);
    final connectorEnd = Offset(w * 0.62, cy);
    final connectorPaint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.78
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(connectorStart, connectorEnd, connectorPaint);

    final headX = (connectorStart.dx + (w * 0.03)) +
        ((connectorEnd.dx - (w * 0.03)) - (connectorStart.dx + (w * 0.03))) *
            Curves.easeInOut.transform(t);
    final pulsePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headX, cy),
      w * 0.048,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(Offset(headX, cy), w * 0.04, pulsePaint);

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arrowTip = Offset(w * 0.62, cy);
    canvas.drawLine(Offset(w * 0.46, cy), arrowTip, arrowPaint);
    canvas.drawLine(
      arrowTip,
      Offset(w * 0.56, cy - (h * 0.08)),
      arrowPaint,
    );
    canvas.drawLine(
      arrowTip,
      Offset(w * 0.56, cy + (h * 0.08)),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AddressPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _NetworkPainter extends CustomPainter {
  final Color color;
  final double t;
  _NetworkPainter({required this.color, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.05;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = sw;
    final points = [
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.15, h * 0.5),
      Offset(w * 0.85, h * 0.5),
      Offset(w * 0.5, h * 0.85)
    ];
    for (var p in points) {
      canvas.drawCircle(p, w * 0.08, paint);
    }
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.2 + (0.3 * t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.6;
    canvas.drawLine(points[0], points[1], linePaint);
    canvas.drawLine(points[0], points[2], linePaint);
    canvas.drawLine(points[1], points[3], linePaint);
    canvas.drawLine(points[2], points[3], linePaint);
    canvas.drawLine(points[1], points[2], linePaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD
class _CardPainter extends CustomPainter {
  final Color color;
  final double t;
  _CardPainter({required this.color, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.06;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.1, h * 0.28, w * 0.8, h * 0.44),
            Radius.circular(w * 0.1)),
        paint);
    // Card chip
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.42, w * 0.15, h * 0.15),
        Paint()..color = color.withValues(alpha: 0.4 + (0.4 * t)));
  }

  @override
  bool shouldRepaint(covariant _CardPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM DRAWING HELPERS
// ─────────────────────────────────────────────────────────────────────────────

void _drawCyberCoin(
    Canvas canvas, Offset center, double radius, Color color, double pulse) {
  final paint = Paint()
    ..shader = RadialGradient(
      colors: [
        color,
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.4),
      ],
      stops: const [0.6, 0.9, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

  // 1. Glow
  canvas.drawCircle(
    center,
    radius + (4 * pulse),
    Paint()
      ..color = color.withValues(alpha: 0.15 + (0.1 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );

  // 2. Base
  canvas.drawCircle(center, radius, paint);

  // 3. Ring
  canvas.drawCircle(
    center,
    radius * 0.9,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
}

void _drawBitcoinLogo(Canvas canvas, Offset center, double size, Color color) {
  final cx = center.dx;
  final cy = center.dy;
  final s = size;

  final bPaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.14
    ..strokeCap = StrokeCap.round;

  // Main vertical bar
  canvas.drawLine(Offset(cx - s * 0.1, cy - s * 0.5),
      Offset(cx - s * 0.1, cy + s * 0.5), bPaint);

  final bPath = Path()
    ..moveTo(cx - s * 0.1, cy - s * 0.5)
    ..quadraticBezierTo(cx + s * 0.6, cy - s * 0.5, cx + s * 0.5, cy - s * 0.2)
    ..quadraticBezierTo(cx + s * 0.4, cy, cx - s * 0.1, cy)
    ..moveTo(cx - s * 0.1, cy)
    ..quadraticBezierTo(cx + s * 0.7, cy, cx + s * 0.6, cy + s * 0.25)
    ..quadraticBezierTo(cx + s * 0.5, cy + s * 0.5, cx - s * 0.1, cy + s * 0.5);
  canvas.drawPath(bPath, bPaint);

  // Ticks
  canvas.drawLine(Offset(cx + s * 0.1, cy - s * 0.65),
      Offset(cx + s * 0.1, cy - s * 0.5), bPaint);
  canvas.drawLine(Offset(cx + s * 0.3, cy - s * 0.65),
      Offset(cx + s * 0.3, cy - s * 0.5), bPaint);
  canvas.drawLine(Offset(cx + s * 0.1, cy + s * 0.5),
      Offset(cx + s * 0.1, cy + s * 0.65), bPaint);
  canvas.drawLine(Offset(cx + s * 0.3, cy + s * 0.5),
      Offset(cx + s * 0.3, cy + s * 0.65), bPaint);
}

void _drawCyberArrow(
    Canvas canvas, Offset tip, double len, Color color, int direction) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = len * 0.18
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  Offset start;
  if (direction == 1) {
    // Up-Right
    start = Offset(tip.dx - len, tip.dy + len);
  } else if (direction == -1) {
    // Down-Left
    start = Offset(tip.dx + len, tip.dy - len);
  } else {
    // Down (direction 0)
    start = Offset(tip.dx, tip.dy - len);
  }

  // Trail effect (shadow/glow)
  canvas.drawLine(
    start,
    tip,
    Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = paint.strokeWidth * 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );

  canvas.drawLine(start, tip, paint);

  final headSize = len * 0.4;
  if (direction == 1) {
    // Up-Right
    canvas.drawLine(
        tip, Offset(tip.dx - headSize, tip.dy + headSize * 0.1), paint);
    canvas.drawLine(
        tip, Offset(tip.dx - headSize * 0.1, tip.dy + headSize), paint);
  } else if (direction == -1) {
    // Down-Left
    canvas.drawLine(
        tip, Offset(tip.dx + headSize, tip.dy - headSize * 0.1), paint);
    canvas.drawLine(
        tip, Offset(tip.dx + headSize * 0.1, tip.dy - headSize), paint);
  } else {
    // Down
    canvas.drawLine(
        tip, Offset(tip.dx - headSize * 0.5, tip.dy - headSize * 0.5), paint);
    canvas.drawLine(
        tip, Offset(tip.dx + headSize * 0.5, tip.dy - headSize * 0.5), paint);
  }
}

void _drawNeonBolt(
    Canvas canvas, Offset center, double size, Color color, double pulse) {
  final cx = center.dx;
  final cy = center.dy;
  final s = size;

  final path = Path()
    ..moveTo(cx + s * 0.15, cy - s * 0.45)
    ..lineTo(cx - s * 0.35, cy + s * 0.05)
    ..lineTo(cx - s * 0.05, cy + s * 0.05)
    ..lineTo(cx - s * 0.15, cy + s * 0.45)
    ..lineTo(cx + s * 0.35, cy - s * 0.05)
    ..lineTo(cx + s * 0.05, cy - s * 0.05)
    ..close();

  // Glow
  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: 0.3 * (0.8 + 0.2 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );

  // Main Bolt
  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill,
  );
}

class _SendLightningPainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _SendLightningPainter(
      {required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.45;
    final cy = h * 0.55;

    _drawNeonBolt(canvas, Offset(cx, cy), w * 0.7, const Color(0xFFFFC107), t);

    final arrowMove = Curves.easeInOut.transform(t2) * (w * 0.1);
    final arrowBase = Offset(w * 0.7 + arrowMove, h * 0.3 - arrowMove);
    _drawCyberArrow(canvas, arrowBase, w * 0.28, color, 1);
  }

  @override
  bool shouldRepaint(covariant _SendLightningPainter o) =>
      o.t != t || o.t2 != t2;
}

class _ReceiveLightningPainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _ReceiveLightningPainter(
      {required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.58;

    final arrowB = Curves.easeInOut.transform(t2) * (h * 0.08);
    final arrowBase = Offset(cx, h * 0.28 + arrowB);
    _drawCyberArrow(canvas, arrowBase, w * 0.3, const Color(0xFFF7931A), 0);

    final deviceRect = Rect.fromCenter(
        center: Offset(cx, cy), width: w * 0.65, height: h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(deviceRect, Radius.circular(w * 0.05)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deviceRect, Radius.circular(w * 0.05)),
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    _drawNeonBolt(canvas, Offset(cx, cy), w * 0.45, const Color(0xFFFFC107), t);

    final scanY = deviceRect.top + (deviceRect.height * t);
    canvas.drawLine(
      Offset(deviceRect.left, scanY),
      Offset(deviceRect.right, scanY),
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ReceiveLightningPainter o) =>
      o.t != t || o.t2 != t2;
}
