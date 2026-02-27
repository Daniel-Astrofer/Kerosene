import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';

class AnimatedLoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final String text;
  final List<String> loadingTexts;
  final Color baseColor;

  const AnimatedLoadingButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.loadingTexts = const ['Loading...'],
    this.baseColor = CyberTheme.neonCyan,
  });

  @override
  State<AnimatedLoadingButton> createState() => _AnimatedLoadingButtonState();
}

class _AnimatedLoadingButtonState extends State<AnimatedLoadingButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  int _currentTextIndex = 0;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startLoading() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentTextIndex = 0;
    });

    if (widget.loadingTexts.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
        if (!mounted) return;
        setState(() {
          _currentTextIndex =
              (_currentTextIndex + 1) % widget.loadingTexts.length;
        });
      });
    }

    try {
      if (widget.onPressed != null) {
        await widget.onPressed!();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _timer?.cancel();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _isLoading
            ? widget.baseColor.withValues(alpha: 0.15)
            : widget.baseColor,
        borderRadius: BorderRadius.circular(14),
        border: _isLoading
            ? Border.all(
                color: widget.baseColor.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed == null || _isLoading ? null : _startLoading,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading ? _buildLoadingState() : _buildIdleState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: widget.baseColor.withValues(alpha: _glowAnimation.value),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                widget.loadingTexts[_currentTextIndex],
                key: ValueKey<int>(_currentTextIndex),
                style: TextStyle(
                  color: widget.baseColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: widget.baseColor.withValues(
                        alpha: _glowAnimation.value * 0.5,
                      ),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIdleState() {
    return Text(
      widget.text,
      style: const TextStyle(
        color: CyberTheme.bgDeep,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
    );
  }
}
