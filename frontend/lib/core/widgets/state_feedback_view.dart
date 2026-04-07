import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_spacing.dart';
import '../presentation/widgets/cyber_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE FEEDBACK VIEW
// A universal, 100% native widget (zero assets) that replaces the white screen
// for Empty, Error, NetworkError and Loading states from the API.
// ─────────────────────────────────────────────────────────────────────────────

enum FeedbackState { empty, error, networkError, loading }

class StateFeedbackView extends StatelessWidget {
  final FeedbackState state;

  /// Human-readable title (uses Theme.of(context).textTheme.titleLarge!).
  final String title;

  /// Supplementary description (uses Theme.of(context).textTheme.bodyMedium!).
  final String description;

  /// Label for the retry/CTA button. Pass null to hide the button.
  final String? actionLabel;

  /// Callback for the CTA button (retry the API call).
  final VoidCallback? onAction;

  const StateFeedbackView({
    super.key,
    required this.state,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  /// Convenience constructors ────────────────────────────────────────────────

  factory StateFeedbackView.empty({
    String title = 'Nada por aqui',
    String description = 'Ainda não tens dados disponíveis nesta secção.',
    String? actionLabel = 'Atualizar',
    VoidCallback? onAction,
  }) =>
      StateFeedbackView(
        state: FeedbackState.empty,
        title: title,
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory StateFeedbackView.error({
    String title = 'Algo correu mal',
    String description = 'O servidor devolveu um erro. Tenta novamente.',
    String? actionLabel = 'Tentar novamente',
    VoidCallback? onAction,
  }) =>
      StateFeedbackView(
        state: FeedbackState.error,
        title: title,
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  factory StateFeedbackView.networkError({
    VoidCallback? onAction,
  }) =>
      StateFeedbackView(
        state: FeedbackState.networkError,
        title: 'Sem ligação',
        description:
            'Não foi possível contactar o servidor. Verifica a tua ligação.',
        actionLabel: 'Tentar novamente',
        onAction: onAction,
      );

  @override
  Widget build(BuildContext context) {
    final color = _colorForState(context, state);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Native Illustration via CustomPaint ──────────────────────────
            _NativeIllustration(state: state, color: color),

            const SizedBox(height: AppSpacing.xl),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: color),
              textAlign: TextAlign.center,
            ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppSpacing.sm),

            // ── Description ──────────────────────────────────────────────────
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium!,
              textAlign: TextAlign.center,
            )
                .animate(delay: 100.ms)
                .fade(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 200,
                child: CyberButton(
                  text: actionLabel!,
                  onTap: onAction,
                ),
              )
                  .animate(delay: 200.ms)
                  .fade(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForState(BuildContext context, FeedbackState s) {
    switch (s) {
      case FeedbackState.empty:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case FeedbackState.error:
        return Theme.of(context).colorScheme.error;
      case FeedbackState.networkError:
        return Theme.of(context).colorScheme.error; // Fallback for warning
      case FeedbackState.loading:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NATIVE ILLUSTRATION — 100% CustomPainter, zero assets
// Picks the correct painter based on state and drives animation natively.
// ─────────────────────────────────────────────────────────────────────────────

class _NativeIllustration extends StatefulWidget {
  final FeedbackState state;
  final Color color;

  const _NativeIllustration({required this.state, required this.color});

  @override
  State<_NativeIllustration> createState() => _NativeIllustrationState();
}

class _NativeIllustrationState extends State<_NativeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 2400.ms);
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _painterForState(widget.state, _ctrl, widget.color);

    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(painter: painter),
    ).animate().scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }

  CustomPainter _painterForState(
    FeedbackState state,
    AnimationController ctrl,
    Color color,
  ) {
    switch (state) {
      case FeedbackState.empty:
        return _EmptyStatePainter(animation: ctrl, color: color);
      case FeedbackState.error:
        return _ErrorStatePainter(animation: ctrl, color: color);
      case FeedbackState.networkError:
        return _NetworkErrorPainter(animation: ctrl, color: color);
      case FeedbackState.loading:
        return _LoadingOrbPainter(animation: ctrl, color: color);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 1 — Empty State
// Draws an abstract "empty box" with a dashed outline and a floating dot.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyStatePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _EmptyStatePainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = animation.value;

    // Floating dot
    final floatOffset = math.sin(t * 2 * math.pi) * 6.0;

    // Box outline
    final rect = Rect.fromCenter(
      center: Offset(cx, cy + 10),
      width: size.width * 0.64,
      height: size.height * 0.52,
    );

    final boxPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, boxPaint);

    // Dashed inner lines
    _drawDashedLine(
      canvas,
      Offset(rect.left + 16, cy),
      Offset(rect.right - 16, cy),
      color.withOpacity(0.15),
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left + 16, cy + 16),
      Offset(rect.right - 36, cy + 16),
      color.withOpacity(0.10),
    );

    // Floating glowing dot
    final dotPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 32 + floatOffset), 7, dotPaint);

