import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';
import 'package:teste/core/utils/device_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/providers/alert_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/monochrome_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/biometric_provider.dart';
import '../../../../core/providers/appearance_provider.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../auth/controller/auth_providers.dart';
import '../../../profile/presentation/screens/security_settings_screen.dart';
import '../../../notifications/presentation/providers/session_notification_provider.dart';
import '../../../security/presentation/screens/sovereignty_status_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../security/domain/entities/admin_access.dart';
import '../../../wallet/presentation/providers/balance_settings_provider.dart';

// ─── Screen Entry ─────────────────────────────────────────────────────────────

final backupCodesProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.read(authRepositoryProvider).getBackupCodes();
  return result.fold((_) => const <String>[], (codes) => codes);
});

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const SettingsScreen({super.key, this.showPrimaryNavigation = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _sectionsController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _sectionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _sectionsController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appearanceProvider);
    final responsive = context.responsive;
    final bottomSectionPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : 80.0;

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientSideGlowBackdrop.authenticated()),
          SafeArea(
            child: Column(
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _SettingsHeader(
                      onBack: widget.showPrimaryNavigation
                          ? () => AppPrimaryNavigationBar.backOrHome(context)
                          : () => Navigator.maybePop(context),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _sectionsController,
                      curve: Curves.easeOut,
                    ),
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                        vertical: AppSpacing.sm,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: responsive.mobileContentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                const _SettingsOverviewCard(),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.shield_outlined,
                                  label: context
                                      .l10n
                                      .settingsUiSecurityAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _SecuritySection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.admin_panel_settings_outlined,
                                  label: context
                                      .l10n
                                      .settingsUiEnterpriseAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _EnterpriseAccessSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.privacy_tip_outlined,
                                  label: context.l10n.settingsUiPrivacySection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _PrivacySection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.manage_accounts_outlined,
                                  label: context
                                      .l10n
                                      .settingsUiAccountAccessSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _CredentialsSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.notifications_outlined,
                                  label: context
                                      .l10n
                                      .settingsUiNotificationsSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _NotificationsSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.palette_outlined,
                                  label: context
                                      .l10n
                                      .settingsUiAppearanceSection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _AppearanceSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.language_rounded,
                                  label: context
                                      .l10n
                                      .settingsUiLocaleCurrencySection
                                      .toUpperCase(),
                                  color: Colors.white70,
                                  child: const _LocaleSection(),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildSection(
                                  icon: Icons.power_settings_new_rounded,
                                  label: context.l10n.settingsUiSessionSection
                                      .toUpperCase(),
                                  color: Colors.white54,
                                  child: const _SessionSection(),
                                ),
                                SizedBox(height: bottomSectionPadding),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showPrimaryNavigation)
            AppPrimaryNavigationBar.overlay(
              currentDestination: AppPrimaryDestination.settings,
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: icon, label: label, color: color),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

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
        ? context.l10n.settingsUiChecking
        : biometricState.isSupported
        ? (biometricState.isEnabled
              ? context.l10n.settingsUiActive
              : context.l10n.settingsUiInactive)
        : context.l10n.settingsUiUnavailable;

    return _Card(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.settingsUiOperationalSummaryTitle,
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
                    label: context.l10n.settingsUiAlertsLabel,
                    value: alerts.backgroundAlertsEnabled
                        ? context.l10n.settingsUiAlertsBackgroundActive
                        : context.l10n.settingsUiDisabled,
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
                    label: context.l10n.settingsUiThemeLabel,
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
          title: context.l10n.settingsUiDecimalPrecisionTitle,
          subtitle: context.l10n.settingsUiDecimalPrecisionSubtitle(
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
          title: context.l10n.settingsUiHideBalanceTitle,
          subtitle: balanceSettings.isHidden
              ? context.l10n.settingsUiBalanceHiddenSubtitle
              : context.l10n.settingsUiBalanceVisibleSubtitle,
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
          title: context.l10n.settingsUiSovereigntyReportTitle,
          subtitle: context.l10n.settingsUiSovereigntyReportSubtitle,
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

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioState = ref.watch(biometricProvider);
    final securityAsync = ref.watch(securityStatusProvider);
    final securitySubtitle = securityAsync.when(
      data: (security) => security.unprotected
          ? context.l10n.settingsUiSecurityUnprotectedSubtitle
          : context.l10n.settingsUiSecurityProtectedSubtitle,
      loading: () => context.l10n.settingsUiSecurityLoadingSubtitle,
      error: (_, __) => context.l10n.settingsUiSecurityErrorSubtitle,
    );
    final passkeySubtitle = securityAsync.when(
      data: (security) => security.passkeyRegistered
          ? context.l10n.settingsUiPasskeyRegisteredSubtitle
          : context.l10n.settingsUiPasskeyRegisterSubtitle,
      loading: () => context.l10n.settingsUiPasskeyLoadingSubtitle,
      error: (_, __) => context.l10n.settingsUiPasskeyErrorSubtitle,
    );
    final showUnprotectedBanner = securityAsync.maybeWhen(
      data: (security) => security.unprotected,
      orElse: () => false,
    );

    return _Card(
      children: [
        if (showUnprotectedBanner) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.settingsUiUnprotectedBannerTitle.toUpperCase(),
                  style: const TextStyle(
                    color: monoTextColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.settingsUiUnprotectedBannerBody,
                  style: const TextStyle(
                    color: monoMutedTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _Divider(),
        ],
        if (bioState.isSupported)
          _SwitchTile(
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: context.l10n.settingsUiBiometricUnlockTitle,
            subtitle: context.l10n.settingsUiBiometricUnlockSubtitle,
            value: bioState.isEnabled,
            accentColor: const Color(0xFFF59E0B),
            onChanged: (v) {
              HapticFeedback.mediumImpact();
              ref.read(biometricProvider.notifier).toggleBiometric(v);
            },
          ),
        if (bioState.isSupported) _Divider(),
        _ActionTile(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFF7AA2F7),
          title: context.l10n.settingsUiSecurityCenterTitle,
          subtitle: securitySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
          ),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: context.l10n.securityAuthenticatedDevicesTitle,
          subtitle: passkeySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showAuthenticatedDevicesSheet(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.devices_rounded,
          iconColor: Colors.white38,
          title: context.l10n.settingsUiSessionsActiveTitle,
          subtitle: context.l10n.settingsUiSessionsActiveSubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showSessionInfoSheet(context),
        ),
      ],
    );
  }

  void _showAuthenticatedDevicesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuthenticatedDevicesSheet(ref: ref),
    );
  }

  void _showSessionInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.devices_rounded,
        iconColor: Colors.white38,
        title: context.l10n.settingsUiSessionsActiveTitle,
        message: context.l10n.settingsUiSessionsActiveMessage,
      ),
    );
  }
}

