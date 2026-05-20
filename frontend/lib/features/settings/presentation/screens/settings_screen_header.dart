part of 'settings_screen.dart';

class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _SettingsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        AppSpacing.lg,
        responsive.horizontalPadding,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURAÇÕES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(
                    letterSpacing: 0,
                    color: Colors.white,
                    fontSize: responsive.compactFontSize(
                      tiny: 20,
                      compact: 22,
                      regular: 24,
                    ),
                  ),
                ),
                Text(
                  'Segurança, privacidade e operação da conta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: monoMutedTextColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsOverviewCard extends ConsumerWidget {
  const _SettingsOverviewCard();

  String _currencyLabel(Currency currency) {
    switch (currency) {
      case Currency.btc:
        return 'BTC';
      case Currency.brl:
        return 'BRL';
      case Currency.eur:
        return 'EUR';
      case Currency.usd:
        return 'USD';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricState = ref.watch(biometricProvider);
    final alerts = ref.watch(alertPreferencesProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final locale = ref.watch(localeProvider).locale;
    final currency = ref.watch(currencyProvider);
    final appearance = ref.watch(appearanceProvider);

    final biometricLabel = biometricState.isLoading
        ? context.tr.settingsUiChecking
        : biometricState.isSupported
            ? (biometricState.isEnabled
                ? context.tr.settingsUiActive
                : context.tr.settingsUiInactive)
            : context.tr.settingsUiUnavailable;

    return _Card(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.settingsUiOperationalSummaryTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppCopy.settingsOverviewSummary.resolve(context),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white54,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _OverviewPill(
                    label: context.tr.settingsUiAlertsLabel,
                    value: alerts.backgroundAlertsEnabled
                        ? context.tr.settingsUiAlertsBackgroundActive
                        : context.tr.settingsUiDisabled,
                    color: Colors.white70,
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsBiometrics.resolve(context),
                    value: biometricLabel,
                    color: Colors.white70,
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsBalance.resolve(context),
                    value: balanceSettings.isHidden
                        ? AppCopy.settingsHidden.resolve(context)
                        : AppCopy.settingsVisible.resolve(context),
                    color: Colors.white70,
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsLocation.resolve(context),
                    value:
                        '${locale.languageCode.toUpperCase()} · ${_currencyLabel(currency)}',
                    color: Colors.white70,
                  ),
                  _OverviewPill(
                    label: context.tr.settingsUiThemeLabel,
                    value: appearance.themeVariant.label,
                    color: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final borderTone =
        Color.lerp(monoBorderStrongColor, color, 0.08) ?? monoBorderStrongColor;

    return Container(
      constraints: BoxConstraints(
        maxWidth: responsive.isTinyPhone ? responsive.clampWidth(260) : 180,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTinyPhone ? 10 : 12,
        vertical: 10,
      ),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: borderTone,
        showShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: monoMutedTextColor,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: monoTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appearance Section ───────────────────────────────────────────────────────
