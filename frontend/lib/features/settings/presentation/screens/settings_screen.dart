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
                          color: const Color(0xFF7DD3A0),
                          child: const _SecuritySection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.privacy_tip_outlined,
                          label: 'PRIVACIDADE',
                          color: const Color(0xFF7AA2F7),
                          child: const _PrivacySection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.manage_accounts_outlined,
                          label: 'CONTA E ACESSO',
                          color: const Color(0xFFE5B97A),
                          child: const _CredentialsSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.notifications_outlined,
                          label: 'NOTIFICAÇÕES',
                          color: const Color(0xFFA78BFA),
                          child: const _NotificationsSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.palette_outlined,
                          label: 'APARÊNCIA',
                          color: const Color(0xFF9FB3C8),
                          child: const _AppearanceSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.language_rounded,
                          label: 'IDIOMA E MOEDA',
                          color: const Color(0xFF60A5FA),
                          child: const _LocaleSection(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildSection(
                          icon: Icons.power_settings_new_rounded,
                          label: 'SESSÃO',
                          color: AppColors.error,
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
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child:
                const Icon(Icons.tune_rounded, color: Colors.white38, size: 18),
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
                    color: const Color(0xFFA78BFA),
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsBiometrics.resolve(context),
                    value: biometricLabel,
                    color: const Color(0xFFF2C94C),
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsBalance.resolve(context),
                    value: balanceSettings.isHidden
                        ? AppCopy.settingsHidden.resolve(context)
                        : AppCopy.settingsVisible.resolve(context),
                    color: const Color(0xFF7DD3A0),
                  ),
                  _OverviewPill(
                    label: AppCopy.settingsLocation.resolve(context),
                    value:
                        '${locale.languageCode.toUpperCase()} · ${_currencyLabel(currency)}',
                    color: const Color(0xFFE5B97A),
                  ),
                  _OverviewPill(
                    label: 'Tema',
                    value: appearance.themeVariant.label,
                    color: const Color(0xFF9FB3C8),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: color,
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5BC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              const Color(0xFF00E5BC).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      appearance.fontScale.label,
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF00E5BC),
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
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
                  activeTrackColor: const Color(0xFF00E5BC),
                  inactiveTrackColor: Colors.white10,
                  thumbColor: const Color(0xFF00E5BC),
                  overlayColor: const Color(0xFF00E5BC).withValues(alpha: 0.12),
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
                              ? const Color(0xFF00E5BC)
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
          iconColor: const Color(0xFF00E5BC),
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
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5BC).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF00E5BC).withValues(alpha: 0.5)
                : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Mini preview circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _previewBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              variant.label,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: selected ? const Color(0xFF00E5BC) : Colors.white38,
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
          iconColor: const Color(0xFF7AA2F7),
          title: 'Ocultar saldo',
          subtitle: balanceSettings.isHidden
              ? 'Valores mascarados na interface principal'
              : 'Valores visíveis em telas operacionais',
          value: balanceSettings.isHidden,
          accentColor: const Color(0xFF7AA2F7),
          onChanged: (_) {
            HapticFeedback.mediumImpact();
            ref.read(balanceSettingsProvider.notifier).toggleVisibility();
          },
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF7AA2F7),
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
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

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
            accentColor: const Color(0xFF60A5FA),
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
            accentColor: const Color(0xFFF7931A),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTA NÃO PROTEGIDA',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'O TOTP está desligado. Abra a central de segurança para ativar o autenticador e revisar os backup codes.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF3E3E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                      color: AppColors.success,
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
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFA78BFA).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFA78BFA).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isSaving ? Icons.sync_rounded : Icons.info_outline_rounded,
                  color: const Color(0xFFA78BFA),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isSaving
                        ? 'Atualizando o monitoramento em segundo plano.'
                        : 'Quando ativo, o Kerosene mantém um serviço em segundo plano para monitorar envios, recebimentos e eventos críticos de segurança. No Android, uma notificação persistente do sistema ficará visível enquanto o monitoramento estiver ligado.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white54,
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
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
          left: BorderSide(color: Colors.white12, width: 0.5),
          right: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Icon header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3),
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
      backgroundColor: const Color(0xFF0E0E0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white54,
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
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        'Cancelar',
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.white54,
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
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        textAlign: TextAlign.center,
                        style: AppTypography.buttonText.copyWith(
                          color: AppColors.error,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.8),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
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
      color: Colors.white.withValues(alpha: 0.06),
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
          color: selected
              ? accentColor.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Row(
            children: [
              if (isPill)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    leading,
                    style: AppTypography.bodyMedium.copyWith(
                      color: selected ? accentColor : Colors.white54,
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
                    color: selected ? accentColor : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null && !selected)
                Text(
                  trailing!,
                  style: AppTypography.caption.copyWith(color: Colors.white24),
                ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: accentColor,
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
            decoration: BoxDecoration(
              color: value
                  ? iconColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: value ? iconColor : Colors.white30,
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
                    color: value ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.2),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.15),
            inactiveTrackColor: Colors.white10,
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
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: titleColor ?? Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Icon(trailing,
                    color: Colors.white.withValues(alpha: 0.2), size: 20),
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white60, size: 18),
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
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color:
                isOutline ? Colors.transparent : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOutline
                  ? Colors.white.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isOutline ? Colors.white38 : color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.buttonText.copyWith(
                  color: isOutline ? Colors.white38 : color,
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
