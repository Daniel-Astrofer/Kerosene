import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:teste/core/presentation/widgets/recent_transaction_destinations_section.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/services/audio_service.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/features/transactions/presentation/screens/payment_confirmation_screen.dart';

import '../../../../core/utils/qr_payment_parser.dart';
import '../../../../core/widgets/transaction_auth_gate.dart';

import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';
import '../../presentation/widgets/receive_flow_ui.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? walletId;
  final String? initialAddress;
  final double? initialAmountBtc;

  const SendMoneyScreen({
    super.key,
    this.walletId,
    this.initialAddress,
    this.initialAmountBtc,
  });

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  double _lockedAmountBtc = 0.0;
  String? _lockedRecipientLabel;
  String? _lockedDestinationHash;
  bool _autoConfirmationScheduled = false;

  final _receiverController = TextEditingController();
  final _contextController = TextEditingController();

  String _amount = '0';
  late Currency _selectedCurrency;

  int _currentStep = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencyProvider);
    if (widget.initialAmountBtc != null) {
      _lockedAmountBtc = widget.initialAmountBtc!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _parsePaymentRequest(widget.initialAddress!);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _receiverController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_lockedAmountBtc > 0) return; // Prevent changing locked amount

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

  double _amountAsDouble() => MoneyDisplay.parseEditableInput(_amount);

  double _currentAmountBtc({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (_lockedAmountBtc > 0) {
      return _lockedAmountBtc;
    }
    return MoneyDisplay.convertToBtcAmount(
      amount: _amountAsDouble(),
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSending = ref.watch(
      sendTransactionProvider.select((state) => state.isLoading),
    );
    final isPayingLink = ref.watch(
      paymentLinkNotifierProvider.select((state) => state.isLoading),
    );
    final isLoading = isSending || isPayingLink;
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final hasLockedDestination =
        _pendingPaymentLinkId != null || _lockedRecipientAddress.isNotEmpty;

    return ReceiveFlowScaffold(
      title: context.l10n.send,
      subtitle: hasLockedDestination
          ? 'Pedido carregado com destino e valor travados para revisão.'
          : 'Informe o destino interno, defina o valor e confirme a transferência.',
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      onBack: () => _handleBack(hasLockedDestination),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (!hasLockedDestination) _buildDestinationStep(context),
          _buildAmountStep(
            context,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
            amountBtc: amountBtc,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  void _handleBack(bool hasLockedDestination) {
    if (_currentStep == 1 && !hasLockedDestination) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep = 0);
      return;
    }

    Navigator.pop(context);
  }

  Widget _buildManualFlowHero(BuildContext context) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: receiveFlowPanelColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: receiveFlowBorderColor),
            ),
            child: const Icon(
              LucideIcons.arrowUpRight,
              color: receiveFlowTextColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReceiveFlowSectionLabel('DESTINO INTERNO'),
                const SizedBox(height: 4),
                Text(
                  'Informe o identificador da carteira de destino e siga para a revisao do valor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
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

  Widget _buildAmountDisplay({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    final primaryAmount = _lockedAmountBtc > 0
        ? MoneyDisplay.convertFromBtcAmount(
            btcAmount: _lockedAmountBtc,
            currency: _selectedCurrency,
            btcUsd: btcUsd,
            btcEur: btcEur,
            btcBrl: btcBrl,
          )
        : _amountAsDouble();
    final primaryAmountLabel = _lockedAmountBtc > 0
        ? MoneyDisplay.format(
            amount: primaryAmount,
            currency: _selectedCurrency,
            withSymbol: false,
          )
        : MoneyDisplay.formatEditableInput(
            rawValue: _amount,
            currency: _selectedCurrency,
            withSymbol: false,
          );

    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            context.l10n.amount.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${MoneyDisplay.tickerSymbolFor(_selectedCurrency)} ",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: receiveFlowMutedTextColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Flexible(
                child: Text(
                  primaryAmountLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amountInput(
                    isBtc: _selectedCurrency == Currency.btc,
                    color: receiveFlowTextColor,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiatReferenceLine({required double amountBtc}) {
    return Text(
      'Equivale a ${MoneyDisplay.format(amount: amountBtc, currency: Currency.btc)}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: receiveFlowMutedTextColor,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildKeypad() {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
          Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
          Row(children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
          Row(children: [_buildKey('.'), _buildKey('0'), _buildKey('←')]),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    return ReceiveFlowKeypadButton(
      onTap: () => _onKeyTap(key),
      child: isBackspace
          ? const Icon(
              LucideIcons.delete,
              color: receiveFlowTextColor,
              size: 18,
            )
          : Text(
              key,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: receiveFlowTextColor,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w400,
                  ),
            ),
    );
  }

  Widget _buildLockedAmountView({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    final lockedPrimaryAmount = MoneyDisplay.convertFromBtcAmount(
      btcAmount: _lockedAmountBtc,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        children: [
          Text(
            MoneyDisplay.formatCompact(
              amount: lockedPrimaryAmount,
              currency: _selectedCurrency,
            ),
            style: AppTypography.amountInput(
              isBtc: _selectedCurrency == Currency.btc,
              color: receiveFlowTextColor,
            ).copyWith(
              fontSize: _selectedCurrency == Currency.btc ? 40 : 46,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedCurrency != Currency.btc)
            Text(
              MoneyDisplay.formatCompact(
                amount: _lockedAmountBtc,
                currency: Currency.btc,
              ),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: receiveFlowMutedTextColor,
                  ),
            ),
          if (_selectedCurrency != Currency.btc)
            const SizedBox(height: AppSpacing.sm),
          if (_lockedRecipientLabel != null) ...[
            Text(
              "PARA: ${_lockedRecipientLabel!.toUpperCase()}",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: receiveFlowTextColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            context.l10n.fixedAmountByRequest,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: receiveFlowFaintTextColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
          ),
        ],
      ),
    );
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    final currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) return;
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    HapticFeedback.mediumImpact();

    await _openPaymentConfirmation(
      wallet: currentWallet,
      amount: amountBtc,
      fee: 0,
      total: amountBtc,
      toAddress: _lockedRecipientAddress.isNotEmpty
          ? _lockedRecipientAddress
          : _receiverController.text.trim(),
      txContext: _contextController.text.trim(),
    );
  }

  Future<AccountSecurityProfile> _resolveSecurityProfile(Wallet wallet) async {
    try {
      return await ref.read(accountSecurityProfileProvider.future);
    } catch (_) {
      return _fallbackSecurityProfile(wallet.accountSecurity);
    }
  }

  AccountSecurityProfile _fallbackSecurityProfile(String rawSecurity) {
    final mode = accountSecurityModeFromApi(rawSecurity);
    final requiredFactors = switch (mode) {
      AccountSecurityMode.shamir => const ['SLIP39_SHARES', 'TOTP'],
      AccountSecurityMode.multisig2fa => const ['PASSPHRASE', 'TOTP'],
      AccountSecurityMode.passkey => const ['PASSKEY'],
      AccountSecurityMode.standard => const ['PASSKEY'],
    };

    return AccountSecurityProfile(
      mode: mode,
      passkeyAvailable: mode == AccountSecurityMode.standard,
      passkeyEnabledForTransactions: mode == AccountSecurityMode.standard,
      requiredFactors: requiredFactors,
    );
  }

  Wallet? _resolveWallet(WalletState walletState) {
    if (walletState is! WalletLoaded) return null;

    if (widget.walletId != null) {
      for (final wallet in walletState.wallets) {
        if (wallet.id == widget.walletId || wallet.name == widget.walletId) {
          return wallet;
        }
      }
    }

    return walletState.selectedWallet ??
        (walletState.wallets.isNotEmpty ? walletState.wallets.first : null);
  }

  Widget _buildDestinationStep(BuildContext context) {
    final recentInternalDestinations = ref
        .watch(recentTransactionDestinationsProvider)
        .where(
          (destination) =>
              destination.kind == RecentTransactionDestinationKind.internal,
        )
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildManualFlowHero(context),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.recipientData,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStepInput(
            controller: _receiverController,
            hint: 'Hash ou identificador da carteira',
            icon: LucideIcons.user,
          ),
          if (recentInternalDestinations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            RecentTransactionDestinationsSection(
              title: 'Ultimos destinos',
              destinations: recentInternalDestinations,
              onSelect: _applyRecentInternalDestination,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildStepInput(
            controller: _contextController,
            hint: context.l10n.descriptionHint,
            icon: LucideIcons.fileText,
            maxLength: 100,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ReceiveFlowPrimaryButton(
            label: 'CONTINUAR',
            icon: LucideIcons.arrowRight,
            onTap: () {
              if (_receiverController.text.trim().isEmpty) {
                SnackbarHelper.showError("Informe o destinatário");
                return;
              }
              if (_isExternalBitcoinTarget(_receiverController.text.trim())) {
                SnackbarHelper.showError(
                    "Pagamentos on-chain devem usar o fluxo de saque.");
                return;
              }
              FocusScope.of(context).unfocus();
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
              setState(() => _currentStep = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmountStep(
    BuildContext context, {
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    required double amountBtc,
    required bool isLoading,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Column(
        children: [
          if (_pendingPaymentLinkId == null &&
              _lockedRecipientAddress.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _buildAmountDisplay(
                btcUsd: btcUsd,
                btcEur: btcEur,
                btcBrl: btcBrl,
              ),
            ),
            if (_selectedCurrency != Currency.btc && amountBtc > 0) ...[
              _buildFiatReferenceLine(amountBtc: amountBtc),
              const SizedBox(height: AppSpacing.md),
            ],
            RepaintBoundary(
              child: _buildKeypad(),
            ),
          ] else ...[
            _buildLockedAmountView(
              btcUsd: btcUsd,
              btcEur: btcEur,
              btcBrl: btcBrl,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ReceiveFlowPrimaryButton(
            label: context.l10n.continueButton.toUpperCase(),
            icon: LucideIcons.arrowRight,
            isLoading: isLoading,
            onTap: amountBtc > 0 ? _handleContinue : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: receiveFlowPanelColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: receiveFlowBorderColor),
      ),
      child: TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: receiveFlowTextColor,
              fontWeight: FontWeight.w500,
            ),
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: receiveFlowFaintTextColor,
              ),
          counterText: '',
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          prefixIcon: Icon(
            icon,
            color: receiveFlowMutedTextColor,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Future<void> _openPaymentConfirmation({
    required Wallet wallet,
    required double amount,
    required double fee,
    required double total,
    required String toAddress,
    required String txContext,
  }) async {
    final selectedCurrency = ref.read(currencyProvider);
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final isPaymentLink = _pendingPaymentLinkId != null;
    final recipientLabel = _lockedRecipientLabel ?? toAddress;
    final destinationSubtitle = isPaymentLink
        ? null
        : _lockedRecipientLabel != null && _lockedRecipientLabel != toAddress
            ? toAddress
            : null;
    final amountLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: amount,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final totalLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: total,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final btcAmountLabel = MoneyDisplay.format(
      amount: amount,
      currency: Currency.btc,
    );
    final btcTotalLabel = MoneyDisplay.format(
      amount: total,
      currency: Currency.btc,
    );
    final balanceLabel = MoneyDisplay.formatAmountFromBtc(
      btcAmount: wallet.balance,
      currency: selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    final details = <PaymentConfirmationDetail>[
      PaymentConfirmationDetail(
        label: 'Tipo',
        value: isPaymentLink
            ? 'Pagamento por link interno'
            : 'Transferência interna Kerosene',
        icon: isPaymentLink ? LucideIcons.link : LucideIcons.repeat2,
      ),
      PaymentConfirmationDetail(
        label: 'Valor',
        value: amountLabel,
        icon: LucideIcons.bitcoin,
        emphasized: true,
      ),
      if (selectedCurrency != Currency.btc)
        PaymentConfirmationDetail(
          label: 'Valor em BTC',
          value: btcAmountLabel,
          icon: LucideIcons.coins,
          monospace: true,
        ),
      PaymentConfirmationDetail(
        label: context.l10n.networkFee,
        value: context.l10n.free,
        icon: LucideIcons.badgeDollarSign,
        valueColor: receiveFlowTextColor,
      ),
      PaymentConfirmationDetail(
        label: context.l10n.total,
        value: totalLabel,
        icon: LucideIcons.receipt,
        emphasized: true,
      ),
      if (selectedCurrency != Currency.btc)
        PaymentConfirmationDetail(
          label: 'Total em BTC',
          value: btcTotalLabel,
          icon: LucideIcons.equal,
          monospace: true,
        ),
      PaymentConfirmationDetail(
        label: 'Saldo antes do envio',
        value: balanceLabel,
        icon: LucideIcons.walletCards,
      ),
      if (txContext.isNotEmpty)
        PaymentConfirmationDetail(
          label: context.l10n.description,
          value: txContext,
          icon: LucideIcons.fileText,
        ),
      if (_pendingPaymentLinkId != null)
        PaymentConfirmationDetail(
          label: 'ID do link',
          value: _pendingPaymentLinkId!,
          icon: LucideIcons.fingerprint,
          monospace: true,
        ),
      if (isPaymentLink && _lockedDestinationHash != null)
        PaymentConfirmationDetail(
          label: 'Hash do destino',
          value: _lockedDestinationHash!,
          icon: LucideIcons.lock,
          monospace: true,
          copyable: true,
          copyMessage: 'Hash do destino copiado.',
        ),
    ];

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen<dynamic>(
          title:
              isPaymentLink ? 'Confirmar pagamento' : context.l10n.reviewSend,
          eyebrow: isPaymentLink ? 'Pedido bloqueado' : 'Revisão final',
          amountPrimary: amountLabel,
          amountSecondary: btcAmountLabel,
          sourceLabel: 'De',
          sourceValue: wallet.name,
          destinationLabel: 'Para',
          destinationValue: recipientLabel,
          destinationSubtitle: destinationSubtitle,
          networkLabel: 'Interno',
          notice: isPaymentLink
              ? 'Valor e destino foram definidos pelo link. Confirme apenas se reconhecer este pedido.'
              : 'Confira os dados antes de confirmar. Depois da autorização, o pedido será enviado ao servidor para processamento.',
          securityMessage:
              'A confirmação usa a sessão atual e os fatores de segurança configurados na sua conta antes de enviar o pagamento.',
          confirmText: context.l10n.confirm,
          cancelText: context.l10n.cancel,
          details: details,
          onConfirm: (confirmationContext, _) => _confirmPayment(
            confirmationContext: confirmationContext,
            wallet: wallet,
            amount: amount,
            fee: fee,
            toAddress: toAddress,
            txContext: txContext,
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  Future<dynamic> _confirmPayment({
    required BuildContext confirmationContext,
    required Wallet wallet,
    required double amount,
    required double fee,
    required String toAddress,
    required String txContext,
  }) async {
    final profile = await _resolveSecurityProfile(wallet);
    final authResult = await TransactionAuthGate.show(
      confirmationContext,
      profile: profile,
      allowDeviceAuthUnavailable: true,
    );

    if (!authResult.isAuthenticated || !mounted) {
      SnackbarHelper.showError("Autenticação cancelada ou falhou");
      return null;
    }

    if (_pendingPaymentLinkId != null) {
      final linkId = _pendingPaymentLinkId;
      if (linkId == null) {
        SnackbarHelper.showError("Solicitação de pagamento inválida.");
        return null;
      }

      final result = await ref.read(paymentLinkNotifierProvider.notifier).pay(
            linkId: linkId,
            payerWalletName: wallet.name,
            totpCode: authResult.totpCode,
            confirmationPassphrase: authResult.confirmationPassphrase,
            passkeyAssertionJson: authResult.passkeyAssertionJson,
          );

      if (result != null) {
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        ref.read(paymentLinkNotifierProvider.notifier).reset();
        return result;
      }

      AudioService.instance.playError();
      HapticFeedback.heavyImpact();
      final error = ref.read(paymentLinkNotifierProvider).error;
      if (error != null) {
        SnackbarHelper.showError(
          ErrorTranslator.translate(confirmationContext.l10n, error),
        );
      }
      ref.read(paymentLinkNotifierProvider.notifier).reset();
      return null;
    }

    final idempotencyKey = const Uuid().v4();
    final result = await ref.read(sendTransactionProvider.notifier).send(
          fromWalletId: wallet.id,
          fromAddress:
              wallet.address.trim().isEmpty ? null : wallet.address.trim(),
          toAddress: toAddress,
          amount: amount,
          feeSatoshis: (fee * 100000000).toInt(),
          context: txContext.isNotEmpty ? txContext : null,
          passkeyAssertionJson: authResult.passkeyAssertionJson,
          confirmationPassphrase: authResult.confirmationPassphrase,
          totpCode: authResult.totpCode,
          idempotencyKey: idempotencyKey,
          requestTimestamp: DateTime.now().millisecondsSinceEpoch,
        );

    if (result != null) {
      await ref
          .read(recentTransactionDestinationsProvider.notifier)
          .saveDestination(
            address: toAddress,
            kind: RecentTransactionDestinationKind.internal,
            label: _resolveRecentInternalDestinationLabel(toAddress),
          );
      AudioService.instance.playTransaction();
      HapticFeedback.vibrate();
      ref.read(sendTransactionProvider.notifier).reset();
      return result;
    }

    AudioService.instance.playError();
    HapticFeedback.heavyImpact();
    final error = ref.read(sendTransactionProvider).error;
    if (error != null) {
      SnackbarHelper.showError(
        ErrorTranslator.translate(confirmationContext.l10n, error),
      );
    }
    ref.read(sendTransactionProvider.notifier).reset();
    return null;
  }

  void _parsePaymentRequest(String data) {
    final linkId = QrPaymentParser.extractPaymentLinkId(data);
    if (linkId != null) {
      _fetchPaymentLinkDetails(linkId);
      return;
    }

    final parsed = QrPaymentParser.decode(data);
    if (parsed != null && parsed.isComplete) {
      if (_isExternalBitcoinTarget(parsed.address)) {
        SnackbarHelper.showError(
          "QR externo detectado. Use o fluxo de saque para pagamentos on-chain.",
        );
        return;
      }
      setState(() {
        _lockedRecipientAddress = parsed.address;
        if (parsed.amountBtc != null && parsed.amountBtc! > 0) {
          _lockedAmountBtc = parsed.amountBtc!;
          _amount = parsed.amountBtc!
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
        if (parsed.label != null && parsed.label!.isNotEmpty) {
          _lockedRecipientLabel = parsed.label;
        }
        if (parsed.message != null && parsed.message!.isNotEmpty) {
          _contextController.text = parsed.message!;
        }
      });

      HapticFeedback.lightImpact();
      SnackbarHelper.showSuccess("Dados da requisição carregados!");
    } else {
      SnackbarHelper.showError("QR/NFC Request inválido");
    }
  }

  Future<void> _fetchPaymentLinkDetails(String linkId) async {
    final result =
        await ref.read(ledgerRepositoryProvider).getPaymentRequest(linkId);

    result.fold((failure) {
      SnackbarHelper.showError(failure.message);
    }, (data) {
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      final rawAmount = payload['amount'];
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
      final status = (payload['status']?.toString() ?? 'PENDING').toUpperCase();
      final destinationHash = _readPaymentRequestDestinationHash(payload);

      if (status == 'PAID') {
        SnackbarHelper.showError("Esta solicitação já foi paga.");
        return;
      }
      if (status == 'CANCELED' || status == 'EXPIRED') {
        SnackbarHelper.showError("Esta solicitação de pagamento expirou.");
        return;
      }

      setState(() {
        _pendingPaymentLinkId = linkId;
        _lockedDestinationHash =
            destinationHash.isNotEmpty ? destinationHash : null;
        _lockedRecipientLabel = destinationHash.isNotEmpty
            ? _shortHash(destinationHash)
            : 'Destino bloqueado';
        _lockedRecipientAddress =
            destinationHash.isNotEmpty ? destinationHash : 'Destino bloqueado';
        if (amount > 0) {
          _lockedAmountBtc = amount;
          _amount = amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
      });
      SnackbarHelper.showSuccess("Solicitação de pagamento carregada.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openLockedPaymentConfirmationIfReady();
      });
    });
  }

  String _readPaymentRequestDestinationHash(Map<String, dynamic> data) {
    const keys = [
      'destinationHash',
      'destination_hash',
      'addressHash',
      'address_hash',
      'walletHash',
      'wallet_hash',
    ];

    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  void _applyRecentInternalDestination(
    RecentTransactionDestination destination,
  ) {
    final value = destination.address.trim();
    if (value.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _receiverController.text = value;
      _receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });
  }

  String? _resolveRecentInternalDestinationLabel(String toAddress) {
    final label = _lockedRecipientLabel?.trim();
    if (label == null ||
        label.isEmpty ||
        label == toAddress ||
        label == 'Destino bloqueado') {
      return null;
    }
    return label;
  }

  Future<void> _openLockedPaymentConfirmationIfReady() async {
    if (_autoConfirmationScheduled ||
        _pendingPaymentLinkId == null ||
        _lockedAmountBtc <= 0 ||
        !mounted) {
      return;
    }

    _autoConfirmationScheduled = true;

    var walletState = ref.read(walletProvider);
    var currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) {
      await ref.read(walletProvider.notifier).refresh();
      walletState = ref.read(walletProvider);
      currentWallet = _resolveWallet(walletState);
    }

    if (currentWallet == null) {
      SnackbarHelper.showError(
        'Carteira não carregada. Abra o pagamento novamente após sincronizar.',
      );
      return;
    }

    await _openPaymentConfirmation(
      wallet: currentWallet,
      amount: _lockedAmountBtc,
      fee: 0,
      total: _lockedAmountBtc,
      toAddress: _lockedRecipientAddress,
      txContext: _contextController.text.trim(),
    );
  }

  String _shortHash(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 8)}';
  }

  bool _isExternalBitcoinTarget(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('bitcoin:') ||
        normalized.startsWith('bc1') ||
        normalized.startsWith('tb1') ||
        normalized.startsWith('bcrt1') ||
        RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(value.trim());
  }
}
