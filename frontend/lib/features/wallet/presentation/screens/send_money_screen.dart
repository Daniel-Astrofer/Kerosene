import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/services/audio_service.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';

import '../../../../core/utils/qr_payment_parser.dart';
import '../../../../core/widgets/transaction_auth_gate.dart';

import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';
import 'nfc_interaction_screen.dart';

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

  final _receiverController = TextEditingController();
  final _contextController = TextEditingController();

  int _selectedTabIndex = 1; // 0: NFC, 1: Manual, 2: QR Code
  String _amount = '0';

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountBtc != null) {
      _amount = widget.initialAmountBtc!.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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
    _receiverController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_lockedAmountBtc > 0) return; // Prevent changing locked amount
    
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '←') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = "0";
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == "0") {
          _amount = key;
        } else {
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts.length > 1 && parts[1].length >= 8) {
              return;
            }
          }
          if (_amount.length < 16) {
            _amount += key;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncActionState>(sendTransactionProvider, (previous, next) {
      if (next.result != null) {
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        ref.read(sendTransactionProvider.notifier).reset();
        Navigator.pop(context, next.result);
      } else if (next.error != null) {
        AudioService.instance.playError();
        HapticFeedback.heavyImpact();
        String errorMsg = ErrorTranslator.translate(context.l10n, next.error!);
        SnackbarHelper.showError(errorMsg);
        ref.read(sendTransactionProvider.notifier).reset();
      }
    });
    ref.listen<AsyncActionState>(paymentLinkNotifierProvider, (previous, next) {
      if (next.result != null) {
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        ref.read(paymentLinkNotifierProvider.notifier).reset();
        Navigator.pop(context, next.result);
      } else if (next.error != null) {
        AudioService.instance.playError();
        HapticFeedback.heavyImpact();
        SnackbarHelper.showError(
          ErrorTranslator.translate(context.l10n, next.error!),
        );
        ref.read(paymentLinkNotifierProvider.notifier).reset();
      }
    });

    final sendState = ref.watch(sendTransactionProvider);
    final paymentLinkState = ref.watch(paymentLinkNotifierProvider);
    final isLoading = sendState.isLoading || paymentLinkState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        resizeToAvoidBottomInset: false,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),
            
            if (_pendingPaymentLinkId == null && _lockedRecipientAddress.isEmpty) ...[
              _buildTabs().animate().fade().slideY(begin: 0.1, end: 0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    _buildAmountDisplay().animate().scale(curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLiveQuote().animate(delay: 200.ms).fade(),
                  ],
                ),
              ),
              _buildKeypad().animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
            ] else ...[
              _buildLockedAmountView().animate().fade().scale(),
            ],

            const SizedBox(height: AppSpacing.xl),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CyberButton(
                text: context.l10n.continueButton.toUpperCase(),
                isLoading: isLoading,
                onTap: (double.tryParse(_amount) ?? 0) > 0 ? _handleContinue : null,
              ).animate(delay: 500.ms).fade().slideY(begin: 0.2, end: 0),
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.send.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTabItem(context.l10n.nfc, 0),
          _buildTabItem(context.l10n.manual, 1),
          _buildTabItem(context.l10n.qrCode, 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1) : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          context.l10n.amount.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            Text(
              _amount,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontSize: 56,
                fontWeight: FontWeight.w300,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveQuote() {
    final btcUsdPrice = ref.watch(latestBtcPriceProvider);
    final amt = double.tryParse(_amount) ?? 0.0;
    final value = amt * (btcUsdPrice ?? 0);
    return Text(
      "≈ \$ ${value.toStringAsFixed(2)} USD",
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
        fontWeight: FontWeight.w500,
      ),
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
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(LucideIcons.delete, color: Theme.of(context).colorScheme.onPrimary, size: 20)
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w300),
                ),
        ),
      ),
    );
  }

  Widget _buildLockedAmountView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              "${(double.tryParse(_amount) ?? 0).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC",
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 40,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_lockedRecipientLabel != null) ...[
                Text(
                  "PARA: ${_lockedRecipientLabel!.toUpperCase()}",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
            ],
            Text(
              context.l10n.fixedAmountByRequest,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    final currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) return;
    
    HapticFeedback.mediumImpact();

    if (_pendingPaymentLinkId != null || _lockedRecipientAddress.isNotEmpty) {
      _showConfirmationDialog(
        context,
        double.tryParse(_amount) ?? 0.0,
        0, // Let backend or prepare Tx define actual fee
        double.tryParse(_amount) ?? 0.0,
        currentWallet.id,
        currentWallet.address,
        _lockedRecipientAddress,
        _contextController.text.trim(),
      );
      return;
    }

    if (_selectedTabIndex == 0) {
      _handleReadNfc();
    } else if (_selectedTabIndex == 2) {
      _handleScanQr();
    } else {
      _showManualAddressInput(double.tryParse(_amount) ?? 0, currentWallet);
    }
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

  void _showManualAddressInput(double amountBtc, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.xl)),
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.recipientData,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildBottomSheetInput(
                controller: _receiverController,
                hint: context.l10n.recipientHint,
                icon: LucideIcons.user,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildBottomSheetInput(
                controller: _contextController,
                hint: context.l10n.descriptionHint,
                icon: LucideIcons.fileText,
                maxLength: 100,
              ),
              const SizedBox(height: AppSpacing.xl),
              CyberButton(
                text: context.l10n.next,
                onTap: () {
                  if (_receiverController.text.trim().isEmpty) {
                    SnackbarHelper.showError("Informe o destinatário");
                    return;
                  }
                  if (_isExternalBitcoinTarget(_receiverController.text.trim())) {
                    SnackbarHelper.showError(
                      "Pagamentos on-chain devem usar o fluxo de saque.",
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _showConfirmationDialog(
                    context,
                    amountBtc,
                    0,
                    amountBtc,
                    wallet.id,
                    wallet.address,
                    _receiverController.text.trim(),
                    _contextController.text.trim(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodyMedium!,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
          border: InputBorder.none,
          counterText: '',
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    double amount,
    double fee,
    double total,
    String fromWalletId,
    String fromAddress,
    String toAddress,
    String txContext,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                borderRadius: BorderRadius.circular(AppSpacing.xl),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.reviewSend,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConfirmRow(context.l10n.recipient, _lockedRecipientLabel ?? toAddress, isSmall: _lockedRecipientLabel == null),
                    if (toAddress != _lockedRecipientLabel && _lockedRecipientLabel != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildConfirmRow("ENDEREÇO", toAddress, isSmall: true),
                    ],
                    Divider(color: AppColors.white10, height: AppSpacing.xl),
                    if (txContext.isNotEmpty) ...[
                      _buildConfirmRow(context.l10n.description, txContext, isSmall: true),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildConfirmRow(context.l10n.amount.toUpperCase(), "${amount.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC"),
                    const SizedBox(height: AppSpacing.xs),
                    _buildConfirmRow(context.l10n.networkFee, context.l10n.free, valueColor: Theme.of(context).colorScheme.primary),
                    Divider(color: AppColors.white10, height: AppSpacing.xl),
                    _buildConfirmRow(context.l10n.total, "${total.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC", isBold: true),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.l10n.cancel.toUpperCase(), style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4))),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: CyberButton(
                            text: context.l10n.confirm,
                            onTap: () async {
                              // We close the review dialog
                              Navigator.pop(context);
                              
                              final walletState = ref.read(walletProvider);
                              final currentWallet = _resolveWallet(walletState);
                              if (currentWallet == null) {
                                SnackbarHelper.showError("Carteira de origem indisponível");
                                return;
                              }

                              final secLevel = TransactionAuthGate.securityFromString(
                                currentWallet.accountSecurity,
                              );
                              final authResult = await TransactionAuthGate.show(
                                context,
                                security: secLevel,
                              );

                              if (authResult.isAuthenticated && mounted) {
                                  if (_pendingPaymentLinkId != null) {
                                    _handlePayPaymentLink(currentWallet);
                                  } else {
                                    ref.read(sendTransactionProvider.notifier).send(
                                      fromWalletId: fromWalletId,
                                      fromAddress: fromAddress,
                                      toAddress: toAddress,
                                      amount: amount,
                                      feeSatoshis: (fee * 100000000).toInt(),
                                      context: txContext.isNotEmpty ? txContext : null,
                                      confirmationPassphrase: authResult.confirmationPassphrase,
                                      totpCode: authResult.totpCode,
                                    );
                                  }
                              } else {
                                  SnackbarHelper.showError("Autenticação cancelada ou falhou");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isSmall = false, bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (isSmall ? Theme.of(context).textTheme.bodySmall! : Theme.of(context).textTheme.bodyLarge!).copyWith(
            color: valueColor ?? Theme.of(context).colorScheme.onPrimary,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'JetBrainsMono',
          ),
          softWrap: true,
        ),
      ],
    );
  }

  void _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _handleReadNfc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NfcInteractionScreen(amountDisplay: _amount)),
    );
    if (result != null && result is String && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _parsePaymentRequest(String data) {
    if (data.startsWith('kerosene:link:')) {
      final linkId = data.replaceFirst('kerosene:link:', '');
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
              _amount = parsed.amountBtc!.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
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
    final result = await ref.read(ledgerRepositoryProvider).getPaymentRequest(linkId);

    result.fold((failure) {
      SnackbarHelper.showError(failure.message);
    }, (data) {
      final rawAmount = data['amount'];
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
      final status = (data['status']?.toString() ?? 'PENDING').toUpperCase();

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
        _lockedRecipientLabel = 'SOLICITAÇÃO INTERNA';
        _lockedRecipientAddress = 'Pagamento por link';
        if (amount > 0) {
          _lockedAmountBtc = amount;
          _amount = amount
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
      });
      SnackbarHelper.showSuccess("Solicitação de pagamento carregada.");
    });
  }

  void _handlePayPaymentLink(Wallet wallet) {
    final linkId = _pendingPaymentLinkId;
    if (linkId == null) {
      SnackbarHelper.showError("Solicitação de pagamento inválida.");
      return;
    }

    ref.read(paymentLinkNotifierProvider.notifier).pay(
      linkId: linkId,
      payerWalletName: wallet.name,
    );
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
