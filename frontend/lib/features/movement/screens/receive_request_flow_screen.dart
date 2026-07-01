import 'package:kerosene/core/theme/app_colors.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/movement/domain/entities/external_transfer.dart';
import 'package:kerosene/features/movement/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/movement/domain/entities/payment_link.dart';
import 'package:kerosene/features/movement/providers/transaction_provider.dart';
import 'package:kerosene/features/movement/widgets/movement_confirmation_surface.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';
import 'package:kerosene/features/movement/screens/receive_method.dart';
import 'receive_request_flow_components.dart';

enum ReceiveRequestStage { qr, confirmations, identified }

const _receiveBackground = AppColors.hexFF050505;
const _receiveBorder = AppColors.hexFF2A2A2A;
const _receiveText = AppColors.hexFFFFFFFF;
const _receiveMuted = AppColors.hexFFA3A3A3;

class ReceiveRequestFlowScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final bool onChainWallet;
  final double amountBtc;
  final ReceiveAmountMethod method;
  final PaymentLink? initialPaymentLink;
  final ReceiveRequestStage? initialStage;
  final bool enableStatusPolling;
  final String? initialAddress;
  final String? initialPaymentUri;
  final String? initialTxid;
  final int? initialConfirmations;
  final int? requiredConfirmations;
  final DateTime? identifiedAt;

  const ReceiveRequestFlowScreen({
    super.key,
    required this.wallet,
    required this.onChainWallet,
    required this.amountBtc,
    required this.method,
    this.initialPaymentLink,
    this.initialStage,
    this.enableStatusPolling = true,
    this.initialAddress,
    this.initialPaymentUri,
    this.initialTxid,
    this.initialConfirmations,
    this.requiredConfirmations,
    this.identifiedAt,
  });

  @override
  ConsumerState<ReceiveRequestFlowScreen> createState() =>
      _ReceiveRequestFlowScreenState();
}

