import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/biometric_service.dart';
import 'shared_preferences_provider.dart';

class BiometricState {
  final bool isEnabled;
  final bool isSupported;
  final bool isLoading;

  const BiometricState({
    this.isEnabled = false,
    this.isSupported = false,
    this.isLoading = true,
  });

  BiometricState copyWith({
    bool? isEnabled,
    bool? isSupported,
    bool? isLoading,
  }) {
    return BiometricState(
      isEnabled: isEnabled ?? this.isEnabled,
      isSupported: isSupported ?? this.isSupported,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BiometricNotifier extends Notifier<BiometricState> {
  late BiometricService _biometricService;

  @override
  BiometricState build() {
    _biometricService = BiometricService();
    _init();
    return const BiometricState();
  }

  Future<void> _init() async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);

    // Check support
    final isSupported = await _biometricService.canAuthenticate();

    // Check preference
    final isEnabled =
        sharedPreferences.getBool('auth_biometric_enabled') ?? false;

    state = state.copyWith(
      isSupported: isSupported,
      isEnabled: isEnabled,
      isLoading: false,
    );
  }

  Future<void> toggleBiometric(bool value) async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);

    await sharedPreferences.setBool('auth_biometric_enabled', value);

    state = state.copyWith(isEnabled: value);
  }
}

final biometricProvider =
    NotifierProvider<BiometricNotifier, BiometricState>(BiometricNotifier.new);
