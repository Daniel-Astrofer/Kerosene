import 'package:equatable/equatable.dart';

import 'app_pin_status.dart';
import 'passkey_inventory.dart';

enum AccountSecurityMode { standard, shamir, multisig2fa, passkey }

AccountSecurityMode accountSecurityModeFromApi(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'SHAMIR':
      return AccountSecurityMode.shamir;
    case 'MULTISIG_2FA':
      return AccountSecurityMode.multisig2fa;
    case 'PASSKEY':
      return AccountSecurityMode.passkey;
    default:
      return AccountSecurityMode.standard;
  }
}

String accountSecurityModeToApi(AccountSecurityMode mode) {
  switch (mode) {
    case AccountSecurityMode.shamir:
      return 'SHAMIR';
    case AccountSecurityMode.multisig2fa:
      return 'MULTISIG_2FA';
    case AccountSecurityMode.passkey:
      return 'PASSKEY';
    case AccountSecurityMode.standard:
      return 'STANDARD';
  }
}

class AccountSecurityProfile extends Equatable {
  final AccountSecurityMode mode;
  final int? shamirTotalShares;
  final int? shamirThreshold;
  final int multisigThreshold;
  final bool passkeyAvailable;
  final bool passkeyEnabledForTransactions;
  final AppPinStatus appPin;
  final List<String> requiredFactors;
  final PasskeyInventory? passkeys;

  const AccountSecurityProfile({
    required this.mode,
    this.shamirTotalShares,
    this.shamirThreshold,
    this.multisigThreshold = 2,
    this.passkeyAvailable = false,
    this.passkeyEnabledForTransactions = false,
    this.appPin = const AppPinStatus(),
    this.requiredFactors = const [],
    this.passkeys,
  });

  factory AccountSecurityProfile.fromJson(Map<String, dynamic> json) {
    final requiredFactorsRaw = json['requiredFactors'];
    return AccountSecurityProfile(
      mode: accountSecurityModeFromApi(json['accountSecurity']?.toString()),
      shamirTotalShares: (json['shamirTotalShares'] as num?)?.toInt(),
      shamirThreshold: (json['shamirThreshold'] as num?)?.toInt(),
      multisigThreshold: (json['multisigThreshold'] as num?)?.toInt() ?? 2,
      passkeyAvailable: json['passkeyAvailable'] == true,
      passkeyEnabledForTransactions:
          json['passkeyEnabledForTransactions'] == true,
      appPin: json['appPin'] is Map
          ? AppPinStatus.fromJson(
              Map<String, dynamic>.from(json['appPin'] as Map),
            )
          : const AppPinStatus(),
      requiredFactors: requiredFactorsRaw is List
          ? requiredFactorsRaw.map((item) => item.toString()).toList()
          : const [],
      passkeys: json['passkeys'] is Map
          ? PasskeyInventory.fromJson(
              Map<String, dynamic>.from(json['passkeys'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'accountSecurity': accountSecurityModeToApi(mode),
      if (shamirTotalShares != null) 'shamirTotalShares': shamirTotalShares,
      if (shamirThreshold != null) 'shamirThreshold': shamirThreshold,
      'multisigThreshold': multisigThreshold,
    };
  }

  bool get requiresShamirShares =>
      requiredFactors.contains('SLIP39_SHARES') ||
      mode == AccountSecurityMode.shamir;

  bool get requiresTotp => requiredFactors.contains('TOTP');

  bool get requiresPassphrase =>
      requiredFactors.contains('PASSPHRASE') || requiresShamirShares;

  bool get requiresPasskey =>
      requiredFactors.contains('PASSKEY') ||
      mode == AccountSecurityMode.passkey ||
      passkeyEnabledForTransactions;

  AccountSecurityProfile copyWith({
    AccountSecurityMode? mode,
    int? shamirTotalShares,
    int? shamirThreshold,
    int? multisigThreshold,
    bool? passkeyAvailable,
    bool? passkeyEnabledForTransactions,
    AppPinStatus? appPin,
    List<String>? requiredFactors,
    PasskeyInventory? passkeys,
  }) {
    return AccountSecurityProfile(
      mode: mode ?? this.mode,
      shamirTotalShares: shamirTotalShares ?? this.shamirTotalShares,
      shamirThreshold: shamirThreshold ?? this.shamirThreshold,
      multisigThreshold: multisigThreshold ?? this.multisigThreshold,
      passkeyAvailable: passkeyAvailable ?? this.passkeyAvailable,
      passkeyEnabledForTransactions:
          passkeyEnabledForTransactions ?? this.passkeyEnabledForTransactions,
      appPin: appPin ?? this.appPin,
      requiredFactors: requiredFactors ?? this.requiredFactors,
      passkeys: passkeys ?? this.passkeys,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        shamirTotalShares,
        shamirThreshold,
        multisigThreshold,
        passkeyAvailable,
        passkeyEnabledForTransactions,
        appPin,
        requiredFactors,
        passkeys,
      ];
}
