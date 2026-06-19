import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/design_system/icons.dart';

enum LoginAccessMotionHeroMode {
  passkeyConnect,
  passkeyTransfer,
  passkeyPrompt,
  passphrase,
  shamir,
  multisig,
  success,
  warning,
  rejected,
  missingUser,
  sessionExpired,
}

class LoginAccessMotionHero extends StatefulWidget {
  final LoginAccessMotionHeroMode mode;
  final Color color;
  final double size;

  const LoginAccessMotionHero({
    super.key,
    required this.mode,
    required this.color,
    this.size = 172,
  });

  @override
  State<LoginAccessMotionHero> createState() => _LoginAccessMotionHeroState();
}

class _LoginAccessMotionHeroState extends State<LoginAccessMotionHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: KeroseneMotion.heroLoop,
    )..repeat();
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
          final progress = KeroseneMotion.standard.transform(_controller.value);
          final pulse = 0.97 + (math.sin(progress * math.pi * 2) * 0.025);

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: widget.size * 0.92,
                  height: widget.size * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.18),
                        widget.color.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              _OrbitShell(
                size: widget.size,
                color: widget.color,
                progress: progress,
              ),
              AnimatedSwitcher(
                duration: KeroseneMotion.long,
                switchInCurve: KeroseneMotion.standard,
                switchOutCurve: KeroseneMotion.exit,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: _SceneLayer(
                  key: ValueKey(widget.mode),
                  mode: widget.mode,
                  color: widget.color,
                  progress: progress,
                  size: widget.size,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitShell extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;

  const _OrbitShell({
    required this.size,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.16),
              ),
            ),
          ),
          Transform.rotate(
            angle: progress * math.pi * 2,
            child: SizedBox(
              width: size * 0.76,
              height: size * 0.76,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: _OrbitDot(
                      color: color,
                      radius: 5,
                      alpha: 0.88,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _OrbitDot(
                      color: color,
                      radius: 3.5,
                      alpha: 0.42,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _OrbitDot(
                      color: color,
                      radius: 4,
                      alpha: 0.56,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SceneLayer extends StatelessWidget {
  final LoginAccessMotionHeroMode mode;
  final Color color;
  final double progress;
  final double size;

  const _SceneLayer({
    super.key,
    required this.mode,
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      LoginAccessMotionHeroMode.passkeyConnect => _PasskeyConnectScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.passkeyTransfer => _PasskeyTransferScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.passkeyPrompt => _PasskeyPromptScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.passphrase => _PassphraseScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.shamir => _ShamirScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.multisig => _MultisigScene(
          color: color,
          progress: progress,
          size: size,
        ),
      LoginAccessMotionHeroMode.success => _StatusScene(
          color: color,
          progress: progress,
          size: size,
          icon: KeroseneIcons.security,
        ),
      LoginAccessMotionHeroMode.warning => _StatusScene(
          color: color,
          progress: progress,
          size: size,
          icon: KeroseneIcons.warning,
        ),
      LoginAccessMotionHeroMode.rejected => _StatusScene(
          color: color,
          progress: progress,
          size: size,
          icon: KeroseneIcons.keyOff,
        ),
      LoginAccessMotionHeroMode.missingUser => _StatusScene(
          color: color,
          progress: progress,
          size: size,
          icon: KeroseneIcons.userUnavailable,
        ),
      LoginAccessMotionHeroMode.sessionExpired => _StatusScene(
          color: color,
          progress: progress,
          size: size,
          icon: KeroseneIcons.timerOff,
        ),
    };
  }
}

class _PasskeyConnectScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _PasskeyConnectScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dotX = -30 + (progress * 60);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.14,
            child: _IconBadge(
              icon: KeroseneIcons.server,
              color: color,
            ),
          ),
          Positioned(
            right: size * 0.14,
            child: _IconBadge(
              icon: KeroseneIcons.hub,
              color: color,
            ),
          ),
          Container(
            width: 74,
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Transform.translate(
            offset: Offset(dotX, 0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyTransferScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _PasskeyTransferScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final chipX = -26 + (progress * 52);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.16,
            child: _IconBadge(
              icon: KeroseneIcons.key,
              color: color,
            ),
          ),
          Positioned(
            right: size * 0.16,
            child: _IconBadge(
              icon: KeroseneIcons.unlock,
              color: color,
            ),
          ),
          Container(
            width: 82,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
          ),
          Transform.translate(
            offset: Offset(chipX, 0),
            child: Container(
              width: 30,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.34),
                    color.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasskeyPromptScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _PasskeyPromptScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ringScale = 0.88 + (progress * 0.28);
    final ringAlpha = (0.28 * (1 - progress)).clamp(0.0, 0.28);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: ringAlpha),
                  width: 1.8,
                ),
              ),
            ),
          ),
          Container(
            width: 92,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  KeroseneIcons.biometric,
                  size: 44,
                  color: color,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassphraseScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _PassphraseScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, math.sin(progress * math.pi * 2) * 4),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _WordLine(width: 64),
                  SizedBox(height: 10),
                  _WordLine(width: 78),
                  SizedBox(height: 10),
                  _WordLine(width: 54),
                ],
              ),
            ),
          ),
          Positioned(
            right: size * 0.20,
            top: size * 0.23,
            child: _IconBadge(
              icon: KeroseneIcons.key,
              color: color,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordLine extends StatelessWidget {
  final double width;

  const _WordLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ShamirScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _ShamirScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final bob = math.sin(progress * math.pi * 2) * 3;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(-18, 16 + bob),
            child:
                _ShardCard(label: 'S1', color: color.withValues(alpha: 0.62)),
          ),
          Transform.translate(
            offset: Offset(0, bob),
            child: _ShardCard(label: 'S2', color: color),
          ),
          Transform.translate(
            offset: Offset(18, -16 + bob),
            child:
                _ShardCard(label: 'S3', color: color.withValues(alpha: 0.74)),
          ),
        ],
      ),
    );
  }
}

