import 'package:flutter/material.dart';
import '../../domain/entities/wallet.dart';
import 'wallet_card.dart';
import '../../../../shared/widgets/draggable_card_3d.dart';

/// Enhanced WalletCardStack with DraggableCard3D support
/// Allows users to swipe cards vertically with 3D depth (Google Pay style)
class DraggableWalletCardStack extends StatefulWidget {
  final List<Wallet> wallets;
  final Function(int) onIndexChanged;
  final Function(Wallet) onCardTap;
  final Function(Wallet)? onCardSwipedAway; // Triggered when card dragged 100%
  final VoidCallback? onAddressCopied;

  const DraggableWalletCardStack({
    super.key,
    required this.wallets,
    required this.onIndexChanged,
    required this.onCardTap,
    this.onCardSwipedAway,
    this.onAddressCopied,
  });

  @override
  State<DraggableWalletCardStack> createState() =>
      _DraggableWalletCardStackState();
}

class _DraggableWalletCardStackState extends State<DraggableWalletCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final ValueNotifier<double> _dragNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _velocityNotifier = ValueNotifier<double>(0.0);

  int _topIndex = 0;
  final bool _isDraggableMode = true; // Google Pay style with DraggableCard3D

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _topIndex = (_topIndex + 1) % widget.wallets.length;
          _dragNotifier.value = 0;
          _velocityNotifier.value = 0;
        });
        _controller.reset();
        widget.onIndexChanged(_topIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dragNotifier.dispose();
    _velocityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wallets.isEmpty) return const SizedBox.shrink();

    // Usar modo Draggable ou modo Stack normal
    if (_isDraggableMode && widget.wallets.isNotEmpty) {
      return _buildDraggableMode();
    } else {
      return _buildStackMode();
    }
  }

  /// Modo Stack tradicional com swipe
  Widget _buildStackMode() {
    return _buildDraggableMode(); // Force draggable mode for Google Pay style
  }

  /// Modo Draggable com Vertical Swap 3D (Google Pay Style)
  Widget _buildDraggableMode() {
    if (widget.wallets.isEmpty) return const SizedBox.shrink();

    final topWallet = widget.wallets[_topIndex];
    final backgroundWallets = <Widget>[];

    // Adiciona TODOS os cartões de fundo (widget.wallets.length - 1)
    final int backgroundCount = widget.wallets.length - 1;
    for (int i = 1; i <= backgroundCount; i++) {
      final index = (_topIndex + i) % widget.wallets.length;
      if (index != _topIndex) {
        backgroundWallets.add(
          WalletCard(
            wallet: widget.wallets[index],
            isSelected: false,
            tilt: 0,
            colorIndex: index,
            onTap: () {}, // Background cards are not interactive
          ),
        );
      }
    }

    return Container(
      height: 400, // Altura maior para acomodar o stack vertical
      alignment: Alignment.center,
      child: DraggableCard3D(
        initialHeight: 210,
        onDragComplete: () {
          setState(() {
            _topIndex = (_topIndex + 1) % widget.wallets.length;
          });
          widget.onIndexChanged(_topIndex);
          widget.onCardSwipedAway?.call(widget.wallets[_topIndex]);
        },
        backgroundCards: backgroundWallets,
        child: WalletCard(
          wallet: topWallet,
          isSelected: true,
          tilt: 0,
          colorIndex: _topIndex,
          onAddressCopied: widget.onAddressCopied,
          onTap: () => widget.onCardTap(topWallet),
        ),
      ),
    );
  }
}
