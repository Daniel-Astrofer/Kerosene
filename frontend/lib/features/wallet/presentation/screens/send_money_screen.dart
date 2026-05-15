import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:teste/core/providers/recent_transaction_destinations_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/services/audio_service.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/features/security/domain/entities/account_security_profile.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';

import '../../../../core/utils/qr_payment_parser.dart';
import '../../../../core/widgets/transaction_auth_gate.dart';

import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/entities/wallet.dart';

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
  static const Color _internalBlack = Color(0xFF000000);
  static const Color _internalSurface = Color(0xFF111111);
  static const Color _internalSurfaceHigh = Color(0xFF1F1F1F);
  static const Color _internalBorder = Color(0xFF2C2C2E);
  static const Color _internalText = Color(0xFFFFFFFF);
  static const Color _internalMutedText = Color(0xFFA3A3A3);
  static const Color _internalOutline = Color(0xFF666666);
  static const Color _internalValidBlue = Color(0xFF1978E5);
  static const Color _internalSuccessGreen = Color(0xFF4ADE80);

  String? _pendingPaymentLinkId;
  String _lockedRecipientAddress = '';
  double _lockedAmountBtc = 0.0;
  String? _lockedRecipientLabel;
  bool _autoConfirmationScheduled = false;

  final _receiverController = TextEditingController();

  String _amount = '0';
  late Currency _selectedCurrency;
  bool _amountKeyboardExpanded = false;
  int _amountPulseKey = 0;
  String? _pressedKey;
  String? _flyingRecipientText;
  bool _recipientTextFlying = false;

  int _currentStep = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = Currency.btc;
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
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_lockedAmountBtc > 0) return; // Prevent changing locked amount

    HapticFeedback.lightImpact();
    if (RegExp(r'^[0-9]$').hasMatch(key)) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _pressedKey = key;
      _amountPulseKey++;
      _amount = MoneyDisplay.applyKeypadInput(
        currentValue: _amount,
        key: key,
        currency: _selectedCurrency,
        maxLength: _selectedCurrency == Currency.btc ? 16 : 12,
      );
    });

    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (mounted && _pressedKey == key) {
        setState(() => _pressedKey = null);
      }
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

    return Scaffold(
      backgroundColor: _internalBlack,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          reverse: true,
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
      ),
    );
  }

  void _handleBack(bool hasLockedDestination) {
    if (_currentStep > 0 && !hasLockedDestination) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep -= 1);
      return;
    }

    Navigator.pop(context);
  }

  Widget _buildInternalTopBar(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                final hasLockedDestination =
                    _pendingPaymentLinkId != null ||
                    _lockedRecipientAddress.isNotEmpty;
                _handleBack(hasLockedDestination);
              },
              icon: const Icon(LucideIcons.arrowLeft, size: 22),
              tooltip: context.l10n.authBackAction,
              style: IconButton.styleFrom(
                foregroundColor: _internalText,
                minimumSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Text(
                'Enviar',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  color: _internalText,
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

  Widget _buildInternalPrimaryButton({
    required String label,
    IconData? icon,
    required bool enabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !isLoading ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: _internalText,
          foregroundColor: _internalBlack,
          disabledBackgroundColor: _internalText.withValues(alpha: 0.22),
          disabledForegroundColor: _internalText.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _internalBlack,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase()),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';
    final display = key == '.' ? '.' : key;
    final isPressed = _pressedKey == key;

    return Expanded(
      child: SizedBox(
        height: 58,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          offset: isPressed ? const Offset(0, -0.16) : Offset.zero,
          child: TextButton(
            onPressed: () => _onKeyTap(key),
            style: TextButton.styleFrom(
              foregroundColor: isBackspace ? _internalOutline : _internalText,
              shape: const CircleBorder(),
              textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'JetBrainsMono',
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
      ),
    );
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    final currentWallet = _resolveWallet(walletState);
    if (currentWallet == null) {
      SnackbarHelper.showError('Carteira não carregada.');
      return;
    }
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final amountBtc = _currentAmountBtc(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    HapticFeedback.mediumImpact();

    if (!_isValidInternalDestination(_currentRecipientValue())) {
      SnackbarHelper.showError('Destino interno inválido.');
      return;
    }

    if (amountBtc <= 0) {
      SnackbarHelper.showError(context.l10n.errorAmountRequired);
      return;
    }

    if (currentWallet.balance > 0 && amountBtc > currentWallet.balance) {
      SnackbarHelper.showError('Saldo insuficiente para esta transferência.');
      return;
    }

    await _openPaymentConfirmation(
      wallet: currentWallet,
      amount: amountBtc,
      fee: 0,
      total: amountBtc,
      toAddress: _currentRecipientValue(),
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
    final destination = _receiverController.text.trim();
    final isValidDestination = _isValidInternalDestination(destination);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInternalTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Adicionar endereço',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            color: _internalText,
                            fontSize: 38,
                            fontWeight: FontWeight.w500,
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Digite o nome de usuário Kerosene ou o hash da carteira.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _internalMutedText,
                                fontSize: 15,
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 42),
                        _buildInternalDestinationInput(
                          context,
                          isValidDestination: isValidDestination,
                        ),
                        if (destination.isNotEmpty && !isValidDestination) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Endereço inválido ou com caracteres não permitidos.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.redAccent,
                                  height: 1.35,
                                ),
                          ),
                        ],
                        if (recentInternalDestinations.isNotEmpty) ...[
                          const SizedBox(height: 38),
                          Text(
                            'ENVIADOS RECENTEMENTE',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: _internalOutline,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 16),
                          for (final destination
                              in recentInternalDestinations.take(6))
                            _buildInternalRecentDestination(destination),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: _buildInternalPrimaryButton(
                label: 'Continuar',
                icon: LucideIcons.arrowRight,
                enabled: isValidDestination,
                onTap: () {
                  if (!isValidDestination) {
                    SnackbarHelper.showError(
                      destination.isEmpty
                          ? context.l10n.sendMoneyMissingDestination
                          : 'Destino interno inválido.',
                    );
                    return;
                  }
                  FocusScope.of(context).unfocus();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                  );
                  setState(() => _currentStep = 1);
                },
              ),
            ),
          ],
        ),
        _buildFlyingRecipientText(),
      ],
    );
  }

  Widget _buildInternalDestinationInput(
    BuildContext context, {
    required bool isValidDestination,
  }) {
    final hasValue = _receiverController.text.trim().isNotEmpty;
    final isInvalid = hasValue && !isValidDestination;
    final lineColor = isInvalid
        ? Colors.redAccent
        : hasValue && isValidDestination
        ? _internalValidBlue
        : _internalOutline;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: lineColor, width: hasValue ? 2 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _receiverController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            cursorColor: isInvalid ? Colors.redAccent : _internalValidBlue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isInvalid ? Colors.redAccent : _internalText,
              fontFamily: 'JetBrainsMono',
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              labelText: 'Endereço ou nome de usuário',
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: lineColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              hintText: 'ex: daniel ou 9f4a2c...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _internalOutline.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 96, 16),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Escanear QR',
                    onPressed: _scanInternalDestination,
                    icon: const Icon(LucideIcons.scanLine, size: 20),
                    color: lineColor,
                  ),
                  if (hasValue && isValidDestination)
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        LucideIcons.checkCircle,
                        color: _internalValidBlue,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalRecentDestination(
    RecentTransactionDestination destination,
  ) {
    final label = destination.label?.trim();
    final title = label == null || label.isEmpty ? destination.address : label;
    final subtitle = label == null || label.isEmpty
        ? _compactInternalValue(destination.address)
        : _compactInternalValue(destination.address);
    final lastUsed = _formatRecentDestinationTime(destination.lastUsedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _applyRecentInternalDestination(destination),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _internalBorder.withValues(alpha: 0.72),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _internalSurfaceHigh,
                    border: Border.all(color: _internalBorder),
                  ),
                  child: const Icon(
                    LucideIcons.user,
                    color: _internalOutline,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _internalText,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _internalMutedText,
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastUsed.$1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _internalMutedText,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastUsed.$2,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _internalOutline,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        height: 1.25,
                        letterSpacing: 0,
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
  }

  Widget _buildAmountStep(
    BuildContext context, {
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
    required double amountBtc,
    required bool isLoading,
  }) {
    final recipient = _currentRecipientLabel();
    final amountLabel = _lockedAmountBtc > 0
        ? _formatBtcValue(_lockedAmountBtc)
        : MoneyDisplay.formatEditableInput(
            rawValue: _amount,
            currency: Currency.btc,
            withSymbol: false,
          );
    final fiatLabel = _formatFiatReference(
      btcAmount: amountBtc,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final wallet = _resolveWallet(ref.read(walletProvider));
    final balanceLabel = wallet == null
        ? '--'
        : '${_formatBtcValue(wallet.balance, decimalPlaces: 6)} BTC';
    final locked =
        _pendingPaymentLinkId != null ||
        _lockedRecipientAddress.isNotEmpty ||
        _lockedAmountBtc > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInternalTopBar(context),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _internalSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _internalBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.user,
                        color: _internalOutline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Para: $recipient',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _internalText,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: locked
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(
                                  () => _amountKeyboardExpanded =
                                      !_amountKeyboardExpanded,
                                );
                              },
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale:
                                            Tween<double>(
                                              begin: 0.82,
                                              end: 1,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutBack,
                                              ),
                                            ),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      amountLabel,
                                      key: ValueKey(_amountPulseKey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.junge(
                                        color: _internalText,
                                        fontSize: 54,
                                        fontWeight: FontWeight.w100,
                                        height: 1.05,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BTC',
                                  style: GoogleFonts.junge(
                                    color: _internalText,
                                    fontSize: 28,
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _internalOutline,
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    height: 1.4,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _internalSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _internalBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SALDO DISPONÍVEL',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: _internalOutline,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              balanceLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _internalMutedText,
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!locked)
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _amountKeyboardExpanded
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
            color: _internalBlack,
            border: Border(
              top: BorderSide(color: _internalBorder.withValues(alpha: 0.3)),
            ),
          ),
          child: _buildInternalPrimaryButton(
            label: 'Revisar',
            enabled: amountBtc > 0 && !isLoading,
            isLoading: isLoading,
            onTap: _handleContinue,
          ),
        ),
      ],
    );
  }

  String _currentRecipientValue() {
    return _lockedRecipientAddress.isNotEmpty
        ? _lockedRecipientAddress
        : _receiverController.text.trim();
  }

  String _currentRecipientLabel() {
    final label = _lockedRecipientLabel?.trim();
    if (label == null || label.isEmpty || label == 'Destino bloqueado') {
      return _currentRecipientValue();
    }
    return label;
  }

  Future<void> _openPaymentConfirmation({
    required Wallet wallet,
    required double amount,
    required double fee,
    required double total,
    required String toAddress,
  }) async {
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);
    final isPaymentLink = _pendingPaymentLinkId != null;
    final recipientLabel = _currentRecipientLabel();
    final btcAmountLabel = MoneyDisplay.format(
      amount: amount,
      currency: Currency.btc,
    );
    final fiatAmountLabel = _formatFiatReference(
      btcAmount: amount,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    final note = isPaymentLink
        ? 'Pagamento por link interno'
        : 'Transferência interna Kerosene';

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => _InternalTransferReviewScreen<dynamic>(
          recipientLabel: recipientLabel,
          recipientAddress: toAddress,
          amountBtcLabel: btcAmountLabel,
          fiatAmountLabel: fiatAmountLabel,
          feeLabel: context.l10n.free,
          note: note,
          sourceWallet: wallet.name,
          onConfirm: (confirmationContext) => _confirmPayment(
            confirmationContext: confirmationContext,
            wallet: wallet,
            amount: amount,
            fee: fee,
            toAddress: toAddress,
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
  }) async {
    final l10n = context.l10n;
    final profile = await _resolveSecurityProfile(wallet);
    if (!mounted || !confirmationContext.mounted) {
      return null;
    }

    final authResult = await TransactionAuthGate.show(
      confirmationContext,
      profile: profile,
      allowDeviceAuthUnavailable: true,
    );

    if (!authResult.isAuthenticated ||
        !mounted ||
        !confirmationContext.mounted) {
      SnackbarHelper.showError(l10n.sendMoneyAuthFailed);
      return null;
    }

    if (_pendingPaymentLinkId != null) {
      final linkId = _pendingPaymentLinkId;
      if (linkId == null) {
        SnackbarHelper.showError(l10n.sendMoneyInvalidPaymentRequest);
        return null;
      }

      final result = await ref
          .read(paymentLinkNotifierProvider.notifier)
          .pay(
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
        if (!mounted || !confirmationContext.mounted) {
          return null;
        }
        SnackbarHelper.showError(
          ErrorTranslator.translate(confirmationContext.l10n, error),
        );
      }
      ref.read(paymentLinkNotifierProvider.notifier).reset();
      return null;
    }

    final idempotencyKey = const Uuid().v4();
    final result = await ref
        .read(sendTransactionProvider.notifier)
        .send(
          fromWalletId: wallet.id,
          fromAddress: wallet.address.trim().isEmpty
              ? null
              : wallet.address.trim(),
          toAddress: toAddress,
          amount: amount,
          feeSatoshis: (fee * 100000000).toInt(),
          context: null,
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
      if (!mounted || !confirmationContext.mounted) {
        return null;
      }
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
      });

      HapticFeedback.lightImpact();
      SnackbarHelper.showSuccess(context.l10n.sendMoneyRequestDataLoaded);
    } else {
      final candidate = data.trim();
      if (_isValidInternalDestination(candidate)) {
        setState(() {
          _receiverController.text = candidate;
          _receiverController.selection = TextSelection.fromPosition(
            TextPosition(offset: candidate.length),
          );
        });
        HapticFeedback.lightImpact();
        return;
      }
      SnackbarHelper.showError(context.l10n.sendMoneyInvalidQrRequest);
    }
  }

  Future<void> _fetchPaymentLinkDetails(String linkId) async {
    final result = await ref
        .read(ledgerRepositoryProvider)
        .getPaymentRequest(linkId);

    result.fold(
      (failure) {
        SnackbarHelper.showError(
          ErrorTranslator.translate(
            context.l10n,
            failure.errorCode ?? failure.message,
          ),
        );
      },
      (data) {
        final payload = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        final rawAmount = payload['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
        final status = (payload['status']?.toString() ?? 'PENDING')
            .toUpperCase();
        final destinationHash = _readPaymentRequestDestinationHash(payload);

        if (status == 'PAID') {
          SnackbarHelper.showError(context.l10n.sendMoneyRequestAlreadyPaid);
          return;
        }
        if (status == 'CANCELED' || status == 'EXPIRED') {
          SnackbarHelper.showError(context.l10n.sendMoneyRequestExpired);
          return;
        }

        setState(() {
          _pendingPaymentLinkId = linkId;
          _lockedRecipientLabel = destinationHash.isNotEmpty
              ? _shortHash(destinationHash)
              : context.l10n.sendMoneyLockedDestination;
          _lockedRecipientAddress = destinationHash.isNotEmpty
              ? destinationHash
              : context.l10n.sendMoneyLockedDestination;
          if (amount > 0) {
            _lockedAmountBtc = amount;
            _amount = amount
                .toStringAsFixed(8)
                .replaceAll(RegExp(r'0+$'), '')
                .replaceAll(RegExp(r'\.$'), '');
          }
        });
        SnackbarHelper.showSuccess(context.l10n.sendMoneyPaymentRequestLoaded);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openLockedPaymentConfirmationIfReady();
        });
      },
    );
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
    _startRecipientTextFlight(
      destination.label?.trim().isNotEmpty == true
          ? destination.label!.trim()
          : _compactInternalValue(value),
    );
    setState(() {
      _receiverController.text = value;
      _receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: value.length),
      );
    });
  }

  void _startRecipientTextFlight(String text) {
    setState(() {
      _flyingRecipientText = text;
      _recipientTextFlying = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _recipientTextFlying = true);
    });

    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (!mounted) return;
      setState(() {
        _flyingRecipientText = null;
        _recipientTextFlying = false;
      });
    });
  }

  Widget _buildFlyingRecipientText() {
    final text = _flyingRecipientText;
    if (text == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          alignment: _recipientTextFlying
              ? const Alignment(0, -0.34)
              : const Alignment(0, 0.38),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _recipientTextFlying ? 0 : 1,
            curve: Curves.easeOut,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _internalText,
                fontFamily: 'JetBrainsMono',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
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
    );
  }

  String _shortHash(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 8)}';
  }

  Future<void> _scanInternalDestination() async {
    final payload = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    final value = payload?.trim();
    if (!mounted || value == null || value.isEmpty) {
      return;
    }

    final parsed = QrPaymentParser.decode(value);
    final candidate = parsed?.address.trim().isNotEmpty == true
        ? parsed!.address.trim()
        : value;

    setState(() {
      _receiverController.text = candidate;
      _receiverController.selection = TextSelection.fromPosition(
        TextPosition(offset: candidate.length),
      );
      if (parsed?.amountBtc != null && parsed!.amountBtc! > 0) {
        _lockedAmountBtc = parsed.amountBtc!;
        _amount = _formatBtcValue(parsed.amountBtc!);
      }
    });
  }

  bool _isValidInternalDestination(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('@') ||
        trimmed.toLowerCase().startsWith('bitcoin:')) {
      return false;
    }
    if (RegExp(r'^[A-Za-z0-9_]{3,50}$').hasMatch(trimmed)) {
      return true;
    }
    return RegExp(r'^[a-fA-F0-9]{32,128}$').hasMatch(trimmed);
  }

  String _compactInternalValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 18) {
      return trimmed;
    }
    return '${trimmed.substring(0, 10)}...${trimmed.substring(trimmed.length - 6)}';
  }

  (String, String) _formatRecentDestinationTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return ('$day/$month', '$hour:$minute');
  }

  String _formatBtcValue(double value, {int decimalPlaces = 8}) {
    return MoneyDisplay.format(
      amount: value,
      currency: Currency.btc,
      withSymbol: false,
      decimalPlaces: decimalPlaces,
    );
  }

  String _formatFiatReference({
    required double btcAmount,
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    return '≈ ${MoneyDisplay.formatAmountFromBtc(btcAmount: btcAmount, currency: Currency.brl, btcUsd: btcUsd, btcEur: btcEur, btcBrl: btcBrl)}';
  }
}

