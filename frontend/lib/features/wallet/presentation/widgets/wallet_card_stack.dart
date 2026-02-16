import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/wallet.dart';
import 'wallet_card.dart';

class WalletCardStack extends StatefulWidget {
  final List<Wallet> wallets;
  final Function(int) onIndexChanged;
  final Function(Wallet) onCardTap;
  final VoidCallback? onNfcPressed;
  final VoidCallback? onQrPressed;
  final VoidCallback? onAddressCopied;

  const WalletCardStack({
    super.key,
    required this.wallets,
    required this.onIndexChanged,
    required this.onCardTap,
    this.onNfcPressed,
    this.onQrPressed,
    this.onAddressCopied,
  });

  @override
  State<WalletCardStack> createState() => _WalletCardStackState();
}

class _WalletCardStackState extends State<WalletCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;

  // Curva ultra suave
  static const Curve _ultraSmooth = Cubic(0.16, 1.0, 0.3, 1.0);

  // Notifiers e rastreamento de velocidade
  final ValueNotifier<double> _dragY = ValueNotifier(0);
  final VelocityTracker _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  double _launchSpin = 0;

  bool _isAnimating = false;
  int _topIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: _ultraSmooth,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishCardSwap();
      }
    });
  }

  void _finishCardSwap() {
    _isAnimating = false;
    _dragY.value = 0;
    _controller.reset();

    _topIndex = (_topIndex + 1) % widget.wallets.length;
    widget.onIndexChanged(_topIndex);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _dragY.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isAnimating || widget.wallets.length <= 1) return;
    _velocityTracker.addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isAnimating || widget.wallets.length <= 1) return;

    _velocityTracker.addPosition(event.timeStamp, event.position);
    double dy = event.delta.dy;

    // Resistência ao puxar para baixo
    if (_dragY.value > 0 && dy > 0) dy *= 0.22;

    final next = (_dragY.value + dy).clamp(-360.0, 50.0);
    _dragY.value = next;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isAnimating || widget.wallets.length <= 1) return;

    final drag = _dragY.value;
    final velocity = _velocityTracker.getVelocity();
    final v = velocity.pixelsPerSecond.dy;
    
    _launchSpin = (v.abs() / 9000).clamp(0.0, 0.12);

    final shouldLaunch = (drag < -90) || (v < -800);

    if (shouldLaunch) {
      _isAnimating = true;

      double velocityFactor = (v.abs() / 2400).clamp(0.0, 0.4);
      _controller.duration = Duration(
        milliseconds: (620 * (1 - velocityFactor)).toInt(),
      );

      _controller.forward();
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    if (_dragY.value == 0) return;

    _isAnimating = true;

    final start = _dragY.value;
    final backController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final anim = CurvedAnimation(
      parent: backController,
      curve: Curves.easeOutBack,
    );

    anim.addListener(() {
      _dragY.value = start * (1 - anim.value);
    });

    backController.forward().then((_) {
      _isAnimating = false;
      backController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wallets.isEmpty) return const SizedBox.shrink();

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 340,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_dragY, _animation]),
          builder: (context, _) {
            final t = _animation.value;
            final drag = _dragY.value;

            final absDrag = drag.abs();
            final gestureT = (absDrag / 300).clamp(0.0, 1.0);
            final backT = (absDrag / 200).clamp(0.0, 0.35);

            final cardsCount = widget.wallets.length;
            
            // Geramos os índices e ordenamos para que o logicalIndex 0 fique no topo (último no Stack)
            final indices = List.generate(cardsCount, (index) => index);
            indices.sort((a, b) {
              final logicalA = (a - _topIndex + cardsCount) % cardsCount;
              final logicalB = (b - _topIndex + cardsCount) % cardsCount;
              
              // Durante a troca (t > 0.5), o card 0 vai para o fundo
              if (_isAnimating && t > 0.5) {
                if (logicalA == 0) return -1;
                if (logicalB == 0) return 1;
              }
              return logicalB.compareTo(logicalA);
            });

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: indices.map((i) {
                final logicalIndex = (i - _topIndex + cardsCount) % cardsCount;

                // Mostra só os 4 primeiros para performance
                if (logicalIndex > 3 && !(_isAnimating && logicalIndex == 0)) {
                   return const SizedBox.shrink();
                }

                double y = 0;
                double scale = 1;
                double rotX = 0;
                double rotZ = 0;
                double z = 0;
                double opacity = 1;

                if (logicalIndex == 0) {
                  // CARD PRINCIPAL
                  if (_isAnimating) {
                    if (t < 0.5) {
                      final x = t * 2;
                      y = drag + (-340 - drag) * x;
                      rotX = -0.72 * x;
                      rotZ = _launchSpin * (drag < 0 ? -1 : 1) * x;
                      z = -180 * x;
                      scale = 1 - 0.15 * x;
                    } else {
                      final x = (t - 0.5) * 2;
                      y = -340 + 380 * x;
                      rotX = -0.72 * (1 - x);
                      rotZ = _launchSpin * (1 - x);
                      z = -180 + 130 * x;
                      scale = 0.85 + 0.03 * x;
                      opacity = 1 - 0.5 * x;
                    }
                  } else {
                    y = drag;
                    final p = gestureT;

                    if (drag < 0) {
                      rotX = -0.55 * p;
                      rotZ = (drag / 1200);
                      z = -140 * p;
                      scale = 1 - 0.13 * p;
                    }
                  }
                } else {
                  // BACK CARDS
                  final baseScale = 1 - (logicalIndex * 0.055);
                  final baseY = logicalIndex * 20.0;
                  final baseZ = logicalIndex * -40.0;

                  final endScale = 1 - ((logicalIndex - 1) * 0.055);
                  final endY = (logicalIndex - 1) * 20.0;
                  final endZ = (logicalIndex - 1) * -40.0;

                  if (_isAnimating) {
                    final x = Curves.easeOut.transform(t);
                    scale = baseScale + (endScale - baseScale) * x;
                    y = baseY + (endY - baseY) * x;
                    z = baseZ + (endZ - baseZ) * x;
                    opacity = (1 - logicalIndex * 0.12 + 0.1 * t).clamp(0.0, 1.0);
                  } else {
                    scale = baseScale + (endScale - baseScale) * backT;
                    y = baseY + (endY - baseY) * backT;
                    z = baseZ + (endZ - baseZ) * backT;
                    opacity = 1 - logicalIndex * 0.12;
                  }
                }

                return Transform(
                  key: ValueKey(widget.wallets[i].id),
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..translate(0.0, y, z)
                    ..rotateX(rotX)
                    ..rotateZ(rotZ)
                    ..scale(scale),
                  alignment: Alignment.center,
                  transformHitTests: true,
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: WalletCard(
                        wallet: widget.wallets[i],
                        isSelected: logicalIndex == 0,
                        tilt: rotX,
                        colorIndex: i,
                        onNfcPressed: widget.onNfcPressed,
                        onQrPressed: widget.onQrPressed,
                        onAddressCopied: widget.onAddressCopied,
                        onTap: logicalIndex == 0 && !_isAnimating
                            ? () => widget.onCardTap(widget.wallets[i])
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
