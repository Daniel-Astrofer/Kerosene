import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/features/auth/domain/repositories/auth_repository.dart';
import 'package:teste/main.dart' show sharedPreferencesProvider;

enum SeedSecurityOption { standard, slip39, multisig2fa }

enum SignupStep {
  feeExplanation,
  seedSecuritySelection,
  passphrase,
  username, // Moved up
  totp,
  passkey,
  payment,
  confirmations,
}

class SignupFlowState extends Equatable {
  final SignupStep currentStep;
  final SeedSecurityOption seedSecurityOption;
  final int slip39TotalShares;
  final int slip39Threshold;
  final String? passphrase;
  final String? totpSecret;
  final String? qrCodeUri; // ← new: full otpauth:// URI for QR display
  final String? sessionId; // ← new: Redis session from TOTP verify
  final String? username;

  // Payment / onboarding
  final String? paymentAddress; // ← new: BTC deposit address
  final double? paymentAmountBtc; // ← new: amount in BTC
  final String? paymentLinkId; // ← new: for WebSocket polling
  final String? paymentUri; // kept for backwards compat

  final int confirmations;
  final bool isLoading;
  final String? error;

  const SignupFlowState({
    this.currentStep = SignupStep.feeExplanation,
    this.seedSecurityOption = SeedSecurityOption.standard,
    this.slip39TotalShares = 5,
    this.slip39Threshold = 3,
    this.passphrase,
    this.totpSecret,
    this.qrCodeUri,
    this.sessionId,
    this.username,
    this.paymentAddress,
    this.paymentAmountBtc,
    this.paymentLinkId,
    this.paymentUri,
    this.confirmations = 0,
    this.isLoading = false,
    this.error,
  });