class _EnterpriseAccessSection extends ConsumerWidget {
  const _EnterpriseAccessSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyStatus = ref.watch(adminKeyStatusProvider);
    final pendingAttempts = ref.watch(pendingAdminAccessAttemptsProvider);

    return _Card(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.settingsUiEnterpriseIntro,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              keyStatus.when(
                data: (status) => _AdminKeyStatusSummary(status: status),
                loading: () => Text(
                  context.l10n.settingsUiEnterpriseKeyLoading,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
                error: (_, __) => Text(
                  context.l10n.settingsUiEnterpriseKeyLoadError,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.vpn_key_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: context.l10n.settingsUiEnterpriseCreateKeyTitle,
          subtitle: context.l10n.settingsUiEnterpriseCreateKeySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _confirmCreateKey(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.rotate_right_rounded,
          iconColor: Colors.white54,
          title: context.l10n.settingsUiEnterpriseRotateKeyTitle,
          subtitle: context.l10n.settingsUiEnterpriseRotateKeySubtitle,
          trailing: Icons.refresh_rounded,
          onTap: () => _confirmCreateKey(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.block_rounded,
          iconColor: Colors.white38,
          title: context.l10n.settingsUiEnterpriseRevokeKeyTitle,
          subtitle: context.l10n.settingsUiEnterpriseRevokeKeySubtitle,
          trailing: Icons.delete_outline_rounded,
          onTap: () => _revokeKey(context, ref),
        ),
        pendingAttempts.when(
          data: (attempts) => attempts.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    _Divider(),
                    ...attempts.map(
                      (attempt) => _AdminAccessAttemptTile(
                        attempt: attempt,
                        onApprove: () =>
                            _decideAttempt(context, ref, attempt, true),
                        onBlock: () =>
                            _decideAttempt(context, ref, attempt, false),
                      ),
                    ),
                  ],
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _confirmCreateKey(BuildContext context, WidgetRef ref) async {
    var confirmed = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => _ConfirmationDialog(
            icon: Icons.admin_panel_settings_outlined,
            title: context.l10n.settingsUiEnterpriseCreateKeyTitle,
            message: context.l10n.settingsUiEnterpriseCreateDialogMessage,
            confirmLabel: context.l10n.settingsUiEnterpriseCreateKeyAction,
            cancelLabel: context.l10n.cancel,
            requireConfirmation: true,
            confirmed: confirmed,
            onConfirmationChanged: (value) => setState(() => confirmed = value),
            onConfirm: confirmed
                ? () => Navigator.pop(dialogContext, true)
                : null,
          ),
        );
      },
    );

    if (accepted != true || !context.mounted) {
      return;
    }

    final key = _generateAdminKey();
    final keyHash = crypto.sha256.convert(utf8.encode(key)).toString();
    final metadata = await DeviceHelper.getDeviceMetadata();
    final result = await ref
        .read(securityRepositoryProvider)
        .createAdminKey(
          keyMaterialHash: keyHash,
          deviceInstallId: metadata.deviceInstallId,
        );

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.l10n.settingsUiEnterpriseCreateKeyFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(adminKeyStatusProvider);
        _showCreatedKey(context, key);
      },
    );
  }

