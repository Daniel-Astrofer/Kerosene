import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart';
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

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(this);
    _initializeIndices();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
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
    final int count = widget.wallets.length + 1;
    _visualIndices = List.generate(count, (i) => i);

    if (widget.initialIndex >= 0 &&
        widget.initialIndex < widget.wallets.length) {
      final currentPos = _visualIndices.indexOf(widget.initialIndex);
      if (currentPos != -1) {
        final temp = _visualIndices[0];
        _visualIndices[0] = _visualIndices[currentPos];
        _visualIndices[currentPos] = temp;
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

  void _finalizeCardSwap(int rank) {
    HapticFeedback.lightImpact();
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

  void _finalizeSendToBack() {
    HapticFeedback.lightImpact();
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

    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = (screenHeight * 0.225).clamp(190.0, 210.0);
    final double peekOffset = cardHeight * 0.088;
    final double totalTravel = cardHeight * 2.05;

    final int n = _visualIndices.length;
    final double frontCardY = max(0, n - 1) * peekOffset;
    final double stackHeight = frontCardY + cardHeight + (screenHeight * 0.12);

    return SizedBox(
      height: stackHeight,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: _buildCards(cardHeight, peekOffset, totalTravel),
          );
        },
      ),
    );
  }

  List<Widget> _buildCards(
    double cardHeight,
    double peekOffset,
    double totalTravel,
  ) {
    final List<Widget> cards = [];
    final double t = _animController.value;
    final int n = _visualIndices.length;

    List<int> drawOrder = List.generate(n, (i) => n - 1 - i);

    if (_draggedVisualRank != null) {
      if (_isDragUp) {
        if (t > 0.45) {
          drawOrder.remove(_draggedVisualRank!);
          drawOrder.add(_draggedVisualRank!);
        }
      } else {
        if (t > 0.45) {
          drawOrder.remove(0);
          drawOrder.insert(0, 0);
        }
      }
    }

    for (int rank in drawOrder) {
      final int vIdx = _visualIndices[rank];
      final bool isAddCard = vIdx == widget.wallets.length;
      final wallet = isAddCard ? null : widget.wallets[vIdx];

      double startScale = 1.0 - (rank * 0.05);
      double startY = (n - 1 - rank) * peekOffset;

      double scale = startScale;
      double y = startY;
      double rotationX = 0.0;

      if (_draggedVisualRank != null) {
        if (_isDragUp) {
          int dragged = _draggedVisualRank!;
          if (rank == dragged) {
            if (t <= 0.45) {
              double progress = t / 0.45;
              y = lerpDouble(startY, startY - (cardHeight + 50), progress)!;
              rotationX = 0.0;
              scale = lerpDouble(startScale, 1.05, progress)!;
            } else if (t <= 0.7) {
              double progress = (t - 0.45) / 0.25;
              double liftedY = startY - (cardHeight + 50);
              double targetY = (n - 1) * peekOffset;
              y = lerpDouble(liftedY, targetY - 60, progress)!;
              rotationX = lerpDouble(0.0, -1.5, progress)!;
              scale = 1.05;
            } else {
              double progress = (t - 0.7) / 0.3;
              double targetY = (n - 1) * peekOffset;
              y = lerpDouble(targetY - 60, targetY, progress)!;
              rotationX = lerpDouble(-1.5, 0.0, progress)!;
              scale = lerpDouble(1.05, 1.0, progress)!;
            }
          } else if (rank < dragged) {
            if (t > 0.6) {
              double progress = (t - 0.6) / 0.4;
              double endY = (n - 1 - (rank + 1)) * peekOffset;
              double endScale = 1.0 - ((rank + 1) * 0.05);
              y = lerpDouble(startY, endY, progress)!;
              scale = lerpDouble(startScale, endScale, progress)!;
            }
          }
        } else {
          if (rank == 0) {
            double frontY = (n - 1) * peekOffset;
            double backY = 0.0;
            double backScale = 1.0 - ((n - 1) * 0.05);
            if (t <= 0.45) {
              double progress = t / 0.45;
              y = lerpDouble(frontY, frontY + (cardHeight + 50), progress)!;
              rotationX = 0.0;
              scale = lerpDouble(1.0, 0.95, progress)!;
            } else if (t <= 0.7) {
              double progress = (t - 0.45) / 0.25;
              double droppedY = frontY + (cardHeight + 50);
              y = lerpDouble(droppedY, backY + 60, progress)!;
              rotationX = lerpDouble(0.0, 1.5, progress)!;
              scale = 0.95;
            } else {
              double progress = (t - 0.7) / 0.3;
              y = lerpDouble(backY + 60, backY, progress)!;
              rotationX = lerpDouble(1.5, 0.0, progress)!;
              scale = lerpDouble(0.95, backScale, progress)!;
            }
          } else {
            if (t > 0.6) {
              double progress = (t - 0.6) / 0.4;
              double newRank = rank - 1;
              double endY = (n - 1 - newRank) * peekOffset;
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

      if (_isDragUp && rank == _draggedVisualRank) {
        elevation = (t > 0.45) ? 1.0 : 0.0;
      }
      if (!_isDragUp && rank == 0) {
        elevation = (t > 0.45) ? 0.0 : 1.0;
      }

      cards.add(
        Positioned(
          top: y,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragStart: (d) => _onDragStart(d, rank),
            onVerticalDragUpdate: (d) => _onDragUpdate(d, rank, totalTravel),
            onVerticalDragEnd: (d) => _onDragEnd(d, rank),
            onTap: () => _onTap(rank, wallet),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(rotationX)
                ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
              child: RepaintBoundary(
                child: _wrapWithDepth(
                  rank: rank,
                  n: n,
                  isDragged:
                      rank == _draggedVisualRank || (!_isDragUp && rank == 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: cardHeight,
                      child: WalletCreditCard(
                        wallet: wallet,
                        isAddCard: isAddCard,
                        colorIndex: isAddCard ? 0 : vIdx,
                        isSelected: rank == 0 &&
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
        ),
      );
    }
    return cards;
  }

  Widget _wrapWithDepth({
    required int rank,
    required int n,
    required bool isDragged,
    required Widget child,
  }) {
    if (rank == 0 || isDragged) return child;
    final double depthOpacity = (rank * 0.15).clamp(0.0, 0.5);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.onPrimary,
            Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 1.0 - depthOpacity),
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
      _animController.stop();
      setState(() {
        _draggedVisualRank = 0;
        _isDragUp = true;
        _rawDragAccumulator = 0.0;
      });
    } else if (rank > 0) {
      _animController.stop();
      setState(() {
        _draggedVisualRank = rank;
        _isDragUp = true;
        _rawDragAccumulator = 0.0;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails d, int rank, double totalTravel) {
    if (_draggedVisualRank == null) return;
    double oldProgress = _animController.value;
    setState(() {
      _rawDragAccumulator += d.delta.dy;
      if (_draggedVisualRank == 0 && oldProgress < 0.01) {
        _isDragUp = _rawDragAccumulator < 0;
      }
      double progress;
      if (_isDragUp) {
        progress = (_rawDragAccumulator / -totalTravel).clamp(0.0, 1.0);
        if (_draggedVisualRank == 0 && _visualIndices.length > 1) {
          _draggedVisualRank = 1;
        }
      } else {
        progress = (_rawDragAccumulator / totalTravel).clamp(0.0, 1.0);
      }
      _animController.value = progress;
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

  void _onTap(int rank, Wallet? wallet) {
    if (rank == 0) {
      if (wallet == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BitcoinAccountsScreen()),
        );
      } else {
        widget.onCardTap(wallet);
      }
    } else if (rank > 0) {
      _draggedVisualRank = rank;
      _isDragUp = true;
      _animController.forward(from: 0).then((_) {
        _finalizeCardSwap(rank);
      });
    }
  }
}
