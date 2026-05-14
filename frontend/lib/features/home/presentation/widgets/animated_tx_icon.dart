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
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEND — arrow shoot upward, dot slides up

class _SendPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 repeating (arrow travels up)
  final double t2; // 0..1 reverse (opacity pulse)

  _SendPainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.055;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stem — fades in at bottom
    final stemTop = cy * 0.2;
    final stemBot = cy * 1.6;
    canvas.drawLine(Offset(cx, stemBot), Offset(cx, stemTop), paint);

    // Arrowhead at top
    final hw = size.width * 0.22;
    final ht = size.height * 0.22;
    final path = Path()
      ..moveTo(cx - hw, stemTop + ht)
      ..lineTo(cx, stemTop)
      ..lineTo(cx + hw, stemTop + ht);
    canvas.drawPath(path, paint);

    // Animated dot sliding up the stem
    final dotY = stemBot - (stemBot - stemTop) * Curves.easeInOut.transform(t);
    canvas.drawCircle(
      Offset(cx, dotY),
      sw * 1.1,
      Paint()..color = color.withValues(alpha: 0.5 + 0.5 * t2),
    );
  }

  @override
  bool shouldRepaint(covariant _SendPainter o) => o.t != t || o.t2 != t2;
}

// ─────────────────────────────────────────────────────────────────────────────
// RECEIVE — arrow dropping down

class _ReceivePainter extends CustomPainter {
  final Color color;
  final double t;
  final double t2;

  _ReceivePainter({required this.color, required this.t, required this.t2});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.055;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stemTop = cy * 0.2;
    final stemBot = cy * 1.6;
    canvas.drawLine(Offset(cx, stemTop), Offset(cx, stemBot), paint);

    final hw = size.width * 0.22;
    final hb = size.height * 0.78;
    final path = Path()
      ..moveTo(cx - hw, hb - size.height * 0.1)
      ..lineTo(cx, hb)
      ..lineTo(cx + hw, hb - size.height * 0.1);
    canvas.drawPath(path, paint);

    // dot travels down
    final dotY = stemTop + (stemBot - stemTop) * Curves.easeInOut.transform(t);
    canvas.drawCircle(
      Offset(cx, dotY),
      sw * 1.1,
      Paint()..color = color.withValues(alpha: 0.5 + 0.5 * t2),
    );
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
    final cx = size.width / 2;
    final sw = size.width * 0.055;
    final floorY = size.height * 0.78;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Floor (tray)
    canvas.drawLine(Offset(size.width * 0.18, floorY),
        Offset(size.width * 0.82, floorY), paint);

    // Stem above floor
    final stemTop = size.height * 0.15;
    final stemBot = floorY - sw;
    canvas.drawLine(Offset(cx, stemTop), Offset(cx, stemBot), paint);

    // Arrowhead
    final hw = size.width * 0.22;
    final path = Path()
      ..moveTo(cx - hw, stemBot - size.height * 0.18)
      ..lineTo(cx, stemBot)
      ..lineTo(cx + hw, stemBot - size.height * 0.18);
    canvas.drawPath(path, paint);

