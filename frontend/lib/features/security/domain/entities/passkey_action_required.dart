import 'passkey_inventory.dart';

class PasskeyActionRequired {
  final String action;
  final String reason;
  final String? challenge;
  final bool totpFallbackAvailable;
  final bool linkNewPasskeyAllowed;
  final String linkPasskeyPath;
  final String guidance;
  final PasskeyInventory? passkeys;

  const PasskeyActionRequired({
    required this.action,
    required this.reason,
    this.challenge,
    this.totpFallbackAvailable = false,
    this.linkNewPasskeyAllowed = false,
    this.linkPasskeyPath = '',
    this.guidance = '',
    this.passkeys,
  });

  factory PasskeyActionRequired.fromJson(Map<String, dynamic> json) {
    return PasskeyActionRequired(
      action: (json['action'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      challenge: json['challenge']?.toString(),
      totpFallbackAvailable: json['totpFallbackAvailable'] == true,
      linkNewPasskeyAllowed: json['linkNewPasskeyAllowed'] == true,
      linkPasskeyPath: (json['linkPasskeyPath'] ?? '').toString(),
      guidance: (json['guidance'] ?? '').toString(),
      passkeys: json['passkeys'] is Map
          ? PasskeyInventory.fromJson(
              Map<String, dynamic>.from(json['passkeys'] as Map),
            )
          : null,
    );
  }

  static PasskeyActionRequired? fromDynamic(Object? data) {
    if (data is Map<String, dynamic>) {
      return PasskeyActionRequired.fromJson(data);
    }
    if (data is Map) {
      return PasskeyActionRequired.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  bool get requiresLinking => action == 'LINK_NEW_PASSKEY';
  bool get canRetryAssertion => action == 'ASSERT_PASSKEY' && challenge != null;
}
