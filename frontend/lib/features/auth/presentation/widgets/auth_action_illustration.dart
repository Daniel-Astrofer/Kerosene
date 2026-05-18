import 'dart:math' as math;

import 'package:flutter/material.dart';

double _sceneProgress(
  double progress,
  double begin,
  double end, {
  Curve curve = Curves.easeInOutCubic,
}) {
  final t = ((progress - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(t);
}

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
    this.duration = const Duration(milliseconds: 5200),
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
    _restart();
  }

  @override
  void didUpdateWidget(covariant AuthActionIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.duration != widget.duration ||
        oldWidget.color != widget.color) {
      _controller.duration = widget.duration;
      _restart();
    }
  }

  void _restart() {
    _controller.stop();
    _controller.reset();
    if (_repeats) {
      _controller.repeat();
      return;
    }
    _controller.forward();
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
          final progress = Curves.easeInOutCubic.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _GlowBackdrop(
                color: widget.color,
                progress: progress,
              ),
              _OrbitLayer(
                color: widget.color,
                progress: progress,
                repeats: _repeats,
              ),
              _ModeScene(
                mode: widget.mode,
                color: widget.color,
                progress: progress,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeScene extends StatelessWidget {
  final AuthActionIllustrationMode mode;
  final Color color;
  final double progress;

  const _ModeScene({
    required this.mode,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      AuthActionIllustrationMode.connectingServer => _ConnectionScene(
          color: color,
          progress: progress,
          sourceIcon: Icons.cloud_queue_rounded,
          targetIcon: Icons.dns_rounded,
        ),
      AuthActionIllustrationMode.keyTransfer => _ConnectionScene(
          color: color,
          progress: progress,
          sourceIcon: Icons.key_rounded,
          targetIcon: Icons.lock_open_rounded,
          emphasizeTarget: true,
        ),
      AuthActionIllustrationMode.fingerprintScan => _FingerprintScene(
          color: color,
          progress: progress,
        ),
      AuthActionIllustrationMode.recoveryCodes => _RecoveryScene(
          color: color,
          progress: progress,
        ),
      AuthActionIllustrationMode.shieldSuccess => _TerminalScene(
          color: color,
          progress: progress,
          icon: Icons.verified_user_rounded,
          badgeIcon: Icons.check_rounded,
          badgeColor: color,
        ),
      AuthActionIllustrationMode.userMissing => _TerminalScene(
          color: color,
          progress: progress,
          icon: Icons.person_off_rounded,
          badgeIcon: Icons.search_off_rounded,
          badgeColor: color,
        ),
      AuthActionIllustrationMode.warning => _TerminalScene(
          color: color,
          progress: progress,
          icon: Icons.warning_amber_rounded,
          badgeIcon: Icons.priority_high_rounded,
          badgeColor: color,
        ),
      AuthActionIllustrationMode.keyRejected => _TerminalScene(
          color: color,
          progress: progress,
          icon: Icons.key_off_rounded,
          badgeIcon: Icons.close_rounded,
          badgeColor: color,
        ),
      AuthActionIllustrationMode.sessionExpired => _TerminalScene(
          color: color,
          progress: progress,
          icon: Icons.timer_off_rounded,
          badgeIcon: Icons.refresh_rounded,
          badgeColor: color,
        ),
    };
  }
}

class _GlowBackdrop extends StatelessWidget {
  final Color color;
  final double progress;

  const _GlowBackdrop({
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.92 + (math.sin(progress * math.pi * 2) * 0.025);
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.07),
              Colors.transparent,
            ],
            stops: const [0.0, 0.52, 1.0],
          ),
        ),
      ),
    );
  }
}

class _OrbitLayer extends StatelessWidget {
  final Color color;
  final double progress;
  final bool repeats;

  const _OrbitLayer({
    required this.color,
    required this.progress,
    required this.repeats,
  });