    // Halo around dot
    final haloPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - 32 + floatOffset), 14, haloPaint);
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Color color) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final steps = (length / (dashWidth + dashSpace)).floor();
    final normX = dx / length;
    final normY = dy / length;
    for (int i = 0; i < steps; i++) {
      final s = Offset(
        start.dx + normX * i * (dashWidth + dashSpace),
        start.dy + normY * i * (dashWidth + dashSpace),
      );
      final e = Offset(s.dx + normX * dashWidth, s.dy + normY * dashWidth);
      canvas.drawLine(s, e, paint);
    }
  }

  @override
  bool shouldRepaint(_EmptyStatePainter old) => old.animation != animation;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 2 — Error State
// Cracked/fragmented screen shape with pulsing glow — uses Path + PathMetrics.
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorStatePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _ErrorStatePainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = animation.value;

    // Pulsing glow (0.0 → 1.0 → 0.0)
    final pulse = (math.sin(t * math.pi * 2) + 1) / 2;

    // Outer rectangle — the "screen"
    final screenRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: size.width * 0.55,
      height: size.height * 0.68,
    );
    final screenPaint = Paint()
      ..color = color.withOpacity(0.20 + pulse * 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(10)),
      screenPaint,
    );

    // Crack — zig-zag path through the center
    final crackPaint = Paint()
      ..color = color.withOpacity(0.7 + pulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final crack = Path()
      ..moveTo(cx - 8, screenRect.top + 10)
      ..lineTo(cx + 4, cy - 12)
      ..lineTo(cx - 6, cy)
      ..lineTo(cx + 8, cy + 16)
      ..lineTo(cx - 2, screenRect.bottom - 10);

    // Animate crack reveal using PathMetrics
    final pm = crack.computeMetrics().first;
    final revealLength = pm.length * 1.0; // fully revealed; you can animate this
    final extractedPath = pm.extractPath(0, revealLength);
    canvas.drawPath(extractedPath, crackPaint);

    // Center "X" icon
    final xPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const r = 10.0;
    canvas.drawLine(Offset(cx - r, cy - 30 - r), Offset(cx + r, cy - 30 + r), xPaint);
    canvas.drawLine(Offset(cx + r, cy - 30 - r), Offset(cx - r, cy - 30 + r), xPaint);
  }

  @override
  bool shouldRepaint(_ErrorStatePainter old) => old.animation != animation;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 3 — Network Error / No Signal
// Draws WiFi arcs with an X, animating their opacity to signal loss.
// ─────────────────────────────────────────────────────────────────────────────

class _NetworkErrorPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _NetworkErrorPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 12;
    final t = animation.value;

    // Oscillate opacity for "no-signal" flicker effect
    final flicker = (math.sin(t * math.pi * 4) + 1) / 2;

    final arcPaints = [
      Paint()
        ..color = color.withOpacity(0.15 + flicker * 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
      Paint()
        ..color = color.withOpacity(0.30 + flicker * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
      Paint()
        ..color = color.withOpacity(0.50 + flicker * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    ];

    final radii = [52.0, 36.0, 20.0];
    const startAngle = math.pi + (math.pi / 6);
    const sweepAngle = (math.pi * 2 / 3);

    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: radii[i] * 2, height: radii[i] * 2),
        startAngle,
        sweepAngle,
        false,
        arcPaints[i],
      );
    }

    // Dot
    canvas.drawCircle(
      Offset(cx, cy + 8),
      4,
      Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    // Slash line — the "no signal"
    final slashPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 40, cy - 44),
      Offset(cx + 40, cy + 12),
      slashPaint,
    );
  }

  @override
  bool shouldRepaint(_NetworkErrorPainter old) => old.animation != animation;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 4 — Loading Orb
// Multi-ring geometric spinner; each ring rotates at a different speed.
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingOrbPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _LoadingOrbPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = animation.value * 2 * math.pi;

    // Inner filled orb
    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    // Three rings rotating at different speeds
    final rings = [
      (radius: 28.0, speed: 1.0, arcLen: 0.65, alpha: 0.85),
      (radius: 44.0, speed: 0.7, arcLen: 0.50, alpha: 0.55),
      (radius: 60.0, speed: 0.4, arcLen: 0.35, alpha: 0.30),
    ];

    for (final ring in rings) {
      final angle = t * ring.speed;
      final sweep = math.pi * 2 * ring.arcLen;

      final paint = Paint()
        ..color = color.withOpacity(ring.alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: ring.radius * 2,
          height: ring.radius * 2,
        ),
        angle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoadingOrbPainter old) => old.animation != animation;
}
