import 'package:flutter/material.dart';

/// Curva de easing para transições suaves: cubic-bezier(0.22, 0.61, 0.36, 1)
const _defaultEasing = Cubic(0.22, 0.61, 0.36, 1.0);

/// HorizontalCardSwap3D - Animação de swap de cartões com profundidade 3D.
/// Ideal para simular uma carteira física trocando cartões.
class HorizontalCardSwap3D extends StatefulWidget {
  final List<Widget> cards;
  final int initialIndex;
  final Function(int)? onIndexChanged;
  final double cardWidth;
  final double cardHeight;

  const HorizontalCardSwap3D({
    super.key,
    required this.cards,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.cardWidth = 320,
    this.cardHeight = 200,
  });

  @override
  State<HorizontalCardSwap3D> createState() => _HorizontalCardSwap3DState();
}

class _HorizontalCardSwap3DState extends State<HorizontalCardSwap3D>
    with TickerProviderStateMixin {
  late ValueNotifier<double> _dragOffset;
  late AnimationController _swapController;
  late int _currentIndex;

  // Variáveis para controle de gesto
  double _startX = 0;
  bool _isDragging = false;
  static const double _swapThreshold = 0.35; // 35% do card width para swap

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex % widget.cards.length;
    _dragOffset = ValueNotifier<double>(0.0);

    _swapController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _dragOffset.dispose();
    _swapController.dispose();
    super.dispose();
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    if (_swapController.isAnimating) return;
    _startX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final currentX = details.globalPosition.dx;
    final delta = currentX - _startX;

    // Normaliza o offset (de -1.0 a 1.0 relativo à largura do card)
    _dragOffset.value = (delta / widget.cardWidth).clamp(-1.2, 1.2);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final offset = _dragOffset.value;
    final velocity = details.primaryVelocity ?? 0;

    // Se arrastou o suficiente ou a velocidade foi alta
    if (offset.abs() > _swapThreshold || velocity.abs() > 800) {
      final direction = offset > 0 || velocity > 800 ? 1 : -1;
      _performSwap(direction);
    } else {
      _resetPosition();
    }
  }

  void _performSwap(int direction) {
    // direction: 1 = swipe para a direita (anterior), -1 = swipe para a esquerda (próximo)
    final targetOffset = direction.toDouble();

    final animation = Tween<double>(
      begin: _dragOffset.value,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _swapController, curve: _defaultEasing));

    void listener() {
      _dragOffset.value = animation.value;
    }

    animation.addListener(listener);
    _swapController.forward(from: 0).then((_) {
      animation.removeListener(listener);
      _swapController.reset();

      setState(() {
        if (direction > 0) {
          _currentIndex =
              (_currentIndex - 1 + widget.cards.length) % widget.cards.length;
        } else {
          _currentIndex = (_currentIndex + 1) % widget.cards.length;
        }
      });

      _dragOffset.value = 0;
      widget.onIndexChanged?.call(_currentIndex);
    });
  }

  void _resetPosition() {
    final animation = Tween<double>(begin: _dragOffset.value, end: 0.0).animate(
      CurvedAnimation(parent: _swapController, curve: ElasticOutCurve(0.8)),
    );

    void listener() {
      _dragOffset.value = animation.value;
    }

    animation.addListener(listener);
    _swapController.forward(from: 0).then((_) {
      animation.removeListener(listener);
      _swapController.reset();
      _dragOffset.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragDown: _onHorizontalDragDown,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.cardWidth + 100,
        height: widget.cardHeight + 100,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _dragOffset,
          builder: (context, _) {
            final offset = _dragOffset.value;
            final nextIndex = (_currentIndex + 1) % widget.cards.length;
            final prevIndex =
                (_currentIndex - 1 + widget.cards.length) % widget.cards.length;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Card Próximo (atrás, entra pela esquerda ou direita)
                if (offset < 0)
                  _buildTransformCard(
                    widget.cards[nextIndex],
                    progress: offset.abs(),
                    isEntering: true,
                    direction: -1,
                  ),
                if (offset > 0)
                  _buildTransformCard(
                    widget.cards[prevIndex],
                    progress: offset.abs(),
                    isEntering: true,
                    direction: 1,
                  ),

                // Card Atual (frente)
                _buildTransformCard(
                  widget.cards[_currentIndex],
                  progress: offset,
                  isEntering: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransformCard(
    Widget child, {
    required double progress,
    required bool isEntering,
    int direction = 1,
  }) {
    final double absProgress = progress.abs();

    // Unificação de transformações em uma única Matrix4
    // setEntry(3, 2, 0.001) é a perspectiva
    final Matrix4 matrix = Matrix4.identity()..setEntry(3, 2, 0.001);

    double opacity;
    double scale;
    double translateX;
    double rotateY;

    if (isEntering) {
      // Card que está entrando por trás
      scale = 0.8 + (0.2 * absProgress);
      opacity = (0.3 + (0.7 * absProgress)).clamp(0.0, 1.0);
      rotateY = (direction * 0.3) * (1.0 - absProgress);
      translateX = direction * widget.cardWidth * 0.1 * (1.0 - absProgress);
    } else {
      // Card principal saindo
      translateX = progress * widget.cardWidth * 1.1;
      scale = 1.0 - (0.1 * absProgress);
      rotateY = -progress * 0.4;
      opacity = (1.1 - absProgress).clamp(0.0, 1.0);
    }

    // Aplica todas as transformações de uma vez na matriz
    matrix.setTranslationRaw(translateX, 0.0, 0.0);
    matrix.scaleByDouble(scale, scale, 1.0, 1.0);
    matrix.rotateY(rotateY);

    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: widget.cardWidth,
            height: widget.cardHeight,
            child: child,
          ),
        ),
      ),
    );
  }
}
