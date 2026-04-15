import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

const Color miningInk = Color(0xFF04070C);
const Color miningSurface = Color(0xFF0F151D);
const Color miningSurfaceRaised = Color(0xFF131C27);
const Color miningBorder = Color(0xFF223244);
const Color miningMuted = Color(0xFF8D9AAF);
const Color miningBlue = Color(0xFF67B5FF);
const Color miningTeal = Color(0xFF2AD1A3);
const Color miningAmber = Color(0xFFF4B562);
const Color miningRed = Color(0xFFFF7474);

enum MiningStatusTone {
  neutral,
  live,
  info,
  warning,
  danger,
}

class MiningPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  final double radius;

  const MiningPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent = miningBlue,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: miningBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            miningSurfaceRaised,
            miningSurface,
            miningInk,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 22,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -18,
            child: IgnorePointer(
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 0,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class MiningSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const MiningSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: miningMuted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

class MiningStatusBadge extends StatelessWidget {
  final String label;
  final MiningStatusTone tone;
  final bool pulse;

  const MiningStatusBadge({
    super.key,
    required this.label,
    this.tone = MiningStatusTone.neutral,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            dot
                .animate(onPlay: (controller) => controller.repeat())
                .fade(begin: 0.45, end: 1, duration: 900.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.18, 1.18),
                  duration: 900.ms,
                )
          else
            dot,
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(MiningStatusTone tone) {
    switch (tone) {
      case MiningStatusTone.live:
        return miningTeal;
      case MiningStatusTone.info:
        return miningBlue;
      case MiningStatusTone.warning:
        return miningAmber;
      case MiningStatusTone.danger:
        return miningRed;
      case MiningStatusTone.neutral:
        return miningMuted;
    }
  }
}

class MiningMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color accent;
  final IconData? icon;

  const MiningMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.helper,
    this.accent = miningBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper,
              style: AppTypography.bodySmall.copyWith(color: miningMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class MiningTrendChip extends StatelessWidget {
  final String label;
  final bool positive;

  const MiningTrendChip({
    super.key,
    required this.label,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? miningTeal : miningAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MiningSkeletonBlock extends StatelessWidget {
  final double height;
  final BorderRadius? borderRadius;

  const MiningSkeletonBlock({
    super.key,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fade(begin: 0.45, end: 1, duration: 900.ms)
        .then()
        .fade(begin: 1, end: 0.45, duration: 900.ms);
  }
}