    // Dot sliding down
    final dotY = stemTop + (stemBot - stemTop) * Curves.easeInOut.transform(t);
    canvas.drawCircle(
      Offset(cx, dotY),
      sw * 1.1,
      Paint()..color = color.withValues(alpha: 0.5 + 0.5 * t2),
    );
  }

  @override
  bool shouldRepaint(covariant _DepositPainter o) => o.t != t;
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
    final cx = size.width / 2;
    final sw = size.width * 0.055;
    final floorY = size.height * 0.82;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset(size.width * 0.18, floorY),
        Offset(size.width * 0.82, floorY), paint);

    final stemTop = size.height * 0.15;
    final stemBot = floorY - sw * 1.5;
    canvas.drawLine(Offset(cx, stemBot), Offset(cx, stemTop), paint);

    final hw = size.width * 0.22;
    final ht = size.height * 0.22;
    final path = Path()
      ..moveTo(cx - hw, stemTop + ht)
      ..lineTo(cx, stemTop)
      ..lineTo(cx + hw, stemTop + ht);
    canvas.drawPath(path, paint);

    // Dot travels up from floor
    final dotY = stemBot - (stemBot - stemTop) * Curves.easeInOut.transform(t);
    canvas.drawCircle(
      Offset(cx, dotY),
      sw * 1.1,
      Paint()..color = color.withValues(alpha: 0.5 + 0.5 * t2),
    );
  }

  @override
  bool shouldRepaint(covariant _WithdrawalPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// SWAP — two circular arrows rotating in opposite directions

class _SwapPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 repeating

  _SwapPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.055;
    final r = size.width * 0.22;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final angle = t * 2 * pi;

    // Left arc (counter-clockwise rotating)
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - r * 0.4, cy), width: r * 1.6, height: r * 1.6),
      pi + angle,
      pi * 1.2,
      false,
      paint,
    );
    // Right arc (clockwise rotating)
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx + r * 0.4, cy), width: r * 1.6, height: r * 1.6),
      -angle,
      pi * 1.2,
      false,
      paint,
    );

    // Arrowhead on left arc (bottom)
    final la = pi + angle + pi * 1.2;
    final tip1 =
        Offset(cx - r * 0.4 + r * 0.8 * cos(la), cy + r * 0.8 * sin(la));
    final arrow1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        tip1,
        Offset(tip1.dx - sw * 3.5 * cos(la - 0.6),
            tip1.dy - sw * 3.5 * sin(la - 0.6)),
        arrow1);
    canvas.drawLine(
        tip1,
        Offset(tip1.dx - sw * 3.5 * cos(la + 0.6),
            tip1.dy - sw * 3.5 * sin(la + 0.6)),
        arrow1);
  }

  @override
  bool shouldRepaint(covariant _SwapPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// FEE — lightning bolt with pulse

class _FeePainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 reverse-bouncing (pulse)

  _FeePainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final alpha = 0.5 + 0.5 * t;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lightning bolt
    final path = Path()
      ..moveTo(w * 0.58, h * 0.1)
      ..lineTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.42, h * 0.9)
      ..lineTo(w * 0.70, h * 0.48)
      ..lineTo(w * 0.50, h * 0.48)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _FeePainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// QR CODE — pixel matrix + animated scanning line

class _QrPainter extends CustomPainter {
  final Color color;
  final double t; // scan line progress 0..1

  _QrPainter({required this.color, required this.t});

  static const _matrix = [
    [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0],
    [0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0],
    [0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0],
    [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0],
    [1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final n = _matrix.length;
    final cell = size.width / n;
    final scanY = t * size.height;

    for (int row = 0; row < n; row++) {
      for (int col = 0; col < n; col++) {
        if (_matrix[row][col] == 0) continue;
        final x = col * cell;
        final y = row * cell;
        final cellCenterY = y + cell / 2;
        // Cells below scan line are dimmer (scanner reveals them)
        final revealed = cellCenterY <= scanY ? 1.0 : 0.25;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x + cell * 0.08, y + cell * 0.08, cell * 0.84, cell * 0.84),
            Radius.circular(cell * 0.15),
          ),
          Paint()..color = color.withValues(alpha: revealed),
        );
      }
    }

    // Scan line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), linePaint);

    // Glow on scan line
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// NFC — concentric arcs radiating outward + pulsing

