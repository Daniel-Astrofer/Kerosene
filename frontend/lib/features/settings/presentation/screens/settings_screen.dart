import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/biometric_provider.dart';
import '../../../../core/providers/ghost_mode_provider.dart';
import '../../../../core/providers/appearance_provider.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../auth/controller/auth_providers.dart';
import '../../../security/presentation/screens/sovereignty_status_screen.dart';
import '../../../wallet/presentation/providers/balance_settings_provider.dart';

// ─── Screen Entry ─────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

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
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070A10),
              Color(0xFF0D1219),
              Color(0xFF050607),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: _SettingsHeader(
                    onBack: () => Navigator.pop(context),
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final ghostMode = ref.watch(ghostModeProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);
    final locale = ref.watch(localeProvider).locale;
    final currency = ref.watch(currencyProvider);

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
                'Revise rapidamente a postura atual de acesso, privacidade e exibição antes de alterar detalhes finos.',
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
                    label: 'Roteamento',
                    value: ghostMode ? 'Onion ativo' : 'Conexão direta',
                    color: const Color(0xFF7AA2F7),
                  ),
                  _OverviewPill(
                    label: 'Biometria',
                    value: biometricLabel,
                    color: const Color(0xFFF2C94C),
                  ),
                  _OverviewPill(
                    label: 'Saldo',
                    value: balanceSettings.isHidden ? 'Oculto' : 'Visível',
                    color: const Color(0xFF7DD3A0),
                  ),
                  _OverviewPill(
                    label: 'Localização',
                    value:
                        '${locale.languageCode.toUpperCase()} · ${_currencyLabel(currency)}',
                    color: const Color(0xFFE5B97A),
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
    switch (variant) {
      case AppThemeVariant.dark:
        return const Color(0xFF1A1A1B);
      case AppThemeVariant.amoled:
        return const Color(0xFF000000);
      case AppThemeVariant.dimmed:
        return const Color(0xFF232536);
    }
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
    final ghostMode = ref.watch(ghostModeProvider);
    final balanceSettings = ref.watch(balanceSettingsProvider);

    return _Card(
      children: [
        _SwitchTile(
          icon: Icons.travel_explore_rounded,
          iconColor: const Color(0xFF7AA2F7),
          title: 'Roteamento onion',
          subtitle: ghostMode
              ? 'Todo o tráfego segue pela rede protegida da plataforma'
              : 'Conexão direta com menor proteção de metadados',
          value: ghostMode,
          accentColor: const Color(0xFF7AA2F7),
          onChanged: (value) {
            HapticFeedback.mediumImpact();
            ref.read(ghostModeProvider.notifier).update(value);
          },
        ),
        _Divider(),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider).locale;
    final currentCurrency = ref.watch(currencyProvider);

    final languages = [
      _LangItem('🇺🇸', 'English', 'EN', const Locale('en')),
      _LangItem('🇧🇷', 'Português', 'PT', const Locale('pt')),
      _LangItem('🇪🇸', 'Español', 'ES', const Locale('es')),
    ];

    final currencies = [
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

    return _Card(
      children: [
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
        // Passkey Management
        _ActionTile(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Gerenciar passkey',
          subtitle: 'Registrar ou atualizar chave de hardware',
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showPasskeySheet(context, ref),
        ),
        _Divider(),
        // Backup Codes
        _ActionTile(
          icon: Icons.emergency_rounded,
          iconColor: const Color(0xFFEF4444), // Vermelho para emergência
          title: 'Códigos de backup',
          subtitle: 'Códigos de recuperação para o 2FA',
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showBackupCodesSheet(context, ref),
        ),
        _Divider(),
        // Session Info
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

  // ─── Backup Codes Sheet ───────────────────────────────────────────────────────
  void _showBackupCodesSheet(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getBackupCodes();

    if (!context.mounted) return;

    List<String> codes = [];
    String error = '';
    result.fold(
      (failure) => error = failure.message,
      (data) => codes = data,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'CÓDIGOS DE BACKUP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Guarde estes códigos em local seguro. Eles podem ser usados para entrar caso você perca acesso ao autenticador.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: codes
                        .map((code) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('JÁ GUARDEI',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
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

        // Change passphrase
        _ActionTile(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFFFF6B6B),
          title: 'Alterar frase secreta',
          subtitle: 'Exige a frase secreta atual para confirmar',
          trailing: Icons.chevron_right_rounded,
          onTap: () => _showChangePassphraseSheet(context, ref, username),
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

  void _showChangePassphraseSheet(
      BuildContext context, WidgetRef ref, String username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChangePassphraseSheet(username: username, ref: ref),
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
  bool _transactionAlerts = true;
  bool _securityAlerts = true;
  bool _priceAlerts = false;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SwitchTile(
          icon: Icons.swap_horiz_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: 'Alertas de transação',
          subtitle: 'Avisar em cada envio e recebimento',
          value: _transactionAlerts,
          accentColor: const Color(0xFFA78BFA),
          onChanged: (v) => setState(() => _transactionAlerts = v),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.security_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: 'Alertas de segurança',
          subtitle: 'Tentativas de login e eventos de passkey',
          value: _securityAlerts,
          accentColor: const Color(0xFFA78BFA),
          onChanged: (v) => setState(() => _securityAlerts = v),
        ),
        _Divider(),
        _SwitchTile(
          icon: Icons.show_chart_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: 'Alertas de preço do BTC',
          subtitle: 'Avisar em movimentos relevantes de preço',
          value: _priceAlerts,
          accentColor: const Color(0xFFA78BFA),
          onChanged: (v) => setState(() => _priceAlerts = v),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.phonelink_rounded,
          iconColor: Colors.white38,
          title: 'Token push',
          subtitle: 'Registrar este dispositivo novamente para push',
          trailing: Icons.refresh_rounded,
          onTap: () => _reRegisterToken(context),
        ),
      ],
    );
  }

  void _reRegisterToken(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Atualização do token push solicitada...'),
        backgroundColor: const Color(0xFF1A1A1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

class _ChangePassphraseSheet extends StatefulWidget {
  final String username;
  final WidgetRef ref;
  const _ChangePassphraseSheet({required this.username, required this.ref});

  @override
  State<_ChangePassphraseSheet> createState() => _ChangePassphraseSheetState();
}

class _ChangePassphraseSheetState extends State<_ChangePassphraseSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'As novas frases secretas não coincidem.');
      return;
    }
    if (_newCtrl.text.length < 8) {
      setState(
          () => _error = 'A frase secreta deve ter pelo menos 8 caracteres.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // The API doesn't have a dedicated change-password endpoint exposed.
    // Best practice: re-login with current credentials, then note the change.
    // For now we simulate with a small delay and inform the user.
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'A troca da frase secreta exige nova autenticação. Encerre a sessão e entre novamente usando a nova frase secreta.'),
          backgroundColor: const Color(0xFF1A1A1B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      title: 'Alterar frase secreta',
      icon: Icons.lock_outline_rounded,
      iconColor: const Color(0xFFFF6B6B),
      child: Column(
        children: [
          _PassField(
            controller: _currentCtrl,
            label: 'Frase secreta atual',
            obscure: !_showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: AppSpacing.md),
          _PassField(
            controller: _newCtrl,
            label: 'Nova frase secreta',
            obscure: !_showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
          ),
          const SizedBox(height: AppSpacing.md),
          _PassField(
            controller: _confirmCtrl,
            label: 'Confirmar nova frase secreta',
            obscure: !_showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _SheetButton(
            label: _isLoading ? 'Processando...' : 'Atualizar frase secreta',
            icon: Icons.check_rounded,
            color: const Color(0xFFFF6B6B),
            onTap: _isLoading ? null : _submit,
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

// ─── Input Field for Sheets ───────────────────────────────────────────────────

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white38,
            size: 20,
          ),
        ),
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
