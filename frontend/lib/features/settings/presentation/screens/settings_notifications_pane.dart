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
import 'settings_modern_components.dart';

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
            subtitle: settingsDeviceTokenSubtitle(token),
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
