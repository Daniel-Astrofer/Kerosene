import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';

const Color receiveFlowBackgroundColor = Color(0xFF020202);
const Color receiveFlowBackgroundTopColor = Color(0xFF090909);
const Color receiveFlowBackgroundBottomColor = Color(0xFF040404);
const Color receiveFlowPanelColor = Color(0xFF0D0D0D);
const Color receiveFlowPanelAltColor = Color(0xFF141414);
const Color receiveFlowPanelRaisedColor = Color(0xFF1A1A1A);
const Color receiveFlowBorderColor = Color(0xFF262626);
const Color receiveFlowBorderStrongColor = Color(0xFF383838);
const Color receiveFlowDividerColor = Color(0xFF1B1B1B);
const Color receiveFlowTextColor = Color(0xFFF1F1ED);
const Color receiveFlowMutedTextColor = Color(0xFFA0A09B);
const Color receiveFlowFaintTextColor = Color(0xFF6B6B66);

class ReceiveFlowScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry bodyPadding;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBackButton;
  final double chromeRadius;

  const ReceiveFlowScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.scrollable = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.actions = const [],
    this.onBack,
    this.showBackButton = true,
    this.chromeRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final resolvedBodyPadding = bodyPadding.resolve(Directionality.of(context));
    final horizontalPadding = responsive.horizontalPadding;
    final effectiveBodyPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      resolvedBodyPadding.top,
      horizontalPadding,
      resolvedBodyPadding.bottom + keyboardInset,
    );
    final body = scrollable
        ? SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: effectiveBodyPadding,
            child: child,
          )
        : Padding(padding: effectiveBodyPadding, child: child);

    return Scaffold(
      backgroundColor: receiveFlowBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ReceiveFlowBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.sm,
                    horizontalPadding,
                    0,
                  ),
                  child: _ReceiveFlowHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    onBack: onBack,
                    showBackButton: showBackButton,
                    chromeRadius: chromeRadius,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveFlowBackdrop extends StatelessWidget {
  const _ReceiveFlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            receiveFlowBackgroundTopColor,
            receiveFlowBackgroundColor,
            receiveFlowBackgroundBottomColor,
          ],
          stops: [0, 0.44, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.92),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.018),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveFlowHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBackButton;
  final double chromeRadius;

  const _ReceiveFlowHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.onBack,
    required this.showBackButton,
    required this.chromeRadius,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final titleSize = responsive.size.width < 340
        ? 22.0
        : responsive.isCompact
        ? 25.0
        : 28.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBackButton)
              ReceiveFlowIconButton(
                icon: LucideIcons.chevronLeft,
                onTap: onBack ?? () => Navigator.maybePop(context),
                radius: chromeRadius,
              )
            else
              const SizedBox(width: 42, height: 42),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: receiveFlowTextColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        height: 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReceiveFlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double radius;

  const ReceiveFlowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: receiveFlowTextColor, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: receiveFlowPanelAltColor,
        minimumSize: const Size(42, 42),
        padding: const EdgeInsets.all(10),
        side: const BorderSide(color: receiveFlowBorderStrongColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ReceiveFlowPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;

  const ReceiveFlowPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? receiveFlowPanelColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? receiveFlowBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ReceiveFlowSectionLabel extends StatelessWidget {
  final String text;

  const ReceiveFlowSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: receiveFlowFaintTextColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class ReceiveFlowTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const ReceiveFlowTag({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: receiveFlowPanelRaisedColor,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: receiveFlowBorderStrongColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: receiveFlowMutedTextColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: receiveFlowMutedTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiveFlowActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? tag;
  final VoidCallback? onTap;
  final bool enabled;

  const ReceiveFlowActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onTap != null;
    final titleColor = isEnabled
        ? receiveFlowTextColor
        : receiveFlowMutedTextColor;
    final subtitleColor = isEnabled
        ? receiveFlowMutedTextColor
        : receiveFlowFaintTextColor;
    final borderColor = isEnabled
        ? receiveFlowBorderColor
        : receiveFlowDividerColor;
    final iconBorderColor = isEnabled
        ? receiveFlowBorderStrongColor
        : receiveFlowBorderColor;
    final tileColor = isEnabled
        ? receiveFlowPanelColor
        : receiveFlowBackgroundTopColor;
    final iconPanelColor = isEnabled
        ? receiveFlowPanelRaisedColor
        : receiveFlowPanelColor;
    final trailingIcon = isEnabled
        ? LucideIcons.chevronRight
        : LucideIcons.lock;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(0),
        child: Ink(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconPanelColor,
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: iconBorderColor),
                  ),
                  child: Icon(icon, color: titleColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (tag != null) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(
                      tag!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(trailingIcon, size: 16, color: subtitleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiveFlowPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final double radius;

  const ReceiveFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.icon,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    final foregroundColor = enabled
        ? const Color(0xFF050505)
        : receiveFlowMutedTextColor;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: enabled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.06),
          foregroundColor: enabled ? Colors.black : receiveFlowMutedTextColor,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
          disabledForegroundColor: receiveFlowMutedTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.92)
                  : receiveFlowBorderStrongColor,
            ),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: foregroundColor,
                  strokeWidth: 2,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: foregroundColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class ReceiveFlowSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;

  const ReceiveFlowSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: receiveFlowPanelColor,
          foregroundColor: receiveFlowTextColor,
          side: const BorderSide(color: receiveFlowBorderStrongColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class ReceiveFlowKeypadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;

  const ReceiveFlowKeypadButton({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Ink(
              height: 60,
              decoration: BoxDecoration(
                color: receiveFlowPanelAltColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: receiveFlowBorderStrongColor),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiveFlowMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const ReceiveFlowMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseValueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: receiveFlowTextColor,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: receiveFlowMutedTextColor,
            letterSpacing: 0,
          ),
        );
        final valueWidget = SelectableText(
          value,
          textAlign: constraints.maxWidth < 360
              ? TextAlign.left
              : TextAlign.right,
          maxLines: constraints.maxWidth < 360 ? 4 : 2,
          style: mono
              ? AppTypography.technicalMono(textStyle: baseValueStyle)
              : baseValueStyle,
        );

        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 4), valueWidget],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 16),
            Flexible(child: valueWidget),
          ],
        );
      },
    );
  }
}

class ReceiveFlowDivider extends StatelessWidget {
  const ReceiveFlowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(color: receiveFlowDividerColor, height: 1, thickness: 1),
    );
  }
}

class ReceiveFlowStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? footer;

  const ReceiveFlowStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiveFlowPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: Icon(icon, color: receiveFlowTextColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: receiveFlowTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: receiveFlowMutedTextColor,
              height: 1.4,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}
