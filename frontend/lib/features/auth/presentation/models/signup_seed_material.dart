import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

class SignupSeedMaterial {
  final String primaryMnemonic;
  final SeedSecurityOption securityOption;
  final int wordCount;
  final List<String> slip39Shares;
  final int slip39TotalShares;
  final int slip39Threshold;

  const SignupSeedMaterial({
    required this.primaryMnemonic,
    required this.securityOption,
    required this.wordCount,
    this.slip39Shares = const [],
    this.slip39TotalShares = 0,
    this.slip39Threshold = 0,
  });

  bool get usesSlip39 => securityOption == SeedSecurityOption.slip39;

  List<String> get words => primaryMnemonic.trim().split(RegExp(r'\s+'));
}
