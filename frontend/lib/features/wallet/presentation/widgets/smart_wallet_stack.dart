import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/wallet.dart';
import 'wallet_credit_card.dart';

/// A wallet card stack with:
/// - Collapsed: cards stacked like stairs (each card behind peeks upward)
/// - Swipe up on the top card → cycles to the next card
/// - Tap any card → opens horizontal carousel
/// - In carousel: swipe left/right to browse, tap to select & collapse
class SmartWalletStack extends StatefulWidget {
  final List<Wallet> wallets;
  final int initialIndex;
  final Function(Wallet) onCardTap;
  final VoidCallback? onAddressCopied;

  const SmartWalletStack({
    super.key,
    required this.wallets,
    required this.initialIndex,
    required this.onCardTap,
    this.onAddressCopied,
  });

  @override
  State<SmartWalletStack> createState() => _SmartWalletStackState();
}

class _SmartWalletStackState extends State<SmartWalletStack>
    with TickerProviderStateMixin {
  // Which card is on top
  int _topIndex = 0;

  // Whether the carousel is open
  bool _carouselOpen = false;

  // Animation for opening/closing carousel
  late AnimationController _carouselController;
  late Animation<double> _carouselAnim;

  // Animation for swipe-up cycling
  late AnimationController _swipeController;
  late Animation<double> _swipeAnim;

  // PageController for carousel
  late PageController _pageController;
  int _carouselPage = 0;

  // Drag tracking for the FRONT card swipe-up
  double _dragStartY = 0;
  double _dragDeltaY = 0;
  bool _isDragging = false;

  // Per-rank drag state for peeking cards (rank=1 closest, rank=3 furthest)
  final Map<int, double> _peekDrag = {}; // rank → drag delta (negative = up)
  int? _draggingRank; // which rank is currently being dragged

  static const double _cardHeight = 200.0;
  // Aumentado para 35.0 para expor mais o cartão
  static const double _peekOffset = 35.0;
  // Max cards that peek behind the front
  static const int _maxPeek = 3;

  // Shake detection
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime(0);
  static const double _shakeThreshold = 25.0; // m/s²
  // Reduzido para 500ms para resposta mais ágil
  static const Duration _shakeCooldown = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _topIndex = widget.initialIndex.clamp(0, widget.wallets.length - 1);
    _carouselPage = _topIndex;

    _carouselController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _carouselAnim = CurvedAnimation(
      parent: _carouselController,
      curve: Curves.easeInOutCubic,
    );

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swipeAnim = CurvedAnimation(
      parent: _swipeController,
      // Usar curva elástica para dar o efeito "snappy" do Dribbble
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInCubic,
    );

    _pageController = PageController(
      initialPage: _topIndex,
      viewportFraction: 0.88,
    );

    _startShakeDetection();
  }

  void _startShakeDetection() {
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((AccelerometerEvent event) {
          final now = DateTime.now();
          if (now.difference(_lastShake) < _shakeCooldown) return;

          // Use X-axis for left/right shake direction
          final absX = event.x.abs();
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final netAccel = (magnitude - 9.8).abs();

          if (_carouselOpen) {
            // Directional shake to navigate carousel
            // Threshold lower (18) since user is intentionally shaking sideways
            if (absX > 18.0) {
              _lastShake = now;
              final n = widget.wallets.length;
              if (event.x < 0) {
                // Shake left → next card
                final next = (_carouselPage + 1) % n;
                _pageController.animateToPage(
                  next,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
                setState(() => _carouselPage = next);
              } else {
                // Shake right → previous card
                final prev = (_carouselPage - 1 + n) % n;
                _pageController.animateToPage(
                  prev,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
                setState(() => _carouselPage = prev);
              }
              HapticFeedback.selectionClick();
            }
          } else {
            // Any strong shake opens the carousel
            if (netAccel > _shakeThreshold) {
              _lastShake = now;
              _openCarousel();
            }
          }
        });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _carouselController.dispose();
    _swipeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _openCarousel() {
    if (_carouselOpen) return;
    setState(() {
      _carouselOpen = true;
      _carouselPage = _topIndex;
    });
    // Recreate PageController at correct page
    _pageController.dispose();
    _pageController = PageController(
      initialPage: _topIndex,
      viewportFraction: 0.88,
    );
    _carouselController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _closeCarousel(int selectedIndex) {
    if (!_carouselOpen) return;
    setState(() {
      _topIndex = selectedIndex;
      _carouselPage = selectedIndex;
    });
    _carouselController.reverse().then((_) {
      setState(() {
        _carouselOpen = false;
      });
    });
    widget.onCardTap(widget.wallets[selectedIndex]);
    HapticFeedback.mediumImpact();
  }

  // Cycle to the next card (swipe up completed)
  void _cycleToNext() {
    final next = (_topIndex + 1) % widget.wallets.length;
    _swipeController.forward(from: 0).then((_) {
      setState(() {
        _topIndex = next;
        _dragDeltaY = 0;
        _isDragging = false;
      });
      _swipeController.reset();
      widget.onCardTap(widget.wallets[_topIndex]);
    });
    HapticFeedback.selectionClick();
  }

  // Total height of the widget: card + peeking area above
  double get _totalHeight => _cardHeight + (_maxPeek * _peekOffset) + 20;

  @override
  Widget build(BuildContext context) {
    if (widget.wallets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _totalHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([_carouselAnim, _swipeAnim]),
        builder: (context, _) {
          final carouselProgress = _carouselAnim.value;
          if (carouselProgress > 0.01) {
            return _buildCarousel(carouselProgress);
          }
          return _buildStack();
        },
      ),
    );
  }

  // ─── STACKED VIEW ────────────────────────────────────────────────────────

  Widget _buildStack() {
    final n = widget.wallets.length;
    final peekCount = (n - 1).clamp(0, _maxPeek);

    // Perspectiva 3D para o efeito "tombado"
    // Matrix4.identity()..setEntry(3, 2, 0.001) cria profundidade
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspectiva
        ..rotateX(-0.1), // Inclinação leve para trás (aprox -5 graus)
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: _buildFanCards(n, peekCount),
      ),
    );
  }

  List<Widget> _buildFanCards(int n, int peekCount) {
    final List<Widget> cards = [];

    // Desenhar cartões de trás (fan out)
    for (int rank = peekCount; rank >= 1; rank--) {
      final idx = (_topIndex + rank) % n;
      final wallet = widget.wallets[idx];

      // Ângulo base: distribuir em leque
      // rank 1 = +4 graus, rank 2 = -4 graus, etc. ou alternado
      // Vamos fazer um leque simétrico:
      // rank 1 (logo atrás) = 0 graus
      // rank 2 = -4 graus
      // rank 3 = +4 graus
      // Ou melhor: distribuir suavemente
      final double fanAngle = (rank * (rank % 2 == 0 ? -1 : 1) * 0.06)
          .toDouble();

      final baseScale = 1.0 - (rank * 0.05);
      // Mais alto para aparecer no leque
      final basePeekY = -(rank * 35.0).toDouble();

      // Pull state
      final pullDelta = (_peekDrag[rank] ?? 0.0).clamp(
        -_cardHeight * 0.85,
        0.0,
      );
      final pullRatio = (-pullDelta / (_cardHeight * 0.85)).clamp(0.0, 1.0);

      // Quando puxa, o cartão endireita (rotação vai a 0) e sobe
      final currentAngle = fanAngle * (1.0 - pullRatio);
      final currentY = basePeekY + pullDelta;
      final currentScale = baseScale + (1.0 - baseScale) * pullRatio;

      final capturedRank = rank;

      cards.add(
        Positioned(
          bottom: 0,
          // Centralizar horizontalmente para permitir rotação correta
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragStart: (d) {
              setState(() {
                _draggingRank = capturedRank;
                _peekDrag[capturedRank] = 0;
              });
            },
            onVerticalDragUpdate: (d) {
              if (_draggingRank == capturedRank) {
                setState(() {
                  final prev = _peekDrag[capturedRank] ?? 0.0;
                  _peekDrag[capturedRank] = (prev + d.delta.dy).clamp(
                    -_cardHeight * 0.85,
                    20.0,
                  );
                });
              }
            },
            onVerticalDragEnd: (d) {
              if (_draggingRank != capturedRank) return;
              final drag = _peekDrag[capturedRank] ?? 0.0;
              final velocity = d.primaryVelocity ?? 0;
              if (drag < -50 || velocity < -400) {
                // Promote
                setState(() {
                  _topIndex = idx;
                  _peekDrag.clear();
                  _draggingRank = null;
                });
                widget.onCardTap(widget.wallets[idx]);
                HapticFeedback.mediumImpact();
              } else {
                // Snap back
                setState(() {
                  _peekDrag.remove(capturedRank);
                  _draggingRank = null;
                });
              }
            },
            onTap: _openCarousel,
            child: Transform(
              alignment: Alignment
                  .bottomCenter, // Rotação a partir da base (como segurar baralho na mão)
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, currentY, 0.0)
                ..multiply(
                  Matrix4.diagonal3Values(currentScale, currentScale, 1.0),
                )
                ..rotateZ(currentAngle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  WalletCreditCard(
                    wallet: wallet,
                    colorIndex: idx,
                    isSelected: false,
                    onTap: _openCarousel,
                  ),
                  if (pullRatio > 0.05)
                    Positioned(
                      top: 24,
                      child: Opacity(
                        opacity: pullRatio.clamp(0.0, 1.0),
                        child: Text(
                          wallet.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Front Card
    final swipeProgress = _swipeAnim.value;
    // Swipe move card down (positive Y) e fade out
    final swipeOffsetY = swipeProgress * (_cardHeight + 100);
    final swipeOpacity = (1.0 - swipeProgress).clamp(0.0, 1.0);
    final dragOffsetY = _isDragging
        ? _dragDeltaY.clamp(-_cardHeight, 0.0)
        : 0.0;

    // Cartão da frente não roda, fica reto
    cards.add(
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onVerticalDragStart: (d) {
            _dragStartY = d.globalPosition.dy;
            setState(() {
              _isDragging = true;
              _dragDeltaY = 0;
            });
          },
          onVerticalDragUpdate: (d) {
            final delta = d.globalPosition.dy - _dragStartY;
            setState(() {
              _dragDeltaY = delta.clamp(-_cardHeight, 20.0);
            });
          },
          onVerticalDragEnd: (d) {
            final velocity = d.primaryVelocity ?? 0; // Negative = up
            // Swipe UP to cycle
            if (_dragDeltaY < -50 || velocity < -400) {
              setState(() {
                _isDragging = false;
              });
              _cycleToNext();
            } else {
              setState(() {
                _isDragging = false;
                _dragDeltaY = 0;
              });
            }
          },
          onTap: _openCarousel,
          child: Transform.translate(
            offset: Offset(0, dragOffsetY + swipeOffsetY),
            child: Opacity(
              opacity: swipeOpacity,
              child: Transform(
                // Cartão da frente tem leve "pop" se estiver sendo tocado (opcional)
                transform: Matrix4.identity(),
                alignment: Alignment.center,
                child: WalletCreditCard(
                  wallet: widget.wallets[_topIndex],
                  colorIndex: _topIndex,
                  isSelected: true,
                  onTap: _openCarousel,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return cards;
  }

  // ─── CAROUSEL VIEW ───────────────────────────────────────────────────────

  Widget _buildCarousel(double progress) {
    return Opacity(
      opacity: progress,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.wallets.length,
        onPageChanged: (i) {
          setState(() => _carouselPage = i);
          HapticFeedback.selectionClick();
        },
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _closeCarousel(i),
            child: Center(
              child: WalletCreditCard(
                wallet: widget.wallets[i],
                colorIndex: i,
                isSelected: i == _carouselPage,
                onTap: () => _closeCarousel(i),
              ),
            ),
          );
        },
      ),
    );
  }
}
