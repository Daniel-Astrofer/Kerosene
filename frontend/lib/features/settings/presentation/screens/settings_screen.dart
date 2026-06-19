import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/navigation/deferred_page.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/core/providers/appearance_provider.dart';
import 'package:kerosene/core/responsive/kerosene_responsive.dart';
import 'package:kerosene/core/services/background_service.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';

import '../../../bitcoin_accounts/presentation/bitcoin_accounts_screen.dart'
    deferred as bitcoin_accounts;
import '../../../profile/presentation/screens/security_settings_screen.dart'
    deferred as security_settings;
import 'settings_modern_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showPrimaryNavigation;

  const SettingsScreen({super.key, this.showPrimaryNavigation = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

enum _SettingsPane { account, security, notifications, appearance, wallets }

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsPane _pane = _SettingsPane.account;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final wide = MediaQuery.sizeOf(context).width >= 860;

    return Scaffold(
      backgroundColor: KeroseneBrandTokens.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(onClose: _close)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                AppSpacing.lg,
                responsive.horizontalPadding,
                MediaQuery.viewPaddingOf(context).bottom + AppSpacing.xxl,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 320,
                                child: _NavigationRail(
                                  selected: _pane,
                                  onSelected: _selectPane,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl2),
                              Expanded(child: _AnimatedPaneSwitcher(_pane)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _NavigationRail(
                                selected: _pane,
                                onSelected: _selectPane,
                              ),
                              const SizedBox(height: AppSpacing.xl2),
                              _AnimatedPaneSwitcher(_pane),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPane(_SettingsPane pane) {
    HapticFeedback.selectionClick();
    setState(() => _pane = pane);
  }

  void _close() {
    HapticFeedback.selectionClick();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/home');
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.md,
        AppSpacing.xl2,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: AppTypography.newsreader(
                    color: KeroseneBrandTokens.textPrimary,
                    fontSize: context.responsive.compactFontSize(
                      tiny: 34,
                      compact: 38,
                      regular: 44,
                    ),
                    fontWeight: FontWeight.w500,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Privacidade financeira com clareza operacional.',
                  style: AppTypography.description.copyWith(
                    color: KeroseneBrandTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SettingsIconButtonFrame(
            icon: KeroseneIcons.close,
            semanticLabel: 'Fechar configurações',
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  final _SettingsPane selected;
  final ValueChanged<_SettingsPane> onSelected;

  const _NavigationRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = <_PaneSpec>[
      _PaneSpec(
        pane: _SettingsPane.account,
        icon: KeroseneIcons.userCheck,
        animation: KeroseneAnimationAsset.secureConnection,
        title: 'Conta',
        subtitle: 'Sessão, usuário e acesso',
      ),
      _PaneSpec(
        pane: _SettingsPane.security,
        icon: KeroseneIcons.security,
        animation: KeroseneAnimationAsset.securityShield,
        title: 'Segurança',
        subtitle: 'PIN, passkeys e TOTP reais',
      ),
      _PaneSpec(
        pane: _SettingsPane.notifications,
        icon: KeroseneIcons.notifications,
        animation: KeroseneAnimationAsset.transactionStatus,
        title: 'Notificações',
        subtitle: 'Preferências e dispositivos',
      ),
      _PaneSpec(
        pane: _SettingsPane.appearance,
        icon: KeroseneIcons.contrast,
        animation: KeroseneAnimationAsset.networkReview,
        title: 'Aparência',
        subtitle: 'Tema e escala local',
      ),
      _PaneSpec(
        pane: _SettingsPane.wallets,
        icon: KeroseneIcons.wallet,
        animation: KeroseneAnimationAsset.emptyWallet,
        title: 'Carteiras',
        subtitle: 'Custódia e ciclo KFE',
      ),
    ];

    return SettingsGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          for (final item in items)
            _NavigationTile(
              spec: item,
              selected: item.pane == selected,
              onTap: () => onSelected(item.pane),
            ),
        ],
      ),
    );
  }
}

class _PaneSpec {
  final _SettingsPane pane;
  final IconData icon;
  final KeroseneAnimationAsset animation;
  final String title;
  final String subtitle;

  const _PaneSpec({
    required this.pane,
    required this.icon,
    required this.animation,
    required this.title,
    required this.subtitle,
  });
}

class _NavigationTile extends StatelessWidget {
  final _PaneSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: AnimatedContainer(
            duration: KeroseneMotion.short,
            curve: KeroseneMotion.standard,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? KeroseneBrandTokens.brand.withValues(alpha: 0.13)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? KeroseneBrandTokens.brand.withValues(alpha: 0.42)
                    : KeroseneBrandTokens.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                SettingsAnimatedIcon(
                  asset: spec.animation,
                  fallbackIcon: spec.icon,
                  selected: selected,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: KeroseneBrandTokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spec.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: KeroseneBrandTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0.45,
                  duration: KeroseneMotion.short,
                  child: const Icon(
                    KeroseneIcons.chevronRight,
                    color: KeroseneBrandTokens.textSecondary,
                    size: 20,
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

class _AnimatedPaneSwitcher extends StatelessWidget {
  final _SettingsPane pane;

  const _AnimatedPaneSwitcher(this.pane);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: KeroseneMotion.duration(context, KeroseneMotion.medium),
      switchInCurve: KeroseneMotion.emphasized,
      switchOutCurve: KeroseneMotion.standard,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(pane),
        child: switch (pane) {
          _SettingsPane.account => const _AccountPane(),
          _SettingsPane.security => const _SecurityPane(),
          _SettingsPane.notifications => const _NotificationsPane(),
          _SettingsPane.appearance => const _AppearancePane(),
          _SettingsPane.wallets => const _WalletsPane(),
        },
      ),
    );
  }
}

class _AccountPane extends ConsumerWidget {
  const _AccountPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SettingsPaneScaffold(
      eyebrow: 'Conta',
      title: 'Acesso e sessão',
      subtitle:
          'Exibe apenas dados disponíveis na sessão autenticada. Não há edição de perfil exposta pelo backend neste momento.',
      animation: KeroseneAnimationAsset.secureConnection,
      children: [
        SettingsInfoGrid(
          items: [
            SettingsInfoItem(
                'Identificador', _formatHandle(user?.username ?? '')),
            SettingsInfoItem('Função', user?.role ?? 'USER'),
            SettingsInfoItem(
                'Perfil', user?.isAdmin == true ? 'Administrador' : 'Usuário'),
            SettingsInfoItem('Criada em', _dateLabel(user?.createdAt)),
            SettingsInfoItem('Último acesso', _dateLabel(user?.lastLogin)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsActionTile(
          icon: KeroseneIcons.logout,
          title: 'Sair desta conta',
          subtitle: 'Encerra a sessão atual e retorna para a entrada do app.',
          destructive: true,
          onTap: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/welcome', (_) => false);
            }
          },
        ),
      ],
    );
  }
}

class _SecurityPane extends ConsumerWidget {
  const _SecurityPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(accountSecurityProfileProvider);

    return SettingsPaneScaffold(
      eyebrow: 'Segurança',
      title: 'Proteção permitida pelo backend',
      subtitle:
          'As opções refletem endpoints ativos: perfil de segurança, PIN do app, TOTP, passkeys e recuperação.',
      animation: KeroseneAnimationAsset.securityShield,
      children: [
        profileAsync.when(
          data: (profile) => _SecuritySummary(profile: profile),
          loading: () => const SettingsLoadingPanel(
              label: 'Carregando perfil de segurança'),
          error: (_, __) => const SettingsEmptyPanel(
            icon: KeroseneIcons.warning,
            title: 'Não conseguimos carregar a segurança',
            body: 'Revise sua conexão e tente novamente.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsActionTile(
          icon: KeroseneIcons.plus,
          title: 'Registrar passkey neste dispositivo',
          subtitle:
              'Chama o fluxo real de criação de passkey vinculado à conta.',
          onTap: () async {
            await ref.read(authControllerProvider.notifier).registerPasskey();
            ref.invalidate(accountSecurityProfileProvider);
            if (context.mounted) {
              AppNotice.showInfo(
                context,
                title: 'Passkey solicitada',
                message:
                    'A lista de dispositivos será atualizada após a conclusão.',
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsActionTile(
          icon: KeroseneIcons.shield,
          title: 'Abrir segurança avançada',
          subtitle:
              'Gerencia TOTP, PIN, códigos de recuperação e dispositivos passkey com chamadas reais ao backend.',
          onTap: () => _pushDeferred(
            context,
            security_settings.loadLibrary,
            (_) => security_settings.SecuritySettingsScreen(),
          ),
        ),
      ],
    );
  }
}

class _SecuritySummary extends StatelessWidget {
  final AccountSecurityProfile profile;

  const _SecuritySummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final appPin = profile.appPin;
    return Column(
      children: [
        SettingsInfoGrid(
          items: [
            SettingsInfoItem('Modo da conta', _securityModeLabel(profile.mode)),
            SettingsInfoItem(
                'Passkey disponível', profile.passkeyAvailable ? 'Sim' : 'Não'),
            SettingsInfoItem('Passkeys conhecidas',
                '${profile.passkeys?.devices.length ?? 0}'),
            SettingsInfoItem(
                'PIN do app', appPin.enabled ? 'Ativo' : 'Inativo'),
            SettingsInfoItem('Tentativas PIN', _pinAttemptsLabel(appPin)),
            SettingsInfoItem(
              'Fatores exigidos',
              profile.requiredFactors.isEmpty
                  ? 'Padrão'
                  : profile.requiredFactors.join(', '),
            ),
          ],
        ),
        if (profile.passkeys?.devices.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.lg),
          for (final device in profile.passkeys!.devices)
            SettingsStatusRow(
              icon: KeroseneIcons.devices,
              title: device.deviceName,
              subtitle: device.compatibleWithCurrentLogin
                  ? 'Compatível com este acesso'
                  : 'Registrado, mas não confirmado para este acesso',
              trailing: device.status,
            ),
        ],
      ],
    );
  }

  static String _pinAttemptsLabel(AppPinStatus status) {
    if (!status.configured) return 'Não configurado';
    if (status.locked) return 'Bloqueado';
    return '${status.remainingAttempts}/${status.maxAttempts} restantes';
  }
}

class _NotificationsPane extends ConsumerStatefulWidget {
  const _NotificationsPane();

  @override
  ConsumerState<_NotificationsPane> createState() => _NotificationsPaneState();
}

class _NotificationsPaneState extends ConsumerState<_NotificationsPane> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(alertPreferencesProvider);
    final devicesAsync = ref.watch(activeDeviceTokensProvider);

    return SettingsPaneScaffold(
      eyebrow: 'Notificações',
      title: 'Alertas e dispositivos autorizados',
      subtitle:
          'Preferências locais controlam como o app avisa. Dispositivos registrados vêm de /notifications/device-tokens.',
      animation: KeroseneAnimationAsset.transactionStatus,
      children: [
        SettingsPreferenceSwitch(
          icon: KeroseneIcons.notifications,
          title: 'Notificações Android',
          subtitle: preferences.backgroundAlertsEnabled
              ? 'Ativas para eventos financeiros e segurança.'
              : 'Desativadas neste dispositivo.',
          value: preferences.backgroundAlertsEnabled,
          onChanged: _saving ? null : _toggleBackgroundAlerts,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsPreferenceSwitch(
          icon: KeroseneIcons.moveHorizontal,
          title: 'Eventos financeiros',
          subtitle: 'Transações, recebimentos e payment requests.',
          value: preferences.transactionAlertsEnabled,
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setTransactionAlertsEnabled(value),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsPreferenceSwitch(
          icon: KeroseneIcons.security,
          title: 'Eventos de segurança',
          subtitle: 'Login, recovery e tentativas de acesso sensíveis.',
          value: preferences.securityAlertsEnabled,
          onChanged: (value) => ref
              .read(alertPreferencesProvider.notifier)
              .setSecurityAlertsEnabled(value),
        ),
        const SizedBox(height: AppSpacing.lg),
        devicesAsync.when(
          data: (devices) => _NotificationDevices(devices: devices),
          loading: () =>
              const SettingsLoadingPanel(label: 'Carregando dispositivos'),
          error: (_, __) => const SettingsEmptyPanel(
            icon: KeroseneIcons.warning,
            title: 'Dispositivos indisponíveis',
            body: 'Não conseguimos consultar os tokens registrados agora.',
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBackgroundAlerts(bool enabled) async {
    setState(() => _saving = true);
    try {
      if (enabled) {
        final granted = await NotificationService().requestPermissions();
        if (!granted) {
          if (mounted) {
            AppNotice.showWarning(
              context,
              title: 'Permissão necessária',
              message: 'Autorize notificações no Android para receber alertas.',
            );
          }
          return;
        }
        await startBackgroundService();
      } else {
        await stopBackgroundService();
      }
      await ref
          .read(alertPreferencesProvider.notifier)
          .setBackgroundAlertsEnabled(enabled);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NotificationDevices extends ConsumerWidget {
  final List<DeviceToken> devices;

  const _NotificationDevices({required this.devices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = devices.where((device) => device.active).toList();
    if (active.isEmpty) {
      return const SettingsEmptyPanel(
        icon: KeroseneIcons.notificationsOff,
        title: 'Nenhum dispositivo registrado',
        body:
            'Ao permitir push notifications, o backend exibirá o dispositivo aqui.',
      );
    }

    return Column(
      children: [
        for (final token in active)
          SettingsStatusRow(
            icon: KeroseneIcons.device,
            title: token.platform.isEmpty ? 'Dispositivo' : token.platform,
            subtitle: _deviceTokenSubtitle(token),
            trailing: 'Ativo',
            actionLabel: 'Revogar',
            onAction: () async {
              final result = await ref
                  .read(notificationRepositoryProvider)
                  .revokeDeviceToken(token.id);
              result.fold(
                (failure) => AppNotice.showError(
                  context,
                  title: 'Não conseguimos revogar',
                  message: failure.message,
                ),
                (_) {
                  ref.invalidate(activeDeviceTokensProvider);
                  AppNotice.showInfo(
                    context,
                    title: 'Dispositivo revogado',
                    message: 'Este token não receberá novas notificações.',
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _AppearancePane extends ConsumerWidget {
  const _AppearancePane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return SettingsPaneScaffold(
      eyebrow: 'Aparência',
      title: 'Tema local do aplicativo',
      subtitle:
          'Preferência local permitida pelo app. Não depende do backend e não altera dados financeiros.',
      animation: KeroseneAnimationAsset.networkReview,
      children: [
        SettingsChoiceGroup<AppThemeVariant>(
          title: 'Tema',
          value: appearance.themeVariant,
          values: AppThemeVariant.values,
          label: (value) => value.label,
          description: (value) => value.description,
          onSelected: notifier.setThemeVariant,
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsChoiceGroup<AppFontScale>(
          title: 'Escala de fonte',
          value: appearance.fontScale,
          values: AppFontScale.values,
          label: (value) => value.label,
          description: (value) =>
              '${(value.scaleFactor * 100).round()}% da escala base',
          onSelected: notifier.setFontScale,
        ),
      ],
    );
  }
}

class _WalletsPane extends StatelessWidget {
  const _WalletsPane();

  @override
  Widget build(BuildContext context) {
    return SettingsPaneScaffold(
      eyebrow: 'Carteiras',
      title: 'Custódia e carteiras KFE',
      subtitle:
          'A gestão de carteiras usa endpoints KFE reais: criar, listar, editar rótulo, arquivar, UTXOs e PSBT de cold wallet.',
      animation: KeroseneAnimationAsset.emptyWallet,
      children: [
        const SettingsInfoGrid(
          items: [
            SettingsInfoItem(
                'Regra de criação', 'Uma carteira por método de custódia'),
            SettingsInfoItem('Endpoint principal', '/kfe/wallets'),
            SettingsInfoItem('Lifecycle', 'PATCH label e POST archive'),
            SettingsInfoItem('Cold wallet', 'UTXOs e PSBT persistido'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsActionTile(
          icon: KeroseneIcons.wallet,
          title: 'Abrir carteiras',
          subtitle: 'Navega para a tela ativa de contas Bitcoin/KFE.',
          onTap: () => _pushDeferred(
            context,
            bitcoin_accounts.loadLibrary,
            (_) => bitcoin_accounts.BitcoinAccountsScreen(),
          ),
        ),
      ],
    );
  }
}

String _formatHandle(String username) {
  final normalized =
      username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  if (normalized.isEmpty) return 'Sessão ativa';
  return normalized.startsWith('@') ? normalized : '@$normalized';
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'Não informado';
  final local = value.toLocal();
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String _securityModeLabel(AccountSecurityMode mode) {
  return switch (mode) {
    AccountSecurityMode.standard => 'Padrão',
    AccountSecurityMode.shamir => 'Shamir',
    AccountSecurityMode.multisig2fa => 'Multisig 2FA',
    AccountSecurityMode.passkey => 'Passkey',
  };
}

String _deviceTokenSubtitle(DeviceToken token) {
  final parts = <String>[
    if (token.deviceRef.isNotEmpty) token.deviceRef,
    if (token.appVersion.isNotEmpty) 'versão ${token.appVersion}',
    if (token.lastSeenAt != null) 'visto em ${_dateLabel(token.lastSeenAt)}',
  ];
  return parts.isEmpty ? 'Token registrado no backend' : parts.join(' · ');
}

void _pushDeferred(
  BuildContext context,
  Future<void> Function() loadLibrary,
  WidgetBuilder builder,
) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: KeroseneMotion.medium,
      reverseTransitionDuration: KeroseneMotion.short,
      pageBuilder: (_, __, ___) => DeferredPage(
        loadLibrary: loadLibrary,
        builder: builder,
      ),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: KeroseneMotion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
