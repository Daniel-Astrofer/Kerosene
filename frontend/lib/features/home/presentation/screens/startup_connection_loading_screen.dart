import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kerosene/core/config/app_config.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';

class StartupConnectionLoadingScreen extends StatefulWidget {
  final Widget? childAfterWarmup;

  const StartupConnectionLoadingScreen({super.key, this.childAfterWarmup});

  @override
  State<StartupConnectionLoadingScreen> createState() =>
      _StartupConnectionLoadingScreenState();
}

class _StartupConnectionLoadingScreenState
    extends State<StartupConnectionLoadingScreen> {
  Timer? _progressTimer;
  Timer? _timeoutTimer;
  double _progress = 0.04;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_progress >= 1 && !_failed && widget.childAfterWarmup != null) {
      return widget.childAfterWarmup!;
    }

    return const Scaffold(
      backgroundColor: KeroseneBrandTokens.background,
      body: SafeArea(
        child: Center(
          child: TorLoadingDots(
            dotSize: 8,
            spacing: 8,
            travel: 9,
            color: KeroseneBrandTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
