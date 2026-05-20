import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

const Color miningInk = Color(0xFF020202);
const Color miningSurface = Color(0xFF090909);
const Color miningSurfaceRaised = Color(0xFF111111);
const Color miningSurfaceElevated = Color(0xFF171717);
const Color miningBorder = Color(0xFF232323);
const Color miningBorderStrong = Color(0xFF383B40);
const Color miningMuted = Color(0xFF8E949C);
const Color miningBlue = Color(0xFFC4CDD8);
const Color miningTeal = Color(0xFFF2F3F4);
const Color miningAmber = Color(0xFFAAB0B8);
const Color miningRed = Color(0xFF727880);

const double miningPanelRadiusValue = 4;
const double miningInnerRadiusValue = 3;
const BorderRadius miningPanelBorderRadius = BorderRadius.all(
  Radius.circular(miningPanelRadiusValue),
);
const BorderRadius miningInnerBorderRadius = BorderRadius.all(
  Radius.circular(miningInnerRadiusValue),
);

enum MiningStatusTone { neutral, live, info, warning, danger }

Color miningToneColor(MiningStatusTone tone) {
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

Color miningAccentBorder(Color accent, {double emphasis = 0.18}) {
  return Color.lerp(miningBorderStrong, accent, emphasis) ?? miningBorderStrong;
}

BoxDecoration miningInsetDecoration({
  Color accent = miningBlue,
  bool emphasized = false,
  Color? color,
}) {
  final borderColor = miningAccentBorder(
    accent,
    emphasis: emphasized ? 0.34 : 0.14,
  );

  return BoxDecoration(
    color: color ?? miningSurfaceRaised,
    borderRadius: miningInnerBorderRadius,
    border: Border.all(color: borderColor),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (color ?? miningSurfaceElevated).withValues(alpha: 0.98),
        (color ?? miningSurfaceRaised).withValues(alpha: 0.98),
      ],
    ),
  );
}

TextStyle miningMonoStyle(
  TextStyle base, {
  Color? color,
  FontWeight? fontWeight,
  double? fontSize,
  double? height,
  double? letterSpacing,
}) {
  return base.copyWith(
    fontFamily: AppTypography.numericFontFamily,
    color: color,
    fontWeight: fontWeight,
    fontSize: fontSize,
    height: height,
    letterSpacing: letterSpacing,
  );
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
    this.radius = miningPanelRadiusValue,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: miningAccentBorder(accent)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [miningSurfaceElevated, miningSurface, miningInk],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _CornerBracket(
              accent: accent.withValues(alpha: 0.32),
              alignEnd: false,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _CornerBracket(
              accent: Colors.white.withValues(alpha: 0.08),
              alignEnd: true,
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 0,
            child: Container(height: 1, color: accent.withValues(alpha: 0.12)),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.018),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
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
                title.toUpperCase(),
                style: AppTypography.h3.copyWith(
                  fontFamily: 'HubotSansCondensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: miningMuted,
                  height: 1.35,
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
    final color = miningToneColor(tone);
    final marker = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: miningInnerBorderRadius,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: miningSurface.withValues(alpha: 0.92),
        borderRadius: miningInnerBorderRadius,
        border: Border.all(color: miningAccentBorder(color, emphasis: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            marker
                .animate(onPlay: (controller) => controller.repeat())
                .fade(begin: 0.35, end: 1, duration: 950.ms)
          else
            marker,
          const SizedBox(width: 8),
          Text(
            label,
            style: miningMonoStyle(
              AppTypography.caption,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
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
      decoration: miningInsetDecoration(accent: accent),
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
                      fontFamily: 'HubotSansCondensed',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
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
              style: miningMonoStyle(
                AppTypography.h2,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0,
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
        color: miningSurface,
        borderRadius: miningInnerBorderRadius,
        border: Border.all(color: miningAccentBorder(color, emphasis: 0.22)),
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
            style: miningMonoStyle(
              AppTypography.caption,
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
        borderRadius: borderRadius ?? miningInnerBorderRadius,
        border: Border.all(color: miningBorder),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
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

class _CornerBracket extends StatelessWidget {
  final Color accent;
  final bool alignEnd;

  const _CornerBracket({required this.accent, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          Align(
            alignment: alignEnd ? Alignment.topRight : Alignment.topLeft,
            child: Container(width: 18, height: 1, color: accent),
          ),
          Align(
            alignment: alignEnd ? Alignment.bottomRight : Alignment.topLeft,
            child: Container(width: 1, height: 18, color: accent),
          ),
        ],
      ),
    );
  }
}
