import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/features/auth/controller/auth_controller.dart';

class ServerAvailabilityGate extends ConsumerStatefulWidget {
  final Widget child;

  const ServerAvailabilityGate({super.key, required this.child});

  @override
  ConsumerState<ServerAvailabilityGate> createState() =>
      _ServerAvailabilityGateState();
}

class _ServerAvailabilityGateState
    extends ConsumerState<ServerAvailabilityGate> {
  bool _showingUnavailableScreen = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider);
    final authState = ref.watch(authControllerProvider);
    final isUnavailable = !isOnline || authState is AuthServerUnavailable;
    final isRetryingUnavailable =
        _showingUnavailableScreen && authState is AuthLoading;

    if (isUnavailable || isRetryingUnavailable) {
      _showingUnavailableScreen = true;
      return const ServerUnavailableScreen();
    }

    _showingUnavailableScreen = false;
    return widget.child;
  }
}

class ServerUnavailableScreen extends ConsumerWidget {
  final String message;
  final String? retryRouteName;

  const ServerUnavailableScreen({
    super.key,
    this.message = 'Servidor em manutenção',
    this.retryRouteName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.serverOff,
                    size: 76,
                    color: Color(0xFFFFFFFF),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Conexão indisponível',
                    style: GoogleFonts.ibmPlexSerif(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Color(0xFFA1A1AA),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: const Color(0xFF000000),
                        disabledBackgroundColor: const Color(0xFFE4E4E7),
                        disabledForegroundColor: const Color(0xFF52525B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                      onPressed: isLoading ? null : () => _retry(context, ref),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF000000),
                              ),
                            )
                          : const Text('Tentar novamente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    if (retryRouteName != null) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(retryRouteName!, (_) => false);
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState is AuthServerUnavailable ||
        authState is AuthAuthenticated ||
        authState is AuthLoading) {
      await ref.read(authControllerProvider.notifier).retrySessionCheck();
      return;
    }

    await ref.read(networkStatusProvider.notifier).checkConnection();
  }
}
