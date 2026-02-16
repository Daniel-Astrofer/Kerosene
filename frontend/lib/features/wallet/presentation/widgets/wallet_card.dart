import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/wallet.dart';

class WalletCard extends StatefulWidget {
  final Wallet wallet;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAddressCopied;
  final int colorIndex;

  /// New: Tilt progress for specular shine (-1.0 to 1.0)
  final double tilt;

  const WalletCard({
    super.key,
    required this.wallet,
    this.isSelected = false,
    this.onTap,
    this.onAddressCopied,
    this.colorIndex = 0,
    this.tilt = 0.0,
  });

  static void precacheAllImages(BuildContext context) {
    for (final path in _cardBackgroundImages) {
      final provider = _getResizedProvider(path);
      if (provider != null) {
        precacheImage(provider, context);
      }
    }
  }

  @override
  State<WalletCard> createState() => _WalletCardState();

  static const _cardColorSchemes = [
    // 0: Gold (Bitcoin)
    [
      Color(0xFFBF953F),
      Color(0xFFFCF6BA),
      Color(0xFFB38728),
      Color(0xFFFBF5B7),
      Color(0xFFAA771C),
    ],
    // 1: Silver
    [
      Color(0xFF757F9A), // Dark Silver
      Color(0xFFD7DDE8), // Bright Silver
      Color(0xFF757F9A),
    ],
    // 2: Platinum / Diamond
    [
      Color(0xFFE3E3E3), // Light Grey
      Color(0xFF5D6D7E), // Steel Blueish
      Color(0xFF8FD6F4), // Icy Blue
      Color(0xFFE3E3E3),
    ],
    // 3: Ruby (Dark Red Metal)
    [
      Color(0xFF800020), // Burgundy
      Color(0xFFD6336C), // Pinkish shine
      Color(0xFF540013), // Deep Red
    ],
    // 4: Emerald (Dark Green Metal)
    [Color(0xFF064e3b), Color(0xFF34d399), Color(0xFF065f46)],
    // 5: Sapphire (Dark Blue Metal)
    [Color(0xFF0f172a), Color(0xFF3b82f6), Color(0xFF1e3a8a)],
    // 6: Black Metal (Obsidian)
    [Color(0xFF27272a), Color(0xFF71717a), Color(0xFF09090b)],
  ];

  static const _cardBackgroundImages = [
    'assets/images/gold-texture-background-minimalist.jpg', // 0: Gold
    'assets/images/black-wooden-floor.jpg', // 1: Silver
    'assets/images/blue-designed-grunge-concrete-texture-vintage-background-with-space-text-image.jpg', // 2: Platinum
    'assets/images/artistic-abstract-painting-textured-backdrop.jpg', // 3: Ruby
    'assets/images/green-oil-paint-texture.jpg', // 4: Emerald
    'assets/images/blue-designed-grunge-concrete-texture-vintage-background-with-space-text-image.jpg', // 5: Sapphire
    'assets/images/black-wooden-floor.jpg', // 6: Black Metal
  ];

  static final Map<String, ImageProvider> _imageProviderCache = {};

  static ImageProvider? _getResizedProvider(String path) {
    if (path.isEmpty) return null;
    if (_imageProviderCache.containsKey(path)) {
      return _imageProviderCache[path]!;
    }
    final provider = ResizeImage.resizeIfNeeded(1000, null, AssetImage(path));
    _imageProviderCache[path] = provider;
    return provider;
  }

  String? _getBackgroundImagePath() {
    final index = colorIndex % _cardBackgroundImages.length;
    return _cardBackgroundImages[index];
  }

  ImageProvider? _getBackgroundImageProvider() {
    final path = _getBackgroundImagePath();
    return path != null ? _getResizedProvider(path) : null;
  }

  List<Color> _getGradientColors() {
    return _cardColorSchemes[colorIndex % _cardColorSchemes.length];
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final height = width / 1.65;
    final colors = widget._getGradientColors();
    final neonColor = colors.first;

    // Specular shine offset based on tilt
    // tilt is from 0 to -0.6 typically. Let's normalize it.
    final shineY = widget.tilt * -1.5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      width: width + 4,
      height: height + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
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

          // The Card Body
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: List.generate(
                  colors.length,
                  (index) => index / (colors.length - 1),
                ),
              ),
              image: widget._getBackgroundImageProvider() != null
                  ? DecorationImage(
                      image: widget._getBackgroundImageProvider()!,
                      fit: BoxFit.cover,
                      colorFilter:
                          widget.colorIndex %
                                  WalletCard._cardColorSchemes.length ==
                              3
                          ? ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.1),
                              BlendMode.srcOver,
                            )
                          : ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.15),
                              BlendMode.dstOut,
                            ),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35 + (widget.tilt * -0.2)),
                  blurRadius: widget.isSelected ? 24 : 14,
                  offset: Offset(0, 8 + (widget.tilt * 10)),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: Offset(0, 6 + (widget.tilt * 5)),
                ),
              ],
              border: Border.all(
                color: widget.isSelected
                    ? neonColor.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.2),
                width: widget.isSelected ? 2.0 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Metal Texture
                  if (widget._getBackgroundImageProvider() == null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BrushedMetalPainter(baseColor: colors.first),
                      ),
                    ),

                  // Pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BitcoinPatternPainter(
                        color: Colors.black.withValues(alpha: 0.05),
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
                              Colors.white.withValues(alpha: 0.2), // The streak
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.35, 0.5, 0.65],
                            // Move the gradient based on tilt
                            transform: GradientTranslation(Offset(0.0, shineY)),
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
                                  color: Colors.white.withValues(alpha: 0.95),
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
                                    if (widget.wallet.address.isEmpty) return;
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
                                          color: Colors.white.withValues(alpha: 0.95),
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
                                            color: Colors.white.withValues(alpha: 
                                              0.95,
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
        ],
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

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CardIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.black.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: 20,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          onPressed: onPressed,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
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

class _BrushedMetalPainter extends CustomPainter {
  final Color baseColor;

  _BrushedMetalPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Use a fixed seed based on the baseColor to avoid DateTime.now() jumps/lags
    final seed = baseColor.value;

    // Draw horizontal lines with varying opacity
    for (double i = 0; i < size.height; i += 1.5) {
      double opacity = ((i * 13 + seed) % 150) / 1000.0; // 0.0 to 0.15
      paint.color = Colors.white.withValues(alpha: opacity);
      paint.strokeWidth = ((i * 7) % 3 == 0) ? 1.5 : 0.5;
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Add some "scratch" noise
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 60; i++) {
      double x = (i * 113 + seed) % size.width;
      double y = (i * 227 + seed) % size.height;
      double w = 20 + ((i * 17) % 40).toDouble();
      paint.color = Colors.black.withValues(alpha: 0.05);
      canvas.drawLine(Offset(x, y), Offset(x + w, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushedMetalPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
