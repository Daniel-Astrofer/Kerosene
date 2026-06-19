import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_spacing.dart';

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
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      body: Stack(
        children: [
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
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(KeroseneIcons.back,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      context.tr.scanQR.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(letterSpacing: 2),
                    ),
                    const Spacer(),
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, state, child) {
                        return IconButton(
                          icon: Icon(
                            state.torchState == TorchState.on
                                ? KeroseneIcons.lightning
                                : KeroseneIcons.unavailable,
                            color: state.torchState == TorchState.on
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: () => _controller.toggleTorch(),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.1),
                          ),
                        )
                            .animate(
                                target:
                                    state.torchState == TorchState.on ? 1 : 0)
                            .tint(color: Theme.of(context).colorScheme.primary);
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: Icon(KeroseneIcons.refresh,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20),
                      onPressed: () => _controller.switchCamera(),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.1),
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
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(KeroseneIcons.qr,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr.qrScannerInstruction,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.8),
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
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(AppSpacing.lg),
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
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 4)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 4)
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
      duration: KeroseneMotion.loop,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: widget.size).animate(
      CurvedAnimation(parent: _controller, curve: KeroseneMotion.standard),
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
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
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
