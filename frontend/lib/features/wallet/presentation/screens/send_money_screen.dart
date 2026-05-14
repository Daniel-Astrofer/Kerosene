import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/services/contact_service.dart';
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
  int _amountPulse = 0;
  String? _pressedKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountBtc != null) {
      _amount = widget.initialAmountBtc!
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
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
    setState(() => _pressedKey = key);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _pressedKey == key) {
        setState(() => _pressedKey = null);
      }
    });
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
      _amountPulse++;
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
            if (_pendingPaymentLinkId == null &&
                _lockedRecipientAddress.isEmpty) ...[
              _buildTabs().animate().fade().slideY(begin: 0.1, end: 0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    _buildAmountDisplay()
                        .animate()
                        .scale(curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.sm),
                    _buildLiveQuote().animate(delay: 200.ms).fade(),
                  ],
                ),
              ),
              _buildKeypad()
                  .animate(delay: 300.ms)
                  .fade()
                  .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic),
            ] else ...[
              _buildLockedAmountView().animate().fade().scale(),
            ],
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CyberButton(
                text: context.l10n.continueButton.toUpperCase(),
                isLoading: isLoading,
                onTap: (double.tryParse(_amount) ?? 0) > 0
                    ? _handleContinue
                    : null,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.chevronLeft,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.send.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
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
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.1)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.4),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.84, end: 1).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                _amount,
                key: ValueKey('amount-$_amountPulse-$_amount'),
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0,
                    ),
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
    final isPressed = _pressedKey == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, isPressed ? -8 : 0, 0),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withOpacity(isPressed ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withOpacity(isPressed ? 0.16 : 0.05),
              ),
            ),
            alignment: Alignment.center,
            child: isBackspace
                ? Icon(
                    LucideIcons.delete,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  )
                : Text(
                    key,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                  ),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.4),
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
    var recipientTouched = false;
    String? flyingText;
    bool flightAtInput = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final recipient = _receiverController.text.trim();
            final isInvalid =
                recipientTouched && !_isValidInternalRecipient(recipient);

            void selectContact(Contact contact) {
              HapticFeedback.selectionClick();
              setSheetState(() {
                flyingText = contact.name ?? contact.address;
                flightAtInput = false;
              });
              Future.delayed(const Duration(milliseconds: 40), () {
                if (!mounted || !context.mounted) return;
                setSheetState(() => flightAtInput = true);
              });
              Future.delayed(const Duration(milliseconds: 360), () {
                if (!mounted || !context.mounted) return;
                _receiverController.text = contact.address;
                recipientTouched = true;
                setSheetState(() {
                  flyingText = null;
                  flightAtInput = false;
                });
              });
            }

            return GlassContainer(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.xl)),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.recipientData,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildBottomSheetInput(
                        controller: _receiverController,
                        label: "Adicionar endereço ou usuário",
                        hint: "Digite ou cole o endereço",
                        icon: LucideIcons.user,
                        isInvalid: isInvalid,
                        onChanged: (_) =>
                            setSheetState(() => recipientTouched = true),
                      ),
                      if (isInvalid) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Endereço ou usuário inválido",
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _buildRecentContacts(selectContact),
                      const SizedBox(height: AppSpacing.lg),
                      _buildBottomSheetInput(
                        controller: _contextController,
                        label: context.l10n.description,
                        hint: context.l10n.descriptionHint,
                        icon: LucideIcons.fileText,
                        maxLength: 100,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CyberButton(
                        text: context.l10n.next,
                        onTap: () {
                          setSheetState(() => recipientTouched = true);
                          if (!_isValidInternalRecipient(
                              _receiverController.text.trim())) {
                            HapticFeedback.heavyImpact();
                            SnackbarHelper.showError(
                                "Informe um endereço ou usuário válido");
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
                  if (flyingText != null)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: flightAtInput ? AppSpacing.xl : AppSpacing.lg,
                      right: flightAtInput ? AppSpacing.xl : AppSpacing.lg,
                      top: flightAtInput ? 104 : 242,
                      child: IgnorePointer(
                        child: Text(
                          flyingText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool isInvalid = false,
    ValueChanged<String>? onChanged,
  }) {
    final lineColor = isInvalid
        ? AppColors.error
        : Theme.of(context).colorScheme.onPrimary.withOpacity(0.24);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: lineColor, width: isInvalid ? 1.6 : 1)),
      ),
      child: TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: isInvalid
                  ? AppColors.error
                  : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: isInvalid
                    ? AppColors.error
                    : Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          counterText: '',
          icon: Icon(icon,
              color: isInvalid
                  ? AppColors.error
                  : Theme.of(context).colorScheme.primary,
              size: 20),
        ),
      ),
    );
  }

  Widget _buildRecentContacts(ValueChanged<Contact> onSelected) {
    return FutureBuilder<List<Contact>>(
      future: ContactService().getContacts(),
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? const <Contact>[];
        if (contacts.isEmpty) {
          return Text(
            context.l10n.noRecentContacts,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.36),
                ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ENVIADOS RECENTEMENTE",
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.42),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 176),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: contacts.length,
                separatorBuilder: (_, __) => Divider(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.08),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return InkWell(
                    onTap: () => onSelected(contact),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.82),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name ?? contact.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contact.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.38),
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _formatContactDate(contact.lastUsed),
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.48),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConfirmRow(context.l10n.recipient,
                        _lockedRecipientLabel ?? toAddress,
                        isSmall: _lockedRecipientLabel == null),
                    if (toAddress != _lockedRecipientLabel &&
                        _lockedRecipientLabel != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildConfirmRow("ENDEREÇO", toAddress, isSmall: true),
                    ],
                    Divider(color: AppColors.white10, height: AppSpacing.xl),
                    if (txContext.isNotEmpty) ...[
                      _buildConfirmRow(context.l10n.description, txContext,
                          isSmall: true),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _buildConfirmRow(context.l10n.amount.toUpperCase(),
                        "${amount.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC"),
                    const SizedBox(height: AppSpacing.xs),
                    _buildConfirmRow(context.l10n.networkFee, context.l10n.free,
                        valueColor: Theme.of(context).colorScheme.primary),
                    Divider(color: AppColors.white10, height: AppSpacing.xl),
                    _buildConfirmRow(context.l10n.total,
                        "${total.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} BTC",
                        isBold: true),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.l10n.cancel.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.4))),
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
                                SnackbarHelper.showError(
                                    "Carteira de origem indisponível");
                                return;
                              }

                              final secLevel =
                                  TransactionAuthGate.securityFromString(
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
                                  await ContactService().saveContact(
                                    toAddress,
                                    name: _lockedRecipientLabel,
                                  );
                                  ref
                                      .read(sendTransactionProvider.notifier)
                                      .send(
                                        fromWalletId: fromWalletId,
                                        fromAddress: fromAddress,
                                        toAddress: toAddress,
                                        amount: amount,
                                        feeSatoshis: (fee * 100000000).toInt(),
                                        context: txContext.isNotEmpty
                                            ? txContext
                                            : null,
                                        confirmationPassphrase:
                                            authResult.confirmationPassphrase,
                                        totpCode: authResult.totpCode,
                                      );
                                }
                              } else {
                                SnackbarHelper.showError(
                                    "Autenticação cancelada ou falhou");
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

  Widget _buildConfirmRow(String label, String value,
      {bool isSmall = false, bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (isSmall
                  ? Theme.of(context).textTheme.bodySmall!
                  : Theme.of(context).textTheme.bodyLarge!)
              .copyWith(
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
      _incomingPageRoute(const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _parsePaymentRequest(result);
    }
  }

  void _handleReadNfc() async {
    final result = await Navigator.push(
      context,
      _incomingPageRoute(NfcInteractionScreen(amountDisplay: _amount)),
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

  bool _isValidInternalRecipient(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _isExternalBitcoinTarget(trimmed)) return false;
    return RegExp(r'^[a-zA-Z0-9._@-]{3,80}$').hasMatch(trimmed);
  }

  String _formatContactDate(DateTime date) {
    return DateFormat('dd/MM\nHH:mm').format(date.toLocal());
  }

  PageRouteBuilder<T> _incomingPageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
