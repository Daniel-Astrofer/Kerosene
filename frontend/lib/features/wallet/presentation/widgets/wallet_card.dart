import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/wallet.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class WalletCard extends StatefulWidget {
  final Wallet wallet;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAddressCopied;
  final int colorIndex;

  /// New: Tilt progress for specular shine (-1.0 to 1.0)
  final double tilt;
  // Callback for menu actions
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

  // Dynamic gradient colors based on index/type
  List<Color> _getCardGradient() {
    // Distinct palettes for the stack fan-out effect
    final List<List<Color>> palettes = [
      // 0: Kerosene Green (Primary)
      [
        const Color(0xFF00FF94),
        const Color(0xFF00CC75),
        const Color(0xFF00AA60),
      ],
      // 1: Deep Purple
      [
        const Color(0xFF7B61FF),
        const Color(0xFF5B41DF),
        const Color(0xFF3B21BF),
      ],
      // 2: Electric Blue
      [
        const Color(0xFF00D4FF),
        const Color(0xFF00AACC),
        const Color(0xFF0088AA),
      ],
      // 3: Hot Pink / Magenta
      [
        const Color(0xFFFF00D4),
        const Color(0xFFCC00AA),
        const Color(0xFFAA0088),
      ],
      // 4: Amber / Orange
      [
        const Color(0xFFFFAA00),
        const Color(0xFFCC8800),
        const Color(0xFFAA7700),
      ],
    ];

    // Cycle through palettes based on colorIndex
    return palettes[colorIndex % palettes.length];
  }

  String _shortAddress(String address) {
    if (address.isEmpty) return '—';
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
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
    )..repeat();
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
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Edit Name',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onMenuAction?.call('edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Wallet',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onMenuAction?.call('delete');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final height = width / 1.65;
    final colors = widget._getCardGradient();
    final neonColor = colors.first;

    // Specular shine offset based on tilt
    // tilt is from 0 to -0.6 typically. Let's normalize it.
    final shineY = widget.tilt * -1.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      width: width + 4,
      height: height + 4,
      child: GestureDetector(
        onTap: widget.isSelected ? () => _showCardMenu(context) : widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Moving Backlight (Behind the card)
            if (widget.isSelected)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  child: Container(
                    width: width * 0.8,
                    height: height * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonColor.withValues(alpha: 0.4),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  builder: (context, child) {
                    final alignX =
                        (0.5 *
                        math.cos(_rotationController.value * 2 * math.pi));
                    final alignY =
                        (0.5 *
                        math.sin(_rotationController.value * 2 * math.pi));
                    return FractionalTranslation(
                      translation: Offset(
                        alignX * 0.125,
                        alignY * 0.125,
                      ), // Adjusted for size diff
                      child: Center(child: child),
                    );
                  },
                ),
              ),

            // Rotating Neon Glow
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _NeonGlowPainter(
                        color: neonColor,
                        rotation: _rotationController.value,
                        intensity: widget.isSelected ? 1.0 : 0.4,
                      ),
                    );
                  },
                ),
              ),
            ),

            // The Card Body (Glass)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // Semi-transparent gradient for glass effect
                    gradient: LinearGradient(
                      colors: widget
                          ._getCardGradient()
                          .map((c) => c.withValues(alpha: 0.85))
                          .toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget._getCardGradient().first.withValues(
                          alpha: 0.25 + (widget.tilt * -0.2),
                        ),
                        blurRadius: widget.isSelected ? 24 : 14,
                        offset: Offset(0, 8 + (widget.tilt * 10)),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6 + (widget.tilt * 15)),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pattern
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _BitcoinPatternPainter(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ),

                      // KEROSENE LOGO
                      Positioned(
                        right: 24,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Opacity(
                            opacity: 0.85,
                            child: Image.asset(
                              'assets/kerosenelogo.png',
                              height: 22,
                              fit: BoxFit.contain,
                              color: Colors.black,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),

                      // --- SPECULAR SHINE (V3 WOW Factor) ---
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
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(
                                    alpha: 0.2,
                                  ), // The streak
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.35, 0.5, 0.65],
                                // Move the gradient based on tilt
                                transform: GradientTranslation(
                                  Offset(0.0, shineY),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Soft reflection top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Tap area
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onTap != null
                                ? () => widget.onTap!()
                                : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₿',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bitcoin',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            Text(
                              widget.wallet.name,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget._shortAddress(widget.wallet.address),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          offset: Offset(0, 2),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(right: 30.0),
                                  child: Material(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: () {
                                        if (widget.wallet.address.isEmpty) {
                                          return;
                                        }
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: widget.wallet.address,
                                          ),
                                        );
                                        widget.onAddressCopied?.call();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 14,
                                              color: Colors.white.withValues(
                                                alpha: 0.95,
                                              ),
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Copiar',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// Support for Gradient Translation
class GradientTranslation extends GradientTransform {
  final Offset offset;
  const GradientTranslation(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      offset.dx * bounds.width,
      offset.dy * bounds.height,
      0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GradientTranslation && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;
}

class _NeonGlowPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final double intensity;

  _NeonGlowPainter({
    required this.color,
    required this.rotation,
    this.intensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(24),
    );

    // 1. Constant subtle glow (Aura)
    final auraPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = color.withValues(alpha: 0.3 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(rRect, auraPaint);

    // 2. High-intensity rotating beam
    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Sharp "Beam" Gradient
    final Gradient beamGradient = SweepGradient(
      center: Alignment.center,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 1.0 * intensity), // The intense part
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.45, 0.5, 0.55], // Tight stops for a "beam" look
      transform: GradientRotation(rotation * 2 * 3.1415926535),
    );

    beamPaint.shader = beamGradient.createShader(rect);
    canvas.drawRRect(rRect, beamPaint);

    // 3. Ultra-bright inner streak for "neon" look
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.8 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    // We reuse the same sweep gradient logic but for a smaller path or just selective redraw
    // To keep it simple but effective, we'll draw the whole RRect again with the same shader
    streakPaint.shader = beamGradient.createShader(rect);
    canvas.drawRRect(rRect, streakPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonGlowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.rotation != rotation ||
        oldDelegate.intensity != intensity;
  }
}

class _BitcoinPatternPainter extends CustomPainter {
  final Color color;

  _BitcoinPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final spacing = 24.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        if ((x / spacing + y / spacing).toInt() % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
