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
  final int multisigThreshold;
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
    this.multisigThreshold = 2,
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
    int? multisigThreshold,
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
      multisigThreshold: multisigThreshold ?? this.multisigThreshold,
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
      'multisigThreshold': multisigThreshold,
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
      multisigThreshold: json['multisigThreshold'] ?? 2,
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
        multisigThreshold,
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

class SignupFlowNotifier extends Notifier<SignupFlowState> {
  static const _prefsKey = 'kerasene_signup_flow_state';
  late SharedPreferences _prefs;

  @override
  SignupFlowState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs();
  }

  SignupFlowState _loadFromPrefs() {
    try {
      final jsonString = _prefs.getString(_prefsKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString);
        return SignupFlowState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading signup flow state: $e');
    }
    return const SignupFlowState();
  }

  void _saveToPrefs(SignupFlowState newState) {
    try {
      _prefs.setString(_prefsKey, jsonEncode(newState.toJson()));
    } catch (e) {
      debugPrint('Error saving signup flow state: $e');
    }
  }

  void updateState(SignupFlowState newState) {
    state = newState;
    _saveToPrefs(newState);
  }

  void nextStep() {
    if (state.currentStep.index < SignupStep.values.length - 1) {
      updateState(state.copyWith(
        currentStep: SignupStep.values[state.currentStep.index + 1],
        clearError: true,
      ));
    }
  }

  void previousStep() {
    if (state.currentStep.index > 0) {
      updateState(state.copyWith(
        currentStep: SignupStep.values[state.currentStep.index - 1],
        clearError: true,
      ));
    }
  }

  void goToStep(SignupStep step) {
    updateState(state.copyWith(currentStep: step, clearError: true));
  }

  void setSeedSecurityOption(SeedSecurityOption option) {
    updateState(state.copyWith(seedSecurityOption: option));
  }

  void setSlip39Config(int total, int threshold) {
    updateState(state.copyWith(
      slip39TotalShares: total,
      slip39Threshold: threshold,
    ));
  }

  void setMultisigThreshold(int threshold) {
    updateState(state.copyWith(multisigThreshold: threshold.clamp(2, 3)));
  }

  void setPassphrase(String passphrase) {
    updateState(state.copyWith(passphrase: passphrase));
  }

  void setTotpSecret(String secret) {
    updateState(state.copyWith(totpSecret: secret));
  }

  void setQrCodeUri(String uri) {
    updateState(state.copyWith(qrCodeUri: uri));
  }

  void setSessionId(String id) {
    updateState(state.copyWith(sessionId: id));
  }

  void setUsername(String username) {
    updateState(state.copyWith(username: username));
  }

  void setPaymentUri(String uri) {
    updateState(state.copyWith(paymentUri: uri));
  }

  void setPaymentDetails({
    required String address,
    required double amountBtc,
    required String linkId,
  }) {
    updateState(state.copyWith(
      paymentAddress: address,
      paymentAmountBtc: amountBtc,
      paymentLinkId: linkId,
    ));
  }

  Future<void> fetchPaymentLink(AuthRepository repo) async {
    if (state.sessionId == null) return;

    setLoading(true);
    final result = await repo.createActivationDepositLink();

    result.fold((failure) => setError(failure.message), (dto) {
      setPaymentDetails(
        address: dto.depositAddress,
        amountBtc: dto.amountBtc,
        linkId: dto.paymentLinkId,
      );
      updateState(state.copyWith(isLoading: false));
    });
  }

  Future<void> checkPaymentStatus(AuthRepository repo) async {
    if (state.sessionId == null) return;
    if (state.paymentLinkId != null) {
      nextStep();
    }
  }

  void updateConfirmations(int confirmations) {
    updateState(state.copyWith(confirmations: confirmations));
  }

  void setLoading(bool isLoading) {
    updateState(state.copyWith(isLoading: isLoading));
  }

  void setError(String error) {
    updateState(state.copyWith(error: error, isLoading: false));
  }

  void clearError() {
    updateState(state.copyWith(clearError: true));
  }

  void reset() {
    _prefs.remove(_prefsKey);
    state = const SignupFlowState();
  }
}

final signupFlowProvider =
    NotifierProvider<SignupFlowNotifier, SignupFlowState>(
        SignupFlowNotifier.new);
