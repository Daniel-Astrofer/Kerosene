import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

/// Curva de easing customizada: cubic-bezier(0.22, 0.61, 0.36, 1)
const _releaseEasing = Cubic(0.22, 0.61, 0.36, 1.0);

/// DraggableCard3D - Card com animação 3D otimizada para 120fps
/// Arraste para cima para mover o card com perspectiva 3D
class DraggableCard3D extends StatefulWidget {
  final Widget child;
  final List<Widget>? backgroundCards; // Cartões que ficam atrás
  final double initialHeight;
  final VoidCallback? onDragComplete;
  final VoidCallback? onDragCancel;
  final Curve releaseCurve;

  const DraggableCard3D({
    required this.child,
    this.backgroundCards,
    this.initialHeight = 300,
    this.onDragComplete,
    this.onDragCancel,
    this.releaseCurve = _releaseEasing,
    super.key,
  });

  @override
  State<DraggableCard3D> createState() => _DraggableCard3DState();
}

class _DraggableCard3DState extends State<DraggableCard3D>
    with TickerProviderStateMixin {
  // ValueNotifiers para máxima eficiência (zero rebuilds)
  late ValueNotifier<double> _dragProgress;
  late ValueNotifier<bool> _isAnimatingRelease;

  // Controllers para animação de release
  late AnimationController _releaseController;

  // Variáveis de tracking do gesto
  double _dragStartY = 0;
  double _maxDragDistance = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // Força 120fps se disponível
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Otimização: Solicita ao scheduler prioridade máxima
        SchedulerBinding.instance.ensureVisualUpdate();
      }
    });

    _dragProgress = ValueNotifier<double>(0);
    _isAnimatingRelease = ValueNotifier<bool>(false);

    _releaseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      animationBehavior: AnimationBehavior.preserve, // Mantém 120fps mesmo em baixa energia
    )..addListener(() {
      _dragProgress.value = _releaseController.value;
    });
  }

  @override
  void dispose() {
    _dragProgress.dispose();
    _isAnimatingRelease.dispose();
    _releaseController.dispose();
    super.dispose();
  }

  /// Calcula distância máxima baseada em altura inicial
  void _calculateMaxDragDistance() {
    _maxDragDistance = widget.initialHeight * 1.5;
  }

  /// Callback: User started dragging
  void _onVerticalDragDown(DragDownDetails details) {
    _calculateMaxDragDistance();
    _dragStartY = details.globalPosition.dy;
    _isDragging = true;
    _releaseController.stop();
    _isAnimatingRelease.value = false;
  }

  /// Callback: User is dragging
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final currentY = details.globalPosition.dy;
    final dragDistance = _dragStartY - currentY; // Positivo = cima
    final progress = (dragDistance / _maxDragDistance).clamp(0.0, 1.0);

    // Update direto no ValueNotifier (sem rebuild via setState)
    _dragProgress.value = progress;
  }

  /// Callback: User stopped dragging
  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final currentProgress = _dragProgress.value;

    if (currentProgress < 0.5) {
      // Volta ao estado inicial
      _isAnimatingRelease.value = true;
      _releaseController.value = currentProgress;
      _releaseController.animateBack(
        0, 
        duration: const Duration(milliseconds: 400),
        curve: widget.releaseCurve,
      ).then((_) {
        _isAnimatingRelease.value = false;
        widget.onDragCancel?.call();
      });
    } else {
      // Completa a animação (vai para trás)
      _isAnimatingRelease.value = true;
      _releaseController.value = currentProgress;
      _releaseController.animateTo(
        1.0, 
        duration: const Duration(milliseconds: 500),
        curve: widget.releaseCurve,
      ).then((_) {
        _isAnimatingRelease.value = false;
        widget.onDragComplete?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Melhora detecção de toque para 120fps
      onVerticalDragDown: _onVerticalDragDown,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: ValueListenableBuilder<double>(
        valueListenable: _dragProgress,
        builder: (context, progress, child) {
          final background = widget.backgroundCards ?? [];

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Renderiza de forma condicional: se progress > 0.5, card principal vai para trás
              if (progress <= 0.5) ...[
                // Cartões de fundo que vêm para frente
                ...List.generate(background.length, (index) {
                  final reversedIndex = background.length - 1 - index;
                  final logicalIndex = reversedIndex + 1;

                  return _BackgroundCardTransform(
                    progress: progress,
                    logicalIndex: logicalIndex,
                    child: background[reversedIndex],
                  );
                }),

                // Cartão principal sendo arrastado (renderizado por cima)
                _Card3DTransform(
                  progress: progress,
                  child: child!,
                ),
              ] else ...[
                // Cartão principal vai para trás primeiro
                _Card3DTransform(
                  progress: progress,
                  child: child!,
                ),

                // Depois os cartões de fundo por cima
                ...List.generate(background.length, (index) {
                  final reversedIndex = background.length - 1 - index;
                  final logicalIndex = reversedIndex + 1;

                  return _BackgroundCardTransform(
                    progress: progress,
                    logicalIndex: logicalIndex,
                    child: background[reversedIndex],
                  );
                }),
              ],
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Widget que aplica transformações nos cartões de fundo
class _BackgroundCardTransform extends StatelessWidget {
  final double progress;
  final int logicalIndex; // 1 = logo atrás do principal, 2 = atrás do 1, etc.
  final Widget child;

  const _BackgroundCardTransform({
    required this.progress,
    required this.logicalIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Estado inicial (progress = 0)
    // Google Pay style: cards are stacked with a small vertical offset (top edges visible)
    final double sScale = 1.0 - (logicalIndex * 0.03);
    final double sTranslateY = logicalIndex * 20.0;
    final double sOpacity = (1.0 - (logicalIndex * 0.15)).clamp(0.0, 1.0);

    // Estado final (progress = 1) - cada card assume a posição do card à sua frente
    final double eScale = 1.0 - ((logicalIndex - 1) * 0.03);
    final double eTranslateY = (logicalIndex - 1) * 20.0;
    final double eOpacity = (1.0 - ((logicalIndex - 1) * 0.15)).clamp(0.0, 1.0);

    // Interpolação linear simples
    final double scale = sScale + (eScale - sScale) * progress;
    final double translateY = sTranslateY + (eTranslateY - sTranslateY) * progress;
    final double opacity = sOpacity + (eOpacity - sOpacity) * progress;

    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transformHitTests: false, // Otimização para 120fps
        transform: Matrix4.identity()
          ..setTranslationRaw(0.0, translateY, 0.0)
          ..scale(scale, scale, 1.0),
        child: Opacity(
          opacity: opacity,
          alwaysIncludeSemantics: false, // Otimização para 120fps
          child: child,
        ),
      ),
    );
  }
}

/// Widget que aplica transformações 3D otimizadas
class _Card3DTransform extends StatelessWidget {
  final double progress; // 0 = início, 1 = final
  final Widget child;

  const _Card3DTransform({
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Animação refinada: Sobe, inclina para a direita e desce para o fundo
    
    // Pré-calculando valores comuns
    final double piProgress = progress * math.pi;
    final double sinProgress = math.sin(piProgress);

    // Movimento vertical: Sobe até -200 e depois desce para a posição de fundo
    // O movimento de "subir" acontece nos primeiros 50% do progresso
    double translateY;
    if (progress < 0.5) {
      translateY = -200.0 * (progress / 0.5);
    } else {
      translateY = -200.0 + (220.0 * (progress - 0.5) / 0.5);
    }

    // Movimento horizontal: Leve desvio para a direita (30px)
    final double translateX = 40.0 * sinProgress;

    // Escala: Diminui suavemente até 0.85 (para não ficar pequeno demais)
    final double scale = 1.0 - (0.15 * progress);

    // Rotação: Inclina para a direita no eixo Y e Z
    final double rotationX = -0.2 * sinProgress; 
    final double rotationY = 0.3 * sinProgress;  // Inclina para a direita
    final double rotationZ = 0.1 * sinProgress;  // Leve giro lateral

    // Opacidade: Mantém opaco no início, e quando vai para trás (progress > 0.7) fica completamente opaco
    final double opacity = progress > 0.7 ? 1.0 : 1.0;

    // Sombra estática otimizada
    final BoxShadow optimizedShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    );

    return RepaintBoundary(
      child: Transform(
        alignment: Alignment.center,
        transformHitTests: false, // Otimização para 120fps
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..setTranslationRaw(translateX, translateY, progress * -100) // Adiciona profundidade Z real
          ..scale(scale, scale, 1.0)
          ..rotateX(rotationX)
          ..rotateY(rotationY)
          ..rotateZ(rotationZ),
        child: Opacity(
          opacity: opacity,
          alwaysIncludeSemantics: false, // Otimização para 120fps
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [optimizedShadow],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
