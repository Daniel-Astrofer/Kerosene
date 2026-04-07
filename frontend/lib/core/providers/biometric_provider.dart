import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/auth/controller/auth_local_provider.dart';
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

class BiometricNotifier extends Notifier<BiometricState> {
  late BiometricService _biometricService;

  @override
  BiometricState build() {
    _biometricService = BiometricService();
    _init();
    return const BiometricState();
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
    NotifierProvider<BiometricNotifier, BiometricState>(BiometricNotifier.new);
