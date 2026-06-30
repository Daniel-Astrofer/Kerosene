import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/financial_activity/domain/entities/payment_link.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_value_entry_surface.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/receive/application/providers/receive_nfc_availability_provider.dart';
import 'package:kerosene/features/receive/presentation/screens/receive_method.dart';
import 'package:kerosene/features/receive/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/features/receive/presentation/screens/receive_request_flow_screen.dart';

class ReceiveAmountScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final ReceiveAmountMethod method;
  final bool onChainWallet;

  const ReceiveAmountScreen({
    super.key,
    required this.wallet,
    required this.method,
    required this.onChainWallet,
  });

  @override
  ConsumerState<ReceiveAmountScreen> createState() =>
      _ReceiveAmountScreenState();
}

class _ReceiveAmountScreenState extends ConsumerState<ReceiveAmountScreen> {
  String _amount = '0';
  bool _isContinuing = false;
  final int _paymentLinkExpiresInMinutes = 60;

  double get _amountBtc {
    return MoneyDisplay.parseEditableInput(_amount);
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_amount == '0' && key == '0') {
        _amount = '0.';
        return;
      }

      _amount = MoneyDisplay.applyKeypadInput(
        currentValue: _amount,
        key: key,
        currency: Currency.btc,
        maxLength: 16,
      );
    });
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    HapticFeedback.mediumImpact();
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
            amountBtc: _amountBtc,
          ),
        ),
      );
      return;
    }

    setState(() => _isContinuing = true);
    try {
      final paymentLink = await _createPaymentLinkIfNeeded();
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ReceiveRequestFlowScreen(
            wallet: widget.wallet,
            method: widget.method,
            onChainWallet: widget.onChainWallet,
            amountBtc: _amountBtc,
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

  Future<PaymentLink?> _createPaymentLinkIfNeeded() async {
    if (widget.method != ReceiveAmountMethod.paymentLink &&
        widget.method != ReceiveAmountMethod.qrCode) {
      return null;
    }

    return ref.read(transactionRepositoryProvider).createPaymentLink(
      amount: _amountBtc,
      description: 'Recebimento ${widget.wallet.name}',
      expiresInMinutes: _paymentLinkExpiresInMinutes,
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

    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountLabel = MoneyDisplay.formatEditableInput(
      rawValue: _amount,
      currency: Currency.btc,
      withSymbol: false,
    );
    final fiatLabel = _formatFiatReference(
      btcAmount: _amountBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return Scaffold(
      body: TransactionValueEntrySurface(
        onBack: () => Navigator.of(context).maybePop(),
        amountLabel: amountLabel,
        fiatReference: fiatLabel,
        details: _details(),
        onKeyTap: _onKeyTap,
        ctaLabel: widget.method == ReceiveAmountMethod.paymentLink
            ? context.tr.receiveGenAction
            : context.tr.continueButton,
        ctaEnabled: _amountBtc > 0 && !_isContinuing,
        isBusy: _isContinuing,
        onCta: _continue,
      ),
    );
  }

  String get _networkLabel => widget.onChainWallet ? 'On-chain' : 'Kerosene';

  List<TransactionValueEntryDetail> _details() {
    return [
      TransactionValueEntryDetail(
        label: 'Destino',
        value: _shortAddress(widget.wallet.address),
      ),
      TransactionValueEntryDetail(label: 'Rede', value: _networkLabel),
      TransactionValueEntryDetail(label: 'Carteira', value: widget.wallet.name),
      TransactionValueEntryDetail(
        label: 'Tempo estimado',
        value: widget.onChainWallet ? '~10 min' : 'Instantâneo',
      ),
    ];
  }

  String _shortAddress(String address) {
    if (address.length <= 18) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
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
