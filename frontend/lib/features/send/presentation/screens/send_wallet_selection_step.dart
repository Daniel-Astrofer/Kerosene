import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/financial_accounts/presentation/state/wallet_state.dart';
import 'package:kerosene/features/send/presentation/screens/send_money_formatters.dart';
import 'package:kerosene/features/send/presentation/send/send_money_copy.dart';
import 'package:kerosene/features/send/presentation/widgets/send_money_components.dart';

class SendWalletSelectionStep extends StatelessWidget {
  final Widget topBar;
  final WalletState walletState;
  final Wallet? selectedWallet;
  final VoidCallback onRefresh;
  final ValueChanged<Wallet> onWalletSelected;
  final VoidCallback onContinue;

  const SendWalletSelectionStep({
    super.key,
    required this.topBar,
    required this.walletState,
    required this.selectedWallet,
    required this.onRefresh,
    required this.onWalletSelected,
    required this.onContinue,
  });

  static const internalBlack = KeroseneBrandTokens.background;
  static const internalSurface = KeroseneBrandTokens.surface;
  static const internalSurfaceHigh = KeroseneBrandTokens.surfaceHigh;
  static const internalBorder = KeroseneBrandTokens.border;
  static const internalText = KeroseneBrandTokens.textPrimary;
  static const internalMutedText = KeroseneBrandTokens.textMuted;
  static const internalOutline = KeroseneBrandTokens.borderStrong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        topBar,
        Expanded(child: _buildBody(context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: InternalPrimaryButton(
            label: context.tr.continueButton,
            icon: KeroseneIcons.next,
            enabled: selectedWallet != null,
            onTap: onContinue,
            backgroundColor: internalText,
            foregroundColor: internalBlack,
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

  const _WalletList({
    required this.walletState,
    required this.selectedWallet,
    required this.onWalletSelected,
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
        final compact = wallets.length >= 3 || constraints.maxWidth < 380;
        final titleSize = compact ? 36.0 : 42.0;
        final topPadding = compact ? 14.0 : 24.0;
        final bottomPadding = compact ? 24.0 : 40.0;
        final headerGap = compact ? 18.0 : 28.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    SendMoneyCopy.sendTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.newsreader(
                      color: SendWalletSelectionStep.internalText,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w400,
                      height: 1.05,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    SendMoneyCopy.walletSelectionSubtitle(context),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SendWalletSelectionStep.internalMutedText,
                          fontSize: compact ? 13 : 14,
                          height: 1.38,
                        ),
                  ),
                  SizedBox(height: headerGap),
                  for (final wallet in wallets)
                    _WalletOption(
                      wallet: wallet,
                      selectedWallet: selectedWallet,
                      compact: compact,
                      onSelected: onWalletSelected,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WalletOption extends StatelessWidget {
  final Wallet wallet;
  final Wallet? selectedWallet;
  final bool compact;
  final ValueChanged<Wallet> onSelected;

  const _WalletOption({
    required this.wallet,
    required this.selectedWallet,
    required this.compact,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedWallet?.id == wallet.id;
    const availableBalanceLabel = 'SALDO DISPONÍVEL';
    final walletMode = wallet.walletMode.trim().isEmpty
        ? 'KEROSENE'
        : wallet.walletMode.trim().replaceAll('_', ' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        final dense = compact || narrow;
        final cardPadding = dense ? 14.0 : 18.0;
        final iconSize = dense ? 36.0 : 42.0;
        final iconGap = dense ? 10.0 : 14.0;
        final checkSize = dense ? 20.0 : 22.0;
        final checkIconSize = dense ? 12.0 : 14.0;
        final titleFontSize = dense ? 15.0 : 16.0;
        final bottomGap = dense ? 10.0 : 12.0;

        return Padding(
          padding: EdgeInsets.only(bottom: dense ? 10 : 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(wallet),
              child: AnimatedContainer(
                duration: KeroseneMotion.short,
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: SendWalletSelectionStep.internalSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? SendWalletSelectionStep.internalText
                        : SendWalletSelectionStep.internalBorder,
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SendWalletSelectionStep.internalSurfaceHigh,
                            border: Border.all(
                              color: SendWalletSelectionStep.internalBorder,
                            ),
                          ),
                          child: Icon(
                            KeroseneIcons.wallet,
                            color: SendWalletSelectionStep.internalText,
                            size: dense ? 18 : 20,
                          ),
                        ),
                        SizedBox(width: iconGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          SendWalletSelectionStep.internalText,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                walletMode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: SendWalletSelectionStep
                                          .internalMutedText,
                                      fontSize: dense ? 11.5 : 12,
                                      height: 1.2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: KeroseneMotion.short,
                          width: checkSize,
                          height: checkSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? SendWalletSelectionStep.internalText
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? SendWalletSelectionStep.internalText
                                  : SendWalletSelectionStep.internalOutline,
                            ),
                          ),
                          child: selected
                              ? Icon(
                                  KeroseneIcons.check,
                                  color: SendWalletSelectionStep.internalBlack,
                                  size: checkIconSize,
                                )
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: dense ? 12 : 16),
                    Container(
                      height: 1,
                      color: SendWalletSelectionStep.internalBorder,
                    ),
                    SizedBox(height: bottomGap),
                    Row(
                      children: [
                        Flexible(
                          flex: 2,
                          child: Text(
                            availableBalanceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      SendWalletSelectionStep.internalMutedText,
                                  fontSize: dense ? 9.5 : 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: dense ? 0.85 : 1.1,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                walletBalanceLabel(wallet.balance),
                                maxLines: 1,
                                softWrap: false,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          SendWalletSelectionStep.internalText,
                                      fontFamily:
                                          AppTypography.financialFontFamily,
                                      fontSize: dense ? 12.5 : 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
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
        );
      },
    );
  }
}
