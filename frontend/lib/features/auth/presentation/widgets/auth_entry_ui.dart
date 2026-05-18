import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

const Color authEntryInk = Color(0xFF020202);
const Color authEntrySurface = Color(0xFF0B0B0B);
const Color authEntrySurfaceRaised = Color(0xFF131313);
const Color authEntryText = Color(0xFFF1F1ED);
const Color authEntryMuted = Color(0xFFA0A09B);
const Color authEntryFaint = Color(0xFF6B6B66);
const Color authEntryButton = Color(0xFFECECE6);

class AuthEntryScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final List<Widget> trailing;
  final EdgeInsetsGeometry padding;

  const AuthEntryScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.trailing = const [],
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authEntryInk,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B0B), Color(0xFF050505), authEntryInk],
            stops: [0, 0.42, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.9),
                    radius: 1.08,
                    colors: [
                      Colors.white.withValues(alpha: 0.045),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final responsive = context.responsive;
                  final horizontalPadding = responsive.horizontalPadding;
                  final resolvedPadding = padding.resolve(
                    Directionality.of(context),
                  );
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      resolvedPadding.top,
                      horizontalPadding,
                      resolvedPadding.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: responsive.isCompact ? 520 : 560,
                          minHeight: constraints.maxHeight - AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthEntryHeader(
                              eyebrow: eyebrow,
                              title: title,
                              subtitle: subtitle,
                              onBack: onBack,
                              trailing: trailing,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            child,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthEntryHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> trailing;

  const AuthEntryHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final titleSize = responsive.size.width < 340
        ? 28.0
        : responsive.isCompact
        ? 31.0
        : 34.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          AuthEntryIconButton(icon: LucideIcons.arrowLeft, onPressed: onBack!),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  fontFamily: 'HubotSansCondensed',
                  color: authEntryFaint,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.h1.copyWith(
                  fontFamily: 'HubotSansCondensed',
                  color: authEntryText,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 0.96,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: authEntryMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (trailing.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: trailing,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthEntryPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;

  const AuthEntryPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.raised = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised ? authEntrySurfaceRaised : authEntrySurface,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AuthEntryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;

  const AuthEntryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final background = outlined
        ? (disabled ? authEntrySurface : authEntrySurfaceRaised)
        : disabled
        ? authEntrySurfaceRaised
        : authEntryButton;
    final foreground = outlined
        ? (disabled ? authEntryFaint : authEntryText)
        : (disabled ? authEntryMuted : authEntryInk);
    final borderColor = outlined
        ? (disabled
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.22))
        : Colors.transparent;

    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: foreground,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 16, color: foreground),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: AppTypography.buttonText.copyWith(
                                fontFamily: 'HubotSansCondensed',
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthEntryIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const AuthEntryIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: authEntrySurface,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: 18, color: authEntryText),
        ),
      ),
    );
  }
}

class AuthEntryNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const AuthEntryNote({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AuthEntryPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      raised: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: authEntryMuted, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'HubotSansCondensed',
                    color: authEntryMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: authEntryText,
                    height: 1.35,
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