class _ShardCard extends StatelessWidget {
  final String label;
  final Color color;

  const _ShardCard({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

class _MultisigScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;

  const _MultisigScene({
    required this.color,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.94 + (math.sin(progress * math.pi * 2) * 0.06);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Transform.scale(
              scale: pulse,
              child: Icon(
                KeroseneIcons.shield,
                size: 40,
                color: color,
              ),
            ),
          ),
          _Connector(
            color: color,
            begin: const Offset(0, -34),
            end: const Offset(0, -62),
          ),
          _Connector(
            color: color,
            begin: const Offset(-28, 22),
            end: const Offset(-56, 44),
          ),
          _Connector(
            color: color,
            begin: const Offset(28, 22),
            end: const Offset(56, 44),
          ),
          const Positioned(
            top: 12,
            child: _NodeDot(),
          ),
          const Positioned(
            left: 18,
            bottom: 18,
            child: _NodeDot(),
          ),
          const Positioned(
            right: 18,
            bottom: 18,
            child: _NodeDot(),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final Color color;
  final Offset begin;
  final Offset end;

  const _Connector({
    required this.color,
    required this.begin,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final angle = math.atan2(end.dy - begin.dy, end.dx - begin.dx);
    final length = (end - begin).distance;

    return Transform.translate(
      offset: begin,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.centerLeft,
        child: Container(
          width: length,
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _NodeDot extends StatelessWidget {
  const _NodeDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.88),
      ),
      child: SizedBox(width: 14, height: 14),
    );
  }
}

class _StatusScene extends StatelessWidget {
  final Color color;
  final double progress;
  final double size;
  final IconData icon;

  const _StatusScene({
    required this.color,
    required this.progress,
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.96 + (math.sin(progress * math.pi * 2) * 0.04);

    return Transform.scale(
      scale: pulse,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Icon(
          icon,
          size: 44,
          color: color,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _IconBadge({
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 46.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Icon(
        icon,
        size: compact ? 18 : 22,
        color: color,
      ),
    );
  }
}
