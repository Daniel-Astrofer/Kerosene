import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/theme/app_animations.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:kerosene/features/wallet/presentation/state/wallet_state.dart';

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
  static const Color _background = Color(0xFF000000);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _muted = Color(0xFFA1A1A1);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context),
            Expanded(child: _buildBody(context, walletState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: widget.showBackButton
                  ? IconButton(
                      onPressed:
                          widget.onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(LucideIcons.arrowLeft, size: 22),
                      tooltip: context.tr.authBackAction,
                      style: IconButton.styleFrom(
                        foregroundColor: _text,
                        minimumSize: const Size.square(40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  : const SizedBox(width: 40, height: 40),
            ),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSerif(
                color: _text,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 40, height: 40),
            ),
          ],
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
          const Icon(LucideIcons.alertCircle, color: _muted, size: 34),
          const SizedBox(height: 16),
          Text(
            context.tr.walletSelectorLoadErrorTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSerif(
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
            icon: const Icon(LucideIcons.refreshCw, size: 18),
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
    final selectedWallet = _resolveSelectedWallet(walletState);
    final wallets = walletState.wallets;

    return Semantics(
      label: widget.subtitle,
      container: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: wallets.length <= 2
                ? _buildTwoWalletLayout(wallets, selectedWallet)
                : _buildMultiWalletGrid(wallets, selectedWallet),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ContinueOverlay(
              enabled: selectedWallet != null,
              onPressed: selectedWallet == null
                  ? null
                  : () => _continueWith(selectedWallet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoWalletLayout(List<Wallet> wallets, Wallet? selectedWallet) {
    return Row(
      children: [
        for (var index = 0; index < wallets.length; index++)
          Expanded(
            child: _WalletFlowTile(
              wallet: wallets[index],
              selected: _sameWallet(wallets[index], selectedWallet),
              showLeftBorder: index > 0,
              onTap: () => _select(wallets[index]),
            )
                .animate(delay: Duration(milliseconds: 60 * index))
                .fade(
                  duration: AppAnimations.emphasized,
                  curve: AppAnimations.standardCurve,
                )
                .slideX(
                  begin: index == 0 ? -0.04 : 0.04,
                  end: 0,
                  duration: AppAnimations.emphasized,
                  curve: AppAnimations.emphasizedCurve,
                ),
          ),
      ],
    );
  }

  Widget _buildMultiWalletGrid(List<Wallet> wallets, Wallet? selectedWallet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 330 ? 1 : 2;
        final tileWidth = constraints.maxWidth / crossAxisCount;
        final aspectRatio = (tileWidth / 292.0).clamp(0.56, 1.08).toDouble();

        return GridView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 112),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            childAspectRatio: aspectRatio,
          ),
          itemCount: wallets.length,
          itemBuilder: (context, index) {
            final wallet = wallets[index];
            final selected = _sameWallet(wallet, selectedWallet);
            return _WalletFlowTile(
              wallet: wallet,
              selected: selected,
              showLeftBorder: crossAxisCount > 1 && index.isOdd,
              onTap: () => _select(wallet),
            )
                .animate(delay: Duration(milliseconds: 45 * index))
                .fade(
                  duration: AppAnimations.emphasized,
                  curve: AppAnimations.standardCurve,
                )
                .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: AppAnimations.emphasized,
                  curve: AppAnimations.emphasizedCurve,
                );
          },
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
    HapticFeedback.selectionClick();
    setState(() => _selectedWallet = wallet);
  }

  void _continueWith(Wallet wallet) {
    HapticFeedback.mediumImpact();
    ref.read(walletProvider.notifier).selectWallet(wallet);
    widget.onContinue(wallet);
  }
}

class _ContinueOverlay extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _ContinueOverlay({
    required this.enabled,
    required this.onPressed,
  });

  static const Color _background = Color(0xFF000000);
  static const Color _text = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _background.withValues(alpha: 0),
            _background.withValues(alpha: 0.70),
            _background.withValues(alpha: 0.94),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: _text,
              foregroundColor: _background,
              disabledBackgroundColor: _text.withValues(alpha: 0.22),
              disabledForegroundColor: _text.withValues(alpha: 0.42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
            ),
            child: Text(context.tr.continueButton),
          ),
        ),
      ),
    );
  }
}

class _WalletFlowTile extends StatelessWidget {
  final Wallet wallet;
  final bool selected;
  final bool showLeftBorder;
  final VoidCallback onTap;

  const _WalletFlowTile({
    required this.wallet,
    required this.selected,
    required this.showLeftBorder,
    required this.onTap,
  });

  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceHigh = Color(0xFF2A2A2A);
  static const Color _border = Color(0xFF333333);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _muted = Color(0xFFA1A1A1);

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? _background : _text;
    final muted = selected ? _background.withValues(alpha: 0.68) : _muted;

    return Semantics(
      key: ValueKey('wallet-flow-tile-${wallet.id}'),
      button: true,
      selected: selected,
      label: wallet.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: AnimatedScale(
            scale: selected ? 1 : 0.985,
            duration: AppAnimations.standard,
            curve: AppAnimations.emphasizedCurve,
            child: AnimatedContainer(
              duration: AppAnimations.emphasized,
              curve: AppAnimations.standardCurve,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                color: selected ? _text : _surface,
                border: Border(
                  left: BorderSide(
                    color: selected
                        ? _text
                        : showLeftBorder
                            ? _border
                            : Colors.transparent,
                  ),
                  top: BorderSide(color: selected ? _text : _border),
                  right: BorderSide(color: selected ? _text : _border),
                  bottom: BorderSide(color: selected ? _text : _border),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: -8,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 2),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: AppAnimations.emphasized,
                          curve: AppAnimations.standardCurve,
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? _background.withValues(alpha: 0.10)
                                : _surfaceHigh,
                          ),
                          child: Icon(
                            _walletIcon(wallet),
                            color: foreground,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _displayName(wallet.name),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSerif(
                            color: foreground,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _modeLabel(wallet),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        context.tr.walletSelectorAvailableBalance.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${wallet.balance.toStringAsFixed(6)} BTC',
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: foreground,
                                    fontFamily: 'IBMPlexSansHebrew',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _walletIcon(Wallet wallet) {
    final mode = wallet.walletMode.trim().toUpperCase();
    if (wallet.isSelfCustody ||
        mode.contains('COLD') ||
        mode.contains('ONCHAIN') ||
        mode.contains('ON_CHAIN')) {
      return LucideIcons.snowflake;
    }
    return LucideIcons.wallet;
  }

  static String _displayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Wallet';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 1) return trimmed;
    return words.take(2).join('\n');
  }

  static String _modeLabel(Wallet wallet) {
    final mode = wallet.walletMode.trim();
    if (mode.isEmpty) return 'KEROSENE';
    final normalized = mode.replaceAll('_', ' ').toUpperCase();
    if (normalized.contains('COLD')) return 'COLD WALLET';
    if (wallet.isSelfCustody) return 'SELF CUSTODY';
    return normalized;
  }
}
