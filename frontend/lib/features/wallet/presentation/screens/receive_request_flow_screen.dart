import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/core/utils/qr_payment_parser.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/transactions/domain/entities/external_transfer.dart';
import 'package:kerosene/features/transactions/domain/entities/onchain_address_allocation.dart';
import 'package:kerosene/features/transactions/domain/entities/payment_link.dart';
import 'package:kerosene/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:kerosene/features/wallet/domain/entities/wallet.dart';
import 'package:kerosene/features/wallet/presentation/screens/receive_method.dart';

enum ReceiveRequestStage { qr, confirmations, identified }

const _receiveBackground = Color(0xFF050505);
const _receiveSurface = Color(0xFF121212);
const _receiveSurfaceLowest = Color(0xFF0E0E0E);
const _receiveSurfaceLow = Color(0xFF1C1B1B);
const _receiveSurfaceHigh = Color(0xFF2A2A2A);
const _receiveBorder = Color(0xFF2A2A2A);
const _receiveText = Color(0xFFFFFFFF);
const _receiveMuted = Color(0xFFA3A3A3);
const _receiveBody = Color(0xFFC4C7C8);
const _receiveSuccess = Color(0xFF4ADE80);
const _receiveWarning = Color(0xFFF59E0B);

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
      duration: const Duration(milliseconds: 2200),
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
      const Duration(seconds: 6),
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
      const Duration(seconds: 6),
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
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(key: ValueKey(_stage), child: child),
                ),
                if (_isLoadingRequest) _buildLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrScreen(BuildContext context) {
    return Column(
      children: [
        _ReceiveContextHeader(
          title: 'Transação',
          icon: LucideIcons.x,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                Text(
                  widget.onChainWallet
                      ? 'Receber Bitcoin'
                      : 'Receber na Kerosene',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSerif(
                    color: _receiveText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mostre este código para receber fundos em sua carteira',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _receiveMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 32),
                _VaultCard(
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
                  _InlineNotice(message: _errorMessage!),
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
                child: _ReceiveActionButton(
                  icon: LucideIcons.copy,
                  label: context.tr.copy,
                  onTap: _copyPaymentValue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReceiveActionButton(
                  icon: LucideIcons.share2,
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
    return _VaultCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          _ReceiveDetailLine(
            icon: LucideIcons.wallet,
            label: 'Carteira',
            value: widget.wallet.name,
          ),
          const _ReceiveDivider(),
          _ReceiveDetailLine(
            icon: widget.onChainWallet ? LucideIcons.bitcoin : LucideIcons.zap,
            label: 'Rede',
            value: _networkLabel,
          ),
          const _ReceiveDivider(),
          _ReceiveDetailLine(
            icon: LucideIcons.receipt,
            label: 'Solicitado',
            value: _amountLabel,
          ),
          const _ReceiveDivider(),
          _ReceiveDetailLine(
            icon: LucideIcons.mapPin,
            label: widget.onChainWallet ? 'Endereço' : 'Destino',
            value: _shortenAddress(_addressValue, head: 14, tail: 8),
            monospace: true,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationsScreen(BuildContext context) {
    return Column(
      children: [
        const _ReceiveShellHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  widget.onChainWallet
                      ? 'Receber Bitcoin'
                      : 'Receber na Kerosene',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSerif(
                    color: _receiveText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escaneie para iniciar a transferência',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _receiveMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _QrFrame(child: _buildQrBox(size: 248)),
                const SizedBox(height: 16),
                _VaultCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildExpectedAmountBlock(),
                      const _ReceiveDivider(),
                      _buildAddressBlock(),
                      const SizedBox(height: 16),
                      _buildNetworkStatusRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ReceiveActionButton(
                        icon: LucideIcons.copy,
                        label: context.tr.copy,
                        onTap: _copyPaymentValue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ReceiveActionButton(
                        icon: LucideIcons.share2,
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
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  children: [
                    _buildSuccessGraphic(),
                    const SizedBox(height: 32),
                    Text(
                      'Pagamento\nIdentificado!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSerif(
                        color: _receiveText,
                        fontSize: 48,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _amountLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSerif(
                        color: _receiveText,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fiatLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: _receiveMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatusChip(label: _statusLabel, color: _receiveSuccess),
                    const SizedBox(height: 32),
                    _VaultCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Destino',
                            value: _shortenAddress(_addressValue),
                            monospace: true,
                          ),
                          const _ReceiveDivider(),
                          _DetailRow(label: 'Rede', value: _networkLabel),
                          const _ReceiveDivider(),
                          _DetailRow(
                            label: 'Data',
                            value: _formatDateTime(_identifiedAt),
                          ),
                        ],
                      ),
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
                    foregroundColor: const Color(0xFF2F3131),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      height: 1.2,
                    ),
                  ),
                  child: const Text('VOLTAR AO INÍCIO'),
                ),
              ),
            ),
          ],
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
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.amountBtc.toStringAsFixed(6),
                style: GoogleFonts.ibmPlexSerif(
                  color: _receiveText,
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
              TextSpan(
                text: ' BTC',
                style: GoogleFonts.ibmPlexSerif(
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
                    _shortenAddress(_addressValue, head: 22, tail: 0)
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
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
                  LucideIcons.copy,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _SectionLabel('VALOR ESPERADO'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.amountBtc.toStringAsFixed(8),
                style: GoogleFonts.ibmPlexSerif(
                  color: _receiveText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BTC',
                style: GoogleFonts.inter(
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

  Widget _buildAddressBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(widget.onChainWallet ? 'ENDEREÇO DA REDE' : 'DESTINO'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _receiveSurfaceLow,
              border: Border.all(color: _receiveBorder),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _addressValue,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSansHebrew(
                color: _receiveText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusRow() {
    final waitingLabel = widget.onChainWallet
        ? 'Aguardando confirmações ($_currentConfirmations/$_requiredConfirmations)'
        : _stage == ReceiveRequestStage.identified
            ? 'Confirmado'
            : 'Aguardando confirmação';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF222222)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _receiveWarning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _receiveWarning.withValues(alpha: 0.60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.onChainWallet ? 'Status da Rede' : 'Status Kerosene',
              style: GoogleFonts.inter(
                color: _receiveText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          Flexible(
            child: Text(
              waitingLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: _receiveMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessGraphic() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        final pulse = _scanController.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.88 + pulse * 0.28,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _receiveSuccess.withValues(
                      alpha: 0.12 * (1 - pulse),
                    ),
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _receiveSurfaceLowest,
                  border: Border.all(color: _receiveBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _receiveSuccess.withValues(alpha: 0.10),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.checkCircle2,
                  color: _receiveSuccess,
                  size: 48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _receiveSurface,
              border: Border.all(color: _receiveBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: _receiveText,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Preparando recebimento',
                  style: GoogleFonts.inter(
                    color: _receiveText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiveContextHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const _ReceiveContextHeader({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onPressed,
                icon: Icon(icon, size: 20),
                color: _receiveText,
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  foregroundColor: _receiveText,
                ),
              ),
            ),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                color: _receiveMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 1.2,
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiveShellHeader extends StatelessWidget {
  const _ReceiveShellHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _receiveBackground,
        border: Border(bottom: BorderSide(color: _receiveBorder)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.menu, color: _receiveText, size: 22),
          const Spacer(),
          Text(
            'KEROSENE',
            style: GoogleFonts.ibmPlexSerif(
              color: _receiveText,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _receiveSurfaceHigh,
              border: Border.all(color: _receiveBorder),
            ),
            child: Center(
              child: Text(
                'K',
                style: GoogleFonts.inter(
                  color: _receiveText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _VaultCard({
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _receiveBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), _receiveSurface],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QrFrame extends StatelessWidget {
  final Widget child;

  const _QrFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _receiveBorder),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), _receiveSurface],
            ),
          ),
          child: Stack(
            children: [
              const _CornerAccent(alignment: Alignment.topLeft),
              const _CornerAccent(alignment: Alignment.topRight),
              const _CornerAccent(alignment: Alignment.bottomLeft),
              const _CornerAccent(alignment: Alignment.bottomRight),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Alignment alignment;

  const _CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: _receiveText.withValues(alpha: 0.20))
                : BorderSide.none,
            bottom: isTop
                ? BorderSide.none
                : BorderSide(color: _receiveText.withValues(alpha: 0.20)),
            left: isLeft
                ? BorderSide(color: _receiveText.withValues(alpha: 0.20))
                : BorderSide.none,
            right: isLeft
                ? BorderSide.none
                : BorderSide(color: _receiveText.withValues(alpha: 0.20)),
          ),
        ),
      ),
    );
  }
}

class _ReceiveActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ReceiveActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.black : _receiveText;
    return SizedBox(
      height: 56,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: primary ? _receiveText : _receiveSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: primary ? _receiveText : _receiveBorder,
            ),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ReceiveDetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _ReceiveDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        (monospace ? GoogleFonts.ibmPlexSansHebrew() : GoogleFonts.inter())
            .copyWith(
      color: _receiveText,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _receiveMuted, size: 17),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _receiveMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _receiveSurfaceLow,
        border: Border.all(color: _receiveBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.60),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFE5E2E1),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: _receiveMuted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (monospace
                      ? GoogleFonts.ibmPlexSansHebrew()
                      : GoogleFonts.inter())
                  .copyWith(
                color: _receiveText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiveDivider extends StatelessWidget {
  const _ReceiveDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: _receiveBorder.withValues(alpha: 0.50),
      height: 1,
      thickness: 1,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: _receiveMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;

  const _InlineNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _receiveWarning.withValues(alpha: 0.08),
        border: Border.all(color: _receiveWarning.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: _receiveWarning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: _receiveBody,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortenAddress(String value, {int head = 6, int tail = 4}) {
  final trimmed = value.trim();
  if (trimmed.length <= head + tail + 3) return trimmed;
  if (tail <= 0) return '${trimmed.substring(0, head)}...';
  return '${trimmed.substring(0, head)}...${trimmed.substring(trimmed.length - tail)}';
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month ${local.year}, $hour:$minute';
}
