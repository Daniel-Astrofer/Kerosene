import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/app_primary_navigation.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
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
import '../../../wallet/presentation/providers/balance_settings_provider.dart';

// ─── Screen Entry ─────────────────────────────────────────────────────────────

final backupCodesProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.read(authRepositoryProvider).getBackupCodes();
  return result.fold(
    (_) => const <String>[],
    (codes) => codes,
  );
});

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const SettingsScreen({
    super.key,
    this.showPrimaryNavigation = false,
  });

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
      duration: const Duration(milliseconds: 600),
    );
    _sectionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic));

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
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
    final bottomSectionPadding = widget.showPrimaryNavigation
        ? AppPrimaryNavigationBar.scaffoldBottomClearance(context)
        : 80.0;

    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientSideGlowBackdrop.authenticated(),
          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        const _SettingsOverviewCard(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.shield_outlined,
                          label: 'SEGURANÇA E ACESSO',
                          color: Colors.white70,
                          child: const _SecuritySection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.privacy_tip_outlined,
                          label: 'PRIVACIDADE',
                          color: Colors.white70,
                          child: const _PrivacySection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.manage_accounts_outlined,
                          label: 'CONTA E ACESSO',
                          color: Colors.white70,
                          child: const _CredentialsSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.notifications_outlined,
                          label: 'NOTIFICAÇÕES',
                          color: Colors.white70,
                          child: const _NotificationsSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.palette_outlined,
                          label: 'APARÊNCIA',
                          color: Colors.white70,
                          child: const _AppearanceSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.language_rounded,
                          label: 'IDIOMA E MOEDA',
                          color: Colors.white70,
                          child: const _LocaleSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.power_settings_new_rounded,
                          label: 'SESSÃO',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONFIGURAÇÕES',
                style: AppTypography.h2.copyWith(
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
              Text(
                'Segurança, privacidade e operação da conta',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
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
          )
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
        ? 'Verificando'
        : biometricState.isSupported
            ? (biometricState.isEnabled ? 'Ativa' : 'Desativada')
            : 'Indisponível';

    return _Card(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo operacional',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppCopy.settingsOverviewSummary.resolve(context),
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
                    label: 'Alertas',
                    value: alerts.backgroundAlertsEnabled
                        ? 'Segundo plano ativo'
                        : 'Desativados',
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
                    label: 'Tema',
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
    final borderTone =
        Color.lerp(monoBorderStrongColor, color, 0.08) ?? monoBorderStrongColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
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
            style: AppTypography.caption.copyWith(
              color: monoMutedTextColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
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
          title: 'Precisão decimal',
          subtitle: 'Exibindo ${balanceSettings.decimalPlaces} casas decimais',
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
          title: 'Ocultar saldo',
          subtitle: balanceSettings.isHidden
              ? 'Valores mascarados na interface principal'
              : 'Valores visíveis em telas operacionais',
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
          title: 'Relatório de soberania',
          subtitle:
              'Abrir o painel de atestação, consenso e integridade operacional',
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
          ? 'Conta não protegida. Revise TOTP e backup codes.'
          : 'Conta protegida com senha forte, passkey e fatores opcionais.',
      loading: () => 'Consultando estado da conta',
      error: (_, __) => 'Não foi possível consultar a segurança da conta',
    );
    final passkeySubtitle = securityAsync.when(
      data: (security) => security.passkeyRegistered
          ? 'Passkey já registrada para esta conta'
          : 'Registrar uma passkey protegida por biometria',
      loading: () => 'Consultando passkey',
      error: (_, __) => 'Não foi possível consultar a passkey',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTA NÃO PROTEGIDA',
                  style: TextStyle(
                    color: monoTextColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'O TOTP está desligado. Abra a central de segurança para ativar o autenticador e revisar os backup codes.',
                  style: TextStyle(color: monoMutedTextColor, height: 1.4),
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
            title: 'Desbloqueio biométrico',
            subtitle: 'Use digital ou rosto para desbloquear',
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
          title: 'Central de segurança',
          subtitle: securitySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SecuritySettingsScreen(),
            ),
          ),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Passkey',
          subtitle: passkeySubtitle,
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showPasskeySheet(context, ref),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.devices_rounded,
          iconColor: Colors.white38,
          title: 'Sessões ativas',
          subtitle: 'Ver e revogar sessões do dispositivo',
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showSessionInfoSheet(context),
        ),
      ],
    );
  }

  void _showPasskeySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PasskeySheet(ref: ref),
    );
  }

  void _showSessionInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.devices_rounded,
        iconColor: Colors.white38,
        title: 'Sessões ativas',
        message:
            'O gerenciamento de sessão é feito automaticamente pelo servidor. Cada dispositivo é identificado por um X-Device-Hash exclusivo. Encerre a sessão para revogar o acesso atual.',
      ),
    );
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
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Autenticado',
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
          title: 'Excluir conta',
          subtitle: 'Remove permanentemente todos os dados',
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
        title: 'Excluir conta?',
        message:
            'Isso vai excluir permanentemente sua conta, suas carteiras e seus fundos. Esta ação NÃO pode ser desfeita.\n\nPara proteger seus recursos, saque todos os saldos antes de excluir a conta.',
        confirmLabel: 'Excluir para sempre',
        onConfirm: () {
          Navigator.pop(context);
          // Logout and inform user — actual deletion depends on backend support
          ref.read(authControllerProvider.notifier).logout();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/welcome', (_) => false);
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
          title: 'Alertas de transação e segurança',
          subtitle: alertsEnabled
              ? 'Ativo. O app permanece em segundo plano para mostrar transações e alertas de segurança.'
              : 'Ative para manter o app em segundo plano e receber transações e alertas de segurança.',
          value: alertsEnabled,
          accentColor: const Color(0xFFA78BFA),
          onChanged: _isSaving ? (_) {} : _handleBackgroundAlertsToggle,
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: 'Banners dentro do app',
          subtitle: alerts.inAppBannersEnabled
              ? 'Mostra alertas contextuais na sessão atual.'
              : 'Mantém o feed, mas não interrompe a navegação com banners.',
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
          title: 'Eventos financeiros',
          subtitle: alerts.transactionAlertsEnabled
              ? 'Recebimentos, envios, depósitos, links e mineração entram no feed.'
              : 'Oculta alertas de operação financeira no feed da sessão.',
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
          title: 'Eventos de segurança',
          subtitle: alerts.securityAlertsEnabled
              ? 'Logins, recuperação e eventos sensíveis continuam destacados.'
              : 'Oculta apenas alertas de segurança da inbox da sessão.',
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
                        ? 'Atualizando o monitoramento em segundo plano.'
                        : 'Quando ativo, o Kerosene mantém um serviço em segundo plano para monitorar envios, recebimentos e eventos críticos de segurança. No Android, uma notificação persistente do sistema ficará visível enquanto o monitoramento estiver ligado. $notificationCount alerta(s) ainda não foram lidos nesta sessão.',
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
      final permissionsGranted =
          await NotificationService().requestPermissions();
      if (!mounted) {
        return;
      }
      if (!permissionsGranted) {
        setState(() => _isSaving = false);
        AppNotice.showWarning(
          context,
          title: 'Permissão necessária',
          message:
              'O sistema não liberou as notificações. Autorize o app para ativar o monitoramento em segundo plano.',
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
        title: enabled ? 'Monitoramento ativo' : 'Monitoramento desativado',
        message: enabled
            ? 'O app continuará em segundo plano para mostrar transações e alertas de segurança.'
            : 'O Kerosene não manterá mais o serviço em segundo plano para alertas.',
      );
    } catch (_) {
      if (mounted) {
        AppNotice.showError(
          context,
          title: 'Falha ao atualizar alertas',
          message:
              'Não foi possível alterar o monitoramento em segundo plano agora.',
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
          title: 'Encerrar sessão',
          subtitle: 'Encerra a sessão atual',
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
        title: 'Encerrar sessão?',
        message:
            'Você precisará se autenticar novamente com sua frase secreta e com o código TOTP para acessar a conta outra vez.',
        confirmLabel: 'Encerrar sessão',
        onConfirm: () async {
          Navigator.pop(context);
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/welcome', (_) => false);
          }
        },
      ),
    );
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────

class _PasskeySheet extends StatelessWidget {
  final WidgetRef ref;
  const _PasskeySheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: 'Gerenciar passkey',
      icon: Icons.key_rounded,
      iconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          Text(
            'A passkey usa o sensor biométrico do seu dispositivo como chave física de segurança. Ela substitui a digitação tradicional da senha por um acesso mais rápido e resistente a phishing.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: 'Registrar nova passkey',
            icon: Icons.add_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).registerPasskey();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: 'Saiba mais',
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
      title: 'Alertas em segundo plano',
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFFA78BFA),
      child: Column(
        children: [
          Text(
            'Ao ativar esta opção, o Kerosene continuará rodando em segundo plano para mostrar transações recebidas, enviadas e alertas críticos de segurança. No Android, o sistema manterá uma notificação persistente enquanto o monitoramento estiver ativo.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: 'Ativar monitoramento',
            icon: Icons.check_rounded,
            color: const Color(0xFFA78BFA),
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            label: 'Cancelar',
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
            label: 'Entendi',
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
    final borderTone = Color.lerp(monoBorderStrongColor, iconColor, 0.08) ??
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
          Container(
            width: 48,
            height: 1,
            color: monoBorderStrongColor,
          ),
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
          Text(
            title,
            style: AppTypography.h3.copyWith(color: monoTextColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

// ─── Danger Dialog ────────────────────────────────────────────────────────────

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
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: monoMutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
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
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected ? monoTextColor : monoMutedTextColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null && !selected)
                Text(
                  trailing!,
                  style:
                      AppTypography.caption.copyWith(color: monoFaintTextColor),
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
    final activeBorder =
        Color.lerp(monoTextColor, iconColor, 0.08) ?? monoTextColor;
    final activeTrack = Color.lerp(monoSurfaceRaisedColor, accentColor, 0.08) ??
        monoSurfaceRaisedColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
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
                  style: AppTypography.bodyMedium.copyWith(
                    color: value ? monoTextColor : monoMutedTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
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
                      style: AppTypography.bodyMedium.copyWith(
                        color: effectiveTitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
