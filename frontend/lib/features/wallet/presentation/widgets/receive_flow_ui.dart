import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_spacing.dart';

const Color receiveFlowPanelColor = Color(0xFF11151A);
const Color receiveFlowPanelAltColor = Color(0xFF0D1116);
const Color receiveFlowBorderColor = Color(0xFF242A31);
const Color receiveFlowDividerColor = Color(0xFF1C222A);
const Color receiveFlowTextColor = Color(0xFFF4F6F8);
const Color receiveFlowMutedTextColor = Color(0xFF97A0AA);
const Color receiveFlowFaintTextColor = Color(0xFF6E7680);

class ReceiveFlowScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry bodyPadding;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBackButton;

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
  });

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: bodyPadding,
            child: child,
          )
        : Padding(
            padding: bodyPadding,
            child: child,
          );

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ReceiveFlowHeader(
                title: title,
                subtitle: subtitle,
                actions: actions,
                onBack: onBack,
                showBackButton: showBackButton,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: body),
          ],
        ),
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

  const _ReceiveFlowHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.onBack,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton)
          ReceiveFlowIconButton(
            icon: LucideIcons.chevronLeft,
            onTap: onBack ?? () => Navigator.maybePop(context),
          )
        else
          const SizedBox(width: 42, height: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ],
    );
  }
}

class ReceiveFlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const ReceiveFlowIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: receiveFlowTextColor, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: receiveFlowPanelColor,
        minimumSize: const Size(42, 42),
        padding: const EdgeInsets.all(10),
        side: const BorderSide(color: receiveFlowBorderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
    this.radius = 12,
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
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
          ),
    );
  }
}

class ReceiveFlowTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const ReceiveFlowTag({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: receiveFlowPanelAltColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: receiveFlowBorderColor),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
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
  final VoidCallback onTap;

  const ReceiveFlowActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: receiveFlowPanelColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: receiveFlowBorderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: receiveFlowPanelAltColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: receiveFlowBorderColor),
                  ),
                  child: Icon(icon, color: receiveFlowTextColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: receiveFlowTextColor,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receiveFlowMutedTextColor,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (tag != null) ...[
                  Text(
                    tag!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: receiveFlowFaintTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: receiveFlowFaintTextColor,
                ),
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

  const ReceiveFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor:
              enabled ? Colors.white : Colors.white.withValues(alpha: 0.08),
          foregroundColor: enabled ? Colors.black : receiveFlowMutedTextColor,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
          disabledForegroundColor: receiveFlowMutedTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.92)
                  : receiveFlowBorderColor,
            ),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                  ),
                ],
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
          side: const BorderSide(color: receiveFlowBorderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontWeight: FontWeight.w500,
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

  const ReceiveFlowKeypadButton({
    super.key,
    required this.child,
    required this.onTap,
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
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                color: receiveFlowPanelColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: receiveFlowBorderColor),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: mono ? 'JetBrainsMono' : null,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class ReceiveFlowDivider extends StatelessWidget {
  const ReceiveFlowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Divider(
        color: receiveFlowDividerColor,
        height: 1,
        thickness: 1,
      ),
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
              color: receiveFlowPanelAltColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: receiveFlowBorderColor),
            ),
            child: Icon(icon, color: receiveFlowTextColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: receiveFlowTextColor,
                  fontWeight: FontWeight.w500,
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
          if (footer != null) ...[
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}
