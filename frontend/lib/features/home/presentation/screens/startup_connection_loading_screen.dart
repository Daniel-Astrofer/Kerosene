import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

class StartupConnectionLoadingScreen extends StatefulWidget {
  final Widget? childAfterWarmup;

  const StartupConnectionLoadingScreen({super.key, this.childAfterWarmup});

  @override
  State<StartupConnectionLoadingScreen> createState() =>
      _StartupConnectionLoadingScreenState();
}

class _StartupConnectionLoadingScreenState
    extends State<StartupConnectionLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _progressTimer;
  Timer? _timeoutTimer;
  double _progress = 0.04;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted || _failed) return;
      setState(() {
        if (AppConfig.isTorEnabled) {
          _progress = 1.0;
          _progressTimer?.cancel();
          _progressTimer = null;
          _timeoutTimer?.cancel();
          _timeoutTimer = null;
          return;
        }
        if (_progress < 0.80) {
          _progress = math.min(0.80, _progress + 0.025);
        }
      });
    });
    _timeoutTimer = Timer(const Duration(seconds: 55), () {
      if (!mounted) return;
      if (_progress < 1) {
        _progressTimer?.cancel();
        _progressTimer = null;
        setState(() => _failed = true);
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _timeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_progress >= 1 && !_failed && widget.childAfterWarmup != null) {
      return widget.childAfterWarmup!;
    }

    if (_progress >= 0.80 && !_failed) {
      return const KeroseneLogoLoadingView(
        status: 'SINCRONIZANDO',
        detail: 'Preparando ambiente Kerosene',
      );
    }

    return Scaffold(
      backgroundColor: KeroseneBrandTokens.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final pulse =
                    (math.sin(_controller.value * math.pi * 2) + 1) / 2;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.96 + pulse * 0.04,
                      child: SizedBox(
                        width: 148,
                        height: 148,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 6,
                          color: _failed
                              ? KeroseneBrandTokens.warning
                              : KeroseneBrandTokens.textPrimary,
                          backgroundColor: KeroseneBrandTokens.surface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _failed ? 'REINICIE O APP' : 'CONECTANDO TOR',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KeroseneBrandTokens.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _failed
                          ? 'A conexao privada nao iniciou. Feche e abra o app para tentar novamente.'
                          : '${(_progress * 100).round()}% preparando conexao privada',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: KeroseneBrandTokens.textMuted,
                        fontSize: 14,
                        height: 1.45,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
