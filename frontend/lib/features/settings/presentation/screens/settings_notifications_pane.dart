import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/providers/alert_preferences_provider.dart';
import 'package:kerosene/core/services/background_service.dart';
import 'package:kerosene/core/services/notification_service.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';
import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/notifications/presentation/providers/session_notification_provider.dart';

import 'settings_formatters.dart';
import 'settings_section_components.dart';

class SettingsNotificationsPane extends ConsumerStatefulWidget {
  const SettingsNotificationsPane({super.key});

  @override
  ConsumerState<SettingsNotificationsPane> createState() =>
      _SettingsNotificationsPaneState();
}

class _SettingsNotificationsPaneState
    extends ConsumerState<SettingsNotificationsPane> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(alertPreferencesProvider);
    final devicesAsync = ref.watch(activeDeviceTokensProvider);
    final deviceRows = devicesAsync.when<List<Widget>>(
      data: (devices) => _deviceRows(context, devices),
      loading: () => const [
        SettingsSectionRow(
          icon: KeroseneIcons.device,
          title: 'Dispositivos',
          subtitle: 'Carregando dispositivos autorizados.',
          onTap: null,
        ),
      ],
      error: (_, __) => const [
        SettingsSectionRow(
          icon: KeroseneIcons.warning,
          title: 'Dispositivos indisponíveis',
          subtitle: 'Não conseguimos consultar os tokens registrados agora.',
          onTap: null,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Notificações',
          style: AppTypography.newsreader(
            color: KeroseneBrandTokens.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Controle local de alertas financeiros, segurança e dispositivos autorizados para push notifications.',
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Alertas',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.notifications,
              title: 'Notificações Android',
              subtitle: preferences.backgroundAlertsEnabled
                  ? 'Ativas neste dispositivo.'
                  : 'Desativadas neste dispositivo.',
              trailing: SettingsReadonlySwitch(
                value: preferences.backgroundAlertsEnabled,
              ),
              onTap: _saving
                  ? null
                  : () => _toggleBackgroundAlerts(
                        !preferences.backgroundAlertsEnabled,
                      ),
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.moveHorizontal,
              title: 'Eventos financeiros',
              subtitle: 'Transações, recebimentos e payment requests.',
              trailing: SettingsReadonlySwitch(
                value: preferences.transactionAlertsEnabled,
              ),
              onTap: () => ref
                  .read(alertPreferencesProvider.notifier)
                  .setTransactionAlertsEnabled(
                    !preferences.transactionAlertsEnabled,
                  ),
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.security,
              title: 'Eventos de segurança',
              subtitle: 'Login, recovery e tentativas de acesso sensíveis.',
              trailing: SettingsReadonlySwitch(
                value: preferences.securityAlertsEnabled,
              ),
              onTap: () => ref
                  .read(alertPreferencesProvider.notifier)
                  .setSecurityAlertsEnabled(
                    !preferences.securityAlertsEnabled,
                  ),
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.bitcoin,
              title: 'Mercado Bitcoin',
              subtitle: preferences.marketAlertsEnabled
                  ? 'Alertas reais de variação 24h ativados.'
                  : 'Desativado por padrão. Sem mock e sem fallback.',
              trailing: SettingsReadonlySwitch(
                value: preferences.marketAlertsEnabled,
              ),
              onTap: () => ref
                  .read(alertPreferencesProvider.notifier)
                  .setMarketAlertsEnabled(
                    !preferences.marketAlertsEnabled,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Dispositivos',
          children: deviceRows,
        ),
      ],
    );
  }

  List<Widget> _deviceRows(BuildContext context, List<DeviceToken> devices) {
    final active = devices.where((device) => device.active).toList();
    if (active.isEmpty) {
      return const [
        SettingsSectionRow(
          icon: KeroseneIcons.notificationsOff,
          title: 'Nenhum dispositivo registrado',
          subtitle:
              'Ao permitir push notifications, o backend exibirá o dispositivo aqui.',
          onTap: null,
        ),
      ];
    }

    return [
      for (final token in active)
        SettingsSectionRow(
          icon: KeroseneIcons.device,
          title: token.platform.isEmpty ? 'Dispositivo' : token.platform,
          subtitle: settingsDeviceTokenSubtitle(token),
          trailing: TextButton(
            onPressed: () => _revokeDevice(context, token),
            style: TextButton.styleFrom(
              foregroundColor: KeroseneBrandTokens.textSecondary,
              textStyle: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            child: const Text('Revogar'),
          ),
          onTap: null,
        ),
    ];
  }

  Future<bool> _confirmBackgroundAlerts() async {
    if (!mounted) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => const _BackgroundAlertsConsentDialog(),
    );
    return result ?? false;
  }

  Future<void> _toggleBackgroundAlerts(bool enabled) async {
    setState(() => _saving = true);
    try {
      if (enabled) {
        final confirmed = await _confirmBackgroundAlerts();
        if (!confirmed) {
          return;
        }

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

  Future<void> _revokeDevice(BuildContext context, DeviceToken token) async {
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
  }
}

class _BackgroundAlertsConsentDialog extends StatelessWidget {
  const _BackgroundAlertsConsentDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: KeroseneBrandTokens.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 40,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Icon(
                      KeroseneIcons.notifications,
                      color: KeroseneBrandTokens.textPrimary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Ativar alertas em segundo plano?',
                      style: AppTypography.newsreader(
                        color: KeroseneBrandTokens.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        height: 1.05,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'O Kerosene pode manter um serviço discreto no Android para avisar sobre transações, depósitos e eventos críticos assim que chegarem.',
                style: AppTypography.bodyMedium.copyWith(
                  color: KeroseneBrandTokens.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  child: const Text('Ativar agora'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: KeroseneBrandTokens.textSecondary,
                  textStyle: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Agora não'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
