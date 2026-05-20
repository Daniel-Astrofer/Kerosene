import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/safe_display_text.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../domain/entities/wallet.dart';

import 'package:teste/shared/widgets/brushed_metal_container.dart';

/// Premium Wallet Card Component - Refactored
class WalletCard extends StatefulWidget {
  final Wallet wallet;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAddressCopied;
  final int colorIndex;
  final double tilt;
  final Function(String action)? onMenuAction;

  const WalletCard({
    super.key,
    required this.wallet,
    this.isSelected = false,
    this.onTap,
    this.onAddressCopied,
    this.onMenuAction,
    this.colorIndex = 0,
    this.tilt = 0.0,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();

  String _shortAddress(String address) {
    return SafeDisplayText.maskAddress(address);
  }
}

class _WalletCardState extends State<WalletCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRotationState();
  }

  @override
  void didUpdateWidget(covariant WalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _syncRotationState();
    }
  }

  bool get _shouldRotate =>
      widget.isSelected &&
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context);

  void _syncRotationState() {
    if (_shouldRotate) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.value = 0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _showCardMenu(BuildContext context) {
    if (widget.onMenuAction == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSpacing.xl),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(LucideIcons.edit,
                  color: Theme.of(context).colorScheme.onPrimary),
              title: Text(context.tr.walletEditNameAction.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
              onTap: () {
                Navigator.pop(context);
                widget.onMenuAction?.call('edit');
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2,
                  color: Theme.of(context).colorScheme.error),
              title: Text(context.tr.removeWallet.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              onTap: () {
                Navigator.pop(context);
                widget.onMenuAction?.call('delete');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final height = width / 1.65;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final shineY = widget.tilt * -1.5;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      width: width + 4,
      height: height + 4,
      child: GestureDetector(
        onTap: widget.isSelected ? () => _showCardMenu(context) : widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _NeonGlowPainter(
                        color: primaryColor,
                        rotation: _shouldRotate ? _rotationController.value : 0,
                        intensity: widget.isSelected ? 1.0 : 0.4,
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: widget.isSelected ? 24 : 14,
                    offset: Offset(0, 8 + (widget.tilt * 10)),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md - 1.5),
                child: Stack(
                  children: [
                    // ── Raw Metal Shader (sem filtros acima) ──
                    Positioned.fill(
                      child: BrushedMetalContainer(
                        width: width,
                        height: height,
                        baseColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.85),
                        borderRadius: AppSpacing.md,
                      ),
                    ),

                    Positioned(
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Icon(LucideIcons.zap,
                          color: primaryColor.withValues(alpha: 0.4), size: 40),
                    ),

                    // ── Shine on selection ──
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: widget.isSelected ? 1.0 : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.0),
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.1),
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.0),
                              ],
                              stops: const [0.35, 0.5, 0.65],
                              transform:
                                  GradientTranslation(Offset(0.0, shineY)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Card content ──
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₿',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Text('BITCOIN',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                    .withValues(alpha: 0.5))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.wallet.name.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget
                                          ._shortAddress(widget.wallet.address),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withValues(alpha: 0.5),
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Clipboard.setData(ClipboardData(
                                          text: widget.wallet.address));
                                      widget.onAddressCopied?.call();
                                    },
                                    icon: Icon(LucideIcons.copy,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.1),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientTranslation extends GradientTransform {
  final Offset offset;
  const GradientTranslation(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
        offset.dx * bounds.width, offset.dy * bounds.height, 0.0);
  }
}

class _NeonGlowPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final double intensity;

  _NeonGlowPainter(
      {required this.color, required this.rotation, this.intensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final auraPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = color.withValues(alpha: 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rRect, auraPaint);

    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final Gradient beamGradient = SweepGradient(
      center: Alignment.center,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8 * intensity),
        color.withValues(alpha: 0.0)
      ],
      stops: const [0.4, 0.5, 0.6],
      transform: GradientRotation(rotation * 2 * 3.14159),
    );

    beamPaint.shader = beamGradient.createShader(rect);
    canvas.drawRRect(rRect, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonGlowPainter oldDelegate) => true;
}
