import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/bitcoin_address_blocks.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/api_display_text.dart';
import 'package:teste/core/utils/bitcoin_network.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/transactions/domain/entities/external_transfer.dart';
import 'package:teste/features/transactions/domain/entities/onchain_address_allocation.dart';
import 'package:teste/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/l10n/l10n_extension.dart';

class DepositOnchainInvoiceScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final double inputAmount;
  final Currency inputCurrency;
  final String providerName;

  const DepositOnchainInvoiceScreen({
    super.key,
    required this.wallet,
    required this.inputAmount,
    required this.inputCurrency,
    required this.providerName,
  });

  @override
  ConsumerState<DepositOnchainInvoiceScreen> createState() =>
      _DepositOnchainInvoiceScreenState();
}

class _DepositOnchainInvoiceScreenState
    extends ConsumerState<DepositOnchainInvoiceScreen> {
  Timer? _statusTimer;
  OnchainAddressAllocation? _allocation;
  ExternalTransfer? _observedTransfer;
  String _depositAddress = '';
  String? _errorMessage;
  bool _isLoadingAddress = true;
  bool _isCancelling = false;
  bool _requestTriggered = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_loadOnchainDepositAddress);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnchainDepositAddress() async {
    if (_requestTriggered) {
      return;
    }
    _requestTriggered = true;
    _statusTimer?.cancel();

    setState(() {
      _isLoadingAddress = true;
      _errorMessage = null;
      _allocation = null;
      _observedTransfer = null;
    });

    try {
      final expectedAmountBtc = _expectedAmountBtcFromCurrentQuote();
      if (expectedAmountBtc <= 0) {
        _requestTriggered = false;
        return;
      }

      final allocation =
          await ref.read(transactionRepositoryProvider).issueOnchainAddress(
                walletName: widget.wallet.name,
                expectedAmountBtc: expectedAmountBtc,
              );
      final normalized = allocation.onchainAddress.trim();

      if (!mounted) {
        return;
      }

      if (normalized.isEmpty) {
        final message = context.l10n.onchainDepositAddressUnavailable;
        setState(() {
          _isLoadingAddress = false;
          _errorMessage = message;
          _depositAddress = '';
        });
        SnackbarHelper.showError(
          message,
          title: context.l10n.onchainDepositTitle,
        );
        return;
      }

      if (!looksLikeBitcoinAddress(normalized)) {
        final message = context.l10n.onchainDepositAddressUnavailable;
        setState(() {
          _isLoadingAddress = false;
          _errorMessage = message;
          _depositAddress = '';
        });
        SnackbarHelper.showError(
          message,
          title: context.l10n.onchainDepositTitle,
        );
        return;
      }

      if (!allocation.hasTransferId) {
        final message = context.l10n.onchainDepositTrackingUnavailable;
        setState(() {
          _isLoadingAddress = false;
          _errorMessage = message;
          _depositAddress = '';
        });
        SnackbarHelper.showError(
          message,
          title: context.l10n.onchainDepositTitle,
        );
        return;
      }

      setState(() {
        _allocation = allocation;
        _observedTransfer = null;
        _depositAddress = normalized;
        _isLoadingAddress = false;
      });
      await _refreshObservedTransfer(showNotice: false);
      _startObservedTransferPolling();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated =
          ErrorTranslator.translate(context.l10n, error.toString());
      setState(() {
        _isLoadingAddress = false;
        _errorMessage = translated;
      });
      SnackbarHelper.showError(
        translated,
        title: context.l10n.onchainDepositTitle,
      );
    }
  }

  double _expectedAmountBtcFromCurrentQuote() {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    return MoneyDisplay.convertToBtcAmount(
      amount: widget.inputAmount,
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
  }

  void _startObservedTransferPolling() {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty) {
      return;
    }
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshObservedTransfer();
    });
  }

  Future<void> _refreshObservedTransfer({bool showNotice = true}) async {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty) {
      return;
    }

    try {
      final latest = await ref
          .read(transactionRepositoryProvider)
          .getExternalTransfer(transferId);
      if (!mounted) {
        return;
      }

      final previousStatus =
          (_observedTransfer?.status ?? _allocation?.transferStatus ?? '')
              .trim()
              .toUpperCase();
      final previousConfirmations =
          _observedTransfer?.confirmations ?? _allocation?.confirmations ?? 0;

      setState(() {
        _observedTransfer = latest;
      });

      if (previousStatus != latest.status.trim().toUpperCase() ||
          previousConfirmations != latest.confirmations) {
        ref.invalidate(externalTransfersProvider);
        ref.invalidate(transactionHistoryProvider);
      }

      if (showNotice) {
        _showObservedTransferNotice(
          previousStatus: previousStatus,
          previousConfirmations: previousConfirmations,
          latest: latest,
        );
      }

      if (_isTransferFinal(latest.status)) {
        _statusTimer?.cancel();
      }
    } catch (_) {
      // Keep the issued address usable even if the refresh fails transiently.
    }
  }

  void _showObservedTransferNotice({
    required String previousStatus,
    required int previousConfirmations,
    required ExternalTransfer latest,
  }) {
    final normalizedStatus = latest.status.trim().toUpperCase();
    if ((normalizedStatus == 'DETECTED' ||
            normalizedStatus == 'MEMPOOL' ||
            normalizedStatus == 'CONFIRMED' ||
            normalizedStatus == 'COMPLETED') &&
        previousStatus != normalizedStatus &&
        latest.blockchainTxid.trim().isNotEmpty) {
      SnackbarHelper.showInfo(
        context.l10n.onchainDepositDetectedNotice(
          latest.confirmations,
          _requiredConfirmations,
        ),
        title: context.l10n.onchainDepositStatusDetected,
      );
    }

    if (latest.confirmations >= _requiredConfirmations &&
        previousConfirmations < _requiredConfirmations &&
        _isTransferFinal(normalizedStatus)) {
      SnackbarHelper.showSuccess(
        context.l10n.onchainDepositConfirmedNotice,
        title: context.l10n.onchainDepositStatusConfirmed,
      );
    }
  }

  bool _isTransferFinal(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'COMPLETED' ||
        normalized == 'CONFIRMED' ||
        normalized == 'FAILED' ||
        normalized == 'CANCELLED' ||
        normalized == 'EXPIRED';
  }

  void _copyAddress(String address) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: address));
    SnackbarHelper.showSuccess(context.l10n.onchainDepositAddressCopied);
  }

  int get _requiredConfirmations => _allocation?.requiredConfirmations ?? 3;

  int get _currentConfirmations =>
      _observedTransfer?.confirmations ?? _allocation?.confirmations ?? 0;

  bool get _canCancelDeposit {
    if (_allocation == null || _isCancelling) {
      return false;
    }
    final status =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    final hasDetectedTx =
        (_observedTransfer?.blockchainTxid.trim().isNotEmpty ?? false) ||
            (_allocation?.blockchainTxid.trim().isNotEmpty ?? false);
    return status == 'PENDING' && !hasDetectedTx;
  }

  bool get _isSelfCustody =>
      _allocation?.isSelfCustody ?? widget.wallet.isSelfCustody;

  String get _destinationWalletLabel {
    final allocationWallet = _allocation?.walletName.trim() ?? '';
    if (allocationWallet.isNotEmpty) {
      return allocationWallet;
    }
    final walletName = widget.wallet.name.trim();
    if (walletName.isNotEmpty) {
      return walletName;
    }
    return context.l10n.onchainDepositSelectedWallet;
  }

  String get _networkLabel {
    final network = (_allocation?.network ?? 'mainnet').trim().toLowerCase();
    return switch (network) {
      'mainnet' => 'Bitcoin',
      'testnet' => 'Testnet',
      'regtest' => context.l10n.onchainDepositLocalNetwork,
      _ => network.isEmpty ? 'Bitcoin' : network,
    };
  }

  String get _statusLabel {
    final status =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    return switch (status) {
      'COMPLETED' => context.l10n.onchainDepositStatusCompleted,
      'CONFIRMED' => context.l10n.onchainDepositStatusConfirmed,
      'DETECTED' || 'MEMPOOL' => context.l10n.onchainDepositStatusDetected,
      'PENDING' => context.l10n.onchainDepositStatusWaiting,
      'FAILED' => context.l10n.onchainDepositStatusFailed,
      'CANCELLED' => context.l10n.onchainDepositStatusCancelled,
      'EXPIRED' => context.l10n.onchainDepositStatusExpired,
      _ => ApiDisplayText.status(context, status),
    };
  }

  String get _statusDescription {
    final normalizedStatus =
        (_observedTransfer?.status ?? _allocation?.transferStatus ?? 'PENDING')
            .trim()
            .toUpperCase();
    if (normalizedStatus == 'CANCELLED') {
      return context.l10n.onchainDepositDescriptionCancelled;
    }
    if (_observedTransfer == null ||
        (_observedTransfer!.blockchainTxid.trim().isEmpty &&
            _currentConfirmations == 0)) {
      return context.l10n.onchainDepositDescriptionWaiting(_networkLabel);
    }
    if (_currentConfirmations >= _requiredConfirmations &&
        _isTransferFinal(_observedTransfer!.status)) {
      return context.l10n.onchainDepositDescriptionConfirmed;
    }
    return context.l10n.onchainDepositDescriptionConfirming(
      _currentConfirmations,
      _requiredConfirmations,
    );
  }

  Future<void> _cancelDeposit() async {
    final transferId = _allocation?.transferId.trim() ?? '';
    if (transferId.isEmpty || !_canCancelDeposit) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.onchainDepositCancelTitle),
            content: Text(context.l10n.onchainDepositCancelMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.onchainDepositCancelAction),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isCancelling = true);
    try {
      final cancelled = await ref
          .read(transactionRepositoryProvider)
          .cancelInboundTransfer(transferId);
      if (!mounted) {
        return;
      }
      _statusTimer?.cancel();
      setState(() {
        _observedTransfer = cancelled;
      });
      ref.invalidate(externalTransfersProvider);
      ref.invalidate(transactionHistoryProvider);
      SnackbarHelper.showSuccess(context.l10n.onchainDepositCancelledNotice);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final translated =
          ErrorTranslator.translate(context.l10n, error.toString());
      SnackbarHelper.showError(translated);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);

    if (btcUsd == null && btcBrl == null) {
      return ReceiveFlowScaffold(
        title: context.l10n.onchainDepositTitle,
        subtitle: context.l10n.onchainDepositPreparingSubtitle,
        child: ReceiveFlowStatePanel(
          icon: LucideIcons.loader2,
          title: context.l10n.onchainDepositLoadingTitle,
          message: context.l10n.onchainDepositLoadingMessage,
        ),
      );
    }

    final receiveBtc = MoneyDisplay.convertToBtcAmount(
      amount: widget.inputAmount,
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    if (!_requestTriggered && _depositAddress.isEmpty && receiveBtc > 0) {
      scheduleMicrotask(_loadOnchainDepositAddress);
    }
    final quoteLabel = MoneyDisplay.formatQuoteValue(
      currency: widget.inputCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowScaffold(
      title: context.l10n.onchainDepositTitle,
      subtitle: context.l10n.onchainDepositSubtitle,
      child: Builder(
        builder: (context) {
          if (_isLoadingAddress) {
            return _buildAddressLoading();
          }

          if (_errorMessage != null) {
            return _buildAddressError();
          }

          final address = _depositAddress;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMainCard(widget.inputAmount),
              const SizedBox(height: AppSpacing.sm),
              _buildAwaitConfirmationBanner(),
              const SizedBox(height: AppSpacing.md),
              _buildQrCodeSection(address, receiveBtc),
              const SizedBox(height: AppSpacing.sm),
              _buildAddressPill(address),
              const SizedBox(height: AppSpacing.md),
              _buildTrackingCard(),
              const SizedBox(height: AppSpacing.md),
              _buildDetailsBlock(
                receiveBtc,
                quoteLabel,
              ),
              if (_canCancelDeposit) ...[
                const SizedBox(height: AppSpacing.md),
                ReceiveFlowSecondaryButton(
                  label: _isCancelling
                      ? context.l10n.onchainDepositCancelling
                      : context.l10n.onchainDepositCancelAction,
                  icon: LucideIcons.xCircle,
                  onTap: _isCancelling ? null : _cancelDeposit,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _buildSecurityFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressLoading() {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.network,
      title: context.l10n.onchainDepositGettingAddressTitle,
      message: context.l10n.onchainDepositGettingAddressMessage,
    );
  }

  Widget _buildAddressError() {
    return ReceiveFlowStatePanel(
      icon: LucideIcons.alertTriangle,
      title: context.l10n.onchainDepositErrorTitle,
      message: _errorMessage ?? context.l10n.errUnexpected,
      footer: ReceiveFlowSecondaryButton(
        label: context.l10n.tryAgain,
        icon: LucideIcons.refreshCw,
        onTap: () {
          _requestTriggered = false;
          _loadOnchainDepositAddress();
        },
      ),
    );
  }

  Widget _buildMainCard(double totalRequested) {
    return ReceiveFlowPanel(
      backgroundColor: receiveFlowPanelAltColor,
      child: Column(
        children: [
          ReceiveFlowSectionLabel(context.l10n.onchainDepositTotalLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MoneyDisplay.format(
              amount: totalRequested,
              currency: widget.inputCurrency,
            ),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: receiveFlowTextColor,
                  fontSize: 32,
                  fontFamily: AppTypography.numericFontFamily,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowTag(
            label: context.l10n.onchainDepositNetworkTag(_networkLabel),
            icon: LucideIcons.bitcoin,
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAwaitConfirmationBanner() {
    return ReceiveFlowPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: const Icon(
              LucideIcons.clock3,
              color: receiveFlowTextColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _statusDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    final transfer = _observedTransfer;
    final txid = transfer?.blockchainTxid.trim().isNotEmpty == true
        ? transfer!.blockchainTxid.trim()
        : _allocation?.blockchainTxid.trim() ?? '';
    final observedAmountBtc = transfer?.amountBtc ?? 0;
    final expectedAmountBtc =
        transfer?.expectedAmountBtc ?? _allocation?.expectedAmountBtc ?? 0;
    final amountMatches = observedAmountBtc > 0 &&
        expectedAmountBtc > 0 &&
        (observedAmountBtc - expectedAmountBtc).abs() < 0.00000001;

    return ReceiveFlowPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiveFlowSectionLabel(context.l10n.onchainDepositTrackingTitle),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowMetricRow(label: context.l10n.status, value: _statusLabel),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositConfirmationsLabel,
            value: '$_currentConfirmations/$_requiredConfirmations',
          ),
          if (txid.isNotEmpty) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.onchainDepositTxidLabel,
              value: txid,
              mono: true,
            ),
          ],
          if (observedAmountBtc > 0) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.onchainDepositObservedAmountLabel,
              value: MoneyDisplay.format(
                amount: observedAmountBtc,
                currency: Currency.btc,
              ),
            ),
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.onchainDepositAmountCheckLabel,
              value: amountMatches
                  ? context.l10n.onchainDepositAmountCheckOk
                  : context.l10n.onchainDepositAmountCheckDifferent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String address, double amountBtc) {
    final qrPayload = amountBtc > 0
        ? 'bitcoin:$address?amount=${amountBtc.toStringAsFixed(8)}'
        : 'bitcoin:$address';
    return ReceiveFlowPanel(
      child: Column(
        children: [
          ReceiveFlowSectionLabel(context.l10n.onchainDepositQrTitle),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = min<double>(220, constraints.maxWidth - 36)
                  .clamp(168.0, 220.0)
                  .toDouble();
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: qrSize,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPill(String address) {
    return ReceiveFlowPanel(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BitcoinAddressBlocks(
            address: address,
            backgroundColor: receiveFlowPanelRaisedColor,
            borderColor: receiveFlowBorderStrongColor,
            style: AppTypography.technicalMono(
              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: receiveFlowTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: ReceiveFlowSecondaryButton(
              label: context.l10n.copy,
              icon: LucideIcons.copy,
              fullWidth: false,
              onTap: () => _copyAddress(address),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBlock(
    double receiveBtc,
    String? quoteLabel,
  ) {
    final transfer = _observedTransfer;
    final observedAmountBtc = transfer?.amountBtc ?? 0;
    final expectedAmountBtc = transfer?.expectedAmountBtc ??
        _allocation?.expectedAmountBtc ??
        receiveBtc;

    return ReceiveFlowPanel(
      child: Column(
        children: [
          if (quoteLabel != null) ...[
            ReceiveFlowMetricRow(
              label: context.l10n.onchainDepositQuoteLabel,
              value: quoteLabel,
            ),
            const ReceiveFlowDivider(),
          ],
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositDestinationWalletLabel,
            value: _destinationWalletLabel,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositNetworkLabel,
            value: _networkLabel,
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositExpectedAmountLabel,
            value: MoneyDisplay.format(
                amount: expectedAmountBtc, currency: Currency.btc),
          ),
          if (observedAmountBtc > 0) ...[
            const ReceiveFlowDivider(),
            ReceiveFlowMetricRow(
              label: context.l10n.onchainDepositReceivedAmountLabel,
              value: MoneyDisplay.format(
                amount: observedAmountBtc,
                currency: Currency.btc,
              ),
            ),
          ],
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositMinimumConfirmationsLabel,
            value: context.l10n.onchainDepositMinimumConfirmationsValue(
                _requiredConfirmations),
          ),
          const ReceiveFlowDivider(),
          ReceiveFlowMetricRow(
            label: context.l10n.onchainDepositCustodyLabel,
            value: _isSelfCustody
                ? context.l10n.onchainDepositCustodySelf
                : context.l10n.onchainDepositCustodyKerosene,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return ReceiveFlowPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: receiveFlowPanelRaisedColor,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: receiveFlowBorderStrongColor),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              color: receiveFlowTextColor,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _isSelfCustody
                  ? context.l10n.onchainDepositSecuritySelf
                  : context.l10n.onchainDepositSecurityKerosene,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: receiveFlowMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