  Future<void> _revokeKey(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmationDialog(
        icon: Icons.block_rounded,
        title: context.l10n.settingsUiEnterpriseRevokeKeyTitle,
        message: context.l10n.settingsUiEnterpriseRevokeDialogMessage,
        confirmLabel: context.l10n.settingsUiEnterpriseRevokeAction,
        cancelLabel: context.l10n.cancel,
        destructive: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (accepted != true) {
      return;
    }

    final result = await ref.read(securityRepositoryProvider).revokeAdminKey();
    if (!context.mounted) {
      return;
    }
    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.l10n.settingsUiEnterpriseRevokeFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(adminKeyStatusProvider);
        AppNotice.showSuccess(
          context,
          title: context.l10n.settingsUiEnterpriseKeyRevokedTitle,
          message: context.l10n.settingsUiEnterpriseKeyRevokedMessage,
        );
      },
    );
  }

  Future<void> _decideAttempt(
    BuildContext context,
    WidgetRef ref,
    AdminAccessAttempt attempt,
    bool approve,
  ) async {
    final result = await ref
        .read(securityRepositoryProvider)
        .decideAdminAttempt(attemptId: attempt.attemptId, approve: approve);
    if (!context.mounted) {
      return;
    }
    result.fold(
      (failure) => AppNotice.showError(
        context,
        title: context.l10n.settingsUiEnterpriseDecisionFailed,
        message: failure.message,
      ),
      (_) {
        ref.invalidate(pendingAdminAccessAttemptsProvider);
        AppNotice.showSuccess(
          context,
          title: approve
              ? context.l10n.settingsUiEnterpriseAccessAllowedTitle
              : context.l10n.settingsUiEnterpriseDeviceBlockedTitle,
          message: approve
              ? context.l10n.settingsUiEnterpriseAccessAllowedMessage
              : context.l10n.settingsUiEnterpriseDeviceBlockedMessage,
        );
      },
    );
  }

  void _showCreatedKey(BuildContext context, String key) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: monoSurfaceColor,
        title: Text(
          context.l10n.settingsUiEnterpriseKeyCreatedTitle,
          style: const TextStyle(color: monoTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.settingsUiEnterpriseKeyCreatedMessage,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              key,
              style: const TextStyle(
                color: monoTextColor,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.settingsUiCloseAction.toUpperCase()),
          ),
        ],
      ),
    );
  }

  String _generateAdminKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return 'krs-admin-${base64Url.encode(bytes).replaceAll('=', '')}';
  }
}

