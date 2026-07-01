import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/movement/flow/movement_flow_coordinator.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/widgets/transaction_value_entry_surface.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/flow/receive_nfc_availability_provider.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'package:kerosene/features/movement/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/features/movement/screens/receive_request_flow_screen.dart';

class MovementAmountScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final ReceiveAmountMethod method;
  final bool onChainWallet;

  const MovementAmountScreen({
    super.key,
    required this.wallet,
    required this.method,
    required this.onChainWallet,
  });

  @override
  ConsumerState<MovementAmountScreen> createState() =>
      _MovementAmountScreenState();
}

class _MovementAmountScreenState extends ConsumerState<MovementAmountScreen> {
  bool _isContinuing = false;
  Currency _selectedCurrency = Currency.btc;

  Future<void> _continue() async {
    if (_isContinuing) return;
    HapticFeedback.mediumImpact();
    final flowState = ref.read(movementFlowCoordinatorProvider);
    final amountBtc = _currentAmountBtc(flowState);
    if (widget.method == ReceiveAmountMethod.nfc) {
      final canUseNfc = await ref.read(receiveNfcCompatibilityProvider.future);
      if (!canUseNfc) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
        return;
      }
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ReceiveNfcFlowScreen(
            wallet: widget.wallet,
            onChainWallet: widget.onChainWallet,
            amountBtc: amountBtc,
          ),
        ),
      );
      return;
    }

    setState(() => _isContinuing = true);
    try {
      final paymentLink = await _createPaymentLinkIfNeeded(
        amountBtc: amountBtc,
        expiresInMinutes: flowState.paymentLinkExpiresInMinutes,
      );
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ReceiveRequestFlowScreen(
            wallet: widget.wallet,
            method: widget.method,
            onChainWallet: widget.onChainWallet,
            amountBtc: amountBtc,
            initialPaymentLink: paymentLink,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(
        ErrorTranslator.translate(context.tr, error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  Future<PaymentLink?> _createPaymentLinkIfNeeded({
    required double amountBtc,
    required int expiresInMinutes,
  }) async {
    if (widget.method != ReceiveAmountMethod.paymentLink &&
        widget.method != ReceiveAmountMethod.qrCode) {
      return null;
    }

    return ref.read(transactionRepositoryProvider).createPaymentLink(
      amount: amountBtc,
      description: 'Recebimento ${widget.wallet.name}',
      expiresInMinutes: expiresInMinutes,
      visibility: 'PRIVATE',
      confirmationMode: 'USER_ACTION_REQUIRED',
      amountLocked: true,
      referenceLabel: widget.wallet.name,
      metadata: {
        'walletName': widget.wallet.name,
        'rail': widget.onChainWallet ? 'ONCHAIN' : 'INTERNAL',
        'method': widget.method.name,
        'source': 'receive_flow',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.method == ReceiveAmountMethod.nfc) {
      final nfcCompatibility = ref.watch(receiveNfcCompatibilityProvider);
      final compatible = nfcCompatibility.asData?.value;
      if (compatible != true) {
        if (compatible == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
        }
        return const KeroseneLogoLoadingView();
      }
    }

    final flowState = ref.watch(movementFlowCoordinatorProvider);
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountBtc = _amountBtcFromInput(
      amountInput: flowState.amountInput,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final secondaryLabel = _selectedCurrency == Currency.btc
        ? _formatFiatReference(
            btcAmount: amountBtc,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          )
        : '≈ ${MoneyDisplay.formatCompact(
            amount: amountBtc,
            currency: Currency.btc,
            maxDecimalPlaces: 8,
          )}';

    return Scaffold(
      body: TransactionValueEntrySurface(
        onBack: () => Navigator.of(context).maybePop(),
        amountInput: flowState.amountInput,
        unitLabel: MoneyDisplay.tickerSymbolFor(_selectedCurrency),
        currency: _selectedCurrency,
        fiatReference: secondaryLabel,
        configuration: _configuration(flowState),
        onAmountChanged:
            ref.read(movementFlowCoordinatorProvider.notifier).setAmountInput,
        ctaLabel: widget.method == ReceiveAmountMethod.paymentLink
            ? context.tr.receiveGenAction.toUpperCase()
            : context.tr.continueButton,
        ctaEnabled: amountBtc > 0 && !_isContinuing,
        isBusy: _isContinuing,
        onCta: _continue,
        onFiatReferenceTap: _toggleAmountCurrency,
      ),
    );
  }

  double _currentAmountBtc(MovementFlowState flowState) {
    return _amountBtcFromInput(
      amountInput: flowState.amountInput,
      currency: _selectedCurrency,
      btcUsd: ref.read(latestBtcPriceProvider),
      btcEur: ref.read(btcEurPriceProvider),
      btcBrl: ref.read(btcBrlPriceProvider),
    );
  }

  double _amountBtcFromInput({
    required String amountInput,
    required Currency currency,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return MoneyDisplay.convertToBtcAmount(
      amount: MoneyDisplay.parseEditableInput(amountInput),
      currency: currency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  void _toggleAmountCurrency() {
    final flowState = ref.read(movementFlowCoordinatorProvider);
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final amountBtc = _amountBtcFromInput(
      amountInput: flowState.amountInput,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final nextCurrency =
        _selectedCurrency == Currency.btc ? Currency.brl : Currency.btc;
    final nextAmount = nextCurrency == Currency.btc
        ? amountBtc
        : MoneyDisplay.convertFromBtcAmount(
            btcAmount: amountBtc,
            currency: nextCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          );

    setState(() => _selectedCurrency = nextCurrency);
    ref.read(movementFlowCoordinatorProvider.notifier).setAmountInput(
          MoneyDisplay.rawInputFromAmount(
            amount: nextAmount,
            currency: nextCurrency,
          ),
        );
  }

  Widget? _configuration(MovementFlowState flowState) {
    if (widget.method != ReceiveAmountMethod.paymentLink) {
      return null;
    }

    final options = [
      (minutes: 15, label: context.tr.receive15Min),
      (minutes: 60, label: context.tr.receive1Hour),
      (minutes: 1440, label: context.tr.receive24Hours),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 0, 3, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.receiveScreenConfigureLinkTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr.receiveExpirationLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _expirationButton(flowState, option),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expirationButton(
    MovementFlowState flowState,
    ({String label, int minutes}) option,
  ) {
    final selected = flowState.paymentLinkExpiresInMinutes == option.minutes;
    return TextButton(
      onPressed: () => ref
          .read(movementFlowCoordinatorProvider.notifier)
          .selectPaymentLinkExpiration(option.minutes),
      style: TextButton.styleFrom(
        foregroundColor: selected ? Colors.black : Colors.white,
        backgroundColor:
            selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
      ),
      child: Text(option.label),
    );
  }

  String _formatFiatReference({
    required double btcAmount,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (btcAmount <= 0) {
      return '≈ R\$ 0,00';
    }
    return '≈ ${MoneyDisplay.formatAmountFromBtc(
      btcAmount: btcAmount,
      currency: Currency.brl,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    )}';
  }
}
