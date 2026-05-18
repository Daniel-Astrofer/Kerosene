import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

class SignupSeedMaterial {
  final String primaryMnemonic;
  final String recoveryMnemonic;
  final SeedSecurityOption securityOption;
  final int wordCount;
  final int recoveryWordCount;
  final List<String> slip39Shares;
  final int slip39TotalShares;
  final int slip39Threshold;

  const SignupSeedMaterial({
    required this.primaryMnemonic,
    this.recoveryMnemonic = '',
    required this.securityOption,
    required this.wordCount,
    this.recoveryWordCount = 0,
    this.slip39Shares = const [],
    this.slip39TotalShares = 0,
    this.slip39Threshold = 0,
  });

  bool get usesSlip39 => securityOption == SeedSecurityOption.slip39;
  bool get usesMultisig => securityOption == SeedSecurityOption.multisig2fa;

  List<String> get words => primaryMnemonic.trim().split(RegExp(r'\s+'));
  List<String> get primaryWords => words;
  List<String> get recoveryWords => recoveryMnemonic
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
}
