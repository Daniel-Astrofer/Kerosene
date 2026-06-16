part of 'withdraw_screen.dart';

class _WithdrawLightningAmountStep extends StatefulWidget {
  final double? initialAmountBtc;
  final Currency selectedCurrency;
  final Wallet wallet;
  final _WithdrawDestinationAnalysis destination;
  final _WithdrawFeeQuote feeQuote;
  final double? btcUsd;
  final double? btcEur;
  final double? btcBrl;
  final bool selfCustodyBlocked;
  final bool treasuryLightningBlocked;
  final void Function(double amountBtc) onContinue;
  final Widget topBar;
  final String recipientLabel;
  final String estimatedTimeLabel;
  final String networkFeeLabel;
  final String networkFeeFiatLabel;

  const _WithdrawLightningAmountStep({
    required this.initialAmountBtc,
    required this.selectedCurrency,
    required this.wallet,
    required this.destination,
    required this.feeQuote,
    required this.btcUsd,
    required this.btcEur,
    required this.btcBrl,
    required this.selfCustodyBlocked,
    required this.treasuryLightningBlocked,
    required this.onContinue,
    required this.topBar,
    required this.recipientLabel,
    required this.estimatedTimeLabel,
    required this.networkFeeLabel,
    required this.networkFeeFiatLabel,
  });

  @override
  State<_WithdrawLightningAmountStep> createState() =>
      _WithdrawLightningAmountStepState();
}

class _WithdrawLightningAmountStepState
    extends State<_WithdrawLightningAmountStep> {
  late final ValueNotifier<String> _amountInput;

  @override
  void initState() {
    super.initState();
    String initial = '0';
    if (widget.initialAmountBtc != null && widget.initialAmountBtc! > 0) {
      initial = widget.initialAmountBtc!
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    _amountInput = ValueNotifier<String>(initial);
  }

  @override
  void dispose() {
    _amountInput.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    _amountInput.value = MoneyDisplay.applyKeypadInput(
      currentValue: _amountInput.value,
      key: key,
      currency: widget.selectedCurrency,
      maxLength: widget.selectedCurrency == Currency.btc ? 16 : 12,
    );
  }

  double _parsedAmountBtc(String amountVal) {
    final parsed = MoneyDisplay.parseEditableInput(amountVal);
    return MoneyDisplay.convertToBtcAmount(
      amount: parsed,
      currency: widget.selectedCurrency,
      btcUsd: widget.btcUsd,
      btcEur: widget.btcEur,
      btcBrl: widget.btcBrl,
    );
  }

  String _displayAmount(String amountVal) {
    return MoneyDisplay.formatEditableInput(
      rawValue: amountVal,
      currency: widget.selectedCurrency,
      withSymbol: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _amountInput,
      builder: (context, amountVal, child) {
        final amountBtc = _parsedAmountBtc(amountVal);
        final fiatLabel = _WithdrawScreenState._lightningFiatReferenceStatic(
          btcAmount: amountBtc,
          btcUsd: widget.btcUsd,
          btcEur: widget.btcEur,
          btcBrl: widget.btcBrl,
        );

        final canContinue = amountBtc > 0 &&
            !widget.feeQuote.isLoading &&
            (!widget.destination.isOnChain || widget.feeQuote.hasAmount);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.topBar,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ExternalSendPartyRow(
                                prefix: context.tr.withdrawUiSendingFromPrefix,
                                title: widget.wallet.name,
                                subtitle: _WithdrawScreenState
                                    ._shortExternalDestinationValueStatic(
                                  widget.wallet.address.trim().isNotEmpty
                                      ? widget.wallet.address
                                      : widget.wallet.id,
                                ),
                                icon: LucideIcons.user,
                              ),
                              const SizedBox(height: 22),
                              _ExternalSendPartyRow(
                                prefix: context.tr.withdrawUiSendingToPrefix,
                                title: widget.recipientLabel,
                                subtitle: _WithdrawScreenState
                                    ._shortExternalDestinationValueStatic(
                                  widget.destination.normalizedValue,
                                ),
                                icon: LucideIcons.user,
                              ),
                              if (widget.selfCustodyBlocked ||
                                  widget.treasuryLightningBlocked) ...[
                                const SizedBox(height: 18),
                                Text(
                                  widget.selfCustodyBlocked
                                      ? context
                                          .tr.withdrawUiColdWalletSendBlocked
                                      : context
                                          .tr.withdrawUiLiquidityBlockedMessage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _WithdrawScreenState
                                            ._lightningMutedTextColor,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 38),
                              const Spacer(),
                              _ExternalSendAmountField(
                                amountLabel: _displayAmount(amountVal),
                                fiatLabel: fiatLabel,
                              ),
                              const SizedBox(height: 28),
                              _ExternalSendFinancialDetails(
                                balanceLabel:
                                    '${_WithdrawScreenState._formatBtcPlainStatic(widget.wallet.balance, decimalPlaces: 6)} BTC',
                                networkFeeLabel: widget.networkFeeLabel,
                                networkFeeFiatLabel: widget.networkFeeFiatLabel,
                                estimatedTimeLabel: widget.estimatedTimeLabel,
                              ),
                              const SizedBox(height: 24),
                              LightningKeypad(
                                onKeyTap: _onKeyTap,
                                textColor:
                                    _WithdrawScreenState._lightningTextColor,
                                mutedColor: _WithdrawScreenState
                                    ._lightningMutedTextColor,
                              ),
                              const SizedBox(height: 18),
                              _WithdrawScreenState
                                  ._buildLightningPrimaryButtonStatic(
                                context,
                                label: context.tr.withdrawUiContinue,
                                icon: LucideIcons.arrowRight,
                                showIcon: false,
                                enabled: canContinue,
                                onTap: () => widget.onContinue(amountBtc),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
