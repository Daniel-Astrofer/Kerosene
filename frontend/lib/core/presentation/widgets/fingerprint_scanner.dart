import 'package:flutter/material.dart';

class CyberFingerprintScanner extends StatefulWidget {
  final double size;
  final Color color;

  const CyberFingerprintScanner({
    super.key,
    this.size = 120,
    this.color = const Color(0xFF00F0FF),
  });

  @override
  State<CyberFingerprintScanner> createState() =>
      _CyberFingerprintScannerState();
}

class _CyberFingerprintScannerState extends State<CyberFingerprintScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing rings
              for (int i = 0; i < 3; i++)
                Opacity(
                  opacity: (1.0 - ((_controller.value + i / 3.0) % 1.0)).clamp(
                    0.0,
                    1.0,
                  ),
                  child: Container(
                    width: widget.size * ((_controller.value + i / 3.0) % 1.0),
                    height: widget.size * ((_controller.value + i / 3.0) % 1.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              // Main Fingerprint Icon with glow
              Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: widget.color,
                  size: widget.size * 0.4,
                ),
              ),
              // Scanning Line
              Positioned(
                top:
                    (widget.size * 0.2) +
                    (widget.size * 0.6 * _controller.value),
                child: Container(
                  width: widget.size * 0.5,
                  height: 2,
                  decoration: BoxDecoration(
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
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
