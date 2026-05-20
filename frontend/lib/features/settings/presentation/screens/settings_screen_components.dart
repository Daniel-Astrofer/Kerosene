part of 'settings_screen.dart';

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final borderTone =
        Color.lerp(monoBorderStrongColor, color, 0.08) ?? monoBorderStrongColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: monochromePanelDecoration(
            color: monoSurfaceAltColor,
            borderColor: borderTone,
            showShadow: false,
          ),
          child: Icon(icon, size: 14, color: monoTextColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: monoMutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: monoDividerColor,
      indent: AppSpacing.lg,
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String leading;
  final String title;
  final String? trailing;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isPill;

  const _SelectionTile({
    required this.leading,
    required this.title,
    this.trailing,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selectedBorder =
        Color.lerp(monoTextColor, accentColor, 0.08) ?? monoTextColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
            vertical: 14,
          ),
          color: selected ? monoSurfaceAltColor : Colors.transparent,
          child: Row(
            children: [
              if (isPill)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: monochromePanelDecoration(
                    color:
                        selected ? monoSurfaceRaisedColor : monoSurfaceAltColor,
                    borderColor:
                        selected ? selectedBorder : monoBorderStrongColor,
                    showShadow: false,
                  ),
                  child: Text(
                    leading,
                    style: AppTypography.bodyMedium.copyWith(
                      color: selected ? monoTextColor : monoMutedTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                )
              else
                Text(leading, style: const TextStyle(fontSize: 22)),
              SizedBox(
                width: responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? monoTextColor : monoMutedTextColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null && !selected)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.isTinyPhone ? 80 : 120,
                  ),
                  child: Text(
                    trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      color: monoFaintTextColor,
                    ),
                  ),
                ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: monoTextColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final activeBorder =
        Color.lerp(monoTextColor, iconColor, 0.08) ?? monoTextColor;
    final activeTrack = Color.lerp(monoSurfaceRaisedColor, accentColor, 0.08) ??
        monoSurfaceRaisedColor;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: monochromePanelDecoration(
              color: value ? monoSurfaceRaisedColor : monoSurfaceAltColor,
              borderColor: value ? activeBorder : monoBorderStrongColor,
              showShadow: false,
            ),
            child: Icon(
              icon,
              color: value ? monoTextColor : monoMutedTextColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: value ? monoTextColor : monoMutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: monoFaintTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: monoTextColor,
            activeTrackColor: activeTrack,
            inactiveThumbColor: Colors.white.withValues(alpha: 0.15),
            inactiveTrackColor: monoSurfaceAltColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final VoidCallback onTap;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final iconBorder = Color.lerp(monoBorderStrongColor, iconColor, 0.08) ??
        monoBorderStrongColor;
    final effectiveTitleColor = titleColor == null
        ? monoTextColor
        : (Color.lerp(monoTextColor, titleColor, 0.08) ?? monoTextColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTinyPhone ? AppSpacing.md : AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: monochromePanelDecoration(
                  color: monoSurfaceAltColor,
                  borderColor: iconBorder,
                  showShadow: false,
                ),
                child: Icon(icon, color: monoTextColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: effectiveTitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: monoFaintTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing, color: monoMutedTextColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: monochromePanelDecoration(
          color: monoSurfaceAltColor,
          borderColor: monoBorderStrongColor,
          showShadow: false,
        ),
        child: Icon(icon, color: monoTextColor, size: 18),
      ),
    );
  }
}

// ─── Sheet Action Button ──────────────────────────────────────────────────────

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutline;
  final VoidCallback? onTap;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isOutline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filledColor = Color.lerp(monoTextColor, color, 0.05) ?? monoTextColor;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: monochromePanelDecoration(
            color: isOutline ? monoSurfaceColor : filledColor,
            borderColor: monoBorderStrongColor,
            showShadow: false,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isOutline ? monoMutedTextColor : Colors.black,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.buttonText.copyWith(
                  color: isOutline ? monoMutedTextColor : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
