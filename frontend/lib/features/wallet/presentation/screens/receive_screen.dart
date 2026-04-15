import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/utils/currency_logic.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/utils/qr_payment_parser.dart'; // [NEW]
import '../../../transactions/domain/entities/payment_link.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/payment_request.dart';
import '../../presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import '../../presentation/state/wallet_state.dart';
import 'nfc_interaction_screen.dart';
import 'receive_payment_link_screen.dart';

enum ReceiveFlowMode { qrCode, nfc, paymentLink }

class ReceiveScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;
  final ReceiveFlowMode initialMode;

  const ReceiveScreen({
    super.key,
    this.initialWallet,
    this.initialMode = ReceiveFlowMode.qrCode,
  });

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  Wallet? _selectedWallet;
  Currency _selectedCurrency = Currency.btc;

  String _amount = '0';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.initialWallet;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalCurrency = ref.read(currencyProvider);
      setState(() {
        _selectedCurrency = globalCurrency;
      });

      if (_selectedWallet == null) {
        final walletState = ref.read(walletProvider);
        if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
          setState(() {
            _selectedWallet = walletState.wallets.first;
          });
        }
      }
    });
  }

  PaymentRequest get _paymentRequest {
    double? amount;
    if (_amount != '0' && _amount.isNotEmpty) {
      final inputAmount = MoneyDisplay.parseEditableInput(_amount);
      if (_selectedCurrency != Currency.btc) {
        final btcUsd = ref.read(latestBtcPriceProvider);
        final btcEur = ref.read(btcEurPriceProvider);
        final btcBrl = ref.read(btcBrlPriceProvider);
        amount = CurrencyLogic.convertToBtc(
          amount: inputAmount,
          fromCurrency: _selectedCurrency,
          btcUsdPrice: btcUsd,
          btcEurPrice: btcEur,
          btcBrlPrice: btcBrl,
        );
      } else {
        amount = inputAmount;
      }
    }

    return PaymentRequest(
      address: _selectedWallet?.address ?? '',
      amountBtc: amount != null && amount > 0 ? amount : null,
    );
  }

  IconData get _flowIcon {
    switch (widget.initialMode) {
      case ReceiveFlowMode.qrCode:
        return LucideIcons.qrCode;
      case ReceiveFlowMode.nfc:
        return LucideIcons.radio;
      case ReceiveFlowMode.paymentLink:
        return LucideIcons.link2;
    }
  }

  String _flowEyebrow(BuildContext context) {
    switch (widget.initialMode) {
      case ReceiveFlowMode.qrCode:
        return 'QR CODE';
      case ReceiveFlowMode.nfc:
        return context.l10n.nfc.toUpperCase();
      case ReceiveFlowMode.paymentLink:
        return 'LINK DE PAGAMENTO';
    }
  }

  String _flowDescription(BuildContext context) {
    switch (widget.initialMode) {
      case ReceiveFlowMode.qrCode:
        return 'Gere um QR interno com valor e destino travados para confirmação.';
      case ReceiveFlowMode.nfc:
        return 'Prepare um payload NFC interno com destino travado.';
      case ReceiveFlowMode.paymentLink:
        return 'Crie um link rastreado que abre direto na confirmação.';
    }
  }

  String _continueLabel(BuildContext context) {
    switch (widget.initialMode) {
      case ReceiveFlowMode.qrCode:
        return 'GERAR QR';
      case ReceiveFlowMode.nfc:
        return 'PREPARAR NFC';
      case ReceiveFlowMode.paymentLink:
        return 'CRIAR LINK';
    }
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _amount = MoneyDisplay.applyKeypadInput(
        currentValue: _amount,
        key: key,
        currency: _selectedCurrency,
        maxLength: _selectedCurrency == Currency.btc ? 16 : 12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CyberBackground.authenticated(
      useScroll: true,
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          _buildFlowHero(context).animate().fade().slideY(begin: 0.08, end: 0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Column(
              children: [
                _buildAmountDisplay()
                    .animate()
                    .scale(curve: Curves.easeOutBack),
              ],
            ),
          ),
          _buildKeypad()
              .animate(delay: 200.ms)
              .fade()
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CyberButton(
              text: _continueLabel(context),
              isLoading: _isGenerating,
              onTap: MoneyDisplay.parseEditableInput(_amount) > 0
                  ? _generateAndNavigate
                  : null,
            ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.receive.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 4, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildFlowHero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              _flowIcon,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _flowEyebrow(context),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.42),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _flowDescription(context),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.74),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final typedAmount = MoneyDisplay.parseEditableInput(_amount);
    final btcEquivalent = _selectedCurrency == Currency.btc
        ? typedAmount
        : CurrencyLogic.convertToBtc(
            amount: typedAmount,
            fromCurrency: _selectedCurrency,
            btcUsdPrice: btcUsd,
            btcEurPrice: btcEur,
            btcBrlPrice: btcBrl,
          );
    final wallet = _selectedWallet;

    return Column(
      children: [
        Text(
          context.l10n.howMuchToReceive.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          MoneyDisplay.formatEditableInput(
            rawValue: _amount,
            currency: _selectedCurrency,
          ),
          style: AppTypography.amountInput(
            isBtc: _selectedCurrency == Currency.btc,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_selectedCurrency != Currency.btc)
          Text(
            'Equivale a ${MoneyDisplay.formatCompact(amount: btcEquivalent, currency: Currency.btc)}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.62),
                ),
            textAlign: TextAlign.center,
          ),
        if (wallet != null && btcEquivalent > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Destino bloqueado: hash publico da carteira ${wallet.name}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Quem pagar verá apenas o hash, o valor e o saldo antes da confirmação.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.54),
                  height: 1.35,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          Row(
            children: [
              _buildKey('.'),
              _buildKey('0'),
              _buildKey('←'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 68,
          margin: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(LucideIcons.delete,
                  color: Theme.of(context).colorScheme.onPrimary, size: 22)
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFamily: 'JetBrainsMono',
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
        ),
      ),
    );
  }

  Future<void> _generateAndNavigate() async {
    HapticFeedback.mediumImpact();
    setState(() => _isGenerating = true);

    final selectedWallet = _selectedWallet;
    if (selectedWallet == null) {
      setState(() => _isGenerating = false);
      SnackbarHelper.showError('Selecione uma carteira para receber.');
      return;
    }

    final double amountBtc = _paymentRequest.amountBtc ?? 0;
    final typedAmount = MoneyDisplay.parseEditableInput(_amount);
    final requestedAmountLabel = MoneyDisplay.format(
      amount: typedAmount,
      currency: _selectedCurrency,
    );
    final btcAmountLabel = MoneyDisplay.format(
      amount: amountBtc,
      currency: Currency.btc,
    );
    PaymentLink link;
    try {
      final result =
          await ref.read(ledgerRepositoryProvider).createPaymentRequest(
                amount: amountBtc,
                receiverWalletName: selectedWallet.name,
              );

      String? failureMessage;
      PaymentLink? createdLink;
      result.fold(
        (failure) => failureMessage = failure.message,
        (data) {
          final normalized = Map<String, dynamic>.from(data);
          final id = normalized['id']?.toString() ?? '';
          normalized['paymentUri'] = QrPaymentParser.encodePaymentLink(id);
          normalized['locked'] = true;
          createdLink = PaymentLink.fromJson(normalized);
        },
      );

      if (failureMessage != null) {
        throw failureMessage!;
      }
      if (createdLink == null || createdLink!.id.isEmpty) {
        throw 'Link de pagamento inválido retornado pelo servidor.';
      }

      link = createdLink!;

      ref.invalidate(paymentLinksProvider);
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(pagedTransactionHistoryProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _isGenerating = false);
        SnackbarHelper.showError(
          'Nao foi possivel gerar o link de pagamento: $error',
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isGenerating = false);

    final btcAmountDisplay = MoneyDisplay.format(
      amount: amountBtc,
      currency: Currency.btc,
      withSymbol: false,
    );
    final paymentUri =
        link.paymentUri ?? QrPaymentParser.encodePaymentLink(link.id);

    switch (widget.initialMode) {
      case ReceiveFlowMode.nfc:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfcInteractionScreen(
              amountDisplay: btcAmountDisplay,
              paymentUri: paymentUri,
            ),
          ),
        );
        return;
      case ReceiveFlowMode.qrCode:
      case ReceiveFlowMode.paymentLink:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceivePaymentLinkScreen(
              initialLink: link,
              requestedAmountLabel: requestedAmountLabel,
              btcAmountLabel: btcAmountLabel,
              walletLabel: selectedWallet.name,
            ),
          ),
        );
        return;
    }
  }
}
