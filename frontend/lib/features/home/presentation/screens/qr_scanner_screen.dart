import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/monochrome_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _hasScanned = true;
        });
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(barcode.rawValue);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: monoBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: monoBackgroundColor),
          ),
          // ── Camera View ───────────────────────────────────────────────────
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // ── Premium Scan Overlay ──────────────────────────────────────────
          _buildScanOverlay(),

          // ── Custom App Bar ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                  top: AppSpacing.xxl, bottom: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.chevronLeft,
                          color: monoTextColor, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: monoSurfaceAltColor,
                        side: const BorderSide(color: monoBorderStrongColor),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ESCANEIE QR CODE',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            letterSpacing: 2,
                            color: monoTextColor,
                          ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        return IconButton(
                          icon: Icon(
                            state.torchState == TorchState.on
                                ? LucideIcons.zap
                                : LucideIcons.zapOff,
                            color: state.torchState == TorchState.on
                                ? monoTextColor
                                : monoMutedTextColor,
                            size: 20,
                          ),
                          onPressed: () => _controller.toggleTorch(),
                          style: IconButton.styleFrom(
                            backgroundColor: monoSurfaceAltColor,
                            side:
                                const BorderSide(color: monoBorderStrongColor),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        )
                            .animate(
                                target:
                                    state.torchState == TorchState.on ? 1 : 0)
                            .tint(color: monoTextColor);
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: Icon(LucideIcons.refreshCcw,
                          color: monoTextColor, size: 20),
                      onPressed: () => _controller.switchCamera(),
                      style: IconButton.styleFrom(
                        backgroundColor: monoSurfaceAltColor,
                        side: const BorderSide(color: monoBorderStrongColor),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fade().slideY(begin: -0.2, end: 0),

          // ── Instruction Area ─────────────────────────────────────────────
          Positioned(
            bottom: AppSpacing.xxl + AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: monochromePanelDecoration(
                color: monoSurfaceColor.withValues(alpha: 0.84),
                borderColor: monoBorderStrongColor,
                showShadow: false,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.scanLine,
                    color: monoTextColor,
                    size: 24,
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Aponte a câmera para um código QR de pagamento',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: monoTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = (constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight) *
            0.7;
        final scanAreaTop = (constraints.maxHeight - scanAreaSize) / 2;
        final scanAreaLeft = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Dark Overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.72),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: scanAreaTop,
                    left: scanAreaLeft,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scanner Frame Corners
            _buildCorner(scanAreaTop, scanAreaLeft, true, true),
            _buildCorner(
                scanAreaTop, scanAreaLeft + scanAreaSize - 40, true, false),
            _buildCorner(
                scanAreaTop + scanAreaSize - 40, scanAreaLeft, false, true),
            _buildCorner(scanAreaTop + scanAreaSize - 40,
                scanAreaLeft + scanAreaSize - 40, false, false),

            // Scanning Line Animation
            _ScanningLine(
                top: scanAreaTop, left: scanAreaLeft, size: scanAreaSize),
          ],
        );
      },
    );
  }

  Widget _buildCorner(double top, double left, bool isTop, bool isLeft) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: monoTextColor, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: monoTextColor, width: 4)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: monoTextColor, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: monoTextColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final double top;
  final double left;
  final double size;

  const _ScanningLine(
      {required this.top, required this.left, required this.size});

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: widget.size).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: widget.top + _animation.value,
          left: widget.left + AppSpacing.md,
          child: Container(
            width: widget.size - AppSpacing.xl,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  monoTextColor.withValues(alpha: 0.0),
                  monoTextColor,
                  monoTextColor.withValues(alpha: 0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: monoTextColor.withValues(alpha: 0.34),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
