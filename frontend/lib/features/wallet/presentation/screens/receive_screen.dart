import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/utils/currency_logic.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/utils/qr_payment_parser.dart'; // [NEW]
import '../../../auth/controller/auth_providers.dart';
import '../../../transactions/domain/entities/payment_link.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/payment_request.dart';
import '../../presentation/providers/wallet_provider.dart'
    hide transactionRepositoryProvider;
import '../../presentation/state/wallet_state.dart';
import '../../presentation/widgets/receive_flow_ui.dart';
import 'deposit/deposit_amount_screen.dart';
import 'deposit/deposit_lightning_invoice_screen.dart';
import 'deposit/deposit_onchain_invoice_screen.dart';
import 'nfc_interaction_screen.dart';
import 'receive_payment_link_screen.dart';

enum ReceiveFlowMode { qrCode, nfc, paymentLink, onChain, lightning }

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
      case ReceiveFlowMode.onChain:
        return LucideIcons.network;
      case ReceiveFlowMode.lightning:
        return LucideIcons.zap;
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
      case ReceiveFlowMode.onChain:
        return 'ON-CHAIN';
      case ReceiveFlowMode.lightning:
        return 'LIGHTNING';
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
      case ReceiveFlowMode.onChain:
        return 'Gere um URI Bitcoin on-chain padrao com valor e rota predefinidos.';
      case ReceiveFlowMode.lightning:
        return 'Gere uma invoice Lightning Network de liquidacao instantanea.';
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
      case ReceiveFlowMode.onChain:
        return 'GERAR QR ON-CHAIN';
      case ReceiveFlowMode.lightning:
        return 'GERAR INVOICE LN';
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

  void _openDeposit() {
    final wallet = _selectedWallet;
    if (wallet == null) {
      SnackbarHelper.showError('Selecione uma carteira para depositar.');
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DepositAmountScreen(wallet: wallet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activationAsync = ref.watch(activationStatusProvider);
    final activationStatus = activationAsync.asData?.value;
    final inboundBlocked = activationStatus?.canReceiveInbound != true;

    return ReceiveFlowScaffold(
      title: 'Receber',
      subtitle: _screenSubtitle(context),
      scrollable: inboundBlocked,
      bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (inboundBlocked) ...[
            _buildInboundBlockedCard(activationAsync.asData?.value),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildFlowHero(context),
          const SizedBox(height: AppSpacing.md),
          AbsorbPointer(
            absorbing: inboundBlocked,
            child: Opacity(
              opacity: inboundBlocked ? 0.45 : 1,
              child: Column(
                children: [
                  _buildAmountDisplay(),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypad(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPrimaryButton(
            label: _continueLabel(context),
            isLoading: _isGenerating,
            onTap:
                !inboundBlocked && MoneyDisplay.parseEditableInput(_amount) > 0
                    ? _generateAndNavigate
                    : null,
          ),
        ],
      ),
    );
  }

  String _screenSubtitle(BuildContext context) {
    switch (widget.initialMode) {
      case ReceiveFlowMode.qrCode:
        return 'Defina o valor e gere um QR interno com destino bloqueado.';
      case ReceiveFlowMode.nfc:
        return 'Defina o valor e prepare uma cobrança por aproximação.';
      case ReceiveFlowMode.paymentLink:
        return 'Defina o valor e gere uma cobrança rastreada.';
      case ReceiveFlowMode.onChain:
        return 'Defina o valor e gere um payload Bitcoin compatível.';
      case ReceiveFlowMode.lightning:
        return 'Defina o valor e siga para uma invoice Lightning.';
    }
  }

  Widget _buildFlowHero(BuildContext context) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: Icon(
              _flowIcon,
              color: receiveFlowTextColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReceiveFlowSectionLabel(_flowEyebrow(context)),
                const SizedBox(height: 4),
                Text(
                  _flowDescription(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboundBlockedCard(dynamic activationStatus) {
    final warning = activationStatus?.warningMessage?.toString() ??
        'Para receber fundos dentro da plataforma, deposite algum valor primeiro.';

    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      borderColor: receiveFlowBorderStrongColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: receiveFlowPanelRaisedColor,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(
                    color: receiveFlowBorderStrongColor,
                  ),
                ),
                child: const Icon(
                  LucideIcons.shieldOff,
                  color: receiveFlowTextColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECEBIMENTO BLOQUEADO',
                      style: TextStyle(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      warning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: receiveFlowTextColor,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _openDeposit,
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Depositar'),
                style: TextButton.styleFrom(
                  foregroundColor: receiveFlowMutedTextColor,
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(activationStatusProvider),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Atualizar status'),
                style: TextButton.styleFrom(
                  foregroundColor: receiveFlowMutedTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
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

    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            context.l10n.howMuchToReceive,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: receiveFlowMutedTextColor,
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
              color: receiveFlowTextColor,
            ).copyWith(
              fontSize: _selectedCurrency == Currency.btc ? 42 : 46,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedCurrency != Currency.btc)
            Text(
              'Equivale a ${MoneyDisplay.formatCompact(amount: btcEquivalent, currency: Currency.btc)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                  ),
              textAlign: TextAlign.center,
            ),
          if (wallet != null && btcEquivalent > 0) ...[
            const SizedBox(height: AppSpacing.md),
            ReceiveFlowTag(
              label: 'Destino ${wallet.name}',
              icon: LucideIcons.lock,
            ),
            const SizedBox(height: 8),
            Text(
              'Quem pagar verá apenas hash público, valor e saldo antes da confirmação.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowFaintTextColor,
                    height: 1.3,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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

    if (widget.initialMode == ReceiveFlowMode.onChain ||
        widget.initialMode == ReceiveFlowMode.lightning) {
      setState(() => _isGenerating = false);
      if (!mounted) {
        return;
      }

      final route = MaterialPageRoute<void>(
        builder: (_) => widget.initialMode == ReceiveFlowMode.lightning
            ? DepositLightningInvoiceScreen(
                wallet: selectedWallet,
                inputAmount: typedAmount,
                inputCurrency: _selectedCurrency,
                providerName: 'Kerosene',
              )
            : DepositOnchainInvoiceScreen(
                wallet: selectedWallet,
                inputAmount: typedAmount,
                inputCurrency: _selectedCurrency,
                providerName: 'Kerosene',
              ),
      );
      Navigator.push(context, route);
      return;
    }

    PaymentLink link;
    try {
      if (widget.initialMode == ReceiveFlowMode.paymentLink) {
        final config = await _showPaymentLinkConfigSheet();
        if (config == null) {
          if (mounted) {
            setState(() => _isGenerating = false);
          }
          return;
        }
        link = await ref.read(transactionRepositoryProvider).createPaymentLink(
              amount: amountBtc,
              description: config.description,
              expiresInMinutes: config.expiresInMinutes,
              visibility: config.visibility,
              confirmationMode: config.confirmationMode,
              amountLocked: true,
              referenceLabel: config.referenceLabel,
              metadata: config.metadata,
            );
      } else {
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
      }

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
      case ReceiveFlowMode.onChain:
      case ReceiveFlowMode.lightning:
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

  Future<_PaymentLinkConfig?> _showPaymentLinkConfigSheet() {
    final descriptionController = TextEditingController(
      text: 'Recebimento ${_selectedWallet?.name ?? 'Kerosene'}',
    );
    final referenceController = TextEditingController();
    final customerController = TextEditingController();
    final noteController = TextEditingController();
    int expiresInMinutes = 60;
    String visibility = 'PRIVATE';
    String confirmationMode = 'MANUAL_REVIEW';

    return showModalBottomSheet<_PaymentLinkConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: monochromePanelDecoration(
                  color: monoSurfaceColor,
                  borderColor: monoBorderStrongColor,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1,
                        width: 52,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        color: monoBorderStrongColor,
                      ),
                      Text(
                        'CONFIGURAR LINK',
                        style: AppTypography.caption.copyWith(
                          color: monoMutedTextColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Link de pagamento',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: monoTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Defina validade, visibilidade e identificadores antes de gerar o link.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: monoMutedTextColor,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: monoTextColor),
                        decoration: monochromeInputDecoration(
                          label: 'Descricao',
                        ),
                      ),
                      TextField(
                        controller: referenceController,
                        style: const TextStyle(color: monoTextColor),
                        decoration: monochromeInputDecoration(
                          label: 'Referencia',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        initialValue: expiresInMinutes,
                        dropdownColor: monoSurfaceAltColor,
                        style: const TextStyle(color: monoTextColor),
                        items: const [
                          DropdownMenuItem(
                              value: 15, child: Text('15 minutos')),
                          DropdownMenuItem(value: 60, child: Text('1 hora')),
                          DropdownMenuItem(value: 180, child: Text('3 horas')),
                          DropdownMenuItem(
                              value: 1440, child: Text('24 horas')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => expiresInMinutes = value);
                          }
                        },
                        decoration: monochromeInputDecoration(
                          label: 'Validade',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: visibility,
                        dropdownColor: monoSurfaceAltColor,
                        style: const TextStyle(color: monoTextColor),
                        items: const [
                          DropdownMenuItem(
                            value: 'PRIVATE',
                            child: Text('Privado'),
                          ),
                          DropdownMenuItem(
                            value: 'PUBLIC',
                            child: Text('Público'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => visibility = value);
                          }
                        },
                        decoration: monochromeInputDecoration(
                          label: 'Visibilidade',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: confirmationMode,
                        dropdownColor: monoSurfaceAltColor,
                        style: const TextStyle(color: monoTextColor),
                        items: const [
                          DropdownMenuItem(
                            value: 'MANUAL_REVIEW',
                            child: Text('Confirmação manual'),
                          ),
                          DropdownMenuItem(
                            value: 'AUTO_COMPLETE',
                            child: Text('Completar automaticamente'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => confirmationMode = value);
                          }
                        },
                        decoration: monochromeInputDecoration(
                          label: 'Fechamento',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: customerController,
                        style: const TextStyle(color: monoTextColor),
                        decoration: monochromeInputDecoration(
                          label: 'Cliente',
                        ),
                      ),
                      TextField(
                        controller: noteController,
                        style: const TextStyle(color: monoTextColor),
                        decoration: monochromeInputDecoration(
                          label: 'Nota',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        style: monochromeFilledButtonStyle(),
                        onPressed: () {
                          Navigator.of(context).pop(
                            _PaymentLinkConfig(
                              description: descriptionController.text.trim(),
                              referenceLabel: referenceController.text.trim(),
                              expiresInMinutes: expiresInMinutes,
                              visibility: visibility,
                              confirmationMode: confirmationMode,
                              metadata: {
                                if (customerController.text.trim().isNotEmpty)
                                  'customer': customerController.text.trim(),
                                if (noteController.text.trim().isNotEmpty)
                                  'note': noteController.text.trim(),
                              },
                            ),
                          );
                        },
                        child: const Text('GERAR LINK'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentLinkConfig {
  final String description;
  final String referenceLabel;
  final int expiresInMinutes;
  final String visibility;
  final String confirmationMode;
  final Map<String, String> metadata;

  const _PaymentLinkConfig({
    required this.description,
    required this.referenceLabel,
    required this.expiresInMinutes,
    required this.visibility,
    required this.confirmationMode,
    required this.metadata,
  });
}
