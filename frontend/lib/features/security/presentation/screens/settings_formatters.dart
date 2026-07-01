import 'package:kerosene/features/notifications/domain/entities/device_token.dart';
import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';

String settingsFormatHandle(String username) {
  final normalized = username
      .trim()
      .replaceFirst(RegExp(r'^@+'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
  if (normalized.isEmpty) return 'Sessão ativa';
  return normalized[0].toUpperCase() + normalized.substring(1);
}

String settingsDateLabel(DateTime? value) {
  if (value == null) return 'Não informado';
  final local = value.toLocal();
  String two(int input) => input.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String settingsSecurityModeLabel(AccountSecurityMode mode) {
  return switch (mode) {
    AccountSecurityMode.standard => 'Padrão',
    AccountSecurityMode.shamir => 'Shamir',
    AccountSecurityMode.multisig2fa => 'Multisig 2FA',
    AccountSecurityMode.passkey => 'Passkey',
  };
}

String settingsDeviceTokenSubtitle(DeviceToken token) {
  final parts = <String>[
    if (token.deviceRef.isNotEmpty) token.deviceRef,
    if (token.appVersion.isNotEmpty) 'versão ${token.appVersion}',
    if (token.lastSeenAt != null)
      'visto em ${settingsDateLabel(token.lastSeenAt)}',
  ];
  return parts.isEmpty ? 'Token registrado no backend' : parts.join(' · ');
}

String settingsPinAttemptsLabel(AppPinStatus status) {
  if (!status.configured) return 'Não configurado';
  if (status.locked) return 'Bloqueado';
  return '${status.remainingAttempts}/${status.maxAttempts} restantes';
}