  SignupFlowState copyWith({
    SignupStep? currentStep,
    SeedSecurityOption? seedSecurityOption,
    int? slip39TotalShares,
    int? slip39Threshold,
    String? passphrase,
    String? totpSecret,
    String? qrCodeUri,
    String? sessionId,
    String? username,
    String? paymentAddress,
    double? paymentAmountBtc,
    String? paymentLinkId,
    String? paymentUri,
    int? confirmations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SignupFlowState(
      currentStep: currentStep ?? this.currentStep,
      seedSecurityOption: seedSecurityOption ?? this.seedSecurityOption,
      slip39TotalShares: slip39TotalShares ?? this.slip39TotalShares,
      slip39Threshold: slip39Threshold ?? this.slip39Threshold,
      passphrase: passphrase ?? this.passphrase,
      totpSecret: totpSecret ?? this.totpSecret,
      qrCodeUri: qrCodeUri ?? this.qrCodeUri,
      sessionId: sessionId ?? this.sessionId,
      username: username ?? this.username,
      paymentAddress: paymentAddress ?? this.paymentAddress,
      paymentAmountBtc: paymentAmountBtc ?? this.paymentAmountBtc,
      paymentLinkId: paymentLinkId ?? this.paymentLinkId,
      paymentUri: paymentUri ?? this.paymentUri,
      confirmations: confirmations ?? this.confirmations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep.name,
      'seedSecurityOption': seedSecurityOption.name,
      'slip39TotalShares': slip39TotalShares,
      'slip39Threshold': slip39Threshold,
      'passphrase': passphrase,
      'totpSecret': totpSecret,
      'qrCodeUri': qrCodeUri,
      'sessionId': sessionId,
      'username': username,
      'paymentAddress': paymentAddress,
      'paymentAmountBtc': paymentAmountBtc,
      'paymentLinkId': paymentLinkId,
      'paymentUri': paymentUri,
      'confirmations': confirmations,
    }; // Ignore isLoading, error on save
  }

  factory SignupFlowState.fromJson(Map<String, dynamic> json) {
    return SignupFlowState(
      currentStep: SignupStep.values.firstWhere(
        (e) => e.name == json['currentStep'],
        orElse: () => SignupStep.feeExplanation,
      ),
      seedSecurityOption: SeedSecurityOption.values.firstWhere(
        (e) => e.name == json['seedSecurityOption'],
        orElse: () => SeedSecurityOption.standard,
      ),
      slip39TotalShares: json['slip39TotalShares'] ?? 5,
      slip39Threshold: json['slip39Threshold'] ?? 3,
      passphrase: json['passphrase'],
      totpSecret: json['totpSecret'],
      qrCodeUri: json['qrCodeUri'],
      sessionId: json['sessionId'],
      username: json['username'],
      paymentAddress: json['paymentAddress'],
      paymentAmountBtc: (json['paymentAmountBtc'] as num?)?.toDouble(),
      paymentLinkId: json['paymentLinkId'],
      paymentUri: json['paymentUri'],
      confirmations: json['confirmations'] ?? 0,
      isLoading: false,
      error: null,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    seedSecurityOption,
    slip39TotalShares,
    slip39Threshold,
    passphrase,
    totpSecret,
    qrCodeUri,
    sessionId,
    username,
    paymentAddress,
    paymentAmountBtc,
    paymentLinkId,
    paymentUri,
    confirmations,
    isLoading,
    error,
  ];
}

class SignupFlowNotifier extends StateNotifier<SignupFlowState> {
  static const _prefsKey = 'kerasene_signup_flow_state';
  final SharedPreferences _prefs;

  SignupFlowNotifier(this._prefs) : super(const SignupFlowState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    try {
      final jsonString = _prefs.getString(_prefsKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString);
        state = SignupFlowState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading signup flow state: $e');
    }
  }

  void _saveToPrefs(SignupFlowState newState) {
    try {
      _prefs.setString(_prefsKey, jsonEncode(newState.toJson()));
    } catch (e) {
      debugPrint('Error saving signup flow state: $e');
    }
  }

  @override
  set state(SignupFlowState value) {
    super.state = value;
    _saveToPrefs(value);
  }

  void nextStep() {
    if (state.currentStep.index < SignupStep.values.length - 1) {
      state = state.copyWith(
        currentStep: SignupStep.values[state.currentStep.index + 1],
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep.index > 0) {
      state = state.copyWith(
        currentStep: SignupStep.values[state.currentStep.index - 1],
        clearError: true,
      );
    }
  }

  void goToStep(SignupStep step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void setSeedSecurityOption(SeedSecurityOption option) {
    state = state.copyWith(seedSecurityOption: option);
  }

  void setSlip39Config(int total, int threshold) {
    state = state.copyWith(
      slip39TotalShares: total,
      slip39Threshold: threshold,
    );
  }

  void setPassphrase(String passphrase) {
    state = state.copyWith(passphrase: passphrase);
  }

  void setTotpSecret(String secret) {
    state = state.copyWith(totpSecret: secret);
  }

  void setQrCodeUri(String uri) {
    state = state.copyWith(qrCodeUri: uri);
  }

  /// Called after signup TOTP verify returns the Redis sessionId.
  void setSessionId(String id) {
    state = state.copyWith(sessionId: id);
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void setPaymentUri(String uri) {
    state = state.copyWith(paymentUri: uri);
  }

  void setPaymentDetails({
    required String address,
    required double amountBtc,
    required String linkId,
  }) {
    state = state.copyWith(
      paymentAddress: address,
      paymentAmountBtc: amountBtc,
      paymentLinkId: linkId,
    );
  }

  Future<void> fetchPaymentLink(AuthRepository repo) async {
    if (state.sessionId == null) return;

    setLoading(true);
    final result = await repo.generateOnboardingLink(state.sessionId!);

    result.fold((failure) => setError(failure.message), (dto) {
      setPaymentDetails(
        address: dto.depositAddress,
        amountBtc: dto.amountBtc,
        linkId: dto.id,
      );
      state = state.copyWith(isLoading: false);
    });
  }

  Future<void> checkPaymentStatus(AuthRepository repo) async {
    if (state.sessionId == null) return;

    // IMPORTANT: generateOnboardingLink is NOT a polling endpoint — it finalizes
    // the user account on first call. Calling it again with the same sessionId
    // causes a race condition (duplicate key insert on the backend).
    //
    // The correct approach is to poll a dedicated status endpoint using paymentLinkId.
    // For now (test bypass), if we already have a paymentLinkId set, the user was
    // created successfully — just advance to the next step.
    if (state.paymentLinkId != null) {
      nextStep();
    }
  }

  void updateConfirmations(int confirmations) {
    state = state.copyWith(confirmations: confirmations);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    _prefs.remove(_prefsKey);
    state = const SignupFlowState();
  }
}

// Emits the globally persisted flow state instead of auto-disposing
final signupFlowProvider =
    StateNotifierProvider<SignupFlowNotifier, SignupFlowState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SignupFlowNotifier(prefs);
    });