class _InternalTransferReviewScreen<T> extends StatefulWidget {
  final String recipientLabel;
  final String recipientAddress;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final String feeLabel;
  final String note;
  final String sourceWallet;
  final Future<T?> Function(BuildContext context) onConfirm;

  const _InternalTransferReviewScreen({
    required this.recipientLabel,
    required this.recipientAddress,
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    required this.feeLabel,
    required this.note,
    required this.sourceWallet,
    required this.onConfirm,
  });

  @override
  State<_InternalTransferReviewScreen<T>> createState() =>
      _InternalTransferReviewScreenState<T>();
}

class _InternalTransferReviewScreenState<T>
    extends State<_InternalTransferReviewScreen<T>> {
  bool _isSubmitting = false;
  T? _result;

  Future<void> _confirm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await widget.onConfirm(context);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return _InternalTransferSuccessView<T>(
        result: result,
        recipientLabel: widget.recipientLabel,
        amountBtcLabel: widget.amountBtcLabel,
        fiatAmountLabel: widget.fiatAmountLabel,
        feeLabel: widget.feeLabel,
      );
    }

    return Scaffold(
      backgroundColor: _SendMoneyScreenState._internalBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.arrowLeft, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: _SendMoneyScreenState._internalText,
                    backgroundColor: _SendMoneyScreenState._internalSurface,
                    side: const BorderSide(
                      color: _SendMoneyScreenState._internalBorder,
                    ),
                    minimumSize: const Size.square(40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        Text(
                          'Revisar transferência',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            color: _SendMoneyScreenState._internalText,
                            fontSize: 38,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _InternalReviewRow(
                          label: 'Para',
                          value: widget.recipientLabel,
                          trailingIcon: LucideIcons.chevronRight,
                        ),
                        if (widget.recipientAddress.trim().isNotEmpty &&
                            widget.recipientAddress.trim() !=
                                widget.recipientLabel.trim())
                          _InternalReviewRow(
                            label: 'ID',
                            value: widget.recipientAddress.trim(),
                          ),
                        _InternalReviewRow(
                          label: 'Valor',
                          value: widget.amountBtcLabel,
                          helper: widget.fiatAmountLabel,
                          valueLarge: true,
                        ),
                        _InternalReviewRow(
                          label: 'Taxa',
                          value: widget.feeLabel,
                        ),
                        _InternalReviewRow(
                          label: 'Origem',
                          value: widget.sourceWallet,
                        ),
                        _InternalReviewRow(
                          label: 'Nota',
                          value: widget.note,
                          alignTop: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: _SendMoneyScreenState._internalText,
                        foregroundColor: _SendMoneyScreenState._internalBlack,
                        disabledBackgroundColor: _SendMoneyScreenState
                            ._internalText
                            .withValues(alpha: 0.32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _SendMoneyScreenState._internalBlack,
                              ),
                            )
                          : const Icon(LucideIcons.arrowRight, size: 20),
                      label: const Text(
                        'Confirmar transferência',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        color: _SendMoneyScreenState._internalMutedText,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'TRANSAÇÃO PROTEGIDA',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _SendMoneyScreenState._internalMutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternalReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData? trailingIcon;
  final bool valueLarge;
  final bool alignTop;

  const _InternalReviewRow({
    required this.label,
    required this.value,
    this.helper,
    this.trailingIcon,
    this.valueLarge = false,
    this.alignTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _SendMoneyScreenState._internalMutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: alignTop ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _SendMoneyScreenState._internalText,
                          fontSize: valueLarge ? 20 : 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        trailingIcon,
                        color: _SendMoneyScreenState._internalMutedText,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (helper != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    helper!,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _SendMoneyScreenState._internalMutedText,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalTransferSuccessView<T> extends StatelessWidget {
  final T result;
  final String recipientLabel;
  final String amountBtcLabel;
  final String fiatAmountLabel;
  final String feeLabel;

  const _InternalTransferSuccessView({
    required this.result,
    required this.recipientLabel,
    required this.amountBtcLabel,
    required this.fiatAmountLabel,
    required this.feeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SendMoneyScreenState._internalBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
          child: Column(
            children: [
              const Spacer(),
              Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _SendMoneyScreenState._internalSuccessGreen
                          .withValues(alpha: 0.12),
                      border: Border.all(
                        color: _SendMoneyScreenState._internalSuccessGreen,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: _SendMoneyScreenState._internalSuccessGreen,
                      size: 42,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.72, 0.72),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                    duration: 420.ms,
                  )
                  .fadeIn(duration: 240.ms),
              const SizedBox(height: 28),
              Text(
                'Transferência concluída',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  color: _SendMoneyScreenState._internalText,
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  height: 1.08,
                  letterSpacing: 0,
                ),
              ).animate().fadeIn(delay: 80.ms, duration: 280.ms),
              const SizedBox(height: 10),
              Text(
                'Os fundos foram enviados dentro da Kerosene.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _SendMoneyScreenState._internalMutedText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 44),
              _InternalReviewRow(label: 'Para', value: recipientLabel),
              _InternalReviewRow(
                label: 'Valor',
                value: amountBtcLabel,
                helper: fiatAmountLabel,
                valueLarge: true,
              ),
              _InternalReviewRow(label: 'Taxa', value: feeLabel),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(result),
                  style: FilledButton.styleFrom(
                    backgroundColor: _SendMoneyScreenState._internalText,
                    foregroundColor: _SendMoneyScreenState._internalBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Concluir',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