class _AdminKeyStatusSummary extends StatelessWidget {
  final AdminKeyStatus status;

  const _AdminKeyStatusSummary({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          status.configured ? Icons.check_circle_outline : Icons.info_outline,
          color: status.configured ? Colors.white70 : Colors.white38,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            status.configured
                ? context.l10n.settingsUiEnterpriseKeyActive
                : context.l10n.settingsUiEnterpriseKeyMissing,
            style: AppTypography.bodySmall.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}

class _AdminAccessAttemptTile extends StatelessWidget {
  final AdminAccessAttempt attempt;
  final VoidCallback onApprove;
  final VoidCallback onBlock;

  const _AdminAccessAttemptTile({
    required this.attempt,
    required this.onApprove,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsUiEnterpriseAttemptTitle,
            style: AppTypography.bodyMedium.copyWith(color: monoTextColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              if (attempt.browser.isNotEmpty)
                '${context.l10n.settingsUiBrowserLabel}: ${attempt.browser}',
              if (attempt.deviceName.isNotEmpty)
                '${context.l10n.settingsUiDeviceLabel}: ${attempt.deviceName}',
              if (attempt.requestedAt != null)
                '${context.l10n.settingsUiTimeLabel}: ${_formatDate(attempt.requestedAt!)}',
            ].join('\n'),
            style: AppTypography.bodySmall.copyWith(
              color: monoMutedTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: monochromeFilledButtonStyle(),
                  child: Text(context.l10n.settingsUiAllowAction.toUpperCase()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onBlock,
                  style: monochromeOutlinedButtonStyle(),
                  child: Text(context.l10n.settingsUiBlockAction.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int input) => input.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

// ─── Credentials Section ──────────────────────────────────────────────────────

class _CredentialsSection extends ConsumerWidget {
  const _CredentialsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final username = authState is AuthAuthenticated ? authState.user.name : '—';

    return _Card(
      children: [
        // Current user info
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: monochromePanelDecoration(
                  color: monoSurfaceAltColor,
                  borderColor: monoBorderStrongColor,
                  showShadow: false,
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.settingsUiAuthenticatedLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: monoMutedTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _Divider(),

        // Danger zone: delete account
        _ActionTile(
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.error,
          title: context.l10n.settingsUiDeleteAccountTitle,
          subtitle: context.l10n.settingsUiDeleteAccountSubtitle,
          trailing: Icons.chevron_right_rounded,
          titleColor: AppColors.error,
          onTap: () => _showDeleteConfirmDialog(context, ref),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _DangerDialog(
        title: context.l10n.settingsUiDeleteAccountDialogTitle,
        message: context.l10n.settingsUiDeleteAccountDialogMessage,
        confirmLabel: context.l10n.settingsUiDeleteForeverAction,
        onConfirm: () {
          Navigator.pop(context);
          // Logout and inform user — actual deletion depends on backend support
          ref.read(authControllerProvider.notifier).logout();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/welcome', (_) => false);
        },
      ),
    );
  }
}

// ─── Notifications Section ────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection();

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertPreferencesProvider);
    final notificationCount = ref.watch(sessionNotificationUnreadCountProvider);
    final alertsEnabled = alerts.backgroundAlertsEnabled;

    return _Card(
      children: [
        _SwitchTile(
          icon: Icons.notifications_active_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: context.l10n.settingsUiTransactionSecurityAlertsTitle,
          subtitle: alertsEnabled
              ? context.l10n.settingsUiBackgroundAlertsOnSubtitle
              : context.l10n.settingsUiBackgroundAlertsOffSubtitle,
          value: alertsEnabled,
          accentColor: const Color(0xFFA78BFA),
          onChanged: _isSaving ? (_) {} : _handleBackgroundAlertsToggle,
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: context.l10n.settingsUiInAppBannersTitle,
          subtitle: alerts.inAppBannersEnabled
              ? context.l10n.settingsUiInAppBannersOnSubtitle
              : context.l10n.settingsUiInAppBannersOffSubtitle,
          value: alerts.inAppBannersEnabled,
          accentColor: const Color(0xFF60A5FA),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setInAppBannersEnabled(value),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.swap_vert_rounded,
          iconColor: const Color(0xFF7DD3A0),
          title: context.l10n.settingsUiFinancialEventsTitle,
          subtitle: alerts.transactionAlertsEnabled
              ? context.l10n.settingsUiFinancialEventsOnSubtitle
              : context.l10n.settingsUiFinancialEventsOffSubtitle,
          value: alerts.transactionAlertsEnabled,
          accentColor: const Color(0xFF7DD3A0),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setTransactionAlertsEnabled(value),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.gpp_maybe_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: context.l10n.settingsUiSecurityEventsTitle,
          subtitle: alerts.securityAlertsEnabled
              ? context.l10n.settingsUiSecurityEventsOnSubtitle
              : context.l10n.settingsUiSecurityEventsOffSubtitle,
          value: alerts.securityAlertsEnabled,
          accentColor: const Color(0xFFF59E0B),
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setSecurityAlertsEnabled(value),
        ),
        _Divider(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: monoBorderStrongColor,
              showShadow: false,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isSaving ? Icons.sync_rounded : Icons.info_outline_rounded,
                  color: monoTextColor,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isSaving
                        ? context.l10n.settingsUiUpdatingBackgroundAlerts
                        : context.l10n.settingsUiBackgroundAlertsInfo(
                            notificationCount,
                          ),
                    style: AppTypography.bodySmall.copyWith(
                      color: monoMutedTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBackgroundAlertsToggle(bool enabled) async {
    if (_isSaving) {
      return;
    }

    if (enabled) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const _BackgroundAlertsConsentSheet(),
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() => _isSaving = true);
      final permissionsGranted = await NotificationService()
          .requestPermissions();
      if (!mounted) {
        return;
      }
      if (!permissionsGranted) {
        setState(() => _isSaving = false);
        AppNotice.showWarning(
          context,
          title: context.l10n.settingsUiPermissionRequiredTitle,
          message: context.l10n.settingsUiPermissionRequiredMessage,
        );
        return;
      }
    } else {
      setState(() => _isSaving = true);
    }

    try {
      await ref
          .read(alertPreferencesProvider.notifier)
          .setBackgroundAlertsEnabled(enabled);
      if (enabled) {
        await startBackgroundService();
      } else {
        await stopBackgroundService();
      }

      if (!mounted) {
        return;
      }

      AppNotice.showInfo(
        context,
        title: enabled
            ? context.l10n.settingsUiMonitoringActiveTitle
            : context.l10n.settingsUiMonitoringInactiveTitle,
        message: enabled
            ? context.l10n.settingsUiMonitoringActiveMessage
            : context.l10n.settingsUiMonitoringInactiveMessage,
      );
    } catch (_) {
      if (mounted) {
        AppNotice.showError(
          context,
          title: context.l10n.settingsUiAlertsUpdateFailedTitle,
          message: context.l10n.settingsUiAlertsUpdateFailedMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// ─── Session Section ──────────────────────────────────────────────────────────

class _SessionSection extends ConsumerWidget {
  const _SessionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      children: [
        _ActionTile(
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          title: context.l10n.settingsUiLogoutTitle,
          subtitle: context.l10n.settingsUiLogoutSubtitle,
          trailing: Icons.chevron_right_rounded,
          titleColor: AppColors.error,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _DangerDialog(
        title: context.l10n.settingsUiLogoutDialogTitle,
        message: context.l10n.settingsUiLogoutDialogMessage,
        confirmLabel: context.l10n.settingsUiLogoutTitle,
        onConfirm: () async {
          Navigator.pop(context);
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (_) => false);
          }
        },
      ),
    );
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────

class _AuthenticatedDevicesSheet extends StatelessWidget {
  final WidgetRef ref;
  const _AuthenticatedDevicesSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: context.l10n.securityAuthenticatedDevicesTitle,
      icon: Icons.devices_rounded,
      iconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          Text(
            context.l10n.settingsUiAuthenticatedDevicesBody,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.l10n.settingsUiRegisterNewDeviceAction,
            icon: Icons.add_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).registerPasskey();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: context.l10n.settingsUiLearnMoreAction,
            icon: Icons.info_outline_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BackgroundAlertsConsentSheet extends StatelessWidget {
  const _BackgroundAlertsConsentSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: context.l10n.settingsUiBackgroundAlertsTitle,
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFFA78BFA),
      child: Column(
        children: [
          Text(
            context.l10n.settingsUiBackgroundAlertsConsentBody,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.l10n.settingsUiEnableMonitoringAction,
            icon: Icons.check_rounded,
            color: const Color(0xFFA78BFA),
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: context.l10n.cancel,
            icon: Icons.close_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _InfoSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: title,
      icon: icon,
      iconColor: iconColor,
      child: Column(
        children: [
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: context.l10n.settingsUiUnderstoodAction,
            icon: Icons.check_rounded,
            color: Colors.white24,
            isOutline: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Bottom Sheet Container ───────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BottomSheetContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderTone =
        Color.lerp(monoBorderStrongColor, iconColor, 0.08) ??
        monoBorderStrongColor;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 1, color: monoBorderStrongColor),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 56,
            height: 56,
            decoration: monochromePanelDecoration(
              color: monoSurfaceAltColor,
              borderColor: borderTone,
              showShadow: false,
            ),
            child: Icon(icon, color: monoTextColor, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3.copyWith(color: monoTextColor)),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

// ─── Danger Dialog ────────────────────────────────────────────────────────────

class _ConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool requireConfirmation;
  final bool confirmed;
  final ValueChanged<bool>? onConfirmationChanged;
  final VoidCallback? onConfirm;

  const _ConfirmationDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    this.requireConfirmation = false,
    this.confirmed = false,
    this.onConfirmationChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: monoSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: monoTextColor, size: 30),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: monoTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (requireConfirmation) ...[
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) =>
                    onConfirmationChanged?.call(value == true),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Entendo que esta chave autoriza acesso ao painel admin.',
                  style: AppTypography.bodySmall.copyWith(color: monoTextColor),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: monochromeOutlinedButtonStyle(),
                    child: Text(cancelLabel.toUpperCase()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: destructive
                        ? monochromeOutlinedButtonStyle()
                        : monochromeFilledButtonStyle(),
                    child: Text(confirmLabel.toUpperCase()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _DangerDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: monoSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: monoBorderStrongColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: monochromePanelDecoration(
                color: monoSurfaceAltColor,
                borderColor: monoBorderStrongColor,
                showShadow: false,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: monoTextColor,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: monoTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: monoMutedTextColor,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: monochromePanelDecoration(
                        color: monoSurfaceAltColor,
                        borderColor: monoBorderStrongColor,
                        showShadow: false,
                      ),
                      child: Text(
                        'Cancelar',
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: monoMutedTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: monochromePanelDecoration(
                        color: monoTextColor,
                        borderColor: monoBorderStrongColor,
                        showShadow: false,
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Primitives ──────────────────────────────────────────────────────

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
                    color: selected
                        ? monoSurfaceRaisedColor
                        : monoSurfaceAltColor,
                    borderColor: selected
                        ? selectedBorder
                        : monoBorderStrongColor,
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
    final activeTrack =
        Color.lerp(monoSurfaceRaisedColor, accentColor, 0.08) ??
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
    final iconBorder =
        Color.lerp(monoBorderStrongColor, iconColor, 0.08) ??
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
