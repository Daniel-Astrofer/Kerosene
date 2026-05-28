part of 'settings_screen.dart';

String _formatAccountHandle(String username) {
  final trimmed = username.trim();
  final value = trimmed.isEmpty
      ? 'lucas_01'
      : trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return value.startsWith('@') ? value : '@$value';
}

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _SettingsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _SettingsDesignColors.background,
        border: Border(
          bottom: BorderSide(color: _SettingsDesignColors.borderMuted),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Fechar',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.close_rounded,
                          color: _SettingsDesignColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsOverviewCard extends ConsumerWidget {
  final VoidCallback onQrTap;

  const _SettingsOverviewCard({required this.onQrTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final handle = _formatAccountHandle(user?.username ?? 'lucas_01');
    final memberLabel =
        user?.isAdmin == true ? 'Admin Member' : 'Private Member';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSerif(
                    color: _SettingsDesignColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  memberLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _SettingsDesignColors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Material(
            color: _SettingsDesignColors.surfaceContainer,
            shape: CircleBorder(
              side: BorderSide(
                color: _SettingsDesignColors.borderMuted.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onQrTap,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.qr_code_rounded,
                  color: _SettingsDesignColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appearance Section ───────────────────────────────────────────────────────