class _ReceiveRequestFlowScreenState
    extends ConsumerState<ReceiveRequestFlowScreen>
    with SingleTickerProviderStateMixin {
  Timer? _statusTimer;
  late final AnimationController _scanController;
  late ReceiveRequestStage _stage;
  late DateTime _identifiedAt;

  PaymentLink? _link;
  OnchainAddressAllocation? _allocation;
  ExternalTransfer? _observedTransfer;
  String? _address;
  String? _paymentUri;
  String? _txid;
  String? _errorMessage;
  bool _isLoadingRequest = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: KeroseneMotion.ceremonial,
    )..repeat();
    _stage = widget.initialStage ?? ReceiveRequestStage.qr;
    _identifiedAt = widget.identifiedAt ?? DateTime.now();
    _link = widget.initialPaymentLink;
    _address = widget.initialAddress ?? _link?.depositAddress;
    _paymentUri = widget.initialPaymentUri ?? _paymentUriFor(_link);
    _txid = widget.initialTxid ?? _link?.txid;

    if (widget.enableStatusPolling) {
      scheduleMicrotask(_prepareRequest);
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _prepareRequest() async {
    final link = _link;
    if (widget.onChainWallet && link == null) {
      await _issueOnchainAddress();
      return;
    }

    if (link != null) {
      _applyPaymentLinkStage(link);
      if (_stage == ReceiveRequestStage.identified) {
        return;
      }
      _startPaymentLinkPolling();
    }
  }

  Future<void> _issueOnchainAddress() async {
    setState(() {
      _isLoadingRequest = true;
      _errorMessage = null;
    });

    try {
      final allocation =
          await ref.read(transactionRepositoryProvider).issueOnchainAddress(
                walletName: widget.wallet.id,
                expectedAmountBtc: widget.amountBtc,
              );
      if (!mounted) return;

      final nextAddress = allocation.onchainAddress.trim();
      if (nextAddress.isEmpty || !allocation.hasTransferId) {
        setState(() {
          _isLoadingRequest = false;
          _errorMessage =
              'Nao foi possivel preparar o acompanhamento deste recebimento.';
        });
        return;
      }

      setState(() {
        _allocation = allocation;
        _address = nextAddress;
        _paymentUri = QrPaymentParser.encode(
          address: nextAddress,
          amountBtc: widget.amountBtc,
          label: widget.wallet.name,
          message: 'Recebimento Kerosene',
        );
        _txid = allocation.blockchainTxid.trim().isEmpty
            ? null
            : allocation.blockchainTxid.trim();
        _isLoadingRequest = false;
        _stage = _stageForOnchain(
          status: allocation.transferStatus,
          confirmations: allocation.confirmations,
          txid: allocation.blockchainTxid,
        );
      });
      _startTransferPolling();
    } catch (error) {
      if (!mounted) return;
      final translated =
          ErrorTranslator.translate(context.tr, error.toString());
      setState(() {
        _isLoadingRequest = false;
        _errorMessage = translated;
      });
      SnackbarHelper.showError(translated);
    }
  }

  void _startTransferPolling() {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty) return;
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      KeroseneMotion.notificationLongHold,
      (_) => _refreshObservedTransfer(),
    );
  }

  Future<void> _refreshObservedTransfer() async {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty) return;

    try {
      final latest = await ref
          .read(transactionRepositoryProvider)
          .getExternalTransfer(transferId);
      if (!mounted) return;

      final previousStatus =
          (_observedTransfer?.status ?? _allocation?.transferStatus ?? '')
              .trim()
              .toUpperCase();
      final previousConfirmations =
          _observedTransfer?.confirmations ?? _allocation?.confirmations ?? 0;
      final latestStatus = latest.status.trim().toUpperCase();

      setState(() {
        _observedTransfer = latest;
        _txid = latest.blockchainTxid.trim().isEmpty
            ? _txid
            : latest.blockchainTxid.trim();
        _stage = _stageForOnchain(
          status: latest.status,
          confirmations: latest.confirmations,
          txid: latest.blockchainTxid,
        );
        if (_stage == ReceiveRequestStage.identified) {
          _identifiedAt = DateTime.now();
        }
      });

      if (previousStatus != latestStatus ||
          previousConfirmations != latest.confirmations) {
        ref.invalidate(externalTransfersProvider);
        ref.invalidate(transactionHistoryProvider);
      }

      if (_stage == ReceiveRequestStage.identified) {
        _statusTimer?.cancel();
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Keep the QR usable if the status refresh fails transiently.
    }
  }

  ReceiveRequestStage _stageForOnchain({
    required String status,
    required int confirmations,
    required String txid,
  }) {
    final normalized = status.trim().toUpperCase();
    final required = _requiredConfirmations;
    final complete = normalized == 'COMPLETED' ||
        normalized == 'SETTLED' ||
        (confirmations >= required &&
            (normalized == 'CONFIRMED' ||
                normalized == 'CREDITED' ||
                normalized == 'SETTLED'));
    if (complete) {
      return ReceiveRequestStage.identified;
    }
    if (txid.trim().isNotEmpty ||
        confirmations > 0 ||
        normalized == 'DETECTED' ||
        normalized == 'MEMPOOL' ||
        normalized == 'CONFIRMED') {
      return ReceiveRequestStage.confirmations;
    }
    return ReceiveRequestStage.qr;
  }

  void _startPaymentLinkPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      KeroseneMotion.notificationLongHold,
      (_) => _refreshPaymentLink(),
    );
  }

  Future<void> _refreshPaymentLink() async {
    final linkId = _link?.id.trim() ?? '';
    if (linkId.isEmpty) return;

    try {
      final PaymentLink latest;
      latest = await ref.read(transactionRepositoryProvider).getPaymentLink(
            linkId,
          );

      if (!mounted) return;
      final previousStatus = _link?.status.trim().toLowerCase() ?? '';
      final previousTxid = _link?.txid?.trim() ?? '';
      final latestStatus = latest.status.trim().toLowerCase();
      final latestTxid = latest.txid?.trim() ?? '';

      setState(() {
        _link = latest;
        _address = latest.depositAddress.trim().isEmpty
            ? _address
            : latest.depositAddress.trim();
        _paymentUri = _paymentUriFor(latest);
        _txid = latest.txid?.trim().isEmpty == true ? _txid : latest.txid;
        _applyPaymentLinkStage(latest);
      });

      if (previousStatus != latestStatus || previousTxid != latestTxid) {
        ref.invalidate(paymentLinksProvider);
        ref.invalidate(transactionHistoryProvider);
        if (widget.onChainWallet) {
          ref.invalidate(externalTransfersProvider);
        }
      }

      if (_stage == ReceiveRequestStage.identified) {
        _statusTimer?.cancel();
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Payment polling is intentionally quiet; the QR/link stays available.
    }
  }

  void _applyPaymentLinkStage(PaymentLink link) {
    if (link.isPaid || link.isCompleted) {
      _stage = ReceiveRequestStage.identified;
      _identifiedAt = link.completedAt ?? link.paidAt ?? DateTime.now();
      return;
    }
    if (link.isVerifyingOnboarding || (link.txid?.trim().isNotEmpty ?? false)) {
      _stage = ReceiveRequestStage.confirmations;
      return;
    }
    _stage = ReceiveRequestStage.qr;
  }

  String? _paymentUriFor(PaymentLink? link) {
    if (link == null) return null;
    final explicitUri = link.paymentUri?.trim();
    if (explicitUri != null && explicitUri.isNotEmpty) {
      return explicitUri;
    }
    if (link.isInternalPaymentRequest || !widget.onChainWallet) {
      return QrPaymentParser.encodePaymentLink(link.id);
    }
    final address = link.depositAddress.trim();
    if (address.isEmpty) return null;
    return QrPaymentParser.encode(
      address: address,
      amountBtc: link.amountBtc > 0 ? link.amountBtc : widget.amountBtc,
      label: widget.wallet.name,
      message: link.description,
    );
  }

  String get _addressValue {
    final current = _address?.trim() ?? '';
    if (current.isNotEmpty) return current;
    final linkAddress = _link?.depositAddress.trim() ?? '';
    if (linkAddress.isNotEmpty) return linkAddress;
    return widget.wallet.address.trim();
  }

  String get _paymentValue {
    final current = _paymentUri?.trim() ?? '';
    if (current.isNotEmpty) return current;
    if (widget.onChainWallet) {
      return QrPaymentParser.encode(
        address: _addressValue,
        amountBtc: widget.amountBtc,
        label: widget.wallet.name,
        message: 'Recebimento Kerosene',
      );
    }
    return QrPaymentParser.encodeKerosene(
      address: _addressValue,
      amountBtc: widget.amountBtc,
      label: widget.wallet.name,
    );
  }

  int get _requiredConfirmations {
    if (!widget.onChainWallet) return widget.requiredConfirmations ?? 1;
    return widget.requiredConfirmations ??
        _allocation?.requiredConfirmations ??
        3;
  }

  int get _currentConfirmations {
    if (!widget.onChainWallet) {
      if (_stage == ReceiveRequestStage.identified) {
        return _requiredConfirmations;
      }
      return widget.initialConfirmations ?? 0;
    }
    return _observedTransfer?.confirmations ??
        _allocation?.confirmations ??
        widget.initialConfirmations ??
        0;
  }

  String get _networkLabel {
    if (!widget.onChainWallet) return 'Kerosene';
    final network = (_allocation?.network ?? '').trim().toLowerCase();
    return switch (network) {
      'testnet' => 'Bitcoin Testnet',
      'regtest' => 'Bitcoin Regtest',
      _ => 'Bitcoin (BTC)',
    };
  }

  String get _statusLabel {
    if (widget.onChainWallet) return 'Confirmado na rede';
    return 'Confirmado na Kerosene';
  }

  String get _amountLabel => '${widget.amountBtc.toStringAsFixed(6)} BTC';

  String get _fiatLabel {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    return '≈ ${MoneyDisplay.formatAmountFromBtc(
      btcAmount: widget.amountBtc,
      currency: Currency.usd,
      btcUsd: btcUsd,
      btcEur: null,
      btcBrl: null,
    )}';
  }

  Future<void> _copyPaymentValue() async {
    final successMessage = context.tr.receiveQrCopied;
    await Clipboard.setData(ClipboardData(text: _paymentValue));
    await HapticFeedback.selectionClick();
    SnackbarHelper.showSuccess(successMessage);
  }

  Future<void> _copyAddressValue() async {
    final address = _addressValue.trim();
    if (address.isEmpty) {
      return;
    }
    final successMessage = context.tr.receivePaymentLinkDepositAddressCopied;

    await Clipboard.setData(ClipboardData(text: address));
    await HapticFeedback.selectionClick();
    SnackbarHelper.showSuccess(successMessage);
  }

  Future<void> _sharePaymentValue() async {
    final successMessage = context.tr.apiDisplayDataCopied;
    await Clipboard.setData(ClipboardData(text: _paymentValue));
    await HapticFeedback.selectionClick();
    SnackbarHelper.showSuccess(successMessage);
  }

  void _goHome() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_stage) {
      ReceiveRequestStage.qr => _buildQrScreen(context),
      ReceiveRequestStage.confirmations => _buildConfirmationsScreen(context),
      ReceiveRequestStage.identified => _buildIdentifiedScreen(context),
    };

    return Scaffold(
      backgroundColor: _receiveBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: KeroseneMotion.medium,
                  switchInCurve: KeroseneMotion.standard,
                  switchOutCurve: KeroseneMotion.exit,
                  child: KeyedSubtree(key: ValueKey(_stage), child: child),
                ),
                if (_isLoadingRequest) const ReceiveLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrScreen(BuildContext context) {
    final receiveTitle =
        widget.onChainWallet ? 'Receber Bitcoin' : 'Receber na Kerosene';
    const receiveSubtitle =
        'Mostre este código para receber fundos em sua carteira';
    return Column(
      children: [
        ReceiveContextHeader(
          title: 'Transação',
          icon: KeroseneIcons.close,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                Text(
                  receiveTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.newsreader(
                    color: _receiveText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  receiveSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    color: _receiveMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 32),
                VaultCard(
                  child: Column(
                    children: [
                      _buildQrBox(size: 240, showScanLine: true),
                      const SizedBox(height: 24),
                      _buildQrAmount(),
                      const SizedBox(height: 24),
                      _buildAddressPill(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentDetailsPanel(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  InlineNotice(message: _errorMessage!),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: ReceiveActionButton(
                  icon: KeroseneIcons.copy,
                  label: context.tr.copy,
                  onTap: _copyPaymentValue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReceiveActionButton(
                  icon: KeroseneIcons.share,
                  label: context.tr.share,
                  onTap: _sharePaymentValue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsPanel() {
    return VaultCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          ReceiveDetailLine(
            icon: KeroseneIcons.wallet,
            label: 'Carteira',
            value: widget.wallet.name,
          ),
          const ReceiveDivider(),
          ReceiveDetailLine(
            icon: widget.onChainWallet
                ? KeroseneIcons.bitcoin
                : KeroseneIcons.lightning,
            label: 'Rede',
            value: _networkLabel,
          ),
          const ReceiveDivider(),
          ReceiveDetailLine(
            icon: KeroseneIcons.history,
            label: 'Solicitado',
            value: _amountLabel,
          ),
          const ReceiveDivider(),
          ReceiveDetailLine(
            icon: KeroseneIcons.location,
            label: widget.onChainWallet ? 'Endereço' : 'Destino',
            value: shortenReceiveAddress(_addressValue, head: 14, tail: 8),
            monospace: true,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationsScreen(BuildContext context) {
    final receiveTitle =
        widget.onChainWallet ? 'Receber Bitcoin' : 'Receber na Kerosene';
    const scanSubtitle = 'Escaneie para iniciar a transferência';
    return Column(
      children: [
        const ReceiveShellHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  receiveTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.newsreader(
                    color: _receiveText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scanSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    color: _receiveMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ReceiveQrFrame(child: _buildQrBox(size: 248)),
                const SizedBox(height: 16),
                VaultCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildExpectedAmountBlock(),
                      const ReceiveDivider(),
                      ReceiveAddressBlock(
                          onChainWallet: widget.onChainWallet,
                          addressValue: _addressValue),
                      const SizedBox(height: 16),
                      ReceiveNetworkStatusRow(
                          onChainWallet: widget.onChainWallet,
                          identified: _stage == ReceiveRequestStage.identified,
                          currentConfirmations: _currentConfirmations,
                          requiredConfirmations: _requiredConfirmations),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ReceiveActionButton(
                        icon: KeroseneIcons.copy,
                        label: context.tr.copy,
                        onTap: _copyPaymentValue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ReceiveActionButton(
                        icon: KeroseneIcons.share,
                        label: context.tr.share,
                        primary: true,
                        onTap: _sharePaymentValue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifiedScreen(BuildContext context) {
    const identifiedLabel = 'Pagamento\nIdentificado!';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: MovementConfirmationSurface(
              leading: ReceiveSuccessGraphic(animation: _scanController),
              title: identifiedLabel,
              amountLabel: _amountLabel,
              supportingLabel: _fiatLabel,
              rows: [
                MovementConfirmationRow(label: 'Status', value: _statusLabel),
                MovementConfirmationRow(
                  label: 'Destino',
                  value: shortenReceiveAddress(_addressValue),
                  technical: true,
                ),
                MovementConfirmationRow(label: 'Rede', value: _networkLabel),
                MovementConfirmationRow(
                  label: 'Data',
                  value: formatReceiveDateTime(_identifiedAt),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: _goHome,
              style: TextButton.styleFrom(
                backgroundColor: _receiveText,
                foregroundColor: AppColors.hexFF2F3131,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  height: 1.2,
                ),
              ),
              child: Text(context.tr.goToHome.toUpperCase()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrBox({required double size, bool showScanLine = false}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          QrImageView(
            data: _paymentValue,
            version: QrVersions.auto,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          if (showScanLine)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                final offset = -size * 0.25 + _scanController.value * size;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: size * 0.16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQrAmount() {
    const btcSuffix = ' BTC';
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.amountBtc.toStringAsFixed(6),
                style: AppTypography.newsreader(
                  color: _receiveText,
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
              TextSpan(
                text: btcSuffix,
                style: AppTypography.newsreader(
                  color: _receiveMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressPill() {
    final borderRadius = BorderRadius.circular(8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _receiveBackground,
        borderRadius: borderRadius,
        border: Border.all(color: _receiveBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('receive-address-pill-copy'),
          borderRadius: borderRadius,
          onTap: _copyAddressValue,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shortenReceiveAddress(_addressValue, head: 22, tail: 0)
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      color: _receiveMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  KeroseneIcons.copy,
                  color: _receiveMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpectedAmountBlock() {
    const btcLabel = 'BTC';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          SectionLabel('VALOR ESPERADO'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.amountBtc.toStringAsFixed(8),
                style: AppTypography.newsreader(
                  color: _receiveText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                btcLabel,
                style: AppTypography.inter(
                  color: _receiveMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
