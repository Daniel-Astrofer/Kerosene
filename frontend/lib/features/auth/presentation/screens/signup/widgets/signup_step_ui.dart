import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/widgets/bouncing_button.dart';

enum SignupSurfaceTone { neutral, primary, success, warning }

class SignupStepLayout extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final SignupSurfaceTone tone;
  final String? highlightLabel;
  final String? highlightValue;
  final String? highlightHint;
  final List<String> chips;
  final List<Widget> children;
  final Widget? footer;

  const SignupStepLayout({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tone = SignupSurfaceTone.neutral,
    this.highlightLabel,
    this.highlightValue,
    this.highlightHint,
    this.chips = const [],
    this.children = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final responsive = context.responsive;
        final horizontalPadding = responsive.horizontalPadding;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.md,
            horizontalPadding,
            AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(820, responsive.maxReadableWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SignupHeroCard(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    tone: tone,
                    highlightLabel: highlightLabel,
                    highlightValue: highlightValue,
                    highlightHint: highlightHint,
                    chips: chips,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...children,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SignupGlassSurface(
                      borderRadius: BorderRadius.circular(24),
                      fillColor: Colors.black.withValues(alpha: 0.18),
                      borderColor: Colors.white.withValues(alpha: 0.08),
                      blurSigma: 10,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: SafeArea(top: false, child: footer!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SignupGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color fillColor;
  final Color borderColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const SignupGlassSurface({
    super.key,
    required this.child,
    this.padding,
    required this.borderRadius,
    required this.fillColor,
    required this.borderColor,
    this.blurSigma = 12,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final decoratedChild = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? fillColor : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: blurSigma <= 0
          ? decoratedChild
          : BackdropFilter(
              filterConfig: ImageFilterConfig.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
                bounded: true,
              ),
              child: decoratedChild,
            ),
    );
  }
}

class SignupHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final SignupSurfaceTone tone;
  final String? highlightLabel;
  final String? highlightValue;
  final String? highlightHint;
  final List<String> chips;

  const SignupHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tone = SignupSurfaceTone.neutral,
    this.highlightLabel,
    this.highlightValue,
    this.highlightHint,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context, tone);
    final responsive = context.responsive;
    final isCompact = responsive.isCompact;
    final titleSize = responsive.size.width < 340
        ? 23.0
        : isCompact
        ? 26.0
        : 29.0;

    return SignupGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(20),
      fillColor: Colors.black.withValues(alpha: 0.12),
      borderColor: accent.withValues(alpha: 0.18),
      blurSigma: 12,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: AnimatedGlyphIcon(
                  icon: icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: accent,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontSize: titleSize,
                        height: 1.02,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (highlightValue != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: SignupGlassSurface(
                padding: const EdgeInsets.all(AppSpacing.lg),
                borderRadius: BorderRadius.circular(18),
                fillColor: Colors.black.withValues(alpha: 0.10),
                borderColor: Colors.white.withValues(alpha: 0.08),
                blurSigma: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlightLabel != null)
                      Text(
                        highlightLabel!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (highlightLabel != null)
                      const SizedBox(height: AppSpacing.xs),
                    Text(
                      highlightValue!,
                      style:
                          (isCompact
                                  ? Theme.of(context).textTheme.headlineSmall
                                  : Theme.of(context).textTheme.displaySmall)!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    if (highlightHint != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        highlightHint!,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: chips
                  .map((chip) => SignupTag(label: chip, tone: tone))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class SignupPanel extends StatelessWidget {
  final Widget child;
  final SignupSurfaceTone tone;
  final EdgeInsetsGeometry? padding;

  const SignupPanel({
    super.key,
    required this.child,
    this.tone = SignupSurfaceTone.neutral,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context, tone);

    return SignupGlassSurface(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(20),
      fillColor: Colors.white.withValues(alpha: 0.025),
      borderColor: tone == SignupSurfaceTone.neutral
          ? Colors.white.withValues(alpha: 0.08)
          : accent.withValues(alpha: 0.18),
      blurSigma: 8,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }
}

class SignupInlineNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final SignupSurfaceTone tone;

  const SignupInlineNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = SignupSurfaceTone.warning,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context, tone);

    return SignupGlassSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      fillColor: accent.withValues(alpha: 0.08),
      borderColor: accent.withValues(alpha: 0.20),
      blurSigma: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedGlyphIcon(icon: icon, color: accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
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

class SignupBulletLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final SignupSurfaceTone tone;

  const SignupBulletLine({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = SignupSurfaceTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context, tone);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedGlyphIcon(icon: icon, size: 18, color: accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignupTag extends StatelessWidget {
  final String label;
  final SignupSurfaceTone tone;
  final IconData? icon;

  const SignupTag({
    super.key,
    required this.label,
    this.tone = SignupSurfaceTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context, tone);
    final maxTagWidth = math
        .min(MediaQuery.sizeOf(context).width * 0.72, 260)
        .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTagWidth),
      child: SignupGlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(999),
        fillColor: tone == SignupSurfaceTone.neutral
            ? Colors.white.withValues(alpha: 0.04)
            : accent.withValues(alpha: 0.10),
        borderColor: tone == SignupSurfaceTone.neutral
            ? Colors.white.withValues(alpha: 0.08)
            : accent.withValues(alpha: 0.20),
        blurSigma: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AnimatedGlyphIcon(
                icon: icon!,
                size: 14,
                color: tone == SignupSurfaceTone.neutral
                    ? Theme.of(context).colorScheme.onPrimary
                    : accent,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupPrimaryFooter extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? caption;
  final IconData? icon;

  const SignupPrimaryFooter({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.caption,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BouncingButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
          height: 54,
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

Color _toneColor(BuildContext context, SignupSurfaceTone tone) {
  switch (tone) {
    case SignupSurfaceTone.primary:
      return Theme.of(context).colorScheme.primary;
    case SignupSurfaceTone.success:
      return AppColors.success;
    case SignupSurfaceTone.warning:
      return AppColors.warning;
    case SignupSurfaceTone.neutral:
      return Theme.of(context).colorScheme.secondary;
  }
}

IconData signupStatusIconForPayment(String status) {
  switch (status) {
    case 'completed':
      return LucideIcons.badgeCheck;
    case 'verifying_onboarding':
      return LucideIcons.loader;
    case 'paid':
      return LucideIcons.receipt;
    case 'expired':
      return LucideIcons.alertTriangle;
    default:
      return LucideIcons.wallet;
  }
}

SignupSurfaceTone signupToneForPayment(String status) {
  switch (status) {
    case 'completed':
      return SignupSurfaceTone.success;
    case 'expired':
      return SignupSurfaceTone.warning;
    case 'verifying_onboarding':
    case 'paid':
      return SignupSurfaceTone.primary;
    default:
      return SignupSurfaceTone.neutral;
  }
}
