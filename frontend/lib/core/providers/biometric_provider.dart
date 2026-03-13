import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../security/biometric_service.dart';

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

class BiometricNotifier extends StateNotifier<BiometricState> {
  final Ref ref;
  final BiometricService _biometricService;

  BiometricNotifier(this.ref)
    : _biometricService = BiometricService(),
      super(const BiometricState()) {
    _init();
  }

  Future<void> _init() async {
    final localDataSource = ref.read(authLocalDataSourceProvider);

    // Check support
    final isSupported = await _biometricService.canAuthenticate();

    // Check preference
    final isEnabled = await localDataSource.getBiometricEnabled();

    state = state.copyWith(
      isSupported: isSupported,
      isEnabled: isEnabled,
      isLoading: false,
    );
  }

  Future<void> toggleBiometric(bool value) async {
    final localDataSource = ref.read(authLocalDataSourceProvider);

    // If enabling, we might want to verify biometrics first?
    // For now just toggle preference.
    await localDataSource.setBiometricEnabled(value);

    state = state.copyWith(isEnabled: value);
  }
}

final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
      return BiometricNotifier(ref);
    });
