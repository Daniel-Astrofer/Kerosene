import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/copy/kerosene_ui_copy.dart';
import 'package:kerosene/core/providers/network_status_provider.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

class _OfflineOverlayCopy {
  const _OfflineOverlayCopy._();

  static const connectionBody =
      'A conexão com o backend caiu. Tentaremos reconectar por tempo limitado.';
}

class OfflineOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  ConsumerState<OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends ConsumerState<OfflineOverlay>
    with TickerProviderStateMixin {
  static const int _maxAutomaticRetries = 5;

  late final AnimationController _pulseController;
  late final AnimationController _retryController;
  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.loop,
    )..repeat();
    _retryController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.offlineRetryPulse,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRetryLoop());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _pulseController.dispose();
    _retryController.dispose();
    super.dispose();
  }

  void _syncRetryLoop() {
    final isOnline = ref.read(networkStatusProvider);
    if (isOnline) {
      _stopRetryLoop();
      if (_retryCount != 0 && mounted) {
        setState(() => _retryCount = 0);
      }
      return;
    }
    if (_retryCount >= _maxAutomaticRetries) {
      _stopRetryLoop();
      return;
    }
    _retryTimer ??= Timer.periodic(KeroseneMotion.offlineRetryInterval, (_) {
      if (!mounted) return;
      _performRetry();
    });
  }

  Future<void> _performRetry({bool manual = false}) async {
    if (!mounted) return;
    if (!manual && _retryCount >= _maxAutomaticRetries) {
      _stopRetryLoop();
      return;
    }

    setState(() => _retryCount += 1);
    _retryController.forward(from: 0);
    await ref.read(networkStatusProvider.notifier).checkConnection();
    if (!mounted) return;
    if (!manual && _retryCount >= _maxAutomaticRetries) {
      _stopRetryLoop();
    }
  }

  void _stopRetryLoop() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRetryLoop());

    return RepaintBoundary(
      child: Stack(
        children: [
          widget.child,
          if (!isOnline)
            Positioned.fill(
              child: Material(
                color: KeroseneBrandTokens.background.withValues(alpha: 0.94),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final iconSize =
                          math.min(148.0, math.max(104.0, width * 0.34));
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AnimatedConnectionIcon(
                                  pulse: _pulseController,
                                  retry: _retryController,
                                  retryCount: _retryCount,
                                  size: iconSize,
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  KeroseneUiCopy.offlineTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: KeroseneBrandTokens.textPrimary,
                                    fontSize: math.min(
                                        30, math.max(22, width * 0.07)),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                    fontFamily: AppTypography.displayFontFamily,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _OfflineOverlayCopy.connectionBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: KeroseneBrandTokens.textMuted,
                                    fontSize: math.min(
                                        16, math.max(13, width * 0.038)),
                                    height: 1.45,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  label: 'Tentar agora',
                                  onPressed: () => _performRetry(manual: true),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _retryCount == 0
                                      ? 'Tentaremos automaticamente até $_maxAutomaticRetries vezes.'
                                      : _retryCount >= _maxAutomaticRetries
                                          ? 'Tentativas automáticas pausadas. Use Tentar agora para verificar novamente.'
                                          : 'Tentativa $_retryCount de $_maxAutomaticRetries enviada.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: KeroseneBrandTokens.textMuted
                                        .withValues(alpha: 0.78),
                                    fontSize: 12,
                                    height: 1.35,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedConnectionIcon extends StatelessWidget {
  final AnimationController pulse;
  final AnimationController retry;
  final int retryCount;
  final double size;

  const _AnimatedConnectionIcon({
    required this.pulse,
    required this.retry,
    required this.retryCount,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, retry]),
      builder: (context, _) {
        final idle = (math.sin(pulse.value * math.pi * 2) + 1) / 2;
        final hit = retry.isAnimating
            ? KeroseneMotion.expressiveBack.transform(retry.value)
            : 0.0;
        final direction = retryCount.isEven ? -1.0 : 1.0;
        final retryGlow = hit * (0.10 + (retryCount % 3) * 0.035);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var index = 0; index < 3; index++)
                Transform.scale(
                  scale: 0.76 + index * 0.18 + idle * 0.06 + hit * 0.05,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KeroseneBrandTokens.warning.withValues(
                          alpha: 0.08 + index * 0.05 + retryGlow,
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(direction * hit * size * 0.08, 0),
                child: Transform.rotate(
                  angle: direction * hit * 0.14,
                  child: Container(
                    width: size * 0.72,
                    height: size * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          KeroseneBrandTokens.surface.withValues(alpha: 0.96),
                      border: Border.all(
                        color: KeroseneBrandTokens.warning.withValues(
                          alpha: 0.28 + retryGlow,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KeroseneBrandTokens.warning.withValues(
                            alpha: 0.12 + idle * 0.10 + retryGlow,
                          ),
                          blurRadius: 32 + hit * 12,
                          spreadRadius: 2 + hit * 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      KeroseneIcons.wifiOff,
                      size: size * 0.34,
                      color: KeroseneBrandTokens.warning,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