class _NfcPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 repeating

  _NfcPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.35;
    final cy = size.height / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const radii = [0.18, 0.32, 0.46];
    for (int i = 0; i < 3; i++) {
      final delay = i / 3.0;
      final phase = ((t - delay) % 1.0 + 1.0) % 1.0;
      final alpha = (1.0 - phase);
      final r = size.width * (radii[i] + 0.06 * phase);

      paint
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = size.width * 0.055 * (1 - phase * 0.5);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi * 0.6,
        pi * 1.2,
        false,
        paint,
      );
    }

    // Central device dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.07,
      Paint()..color = color.withValues(alpha: 0.85),
    );

    // "Phone edge" line
    final phoneX = size.width * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(phoneX, cy),
            width: size.width * 0.14,
            height: size.height * 0.7),
        Radius.circular(size.width * 0.06),
      ),
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055,
    );
  }

  @override
  bool shouldRepaint(covariant _NfcPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING — rotating clock face

class _PendingPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 repeating

  _PendingPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.40;
    final sw = size.width * 0.055;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    // Circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Hour hand (slow)
    final hourAngle = -pi / 2 + t * pi;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.45 * cos(hourAngle), cy + r * 0.45 * sin(hourAngle)),
      paint,
    );

    // Minute hand (fast)
    final minAngle = -pi / 2 + t * 2 * pi;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.65 * cos(minAngle), cy + r * 0.65 * sin(minAngle)),
      paint,
    );

    // Center dot
    canvas.drawCircle(Offset(cx, cy), sw * 0.7, Paint()..color = color);

    // Tick marks
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * 2 * pi;
      final inner = r * 0.82;
      final outer = r * 0.97;
      canvas.drawLine(
        Offset(cx + inner * cos(a), cy + inner * sin(a)),
        Offset(cx + outer * cos(a), cy + outer * sin(a)),
        paint..strokeWidth = sw * (i % 3 == 0 ? 1.5 : 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PendingPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRMED — checkmark draws itself (path trim animation)

class _ConfirmedPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 one-shot

  _ConfirmedPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.07;

    // Circle fades in
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..color = color.withValues(alpha: t * 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..color = color.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 0.6,
    );

    if (t < 0.01) return;

    // Checkmark path trim
    final path = Path()
      ..moveTo(size.width * 0.25, cy * 1.02)
      ..lineTo(size.width * 0.44, size.height * 0.70)
      ..lineTo(size.width * 0.75, size.height * 0.32);

    final pm = path.computeMetrics();
    for (final m in pm) {
      final extracted =
          m.extractPath(0, m.length * Curves.easeOut.transform(t));
      canvas.drawPath(
        extracted,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfirmedPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// FAILED — X draws itself

class _FailedPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 one-shot

  _FailedPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.07;
    final pad = size.width * 0.22;

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..color = color.withValues(alpha: t * 0.15)
        ..style = PaintingStyle.fill,
    );

    // First diagonal
    final p1 = Path()
      ..moveTo(pad, pad)
      ..lineTo(size.width - pad, size.height - pad);
    // Second diagonal
    final p2 = Path()
      ..moveTo(size.width - pad, pad)
      ..lineTo(pad, size.height - pad);

    final strokePaint = Paint()
      ..color = color.withValues(alpha: t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    for (final path in [p1, p2]) {
      for (final m in path.computeMetrics()) {
        canvas.drawPath(
          m.extractPath(0, m.length * Curves.easeOut.transform(t)),
          strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FailedPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOCK
class _ClockPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1 reverse-bouncing pulse
  _ClockPainter({required this.color, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;
    final sw = size.width * 0.06;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Hour hand static, minute hand pulses
    canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * 0.3 * cos(-pi / 3), cy + r * 0.3 * sin(-pi / 3)),
        paint);
    canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * 0.6 * cos(-pi / 3 + (t * 0.1)),
            cy + r * 0.6 * sin(-pi / 3 + (t * 0.1))),
        paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS
class _AddressPainter extends CustomPainter {
  final Color color;
  final double t;
  _AddressPainter({required this.color, required this.t});
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
    final p1 = Offset(w * 0.2, h * 0.82);
    final p2 = Offset(w * 0.8, h * 0.18);
    canvas.drawCircle(p1, w * 0.12, paint);
    canvas.drawCircle(p2, w * 0.12, paint);
    final path = Path()
      ..moveTo(p1.dx + w * 0.08, p1.dy - w * 0.08)
      ..lineTo(p2.dx - w * 0.08, p2.dy + w * 0.08);
    canvas.drawPath(
        path, paint..color = color.withValues(alpha: 0.3 + 0.3 * t));
  }

  @override
  bool shouldRepaint(covariant _AddressPainter o) => o.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// NETWORK
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
      ..color = color.withValues(alpha: 0.2 + 0.3 * t)
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
        Paint()..color = color.withValues(alpha: 0.4 + 0.4 * t));
  }

  @override
  bool shouldRepaint(covariant _CardPainter o) => o.t != t;
}
