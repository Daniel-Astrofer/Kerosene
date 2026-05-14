import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/wallet.dart';
import 'wallet_credit_card.dart';

/// A wallet card stack with premium features - Refactored
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
  int _topIndex = 0;
  bool _carouselOpen = false;

  late AnimationController _carouselController;
  late Animation<double> _carouselAnim;
  late AnimationController _swipeController;
  late Animation<double> _swipeAnim;
  late PageController _pageController;
  int _carouselPage = 0;

  double _dragStartY = 0;
  double _dragDeltaY = 0;
  bool _isDragging = false;

  final Map<int, double> _peekDrag = {};
  int? _draggingRank;

  static const double _cardHeight = 212.0;
  static const double _peekOffset = 35.0;
  static const int _maxPeek = 3;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime(0);
  static const double _shakeThreshold = 25.0;
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
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((AccelerometerEvent event) {
      final now = DateTime.now();
      if (now.difference(_lastShake) < _shakeCooldown) return;

      final absX = event.x.abs();
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final netAccel = (magnitude - 9.8).abs();

      if (_carouselOpen) {
        if (absX > 18.0) {
          _lastShake = now;
          final n = widget.wallets.length;
          if (event.x < 0) {
            final next = (_carouselPage + 1) % n;
            _pageController.animateToPage(next,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic);
            setState(() => _carouselPage = next);
          } else {
            final prev = (_carouselPage - 1 + n) % n;
            _pageController.animateToPage(prev,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic);
            setState(() => _carouselPage = prev);
          }
          HapticFeedback.selectionClick();
        }
      } else {
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
    _pageController.dispose();
    _pageController =
        PageController(initialPage: _topIndex, viewportFraction: 0.88);
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
      setState(() => _carouselOpen = false);
    });
    widget.onCardTap(widget.wallets[selectedIndex]);
    HapticFeedback.mediumImpact();
  }

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

  Widget _buildStack() {
    final n = widget.wallets.length;
    final peekCount = (n - 1).clamp(0, _maxPeek);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.1),
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

    for (int rank = peekCount; rank >= 1; rank--) {
      final idx = (_topIndex + rank) % n;
      final wallet = widget.wallets[idx];
      final double fanAngle =
          (rank * (rank % 2 == 0 ? -1 : 1) * 0.06).toDouble();
      final baseScale = 1.0 - (rank * 0.05);
      final basePeekY = -(rank * 35.0).toDouble();

      final pullDelta =
          (_peekDrag[rank] ?? 0.0).clamp(-_cardHeight * 0.85, 0.0);
      final pullRatio = (-pullDelta / (_cardHeight * 0.85)).clamp(0.0, 1.0);

      final currentAngle = fanAngle * (1.0 - pullRatio);
      final currentY = basePeekY + pullDelta;
      final currentScale = baseScale + (1.0 - baseScale) * pullRatio;
      final capturedRank = rank;

      cards.add(
        Positioned(
          bottom: 0,
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
                  _peekDrag[capturedRank] =
                      (prev + d.delta.dy).clamp(-_cardHeight * 0.85, 20.0);
                });
              }
            },
            onVerticalDragEnd: (d) {
              if (_draggingRank != capturedRank) return;
              final drag = _peekDrag[capturedRank] ?? 0.0;
              final velocity = d.primaryVelocity ?? 0;
              if (drag < -50 || velocity < -400) {
                setState(() {
                  _topIndex = idx;
                  _peekDrag.clear();
                  _draggingRank = null;
                });
                widget.onCardTap(widget.wallets[idx]);
                HapticFeedback.mediumImpact();
              } else {
                setState(() {
                  _peekDrag.remove(capturedRank);
                  _draggingRank = null;
                });
              }
            },
            onTap: _openCarousel,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, currentY, 0.0)
                ..multiply(
                    Matrix4.diagonal3Values(currentScale, currentScale, 1.0))
                ..rotateZ(currentAngle),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  WalletCreditCard(
                      wallet: wallet,
                      colorIndex: idx,
                      isSelected: false,
                      onTap: _openCarousel),
                  if (pullRatio > 0.05)
                    Positioned(
                      top: 24,
                      child: Opacity(
                        opacity: pullRatio.clamp(0.0, 1.0),
                        child: Text(
                          wallet.name.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                  blurRadius: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8))
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

    final swipeProgress = _swipeAnim.value;
    final swipeOffsetY = swipeProgress * (_cardHeight + 100);
    final swipeOpacity = (1.0 - swipeProgress).clamp(0.0, 1.0);
    final dragOffsetY =
        _isDragging ? _dragDeltaY.clamp(-_cardHeight, 0.0) : 0.0;

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
            setState(() => _dragDeltaY = delta.clamp(-_cardHeight, 20.0));
          },
          onVerticalDragEnd: (d) {
            final velocity = d.primaryVelocity ?? 0;
            if (_dragDeltaY < -50 || velocity < -400) {
              setState(() => _isDragging = false);
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
    );

    return cards;
  }

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
