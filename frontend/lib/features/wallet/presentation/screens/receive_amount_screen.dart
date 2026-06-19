import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/transactions/domain/entities/payment_link.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/transactions/presentation/widgets/transaction_amount_surface.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_method.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_request_flow_screen.dart';

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
  static const Color _black = KeroseneBrandTokens.background;
  static const Color _surface = KeroseneBrandTokens.surface;
  static const Color _border = KeroseneBrandTokens.border;
  static const Color _text = KeroseneBrandTokens.textPrimary;
  static const Color _mutedText = KeroseneBrandTokens.textSecondary;
  static const Color _outline = KeroseneBrandTokens.textMuted;

  String _amount = '0';
  bool _isContinuing = false;
  int _paymentLinkExpiresInMinutes = 60;

  IconData get _methodIcon {
    return switch (widget.method) {
      ReceiveAmountMethod.qrCode => KeroseneIcons.qr,
      ReceiveAmountMethod.paymentLink => KeroseneIcons.onchain,
      ReceiveAmountMethod.nfc => KeroseneIcons.nfc,
      ReceiveAmountMethod.p2p => KeroseneIcons.internalTransfer,
    };
  }

  double get _amountBtc {
    return MoneyDisplay.parseEditableInput(_amount);
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
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
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context),
            Expanded(
              child: TransactionAmountSurface(
                direction: TransactionAmountDirection.receive,
                rail: _methodLabel(context),
                connectionLabel: _networkLabel,
                topContent: widget.method == ReceiveAmountMethod.paymentLink
                    ? _buildPaymentLinkExpiryOptions(context)
                    : null,
                sourceParty: TransactionPartyData(
                  prefix: 'Recebimento por:',
                  title: _methodLabel(context),
                  subtitle: _networkLabel,
                  icon: _methodIcon,
                ),
                destinationParty: TransactionPartyData(
                  prefix: 'Recebendo em:',
                  title: widget.wallet.name,
                  subtitle: _shortAddress(widget.wallet.address),
                  icon: _methodIcon,
                ),
                amountLabel: amountLabel,
                unitLabel: 'BTC',
                fiatReference: fiatLabel,
                keypadConfig: TransactionKeypadConfig(onKeyTap: _onKeyTap),
                details: _receiveDetails,
                ctaLabel: widget.method == ReceiveAmountMethod.paymentLink
                    ? context.tr.receiveGenAction
                    : context.tr.continueButton,
                ctaEnabled: _amountBtc > 0 && !_isContinuing,
                isBusy: _isContinuing,
                onContinue: _continue,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                fillAvailableHeight: false,
                backgroundColor: _black,
                textColor: _text,
                mutedTextColor: _mutedText,
                tertiaryTextColor: _outline,
                surfaceColor: _surface,
                borderColor: _border,
                primaryButtonColor: _text,
                primaryButtonTextColor: _black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(BuildContext context) {
    return switch (widget.method) {
      ReceiveAmountMethod.qrCode => context.tr.receiveQrMethod,
      ReceiveAmountMethod.paymentLink =>
        context.tr.receiveMethodPaymentLinkTitle,
      ReceiveAmountMethod.nfc => context.tr.receiveNfcMethod,
      ReceiveAmountMethod.p2p => context.tr.receiveMethodKeroseneTitle,
    };
  }

  String get _networkLabel => widget.onChainWallet ? 'On-chain' : 'Kerosene';

  List<TransactionDetailRowData> get _receiveDetails {
    if (widget.method == ReceiveAmountMethod.paymentLink) {
      return const [];
    }

    return [
      TransactionDetailRowData(
        label: 'Destino',
        value: widget.wallet.name,
        secondaryValue: _shortAddress(widget.wallet.address),
      ),
      TransactionDetailRowData(
        label: 'Rede',
        value: _networkLabel,
      ),
    ];
  }

  Widget _buildPaymentLinkExpiryOptions(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.tr.receiveExpirationLabel.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildExpiryOption(context.tr.receive15Min, 15),
            const SizedBox(width: 8),
            _buildExpiryOption(context.tr.receive1Hour, 60),
            const SizedBox(width: 8),
            _buildExpiryOption(context.tr.receive24Hours, 1440),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(KeroseneIcons.back),
              color: _text,
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                context.tr.howMuchToReceive,
                textAlign: TextAlign.center,
                style: AppTypography.newsreader(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryOption(String label, int minutes) {
    final selected = _paymentLinkExpiresInMinutes == minutes;

    return Expanded(
      child: SizedBox(
        height: 42,
        child: OutlinedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _paymentLinkExpiresInMinutes = minutes);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? _text : _surface,
            foregroundColor: selected ? _black : _text,
            side: BorderSide(color: selected ? _text : _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
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
