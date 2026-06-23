import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';

import '../../../profile/presentation/screens/security_app_pin_sheet.dart';
import '../../../profile/presentation/screens/security_totp_screen.dart'
    deferred as security_totp;
import 'settings_formatters.dart';
import 'settings_modern_components.dart';
import 'settings_route_helpers.dart';
import 'settings_section_components.dart';

class _SettingsSecurityPaneCopy {
  const _SettingsSecurityPaneCopy._();

  static const title = 'Seguran\u00e7a';
  static const description =
      'Proteja sua conta com autentica\u00e7\u00e3o, acesso local e controles de recupera\u00e7\u00e3o.';
}

class SettingsSecurityPane extends ConsumerWidget {
  const SettingsSecurityPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(accountSecurityProfileProvider);

    Future<void> registerPasskey() async {
      await ref.read(authControllerProvider.notifier).registerPasskey();
      ref.invalidate(accountSecurityProfileProvider);
      if (context.mounted) {
        AppNotice.showInfo(
          context,
          title: 'Passkey solicitada',
          message: 'A lista de dispositivos será atualizada após a conclusão.',
        );
      }
    }

    Future<void> openAppPinSheet(AppPinStatus status) async {
      final refreshed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AppPinManagementSheet(
          initialStatus: status,
          mode:
              status.enabled ? AppPinSheetMode.change : AppPinSheetMode.enable,
        ),
      );

      if (refreshed == true) {
        ref.invalidate(accountSecurityProfileProvider);
        ref.invalidate(appPinStatusProvider);
      }
    }

    void showSecurityNotice({
      required String title,
      required String message,
    }) {
      AppNotice.showInfo(
        context,
        title: title,
        message: message,
      );
    }

    void openTotpSecurity() {
      pushSettingsDeferred(
        context,
        security_totp.loadLibrary,
        (_) => security_totp.SecurityTotpScreen(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _SettingsSecurityPaneCopy.title,
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
          _SettingsSecurityPaneCopy.description,
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        profileAsync.when(
          data: (profile) => _SecurityAdvancedContent(
            profile: profile,
            onOpenAppPin: openAppPinSheet,
            onOpenTotpSecurity: openTotpSecurity,
            onRegisterPasskey: registerPasskey,
            onShowSecurityNotice: showSecurityNotice,
          ),
          loading: () => const SettingsLoadingPanel(
            label: 'Carregando perfil de segurança',
          ),
          error: (_, __) => const SettingsEmptyPanel(
            icon: KeroseneIcons.warning,
            title: 'Não conseguimos carregar a segurança',
            body: 'Revise sua conexão e tente novamente.',
          ),
        ),
      ],
    );
  }
}

class _SecurityAdvancedContent extends StatelessWidget {
  final AccountSecurityProfile profile;
  final Future<void> Function(AppPinStatus status) onOpenAppPin;
  final VoidCallback onOpenTotpSecurity;
  final Future<void> Function() onRegisterPasskey;
  final void Function({required String title, required String message})
      onShowSecurityNotice;

  const _SecurityAdvancedContent({
    required this.profile,
    required this.onOpenAppPin,
    required this.onOpenTotpSecurity,
    required this.onRegisterPasskey,
    required this.onShowSecurityNotice,
  });

  @override
  Widget build(BuildContext context) {
    final appPin = profile.appPin;
    final registeredPasskey = profile.passkeys?.passkeyRegistered == true;
    final knownDevices = profile.passkeys?.devices ?? const [];
    final firstDevice = knownDevices.isEmpty ? null : knownDevices.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: 'Proteção de acesso',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.lock,
              title: 'Alterar PIN',
              subtitle: appPin.enabled
                  ? 'Atualize seu código de 4 dígitos'
                  : 'Configure um código de 4 dígitos',
              onTap: () => onOpenAppPin(appPin),
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.biometric,
              title: 'Biometria',
              subtitle: registeredPasskey
                  ? 'Usar digital para entrar no app'
                  : 'Registre uma passkey neste dispositivo',
              trailing: SettingsReadonlySwitch(value: registeredPasskey),
              onTap: onRegisterPasskey,
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.verified,
              title: 'Autenticação em 2 fatores',
              subtitle: profile.requiresTotp
                  ? 'Ativa no modo ${settingsSecurityModeLabel(profile.mode)}'
                  : 'Validar TOTP e ativar proteção extra',
              onTap: onOpenTotpSecurity,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Sessões e dispositivos',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.devices,
              title: 'Dispositivos autorizados',
              subtitle: firstDevice == null
                  ? 'Nenhum dispositivo confirmado'
                  : '${firstDevice.deviceName} • Este dispositivo',
              onTap: onRegisterPasskey,
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.monitor,
              title: 'Sessões ativas',
              subtitle: knownDevices.isEmpty
                  ? 'Gerencie acessos em outros aparelhos'
                  : '${knownDevices.length} acesso(s) conhecido(s)',
              onTap: () => onShowSecurityNotice(
                title: 'Sessões ativas',
                message:
                    'O gerenciamento detalhado de sessões ficará em uma tela dedicada. A tela antiga foi removida.',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Recuperação',
          children: [
            SettingsSectionRow(
              icon: KeroseneIcons.inbox,
              title: 'Recuperação da conta',
              subtitle: profile.requiresPassphrase
                  ? 'Frase e métodos de recuperação exigidos'
                  : 'E-mail e métodos de recuperação',
              onTap: () => onShowSecurityNotice(
                title: 'Recuperação da conta',
                message:
                    'Os controles de recuperação serão exibidos em uma tela moderna dedicada. A tela antiga foi removida.',
              ),
            ),
            SettingsSectionRow(
              icon: KeroseneIcons.download,
              title: 'Backup de segurança',
              subtitle: 'Salvar códigos de recuperação',
              onTap: onOpenTotpSecurity,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'PIN do app: ${settingsPinAttemptsLabel(appPin)}',
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textMuted,
            fontSize: 12,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
