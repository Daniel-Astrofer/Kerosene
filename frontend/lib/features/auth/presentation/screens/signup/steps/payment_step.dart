import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';

class PaymentStep extends ConsumerStatefulWidget {
  const PaymentStep({super.key});

  @override
  ConsumerState<PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends ConsumerState<PaymentStep> {
  Timer? _paymentDetector;
  Timer? _countdownTimer;
  int _timeLeft = 15 * 60; // 15 minutes to pay

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPaymentDetection();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          ref
              .read(signupFlowProvider.notifier)
              .setError("Payment window expired. Please try again.");
          // Ideally redirect back to start or restart flow
        }
      });
    });
  }

  // This method is now responsible for starting the actual payment detection
  void _startPaymentDetection() {
    _paymentDetector = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final repo = ref.read(authProvider.notifier).authRepository;
      ref.read(signupFlowProvider.notifier).checkPaymentStatus(repo);
    });
  }

  @override
  void dispose() {
    _paymentDetector?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimeLeft() {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(signupFlowProvider);
    final depositAddress = flowState.paymentAddress ?? "Loading...";
    final amountBtc = flowState.paymentAmountBtc ?? 0.003;
    final paymentUri =
        flowState.paymentUri ?? "bitcoin:$depositAddress?amount=$amountBtc";

    String amountStr = amountBtc.toStringAsFixed(8);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: CyberTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeLeft(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft < 300
                      ? CyberTheme.neonRed
                      : CyberTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Pay Creation Fee',
            style: CyberTheme.heading(size: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Send exactly $amountStr BTC to the address below. This tab will update automatically once the payment is detected.',
            style: CyberTheme.label(size: 14, color: CyberTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: CyberTheme.subtleGlow(CyberTheme.neonPurple),
            ),
            child: QrImageView(
              data: paymentUri,
              version: QrVersions.auto,
              size: 220,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF050511),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF050511),
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: depositAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Address Copied!'),
                  backgroundColor: CyberTheme.neonPurple.withValues(alpha: 0.8),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: CyberTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CyberTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      depositAddress,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: CyberTheme.neonPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: CyberTheme.neonPurple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CyberTheme.neonPurple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Awaiting payment in mempool...',
                style: TextStyle(
                  color: CyberTheme.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
