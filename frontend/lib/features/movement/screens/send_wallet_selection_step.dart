import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/widgets/wallet_hold_selection_tile.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/movement/copy/send_money_copy.dart';

class SendWalletSelectionStep extends StatelessWidget {
  final WalletState walletState;
  final Wallet? selectedWallet;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final ValueChanged<Wallet> onWalletSelected;
  final ValueChanged<Wallet> onWalletConfirmed;

  const SendWalletSelectionStep({
    super.key,
    required this.walletState,
    required this.selectedWallet,
    required this.onRefresh,
    required this.onBack,
    required this.onWalletSelected,
    required this.onWalletConfirmed,
  });

  static const internalBlack = KeroseneBrandTokens.background;
  static const internalBorder = KeroseneBrandTokens.border;
  static const internalText = KeroseneBrandTokens.textPrimary;
  static const internalMutedText = KeroseneBrandTokens.textMuted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildBody(context)),
        Positioned(
          top: 12,
          left: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: internalBlack.withValues(alpha: 0.42),
              shape: BoxShape.circle,
              border: Border.all(color: internalText.withValues(alpha: 0.10)),
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(KeroseneIcons.back, size: 22),
              tooltip: context.tr.authBackAction,
              style: IconButton.styleFrom(
                foregroundColor: internalText,
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = walletState;
    if (state is WalletLoading || state is WalletInitial) {
      return _WalletLoading(
        onRefresh: onRefresh,
      );
    }
    if (state is WalletError) {
      return _WalletLoadError(message: state.message, onRefresh: onRefresh);
    }
    if (state is WalletLoaded) {
      return _WalletList(
        walletState: state,
        selectedWallet: selectedWallet,
        onWalletSelected: onWalletSelected,
        onWalletConfirmed: onWalletConfirmed,
      );
    }
    return const SizedBox.shrink();
  }
}

class _WalletLoading extends StatefulWidget {
  final VoidCallback onRefresh;

  const _WalletLoading({required this.onRefresh});

  @override
  State<_WalletLoading> createState() => _WalletLoadingState();
}

class _WalletLoadingState extends State<_WalletLoading> {
  static const int _slowLoadSeconds = 12;
  late Timer _timer;
  int _elapsedSeconds = 0;

  bool get _isSlow => _elapsedSeconds >= _slowLoadSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds += 1);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() => _elapsedSeconds = 0);
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSlow
        ? SendMoneyCopy.walletLoadSlowTitle(context)
        : SendMoneyCopy.walletLoadLoadingTitle(context);
    final body = _isSlow
        ? SendMoneyCopy.walletLoadSlowBody(context)
        : SendMoneyCopy.walletLoadLoadingBody(context, _elapsedSeconds);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.56,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    color: SendWalletSelectionStep.internalText,
                    strokeWidth: 2.2,
                    backgroundColor: SendWalletSelectionStep.internalBorder,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.newsreader(
                    color: SendWalletSelectionStep.internalText,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SendWalletSelectionStep.internalMutedText,
                        fontSize: 13,
                        height: 1.45,
                      ),
                ),
                if (_isSlow) ...[
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(KeroseneIcons.refresh, size: 18),
                    label: Text(context.tr.tryAgain),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _WalletLoadError({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            KeroseneIcons.warning,
            color: SendWalletSelectionStep.internalMutedText,
            size: 34,
          ),
          const SizedBox(height: 16),
          Text(
            SendMoneyCopy.walletLoadFailed(context),
            textAlign: TextAlign.center,
            style: AppTypography.newsreader(
              color: SendWalletSelectionStep.internalText,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ErrorTranslator.translate(context.tr, message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SendWalletSelectionStep.internalMutedText,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(KeroseneIcons.refresh, size: 18),
            label: Text(context.tr.tryAgain),
          ),
        ],
      ),
    );
  }
}

class _WalletList extends StatelessWidget {
  final WalletLoaded walletState;
  final Wallet? selectedWallet;
  final ValueChanged<Wallet> onWalletSelected;
  final ValueChanged<Wallet> onWalletConfirmed;

  const _WalletList({
    required this.walletState,
    required this.selectedWallet,
    required this.onWalletSelected,
    required this.onWalletConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final wallets = walletState.wallets;
    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            SendMoneyCopy.noWalletsForSend(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SendWalletSelectionStep.internalMutedText,
                  height: 1.5,
                ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final compact = width < 380 || height < 720 || wallets.length >= 3;
        final outerHorizontal = width <= 360 ? 12.0 : 18.0;
        final maxWidth =
            (width - outerHorizontal * 2).clamp(280.0, 430.0).toDouble();
        final canFitWithoutScrolling = wallets.length <= 3;
        final verticalPadding = canFitWithoutScrolling ? 32.0 : 84.0;
        final gap = compact ? 10.0 : 14.0;

        Widget itemBuilder(Wallet wallet) {
          final selected = selectedWallet?.id == wallet.id;
          final tileWidth = selected ? maxWidth : maxWidth * 0.86;
          return Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              key: ValueKey('send-wallet-option-${wallet.id}'),
              duration: KeroseneMotion.medium,
              curve: KeroseneMotion.entrance,
              width: tileWidth,
              child: WalletHoldSelectionTile(
                wallet: wallet,
                selected: selected,
                compact: compact,
                onSelect: onWalletSelected,
                onConfirmed: onWalletConfirmed,
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
                  .clamp(compact ? 156.0 : 184.0, compact ? 210.0 : 250.0)
                  .toDouble();
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: outerHorizontal,
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
          padding: EdgeInsets.fromLTRB(
            outerHorizontal,
            84,
            outerHorizontal,
            28,
          ),
          itemCount: wallets.length,
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder: (context, index) => itemBuilder(wallets[index]),
        );
      },
    );
  }
}
