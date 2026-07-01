import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_hold_selection_tile.dart';

class WalletFlowSelector extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final Wallet? initialWallet;
  final ValueChanged<Wallet> onContinue;
  final VoidCallback? onBack;
  final bool showBackButton;

  const WalletFlowSelector({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.initialWallet,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  ConsumerState<WalletFlowSelector> createState() => _WalletFlowSelectorState();
}

class _WalletFlowSelectorState extends ConsumerState<WalletFlowSelector> {
  static const Color _background = AppColors.hexFF000000;
  static const Color _text = AppColors.hexFFFFFFFF;
  static const Color _muted = AppColors.hexFFA1A1A1;

  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(walletProvider);
      if (state is WalletInitial || state is WalletError) {
        unawaited(ref.read(walletProvider.notifier).refresh());
      }
    });
  }

  @override
  void didUpdateWidget(covariant WalletFlowSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWallet?.id != widget.initialWallet?.id) {
      _selectedWallet = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody(context, walletState)),
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    if (!widget.showBackButton) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 12,
      left: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(color: _text.withValues(alpha: 0.10)),
        ),
        child: IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(KeroseneIcons.back, size: 22),
          tooltip: context.tr.authBackAction,
          style: IconButton.styleFrom(
            foregroundColor: _text,
            minimumSize: const Size.square(40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletState walletState) {
    return switch (walletState) {
      WalletInitial() || WalletLoading() => const Center(
          child: CircularProgressIndicator(color: _text),
        ),
      WalletError(:final message) => _buildError(context, message),
      WalletLoaded(:final wallets) => wallets.isEmpty
          ? _buildEmpty(context)
          : _buildWalletGrid(context, walletState),
    };
  }

  Widget _buildError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(KeroseneIcons.warning, color: _muted, size: 34),
          const SizedBox(height: 16),
          Text(
            context.tr.walletSelectorLoadErrorTitle,
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: _text,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ErrorTranslator.translate(context.tr, message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _muted,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => ref.read(walletProvider.notifier).refresh(),
            icon: const Icon(KeroseneIcons.refresh, size: 18),
            label: Text(context.tr.walletSelectorRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          context.tr.walletSelectorNoWallets,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _muted,
                height: 1.45,
              ),
        ),
      ),
    );
  }

  Widget _buildWalletGrid(BuildContext context, WalletLoaded walletState) {
    final wallets = walletState.wallets.toList();
    final selectedWallet = _resolveSelectedWallet(
      walletState.copyWith(wallets: wallets),
    );

    return Semantics(
      label: widget.subtitle,
      container: true,
      child: _buildVerticalWalletList(wallets, selectedWallet),
    );
  }

  Widget _buildVerticalWalletList(
      List<Wallet> wallets, Wallet? selectedWallet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final compact = width < 380 || height < 720 || wallets.length >= 3;
        final maxWidth = width;
        final canFitWithoutScrolling = wallets.length <= 3;
        final verticalPadding = canFitWithoutScrolling ? 32.0 : 84.0;
        final gap = compact ? 10.0 : 14.0;

        Widget itemBuilder(Wallet wallet) {
          final selected = _sameWallet(wallet, selectedWallet);
          final tileWidth = selected ? maxWidth : maxWidth * 0.86;
          return Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              key: ValueKey('wallet-flow-tile-${wallet.id}'),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutQuart,
              width: tileWidth,
              child: WalletHoldSelectionTile(
                wallet: wallet,
                selected: selected,
                compact: compact,
                onSelect: _select,
                onConfirmed: _continueWith,
              ),
            ),
          );
        }

        if (canFitWithoutScrolling) {
          final availableHeight =
              (height - verticalPadding * 2 - gap * (wallets.length - 1))
                  .clamp(0.0, double.infinity)
                  .toDouble();
          final maxTileHeight = wallets.isEmpty
              ? 0.0
              : (availableHeight / wallets.length)
                  .clamp(compact ? 156.0 : 184.0, double.infinity)
                  .toDouble();
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 0,
              vertical: verticalPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < wallets.length; index++) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: compact ? 148 : 172,
                          maxHeight: maxTileHeight,
                        ),
                        child: itemBuilder(wallets[index]),
                      ),
                      if (index < wallets.length - 1) SizedBox(height: gap),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            0,
            84,
            0,
            28,
          ),
          itemCount: wallets.length,
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder: (context, index) => itemBuilder(wallets[index]),
        );
      },
    );
  }

  Wallet? _resolveSelectedWallet(WalletLoaded walletState) {
    final selected = _selectedWallet;
    if (selected != null) {
      final loaded = _findLoadedWallet(walletState.wallets, selected);
      if (loaded != null) return loaded;
    }
    final initial = widget.initialWallet;
    if (initial != null) {
      final loaded = _findLoadedWallet(walletState.wallets, initial);
      if (loaded != null) return loaded;
    }
    final stateSelected = walletState.selectedWallet;
    if (stateSelected != null) {
      final loaded = _findLoadedWallet(walletState.wallets, stateSelected);
      if (loaded != null) return loaded;
    }
    return walletState.wallets.isNotEmpty ? walletState.wallets.first : null;
  }

  Wallet? _findLoadedWallet(List<Wallet> wallets, Wallet candidate) {
    for (final wallet in wallets) {
      if (_sameWallet(wallet, candidate)) {
        return wallet;
      }
    }
    return null;
  }

  bool _sameWallet(Wallet? left, Wallet? right) {
    if (left == null || right == null) return false;
    return left.id == right.id || left.name == right.name;
  }

  void _select(Wallet wallet) {
    if (_selectedWallet?.id != wallet.id) {
      HapticFeedback.selectionClick();
    }
    setState(() => _selectedWallet = wallet);
  }

  void _continueWith(Wallet wallet) {
    HapticFeedback.mediumImpact();
    ref.read(walletProvider.notifier).selectWallet(wallet);
    widget.onContinue(wallet);
  }
}
