import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo_loading_view.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/financial_activity/domain/entities/payment_link.dart';
import 'package:kerosene/features/financial_activity/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/financial_activity/presentation/widgets/transaction_amount_surface.dart';
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
  static const Color _black = KeroseneBrandTokens.backgroundSoft;
  static const Color _surface = KeroseneBrandTokens.surface;
  static const Color _buttonText = KeroseneBrandTokens.background;
  static const Color _border = KeroseneBrandTokens.border;
  static const Color _text = KeroseneBrandTokens.textPrimary;
  static const Color _mutedText = KeroseneBrandTokens.textSecondary;
  static const Color _outline = KeroseneBrandTokens.textMuted;

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
      backgroundColor: _black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final compact = height < 720;
            final dense = height < 640;
            final sidePadding = width < 380 ? 18.0 : 24.0;
            final amountFontSize = width < 360
                ? 42.0
                : dense
                    ? 46.0
                    : compact
                        ? 50.0
                        : 56.0;
            final verticalGap = dense
                ? 10.0
                : compact
                    ? 14.0
                    : 20.0;
            final keypadMaxWidth =
                width < 390 ? width - sidePadding * 2 : 360.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                8,
                sidePadding,
                dense ? 10 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  SizedBox(height: dense ? 2 : 8),
                  const Spacer(),
                  _buildCenteredAmount(
                    context,
                    amountLabel: amountLabel,
                    fiatLabel: fiatLabel,
                    amountFontSize: amountFontSize,
                  ),
                  SizedBox(height: verticalGap),
                  _buildReceiveContext(context),
                  const Spacer(),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: keypadMaxWidth.clamp(280.0, 360.0).toDouble(),
                      ),
                      child: TransactionKeypad(
                        mode: TransactionKeypadMode.decimal,
                        onKeyTap: _onKeyTap,
                        textColor: _text,
                        mutedTextColor: _mutedText,
                        pressedColor: _surface,
                      ),
                    ),
                  ),
                  SizedBox(height: dense ? 10 : 14),
                  TransactionPrimaryButton(
                    label: widget.method == ReceiveAmountMethod.paymentLink
                        ? context.tr.receiveGenAction
                        : context.tr.continueButton,
                    enabled: _amountBtc > 0 && !_isContinuing,
                    isLoading: _isContinuing,
                    onTap: _continue,
                    backgroundColor: _text,
                    foregroundColor: _buttonText,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String get _networkLabel => widget.onChainWallet ? 'On-chain' : 'Kerosene';

  Widget _buildCenteredAmount(
    BuildContext context, {
    required String amountLabel,
    required String fiatLabel,
    required double amountFontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: amountFontSize + 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: FittedBox(
              key: ValueKey(amountLabel),
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: amountLabel),
                    TextSpan(
                      text: ' BTC',
                      style: AppTypography.captionLarge.copyWith(
                        color: _mutedText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppTypography.amountInput(
                  isBtc: true,
                  color: _text,
                ).copyWith(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: Text(
            fiatLabel,
            key: ValueKey(fiatLabel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.captionLarge.copyWith(
              color: _mutedText,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiveContext(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildContextLine(
          label: 'Destino',
          value: widget.wallet.name,
          secondaryValue: _shortAddress(widget.wallet.address),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: _border.withValues(alpha: 0.72),
        ),
        _buildContextLine(
          label: 'Rede',
          value: _networkLabel,
        ),
      ],
    );
  }

  Widget _buildContextLine({
    required String label,
    required String value,
    String? secondaryValue,
  }) {
    final secondary = secondaryValue?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: secondary == null || secondary.isEmpty
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _mutedText,
                      fontSize: 14,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.financial(
                      textStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _text,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                                letterSpacing: 0,
                              ),
                    ),
                  ),
                  if (secondary != null && secondary.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTypography.technicalMono(
                        textStyle:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _outline,
                                  fontSize: 12,
                                  height: 1.15,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(KeroseneIcons.back),
          color: _text,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            shape: const CircleBorder(),
          ),
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
