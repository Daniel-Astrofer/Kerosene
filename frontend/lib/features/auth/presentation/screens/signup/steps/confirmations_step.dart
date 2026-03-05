import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/cyber_theme.dart';
import '../../../../../../l10n/l10n_extension.dart';
import '../../../providers/signup_flow_provider.dart';
import '../../../providers/auth_provider.dart';

class ConfirmationsStep extends ConsumerStatefulWidget {
  const ConfirmationsStep({super.key});

  @override
  ConsumerState<ConfirmationsStep> createState() => _ConfirmationsStepState();
}

class _ConfirmationsStepState extends ConsumerState<ConfirmationsStep> {
  Timer? _confTimer;

  @override
  void initState() {
    super.initState();
    _startMockConfirmationTracker();
  }

  void _startMockConfirmationTracker() {
    // Mock blockchain block intervals (sped up for UX, usually 10 mins each)
    _confTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final currentConfs = ref.read(signupFlowProvider).confirmations;
      if (currentConfs < 3) {
        ref
            .read(signupFlowProvider.notifier)
            .updateConfirmations(currentConfs + 1);
      } else {
        timer.cancel();
        _finalizeOnboarding();
      }
    });
  }

  void _finalizeOnboarding() {
    final state = ref.read(signupFlowProvider);
    // Call the auth provider to login the user into the real system now that it's persisted
    // In complete integration, maybe the backend already logged us in, or we do a normal login call
    ref
        .read(authProvider.notifier)
        .login(
          username: state.username ?? '',
          password: state.passphrase ?? '',
        );
  }

  @override
  void dispose() {
    _confTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the full state to dynamically rebuild if an error is present
    final state = ref.watch(signupFlowProvider);
    final confirmations = state.confirmations;
    final progress = confirmations / 3;
    final hasError = state.error != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 64),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOutBack,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: CyberTheme.border,
                    color: hasError ? CyberTheme.neonRed : CyberTheme.neonCyan,
                  ),
                ),
              ),
              if (hasError)
                const Icon(
                  Icons.error_outline_rounded,
                  color: CyberTheme.neonRed,
                  size: 80,
                )
              else if (confirmations >= 3)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CyberTheme.neonCyan,
                  size: 80,
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$confirmations / 3',
                      style: CyberTheme.heading(size: 32),
                    ),
                    Text(
                      'CONFS',
                      style: CyberTheme.label(
                        size: 12,
                        color: CyberTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            hasError
                ? context.l10n.confNetworkError
                : (confirmations >= 3
                      ? context.l10n.confNetworkVerified
                      : context.l10n.confConfirming),
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            hasError
                ? context.l10n.confErrorMsg
                : (confirmations >= 3
                      ? context.l10n.confVerifiedMsg
                      : context.l10n.confWaitingMsg),
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          if (hasError)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).clearError();
                  ref.read(signupFlowProvider.notifier).reset();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.neonRed,
                  foregroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.confRestartSignup,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else if (confirmations < 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CyberTheme.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CyberTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: CyberTheme.neonCyan,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.confNotificationNotice,
                      style: const TextStyle(
                        color: CyberTheme.neonCyan,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
