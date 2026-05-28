part of 'settings_screen.dart';

class _SettingsNavigationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsNavigationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SettingsNavigationList extends StatelessWidget {
  final List<_SettingsNavigationItem> items;

  const _SettingsNavigationList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          for (final item in items)
            _SettingsNavigationTile(
              item: item,
              key: ValueKey(item.title),
            ),
        ],
      ),
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  final _SettingsNavigationItem item;

  const _SettingsNavigationTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _SettingsDesignColors.surfaceContainerHighest,
                  border: Border.all(
                    color: _SettingsDesignColors.borderMuted.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: _SettingsDesignColors.outlineVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _SettingsDesignColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _SettingsDesignColors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _SettingsDesignColors.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDetailsSheet extends ConsumerWidget {
  const _AccountDetailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final handle = _formatAccountHandle(user?.username ?? 'lucas_01');
    final memberLabel =
        user?.isAdmin == true ? 'Admin Member' : 'Private Member';

    return _BottomSheetContainer(
      title: 'Conta',
      icon: Icons.manage_accounts_rounded,
      iconColor: Colors.white54,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _SettingsDesignColors.surfaceContainerHighest,
              border: Border.all(color: _SettingsDesignColors.borderMuted),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _SettingsDesignColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(color: monoTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            memberLabel,
            style: AppTypography.bodySmall.copyWith(color: monoMutedTextColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.tr.settingsUiLogoutTitle,
            icon: Icons.logout_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => _logoutFromSheet(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutFromSheet(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
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