  @override
  Widget build(BuildContext context) {
    final rotation =
        repeats ? progress * math.pi * 1.2 : progress * math.pi * 0.9;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.10),
            ),
          ),
        ),
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.14),
            ),
          ),
        ),
        Transform.rotate(
          angle: rotation,
          child: SizedBox(
            width: 138,
            height: 138,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: _OrbitDot(
                    color: color,
                    radius: 5,
                    alpha: 0.82,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _OrbitDot(
                    color: color,
                    radius: 3,
                    alpha: 0.38,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _OrbitDot(
                    color: color,
                    radius: 4,
                    alpha: 0.52,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbitDot extends StatelessWidget {
  final Color color;
  final double radius;
  final double alpha;

  const _OrbitDot({
    required this.color,
    required this.radius,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha * 0.35),
            blurRadius: radius * 4,
            spreadRadius: -1,
          ),
        ],
      ),
    );
  }
}

class _ConnectionScene extends StatelessWidget {
  final Color color;
  final double progress;
  final IconData sourceIcon;
  final IconData targetIcon;
  final bool emphasizeTarget;

  const _ConnectionScene({
    required this.color,
    required this.progress,
    required this.sourceIcon,
    required this.targetIcon,
    this.emphasizeTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final sourceReveal = _sceneProgress(progress, 0.00, 0.22);
    final trackReveal = _sceneProgress(progress, 0.14, 0.62);
    final pulseReveal = _sceneProgress(progress, 0.34, 0.84);
    final targetReveal = _sceneProgress(progress, 0.52, 0.96);
    final bubbleX = -0.78 + (pulseReveal * 1.56);
    final centerLift = math.sin(progress * math.pi * 2) * 3;
    final centerScale = 0.92 + (_sceneProgress(progress, 0.10, 0.38) * 0.08);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 28,
          right: 28,
          child: SizedBox(
            height: 4,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.16 + (trackReveal * 0.84),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.78),
                          color.withValues(alpha: 0.28),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.26),
                          blurRadius: 16,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(-0.82, 0),
          child: _SideGlyph(
            icon: sourceIcon,
            color: color,
            filled: false,
            reveal: sourceReveal,
          ),
        ),
        Align(
          alignment: const Alignment(0.82, 0),
          child: _SideGlyph(
            icon: targetIcon,
            color: color,
            filled: emphasizeTarget,
            reveal: targetReveal,
          ),
        ),
        Align(
          alignment: Alignment(bubbleX, 0),
          child: Opacity(
            opacity: 0.18 + (pulseReveal * 0.82),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.40),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, centerLift),
          child: Transform.scale(
            scale: centerScale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 28,
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    sourceIcon == Icons.key_rounded
                        ? Icons.shield_rounded
                        : Icons.sync_rounded,
                    size: 44,
                    color: color.withValues(alpha: 0.14),
                  ),
                  Icon(
                    sourceIcon == Icons.key_rounded
                        ? Icons.key_rounded
                        : Icons.cloud_sync_rounded,
                    size: 34,
                    color: color.withValues(alpha: 0.96),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FingerprintScene extends StatelessWidget {
  final Color color;
  final double progress;

  const _FingerprintScene({
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final frameReveal = _sceneProgress(progress, 0.00, 0.22);
    final printReveal = _sceneProgress(progress, 0.16, 0.52);
    final scanProgress = _sceneProgress(
      progress,
      0.32,
      0.96,
      curve: Curves.easeInOutSine,
    );
    final promptReveal = _sceneProgress(progress, 0.62, 0.92);
    final scanAlignment = -0.78 + (scanProgress * 1.56);
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: 0.92 + (frameReveal * 0.08),
          child: Container(
            width: 104,
            height: 124,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: color.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 26,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Center(
              child: Opacity(
                opacity: 0.20 + (printReveal * 0.80),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 58,
                  color: color.withValues(alpha: 0.96),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          child: Align(
            alignment: Alignment(0, scanAlignment),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.88),
                    color.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.30),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 26,
          right: 34,
          child: Opacity(
            opacity: 0.18 + (promptReveal * 0.82),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: color.withValues(alpha: 0.88),
              ),
            ),
          ),
        ),
        Positioned(
          left: 36,
          top: 18,
          child: Opacity(
            opacity: frameReveal,
            child: _FrameCorner(
              color: color,
              top: true,
              left: true,
            ),
          ),
        ),
        Positioned(
          right: 36,
          top: 18,
          child: Opacity(
            opacity: frameReveal,
            child: _FrameCorner(
              color: color,
              top: true,
              left: false,
            ),
          ),
        ),
        Positioned(
          left: 36,
          bottom: 18,
          child: Opacity(
            opacity: frameReveal,
            child: _FrameCorner(
              color: color,
              top: false,
              left: true,
            ),
          ),
        ),
        Positioned(
          right: 36,
          bottom: 18,
          child: Opacity(
            opacity: frameReveal,
            child: _FrameCorner(
              color: color,
              top: false,
              left: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryScene extends StatelessWidget {
  final Color color;
  final double progress;

  const _RecoveryScene({
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final firstReveal = _sceneProgress(progress, 0.00, 0.30);
    final secondReveal = _sceneProgress(progress, 0.18, 0.48);
    final thirdReveal = _sceneProgress(progress, 0.36, 0.70);
    final yOffset = math.sin(progress * math.pi * 2) * 3;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(-18, 16 - yOffset),
          child: _RecoveryCard(
            color: color,
            alpha: 0.10,
            reveal: firstReveal,
            icon: Icons.key_rounded,
          ),
        ),
        Transform.translate(
          offset: Offset(18, 2 + (yOffset * 0.4)),
          child: _RecoveryCard(
            color: color,
            alpha: 0.14,
            reveal: secondReveal,
            icon: Icons.security_rounded,
          ),
        ),
        Transform.translate(
          offset: Offset(0, -16 + yOffset),
          child: Transform.scale(
            scale: 0.94 + (thirdReveal * 0.06),
            child: Container(
              width: 96,
              height: 116,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 24,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 34,
                    color: color.withValues(alpha: 0.96),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: color.withValues(alpha: 0.30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: color.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final Color color;
  final double alpha;
  final double reveal;
  final IconData icon;

  const _RecoveryCard({
    required this.color,
    required this.alpha,
    required this.reveal,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.20 + (reveal * 0.80),
      child: Transform.scale(
        scale: 0.92 + (reveal * 0.08),
        child: Container(
          width: 82,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: color.withValues(alpha: alpha)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color.withValues(alpha: 0.92),
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  2,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: index == 1 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TerminalScene extends StatelessWidget {
  final Color color;
  final double progress;
  final IconData icon;
  final IconData badgeIcon;
  final Color badgeColor;

  const _TerminalScene({
    required this.color,
    required this.progress,
    required this.icon,
    required this.badgeIcon,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final reveal = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: 0.86 + (reveal * 0.18),
          child: Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: color.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.16),
                  blurRadius: 28,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 52,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ),
        Positioned(
          right: 30,
          bottom: 28,
          child: Transform.scale(
            scale: 0.6 + (reveal * 0.4),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.94),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(
                badgeIcon,
                size: 18,
                color: Colors.black.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SideGlyph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final double reveal;

  const _SideGlyph({
    required this.icon,
    required this.color,
    this.filled = false,
    this.reveal = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.24 + (reveal * 0.76),
      child: Transform.scale(
        scale: 0.88 + (reveal * 0.12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color.withValues(alpha: 0.90),
          ),
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  final Color color;
  final bool top;
  final bool left;

  const _FrameCorner({
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: color.withValues(alpha: 0.44),
      width: 2,
    );

    return SizedBox(
      width: 18,
      height: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? borderSide : BorderSide.none,
            bottom: top ? BorderSide.none : borderSide,
            left: left ? borderSide : BorderSide.none,
            right: left ? BorderSide.none : borderSide,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(8) : Radius.zero,
            topRight: top && !left ? const Radius.circular(8) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
