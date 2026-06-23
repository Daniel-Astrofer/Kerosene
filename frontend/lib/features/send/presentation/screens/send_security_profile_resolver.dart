import 'package:kerosene/features/security/domain/entities/account_security_profile.dart';

AccountSecurityProfile fallbackSendSecurityProfile(String rawSecurity) {
  final mode = accountSecurityModeFromApi(rawSecurity);
  final requiredFactors = switch (mode) {
    AccountSecurityMode.shamir => const ['SLIP39_SHARES', 'TOTP'],
    AccountSecurityMode.multisig2fa => const ['PASSPHRASE', 'TOTP'],
    AccountSecurityMode.passkey => const ['PASSKEY'],
    AccountSecurityMode.standard => const ['PASSKEY'],
  };

  return AccountSecurityProfile(
    mode: mode,
    passkeyAvailable: mode == AccountSecurityMode.standard,
    passkeyEnabledForTransactions: mode == AccountSecurityMode.standard,
    requiredFactors: requiredFactors,
  );
}
