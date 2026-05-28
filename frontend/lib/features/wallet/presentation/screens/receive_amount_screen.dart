import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/l10n/l10n_extension.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/domain/entities/payment_link.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/screens/receive_method.dart';
import 'package:teste/features/wallet/presentation/screens/receive_nfc_flow_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_request_flow_screen.dart';

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
  static const Color _black = Color(0xFF000000);
  static const Color _surface = Color(0xFF111111);
  static const Color _border = Color(0xFF2C2C2E);
  static const Color _text = Color(0xFFFFFFFF);
  static const Color _mutedText = Color(0xFFA3A3A3);
  static const Color _outline = Color(0xFF666666);

  String _amount = '0';
  bool _keyboardExpanded = true;
  bool _isContinuing = false;

  String get _methodTitle {
    return switch (widget.method) {
      ReceiveAmountMethod.qrCode => 'QR Code',
      ReceiveAmountMethod.paymentLink => 'Link de pagamento',
      ReceiveAmountMethod.nfc => 'NFC',
    };
  }

  IconData get _methodIcon {
    return switch (widget.method) {
      ReceiveAmountMethod.qrCode => LucideIcons.qrCode,
      ReceiveAmountMethod.paymentLink => LucideIcons.link2,
      ReceiveAmountMethod.nfc => LucideIcons.nfc,
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
    if (widget.onChainWallet) {
      if (widget.method != ReceiveAmountMethod.paymentLink) {
        return null;
      }
      return ref.read(transactionRepositoryProvider).createPaymentLink(
        amount: _amountBtc,
        description: 'Recebimento ${widget.wallet.name}',
        expiresInMinutes: 60,
        visibility: 'PRIVATE',
        confirmationMode: 'USER_ACTION_REQUIRED',
        amountLocked: true,
        metadata: {
          'walletName': widget.wallet.name,
          'rail': 'ONCHAIN',
          'source': 'receive_flow',
        },
      );
    }

    final link = await ref.read(paymentLinkNotifierProvider.notifier).create(
          amount: _amountBtc,
          receiverWalletName: widget.wallet.name,
        );
    if (link != null) {
      return link;
    }
    final error = ref.read(paymentLinkNotifierProvider).error;
    throw Exception(error ?? 'Nao foi possivel criar o recebimento.');
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Center(child: _buildMethodChip(context)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 240;
                        final topPadding = compact ? 12.0 : 40.0;
                        final bottomPadding = compact ? 8.0 : 16.0;
                        final minHeight =
                            constraints.maxHeight - topPadding - bottomPadding;
                        final content = _buildAmountContent(
                          context,
                          amountLabel: amountLabel,
                          fiatLabel: fiatLabel,
                          compact: compact,
                        );

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            topPadding,
                            16,
                            bottomPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minHeight > 0 ? minHeight : 0,
                            ),
                            child: content,
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: _keyboardExpanded
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                            child: RepaintBoundary(child: _buildKeypad()),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              decoration: BoxDecoration(
                color: _black,
                border: Border(
                  top: BorderSide(color: _border.withValues(alpha: 0.3)),
                ),
              ),
              child: _buildPrimaryButton(context),
            ),
          ],
        ),
      ),
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
              icon: const Icon(LucideIcons.chevronLeft),
              color: _text,
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                'Valor a receber',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSerif(
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

  Widget _buildAmountContent(
    BuildContext context, {
    required String amountLabel,
    required String fiatLabel,
    required bool compact,
  }) {
    final amountFontSize = compact ? 42.0 : 54.0;
    final unitFontSize = compact ? 22.0 : 28.0;
    final summaryGap = compact ? 20.0 : 40.0;

    return Column(
      mainAxisAlignment:
          compact ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _keyboardExpanded = !_keyboardExpanded);
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSerif(
                        color: _text,
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.w100,
                        height: 1.05,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BTC',
                    style: GoogleFonts.ibmPlexSerif(
                      color: _text,
                      fontSize: unitFontSize,
                      fontWeight: FontWeight.w100,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fiatLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _outline,
                      fontFamily: 'IBMPlexSansHebrew',
                      fontSize: compact ? 12 : 14,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: summaryGap),
        _buildWalletSummary(context, compact: compact),
      ],
    );
  }

  Widget _buildMethodChip(BuildContext context) {
    final rail = widget.onChainWallet ? 'Carteira fria' : 'Kerosene';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_methodIcon, color: _outline, size: 18),
          const SizedBox(width: 8),
          Text(
            '$rail · $_methodTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _text,
                  fontSize: 16,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSummary(BuildContext context, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DESTINO DO RECEBIMENTO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _outline,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.wallet.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _mutedText,
                  fontFamily: 'IBMPlexSansHebrew',
                  fontSize: compact ? 12 : 14,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _amountBtc > 0 && !_isContinuing ? _continue : null,
        style: FilledButton.styleFrom(
          backgroundColor: _text,
          foregroundColor: _black,
          disabledBackgroundColor: _text.withValues(alpha: 0.22),
          disabledForegroundColor: _text.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
        ),
        child: _isContinuing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _black,
                ),
              )
            : const Text('CONTINUAR'),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
        Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
        Row(children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
        Row(children: [_buildKey('.'), _buildKey('0'), _buildKey('←')]),
      ],
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    final display = key == '.' ? '.' : key;

    return Expanded(
      child: SizedBox(
        height: 58,
        child: TextButton(
          onPressed: () => _onKeyTap(key),
          style: TextButton.styleFrom(
            foregroundColor: isBackspace ? _outline : _text,
            shape: const CircleBorder(),
            textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'IBMPlexSansHebrew',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
          ),
          child: isBackspace
              ? const Icon(LucideIcons.delete, size: 24)
              : Text(display),
        ),
      ),
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
