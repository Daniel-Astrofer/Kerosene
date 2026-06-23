import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

class SettingsGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsGlassPanel({
    super.key,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hexFF1A1A1A),
      ),
      child: child,
    );
  }
}

class SettingsAnimatedIcon extends StatelessWidget {
  final KeroseneAnimationAsset asset;
  final IconData fallbackIcon;
  final bool selected;
  final double size;

  const SettingsAnimatedIcon({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.selected,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
      curve: KeroseneMotion.emphasized,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.94 + (value * 0.06),
          child: AnimatedContainer(
            duration: KeroseneMotion.duration(context, KeroseneMotion.short),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color.lerp(
                KeroseneBrandTokens.surface,
                AppColors.hexFF1C1C1E,
                value,
              ),
              borderRadius: BorderRadius.circular(size * 0.50),
              border: Border.all(
                color: Color.lerp(
                      AppColors.hexFF1A1A1A,
                      Colors.white.withValues(alpha: 0.12),
                      value,
                    ) ??
                    AppColors.hexFF1A1A1A,
              ),
            ),
            child: KeroseneAnimationHost(
              asset: asset,
              width: size,
              height: size,
              semanticLabel: asset.semanticLabel,
              child: Transform.rotate(
                angle: value * 0.08,
                child: Icon(
                  fallbackIcon,
                  color: Color.lerp(
                    KeroseneBrandTokens.textSecondary,
                    KeroseneBrandTokens.textPrimary,
                    value,
                  ),
                  size: size * 0.45,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsIconButtonFrame extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const SettingsIconButtonFrame({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KeroseneBrandTokens.surface,
              border: Border.all(color: AppColors.hexFF1A1A1A),
            ),
            child: Icon(icon, color: KeroseneBrandTokens.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}

class SettingsPaneScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final KeroseneAnimationAsset animation;
  final List<Widget> children;

  const SettingsPaneScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KeroseneBrandTokens.surface,
                  border: Border.all(color: AppColors.hexFF1A1A1A),
                ),
                child: Icon(
                  animation.fallbackIcon,
                  color: KeroseneBrandTokens.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.inter(
                        color: KeroseneBrandTokens.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.65,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: AppTypography.newsreader(
                        color: KeroseneBrandTokens.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        color: KeroseneBrandTokens.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}

class SettingsInfoGrid extends StatelessWidget {
  final List<SettingsInfoItem> items;

  const SettingsInfoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: columns == 2
                    ? (constraints.maxWidth - AppSpacing.md) / 2
                    : constraints.maxWidth,
                child: _InfoCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class SettingsInfoItem {
  final String label;
  final String value;

  const SettingsInfoItem(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final SettingsInfoItem item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hexFF1A1A1A),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: KeroseneBrandTokens.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: KeroseneBrandTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        destructive ? KeroseneBrandTokens.error : KeroseneBrandTokens.brand;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: KeroseneBrandTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: KeroseneBrandTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: KeroseneBrandTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                KeroseneIcons.chevronRight,
                color: KeroseneBrandTokens.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPreferenceSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsPreferenceSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hexFF1A1A1A),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? KeroseneBrandTokens.brand
                : KeroseneBrandTokens.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: KeroseneBrandTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: KeroseneBrandTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: KeroseneBrandTokens.brand,
            activeTrackColor: KeroseneBrandTokens.brand.withValues(alpha: 0.24),
            inactiveThumbColor: KeroseneBrandTokens.textMuted,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }
}

class SettingsStatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SettingsStatusRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hexFF1A1A1A),
      ),
      child: Row(
        children: [
          Icon(icon, color: KeroseneBrandTokens.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: KeroseneBrandTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: KeroseneBrandTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!))
          else
            SettingsPill(label: trailing),
        ],
      ),
    );
  }
}

class SettingsPill extends StatelessWidget {
  final String label;

  const SettingsPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: KeroseneBrandTokens.brand.withValues(alpha: 0.28)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: KeroseneBrandTokens.brand,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class SettingsChoiceGroup<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> values;
  final String Function(T value) label;
  final String Function(T value) description;
  final FutureOr<void> Function(T value) onSelected;

  const SettingsChoiceGroup({
    super.key,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.description,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style:
              AppTypography.h3.copyWith(color: KeroseneBrandTokens.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChoiceTile(
              selected: option == value,
              title: label(option),
              subtitle: description(option),
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(option);
              },
            ),
          ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: KeroseneMotion.short,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.hexFF2C2C2E : KeroseneBrandTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.hexFF1A1A1A,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? KeroseneIcons.check : KeroseneIcons.circle,
                color: selected
                    ? KeroseneBrandTokens.brand
                    : KeroseneBrandTokens.textMuted,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: KeroseneBrandTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: KeroseneBrandTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsLoadingPanel extends StatelessWidget {
  final String label;

  const SettingsLoadingPanel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return SettingsGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: KeroseneBrandTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const SettingsEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: KeroseneBrandTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hexFF1A1A1A),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KeroseneBrandTokens.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: KeroseneBrandTokens.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: KeroseneBrandTokens.textMuted,
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
