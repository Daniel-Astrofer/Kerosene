part of 'settings_screen.dart';

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);

    return _Card(
      children: [
        // Theme Selection
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema da interface',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: AppThemeVariant.values
                    .map(
                      (v) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: v != AppThemeVariant.values.last
                                ? AppSpacing.sm
                                : 0,
                          ),
                          child: _ThemeChip(
                            variant: v,
                            selected: appearance.themeVariant == v,
                            onTap: () => ref
                                .read(appearanceProvider.notifier)
                                .setThemeVariant(v),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        _Divider(),

        // Font Size
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tamanho da fonte',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: monochromePanelDecoration(
                      color: monoSurfaceAltColor,
                      borderColor: monoBorderStrongColor,
                      showShadow: false,
                    ),
                    child: Text(
                      appearance.fontScale.label,
                      style: AppTypography.caption.copyWith(
                        color: monoTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Preview text
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: monochromePanelDecoration(
                  color: monoSurfaceAltColor,
                  borderColor: monoBorderStrongColor,
                  showShadow: false,
                ),
                child: Text(
                  'Pré-visualização: ₿ 0.00042100',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 16 * appearance.fontScale.scaleFactor,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white70,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.12),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: appearance.fontScale.index.toDouble(),
                  min: 0,
                  max: (AppFontScale.values.length - 1).toDouble(),
                  divisions: AppFontScale.values.length - 1,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(appearanceProvider.notifier)
                        .setFontScale(AppFontScale.values[v.round()]);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppFontScale.values
                    .map(
                      (s) => Text(
                        s.label,
                        style: AppTypography.caption.copyWith(
                          color: appearance.fontScale == s
                              ? Colors.white
                              : Colors.white24,
                          fontWeight: appearance.fontScale == s
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        _Divider(),
        // Balance Decimals
        _ActionTile(
          icon: Icons.onetwothree_rounded,
          iconColor: Colors.white70,
          title: context.tr.settingsUiDecimalPrecisionTitle,
          subtitle: context.tr.settingsUiDecimalPrecisionSubtitle(
            balanceSettings.decimalPlaces,
          ),
          trailing: Icons.refresh_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(balanceSettingsProvider.notifier).cycleDecimals();
          },
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  Color get _previewBg {
    return AppTheme.paletteFor(variant).background;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: monochromePanelDecoration(
          color: selected ? monoSurfaceRaisedColor : monoSurfaceAltColor,
          borderColor: selected ? monoTextColor : monoBorderStrongColor,
          showShadow: false,
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: monochromePanelDecoration(
                color: _previewBg,
                borderColor: monoBorderStrongColor,
                showShadow: false,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              variant.label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: selected ? monoTextColor : monoMutedTextColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceSettings = ref.watch(balanceSettingsProvider);

    return _Card(
      children: [
        _SwitchTile(
          icon: Icons.visibility_off_outlined,
          iconColor: Colors.white70,
          title: context.tr.settingsUiHideBalanceTitle,
          subtitle: balanceSettings.isHidden
              ? context.tr.settingsUiBalanceHiddenSubtitle
              : context.tr.settingsUiBalanceVisibleSubtitle,
          value: balanceSettings.isHidden,
          accentColor: Colors.white70,
          onChanged: (_) {
            HapticFeedback.mediumImpact();
            ref.read(balanceSettingsProvider.notifier).toggleVisibility();
          },
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.verified_user_outlined,
          iconColor: Colors.white70,
          title: context.tr.settingsUiSovereigntyReportTitle,
          subtitle: context.tr.settingsUiSovereigntyReportSubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SovereigntyStatusScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Locale & Currency Section ────────────────────────────────────────────────
class _LocaleSection extends ConsumerWidget {
  const _LocaleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider).locale;
    final currentCurrency = ref.watch(currencyProvider);

    final languages = [
      _LangItem('🇺🇸', 'English', 'EN', const Locale('en')),
      _LangItem('🇧🇷', 'Português', 'PT', const Locale('pt')),
      _LangItem('🇪🇸', 'Español', 'ES', const Locale('es')),
    ];

    final currencies = [
      _CurrItem(Currency.btc, '₿', 'BTC — Bitcoin'),
      _CurrItem(Currency.usd, '\$', 'USD — Dólar'),
      _CurrItem(Currency.brl, 'R\$', 'BRL — Real'),
      _CurrItem(Currency.eur, '€', 'EUR — Euro'),
    ];

    return _Card(
      children: [
        // Language
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            'Idioma',
            style: AppTypography.bodySmall.copyWith(color: Colors.white38),
          ),
        ),
        ...languages.map(
          (lang) => _SelectionTile(
            leading: lang.flag,
            title: lang.name,
            trailing: lang.code,
            selected: currentLocale.languageCode == lang.locale.languageCode,
            accentColor: Colors.white70,
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(lang.locale),
          ),
        ),
        _Divider(),

        // Currency
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            'Moeda exibida',
            style: AppTypography.bodySmall.copyWith(color: Colors.white38),
          ),
        ),
        ...currencies.map(
          (curr) => _SelectionTile(
            leading: curr.symbol,
            title: curr.label,
            selected: currentCurrency == curr.currency,
            accentColor: Colors.white70,
            onTap: () =>
                ref.read(currencyProvider.notifier).setCurrency(curr.currency),
            isPill: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _LangItem {
  final String flag, name, code;
  final Locale locale;
  const _LangItem(this.flag, this.name, this.code, this.locale);
}

class _CurrItem {
  final Currency currency;
  final String symbol, label;
  const _CurrItem(this.currency, this.symbol, this.label);
}

// ─── Security Section ─────────────────────────────────────────────────────────
