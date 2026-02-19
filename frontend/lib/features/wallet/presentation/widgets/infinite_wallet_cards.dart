import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/wallet.dart';
import 'wallet_credit_card.dart';

class InfiniteCardsController {
  _InfiniteWalletCardsState? _state;

  void _bind(_InfiniteWalletCardsState state) {
    _state = state;
  }

  void next() {
    _state?.next();
  }

  void reset() {
    _state?.reset();
  }
}

class InfiniteWalletCards extends StatefulWidget {
  final List<Wallet> wallets;
  final InfiniteCardsController? controller;
  final Function(Wallet) onCardTap;
  final int initialIndex;

  const InfiniteWalletCards({
    super.key,
    required this.wallets,
    this.controller,
    required this.onCardTap,
    this.initialIndex = 0,
  });

  @override
  State<InfiniteWalletCards> createState() => _InfiniteWalletCardsState();
}

class _InfiniteWalletCardsState extends State<InfiniteWalletCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<int> _visualIndices;

  int? _draggedVisualRank;
  double _rawDragAccumulator = 0.0;

  /// true = pull UP (bring-to-front), false = pull DOWN (send-to-back)
  bool _isDragUp = true;

  // ── PARALLAX STATE ──────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _tiltX = 0.0; // Rotation around X-axis (up/down tilt)
  double _tiltY = 0.0; // Rotation around Y-axis (left/right tilt)
  static const double _maxTilt = 0.25; // Max tilt in radians (~14 degrees)
  static const double _smoothing = 0.15; // Smoothing factor for motion

  // DRAG CONSTANTS
  static const double _cardHeight = 170.0;
  static const double _peekOffset = 15.0;
  static const double _totalTravel = 350.0;

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(this);
    _initializeIndices();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _initAccelerometer();
  }

  void _initAccelerometer() {
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Accelerometer gives absolute orientation relative to gravity (~9.8 m/s^2)
          // X: sideways tilt, Y: forward/backward tilt
          // We normalize and apply a target tilt factor
          double targetTiltX =
              (event.y / 9.8) * 0.35; // Map Y to X-axis rotation
          double targetTiltY =
              (-event.x / 9.8) * 0.35; // Map X to Y-axis rotation

          _tiltX = _tiltX * (1.0 - _smoothing) + targetTiltX * _smoothing;
          _tiltY = _tiltY * (1.0 - _smoothing) + targetTiltY * _smoothing;

          // Clamp for safety
          _tiltX = _tiltX.clamp(-_maxTilt, _maxTilt);
          _tiltY = _tiltY.clamp(-_maxTilt, _maxTilt);
        });
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InfiniteWalletCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallets != widget.wallets && widget.wallets.isNotEmpty) {
      _initializeIndices();
    }
  }

  void _initializeIndices() {
    if (widget.wallets.isEmpty) {
      _visualIndices = [];
    } else {
      _visualIndices = List.generate(widget.wallets.length, (i) => i);
      if (widget.initialIndex > 0 &&
          widget.initialIndex < widget.wallets.length) {
        final temp = _visualIndices[0];
        _visualIndices[0] = _visualIndices[widget.initialIndex];
        _visualIndices[widget.initialIndex] = temp;
      }
    }
  }

  void next() {
    if (_visualIndices.length > 1 && !_animController.isAnimating) {
      _draggedVisualRank = 1;
      _isDragUp = true;
      _animController.animateTo(1.0, curve: Curves.easeInOut).then((_) {
        _finalizeCardSwap(_draggedVisualRank!);
      });
    }
  }

  void reset() {
    setState(() {
      _initializeIndices();
    });
  }

  // ── BRING-TO-FRONT: Move card at [rank] to index 0 ──
  void _finalizeCardSwap(int rank) {
    HapticFeedback.lightImpact(); // Tactile "click" on swap
    setState(() {
      if (_visualIndices.isNotEmpty && rank < _visualIndices.length) {
        final int moved = _visualIndices.removeAt(rank);
        _visualIndices.insert(0, moved);
      }
      _draggedVisualRank = null;
      _rawDragAccumulator = 0.0;
      _isDragUp = true;
      _animController.value = 0.0;
    });
  }

  // ── SEND-TO-BACK: Move card at rank 0 to the last index ──
  void _finalizeSendToBack() {
    HapticFeedback.lightImpact(); // Tactile "click" on send-to-back
    setState(() {
      if (_visualIndices.isNotEmpty) {
        final int moved = _visualIndices.removeAt(0);
        _visualIndices.add(moved);
      }
      _draggedVisualRank = null;
      _rawDragAccumulator = 0.0;
      _isDragUp = true;
      _animController.value = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_visualIndices.isEmpty && widget.wallets.isNotEmpty) {
      _initializeIndices();
    }

    final int n = _visualIndices.length;
    final double frontCardY = max(0, n - 1) * _peekOffset;
    final double stackHeight = frontCardY + _cardHeight + 100;

    return SizedBox(
      height: stackHeight,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: _buildCards(),
          );
        },
      ),
    );
  }

  List<Widget> _buildCards() {
    final List<Widget> cards = [];
    final double t = _animController.value;
    final int n = _visualIndices.length;

    // Draw Order: Back to Front [N-1 ... 0]
    List<int> drawOrder = List.generate(n, (i) => n - 1 - i);

    // DYNAMIC Z-INDEX LOGIC
    if (_draggedVisualRank != null) {
      if (_isDragUp) {
        // Pull UP: Promote dragged card to top only after clearing stack
        if (t > 0.45) {
          drawOrder.remove(_draggedVisualRank!);
          drawOrder.add(_draggedVisualRank!);
        }
      } else {
        // Pull DOWN: Front card (rank 0) goes behind all once it dips below stack
        if (t > 0.45) {
          drawOrder.remove(0);
          drawOrder.insert(0, 0); // Paint first = behind everything
        }
      }
    }

    for (int rank in drawOrder) {
      final int walletIdx = _visualIndices[rank];
      final wallet = widget.wallets[walletIdx];

      double startScale = 1.0 - (rank * 0.05);
      double startY = (n - 1 - rank) * _peekOffset;

      double scale = startScale;
      double y = startY;
      double rotationX = 0.0;

      // ── CHOREOGRAPHY ──────────────────────────────────────────

      if (_draggedVisualRank != null) {
        if (_isDragUp) {
          // ═══════════════════════════════════════════════════
          // PULL UP: Bring card to front (existing logic)
          // ═══════════════════════════════════════════════════
          int dragged = _draggedVisualRank!;

          if (rank == dragged) {
            // Phase 1: 0.0 - 0.45 (Lift Vertical - Behind Stack)
            if (t <= 0.45) {
              double progress = t / 0.45;
              y = lerpDouble(startY, startY - 220, progress)!;
              rotationX = 0.0;
              scale = lerpDouble(startScale, 1.05, progress)!;
            }
            // Phase 2: 0.45 - 0.7 (Switch Layer, Tilt Back & Fly Over)
            else if (t <= 0.7) {
              double progress = (t - 0.45) / 0.25;
              double liftedY = startY - 220;
              double targetY = (n - 1) * _peekOffset;
              y = lerpDouble(liftedY, targetY - 60, progress)!;
              rotationX = lerpDouble(0.0, -1.5, progress)!;
              scale = 1.05;
            }
            // Phase 3: 0.7 - 1.0 (Forward Landing)
            else {
              double progress = (t - 0.7) / 0.3;
              double targetY = (n - 1) * _peekOffset;
              y = lerpDouble(targetY - 60, targetY, progress)!;
              rotationX = lerpDouble(-1.5, 0.0, progress)!;
              scale = lerpDouble(1.05, 1.0, progress)!;
            }
          } else if (rank < dragged) {
            // Cards being pushed down
            if (t > 0.6) {
              double progress = (t - 0.6) / 0.4;
              double endY = (n - 1 - (rank + 1)) * _peekOffset;
              double endScale = 1.0 - ((rank + 1) * 0.05);
              y = lerpDouble(startY, endY, progress)!;
              scale = lerpDouble(startScale, endScale, progress)!;
            }
          }
        } else {
          // ═══════════════════════════════════════════════════
          // PULL DOWN: Send front card to back (REVERSE)
          // ═══════════════════════════════════════════════════

          if (rank == 0) {
            // Front card being sent to back
            double frontY = (n - 1) * _peekOffset; // Current front position
            double backY = 0.0; // Back position (top of stack)
            double backScale = 1.0 - ((n - 1) * 0.05);

            // Phase 1: 0.0 - 0.45 (Drop Down - Still in Front)
            if (t <= 0.45) {
              double progress = t / 0.45;
              y = lerpDouble(frontY, frontY + 220, progress)!;
              rotationX = 0.0;
              scale = lerpDouble(1.0, 0.95, progress)!;
            }
            // Phase 2: 0.45 - 0.7 (Tilt Forward & Fly Behind)
            else if (t <= 0.7) {
              double progress = (t - 0.45) / 0.25;
              double droppedY = frontY + 220;
              y = lerpDouble(droppedY, backY + 60, progress)!;
              rotationX = lerpDouble(
                0.0,
                1.5,
                progress,
              )!; // Forward tilt (positive)
              scale = 0.95;
            }
            // Phase 3: 0.7 - 1.0 (Settle into Back)
            else {
              double progress = (t - 0.7) / 0.3;
              y = lerpDouble(backY + 60, backY, progress)!;
              rotationX = lerpDouble(1.5, 0.0, progress)!;
              scale = lerpDouble(0.95, backScale, progress)!;
            }
          } else {
            // All other cards shift UP (promote by one rank)
            if (t > 0.6) {
              double progress = (t - 0.6) / 0.4;
              double newRank = rank - 1;
              double endY = (n - 1 - newRank) * _peekOffset;
              double endScale = 1.0 - (newRank * 0.05);
              y = lerpDouble(startY, endY, progress)!;
              scale = lerpDouble(startScale, endScale, progress)!;
            }
          }
        }
      }

      bool showDetails = (rank == 0 || (rank == _draggedVisualRank && t > 0.3));
      double elevation = (rank < 3 || rank == _draggedVisualRank)
          ? (rank == 0 ? 1.0 : 0.0)
          : -1.0;

      // Fix Elevation for dragged card
      if (_isDragUp && rank == _draggedVisualRank) {
        elevation = (t > 0.45) ? 1.0 : 0.0;
      }
      if (!_isDragUp && rank == 0) {
        elevation = (t > 0.45) ? 0.0 : 1.0; // Lose elevation as it goes behind
      }

      cards.add(
        Positioned(
          top: y,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragStart: (d) => _onDragStart(d, rank),
            onVerticalDragUpdate: (d) => _onDragUpdate(d, rank),
            onVerticalDragEnd: (d) => _onDragEnd(d, rank),
            onTap: () => _onTap(rank, wallet),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(rotationX + _tiltX)
                ..rotateY(_tiltY)
                ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
              child: RepaintBoundary(
                child: _wrapWithDepth(
                  rank: rank,
                  n: n,
                  isDragged:
                      rank == _draggedVisualRank || (!_isDragUp && rank == 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: WalletCreditCard(
                      wallet: wallet,
                      colorIndex: walletIdx,
                      isSelected:
                          rank == 0 &&
                          !(!_isDragUp && _draggedVisualRank != null),
                      elevation: elevation,
                      showDetails: showDetails,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return cards;
  }

  /// Wraps back cards in a ShaderMask gradient for visual depth focus.
  /// Front card and dragged cards pass through untouched.
  Widget _wrapWithDepth({
    required int rank,
    required int n,
    required bool isDragged,
    required Widget child,
  }) {
    // Front card or actively dragged card: no overlay
    if (rank == 0 || isDragged) return child;

    // Depth opacity scales with rank (further back = darker)
    final double depthOpacity = (rank * 0.15).clamp(0.0, 0.5);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 1.0 - depthOpacity),
          ],
          stops: const [0.3, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }

  void _onDragStart(DragStartDetails d, int rank) {
    if (_animController.isAnimating) return;

    if (rank == 0) {
      // Front card: could go either direction, we'll decide in _onDragUpdate
      _animController.stop();
      setState(() {
        _draggedVisualRank = 0;
        _isDragUp = true; // Default, will be decided on first delta
        _rawDragAccumulator = 0.0;
      });
    } else if (rank > 0) {
      // Back card: always pull UP
      _animController.stop();
      setState(() {
        _draggedVisualRank = rank;
        _isDragUp = true;
        _rawDragAccumulator = 0.0;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails d, int rank) {
    if (_draggedVisualRank == null) return;

    double oldProgress = _animController.value;

    setState(() {
      _rawDragAccumulator += d.delta.dy;

      // Determine direction on first meaningful delta
      if (_draggedVisualRank == 0 && oldProgress < 0.01) {
        _isDragUp = _rawDragAccumulator < 0;
      }

      double progress;
      if (_isDragUp) {
        // Pull UP: negative delta = progress
        progress = (_rawDragAccumulator / -_totalTravel).clamp(0.0, 1.0);

        // If front card is being dragged UP, proxy to rank 1
        if (_draggedVisualRank == 0 && _visualIndices.length > 1) {
          _draggedVisualRank = 1;
        }
      } else {
        // Pull DOWN: positive delta = progress
        progress = (_rawDragAccumulator / _totalTravel).clamp(0.0, 1.0);
      }

      _animController.value = progress;

      // HAPTIC FEEDBACK at layer switch
      if (oldProgress < 0.45 && progress >= 0.45) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _onDragEnd(DragEndDetails d, int rank) {
    if (_draggedVisualRank == null) return;

    bool fastFlick;
    if (_isDragUp) {
      fastFlick = (d.primaryVelocity ?? 0) < -600;
    } else {
      fastFlick = (d.primaryVelocity ?? 0) > 600;
    }

    if (_animController.value > 0.4 || fastFlick) {
      _animController.animateTo(1.0, curve: Curves.easeOutBack).then((_) {
        if (_isDragUp) {
          _finalizeCardSwap(_draggedVisualRank!);
        } else {
          _finalizeSendToBack();
        }
      });
    } else {
      _animController.animateTo(0.0, curve: Curves.bounceOut).then((_) {
        setState(() {
          _draggedVisualRank = null;
          _rawDragAccumulator = 0.0;
          _isDragUp = true;
        });
      });
    }
  }

  void _onTap(int rank, Wallet wallet) {
    if (rank == 0) {
      widget.onCardTap(wallet);
    } else if (rank > 0) {
      _draggedVisualRank = rank;
      _isDragUp = true;
      _animController.forward(from: 0).then((_) {
        _finalizeCardSwap(rank);
      });
    }
  }
}
