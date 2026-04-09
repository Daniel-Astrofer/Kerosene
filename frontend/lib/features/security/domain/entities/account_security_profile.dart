import 'package:equatable/equatable.dart';

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
  final List<String> requiredFactors;

  const AccountSecurityProfile({
    required this.mode,
    this.shamirTotalShares,
    this.shamirThreshold,
    this.multisigThreshold = 2,
    this.passkeyAvailable = false,
    this.passkeyEnabledForTransactions = false,
    this.requiredFactors = const [],
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
      requiredFactors: requiredFactorsRaw is List
          ? requiredFactorsRaw.map((item) => item.toString()).toList()
          : const [],
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
    List<String>? requiredFactors,
  }) {
    return AccountSecurityProfile(
      mode: mode ?? this.mode,
      shamirTotalShares: shamirTotalShares ?? this.shamirTotalShares,
      shamirThreshold: shamirThreshold ?? this.shamirThreshold,
      multisigThreshold: multisigThreshold ?? this.multisigThreshold,
      passkeyAvailable: passkeyAvailable ?? this.passkeyAvailable,
      passkeyEnabledForTransactions:
          passkeyEnabledForTransactions ?? this.passkeyEnabledForTransactions,
      requiredFactors: requiredFactors ?? this.requiredFactors,
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
        requiredFactors,
      ];
}
