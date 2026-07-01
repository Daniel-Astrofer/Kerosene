import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 1.65,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KeroseneBrandTokens.surfaceMuted,
              border: Border.all(color: AppColors.hexFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.hexFF1A1A1A.withValues(alpha: 0.20),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsSectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final FutureOr<void> Function()? onTap;

  const SettingsSectionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final trailingWidget = trailing ??
        (onTap == null
            ? const SizedBox.shrink()
            : const Icon(
                KeroseneIcons.chevronRight,
                color: KeroseneBrandTokens.textMuted,
                size: 20,
              ));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hexFF201F1F,
                  border: Border.all(color: AppColors.hexFF353534),
                ),
                child: Icon(
                  icon,
                  color: KeroseneBrandTokens.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: KeroseneBrandTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: KeroseneBrandTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsReadonlySwitch extends StatelessWidget {
  final bool value;

  const SettingsReadonlySwitch({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: KeroseneMotion.short,
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: value ? Colors.white : AppColors.hexFF353534,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: KeroseneMotion.short,
        curve: KeroseneMotion.standard,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
