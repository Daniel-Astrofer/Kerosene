import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/currency_logic.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../l10n/app_localizations.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? walletId;
  final String? initialAddress;

  /// Pre-fill amount in BTC (e.g. from QR or NFC payment request).
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
  final _amountController = TextEditingController();
  Currency _selectedCurrency = Currency.btc;
  late TextEditingController _receiverController;
  final _contactService = ContactService();
  List<Contact> _recentContacts = [];
  Contact? _selectedContact;

  @override
  void initState() {
    super.initState();
    _receiverController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
    if (widget.initialAmountBtc != null && widget.initialAmountBtc! > 0) {
      _amountController.text = CurrencyLogic.formatAmount(
        widget.initialAmountBtc!,
        Currency.btc,
      );
    }
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactService.getContacts();
    if (mounted) {
      setState(() {
        _recentContacts = contacts;
        if (widget.initialAddress != null) {
          try {
            _selectedContact = contacts.firstWhere(
              (c) => c.address == widget.initialAddress,
            );
          } catch (_) {
            _selectedContact = Contact(
              address: widget.initialAddress!,
              lastUsed: DateTime.now(),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncActionState>(sendTransactionProvider, (previous, next) {
      if (next.result != null) {
        _contactService.saveContact(
          _receiverController.text,
          name: _selectedContact?.name,
        );
        // Success handled by HomeScreen with a dialog
        // ref.read(sendTransactionProvider.notifier).reset(); // Reset is good but we can do it after pop if needed, or before.
        ref.read(sendTransactionProvider.notifier).reset();
        Navigator.pop(context, true);
      } else if (next.error != null) {
        showCustomErrorDialog(context, next.error!);
        ref.read(sendTransactionProvider.notifier).reset();
      }
    });

    final walletState = ref.watch(walletProvider);
    final sendState = ref.watch(sendTransactionProvider);
    final selectedWallet = walletState is WalletLoaded
        ? walletState.selectedWallet
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF0A0A0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header minimalista
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.send,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Value Input with Currency Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.amount,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CurrencyInputFormatter(
                                      maxDigits: 20,
                                      symbol: '',
                                      decimals:
                                          _selectedCurrency == Currency.btc
                                          ? 8
                                          : 2,
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: _selectedCurrency == Currency.btc
                                        ? "0.00000000"
                                        : "0.00",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      fontSize: 28,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              _buildCurrencySelector(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Conversion Hint
                    if (_amountController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final btcUsd = ref.watch(latestBtcPriceProvider);
                            final btcEur = ref.watch(btcEurPriceProvider);
                            final btcBrl = ref.watch(btcBrlPriceProvider);

                            final amount = CurrencyLogic.parseAmount(
                              _amountController.text,
                            );
                            if (amount <= 0) return const SizedBox.shrink();

                            double converted = 0;
                            String targetUnit = '';

                            if (_selectedCurrency == Currency.btc) {
                              converted = amount * (btcUsd ?? 0);
                              targetUnit = 'USD';
                            } else {
                              converted = CurrencyLogic.convertToBtc(
                                amount: amount,
                                fromCurrency: _selectedCurrency,
                                btcUsdPrice: btcUsd,
                                btcEurPrice: btcEur,
                                btcBrlPrice: btcBrl,
                              );
                              targetUnit = 'BTC';
                            }

                            return Text(
                              "≈ ${converted.toStringAsFixed(targetUnit == 'BTC' ? 8 : 2)} $targetUnit",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recipient card minimalista
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GestureDetector(
                  onTap: () => _showContactSelector(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _selectedContact?.name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  (_receiverController.text.isNotEmpty
                                      ? _receiverController.text
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : "?"),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedContact?.name ??
                                    (_receiverController.text.isNotEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.recipient
                                        : AppLocalizations.of(
                                            context,
                                          )!.selectRecipient),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_receiverController.text.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _shortenAddress(
                                    _receiverController.text,
                                    length: 8,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Wallet selector minimalista
              if (selectedWallet != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GestureDetector(
                    onTap: () => walletState is WalletLoaded
                        ? _showWalletSelector(context, walletState)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.fromWallet(selectedWallet.name),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "${selectedWallet.balance.toStringAsFixed(8)} BTC",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withValues(alpha: 0.2),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const Spacer(),

              const SizedBox(height: 12),

              // Botão Send minimalista
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sendState.isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: sendState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.send,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
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

  String _shortenAddress(String address, {int length = 8}) {
    if (address.length <= length * 2) return address;
    return "${address.substring(0, length)}...${address.substring(address.length - length)}";
  }

  void _showContactSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppLocalizations.of(context)!.selectRecipient,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _receiverController,
                onChanged: (val) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchAddress,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_recentContacts.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noRecentContacts,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _recentContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _recentContacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedContact = contact;
                            _receiverController.text = contact.address;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    contact.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        "?",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name ??
                                          AppLocalizations.of(context)!.unknown,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _shortenAddress(
                                        contact.address,
                                        length: 10,
                                      ),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          value: _selectedCurrency,
          dropdownColor: const Color(0xFF1E1E24),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 16,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (Currency? newCurrency) {
            if (newCurrency != null && newCurrency != _selectedCurrency) {
              _updateCurrency(newCurrency);
            }
          },
          items: Currency.values.map((Currency currency) {
            return DropdownMenuItem<Currency>(
              value: currency,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currency == Currency.btc)
                    const Icon(
                      Icons.currency_bitcoin,
                      color: Color(0xFFF7931A),
                      size: 16,
                    )
                  else if (currency == Currency.usd)
                    const Icon(
                      Icons.attach_money,
                      color: Colors.greenAccent,
                      size: 16,
                    )
                  else if (currency == Currency.eur)
                    const Icon(Icons.euro, color: Colors.blueAccent, size: 16)
                  else if (currency == Currency.brl)
                    const Text(
                      'R\$',
                      style: TextStyle(
                        color: Colors.lightGreenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(currency.code),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _updateCurrency(Currency newCurrency) {
    final currentText = _amountController.text;
    final startCurrency = _selectedCurrency;

    setState(() {
      _selectedCurrency = newCurrency;
    });

    if (currentText.isEmpty) {
      _amountController.clear();
      return;
    }

    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);

    try {
      double amount = CurrencyLogic.parseAmount(currentText);
      if (amount <= 0) return;

      // 1. Convert to BTC
      double amountInBtc = CurrencyLogic.convertToBtc(
        amount: amount,
        fromCurrency: startCurrency,
        btcUsdPrice: btcUsd,
        btcEurPrice: btcEur,
        btcBrlPrice: btcBrl,
      );

      // 2. Convert BTC to new currency
      double finalAmount = 0;
      switch (newCurrency) {
        case Currency.btc:
          finalAmount = amountInBtc;
          break;
        case Currency.usd:
          finalAmount = amountInBtc * (btcUsd ?? 0);
          break;
        case Currency.eur:
          finalAmount = amountInBtc * (btcEur ?? 0);
          break;
        case Currency.brl:
          finalAmount = amountInBtc * (btcBrl ?? 0);
          break;
      }

      _amountController.text = CurrencyLogic.formatAmount(
        finalAmount,
        newCurrency,
      );
    } catch (e) {
      // ignore
    }
  }

  void _handleContinue() async {
    final walletState = ref.read(walletProvider);
    if (_receiverController.text.isEmpty ||
        _amountController.text.isEmpty ||
        walletState is! WalletLoaded) {
      showCustomErrorDialog(
        context,
        AppLocalizations.of(context)!.pleaseCompleteFields,
      );
      return;
    }

    // Biometric / PIN confirmation before sending
    final biometricService = BiometricService();
    final canAuth = await biometricService.canAuthenticate();
    final isEnrolled = await biometricService.isBiometricEnrolled();

    if (canAuth && isEnrolled) {
      final authenticated = await biometricService.authenticate(
        localizedReason: 'Confirm Bitcoin transaction',
      );
      if (!mounted) return;
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Authentication failed. Transaction cancelled.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    } else {
      // No system biometrics/PIN or not enrolled — use in-app PIN
      final pinService = AppPinService();
      final hasPinSet = await pinService.hasPinSet();
      if (!mounted) return;
      final authenticated = await PinDialog.show(context, isSetup: !hasPinSet);
      if (!mounted) return;
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Authentication failed. Transaction cancelled.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    }

    // Parse amount using CurrencyLogic
    final rawAmount = CurrencyLogic.parseAmount(_amountController.text);
    final btcUsd = ref.read(latestBtcPriceProvider);
    final btcEur = ref.read(btcEurPriceProvider);
    final btcBrl = ref.read(btcBrlPriceProvider);

    final btcAmount = CurrencyLogic.convertToBtc(
      amount: rawAmount,
      fromCurrency: _selectedCurrency,
      btcUsdPrice: btcUsd,
      btcEurPrice: btcEur,
      btcBrlPrice: btcBrl,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF7931A)),
      ),
    );

    // Platform transfers are internal, thus 0 fee.
    const feeBtc = 0.0;
    final totalBtc = btcAmount;

    if (!mounted) return;
    Navigator.pop(context);

    _showConfirmationDialog(
      context,
      btcAmount,
      feeBtc,
      totalBtc,
      walletState.selectedWallet!.id,
      walletState.selectedWallet!.address,
      _receiverController.text,
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
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                blur: 40,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Review Transaction",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildConfirmRow("Recipient", toAddress, isSmall: true),
                    const Divider(color: Colors.white10, height: 32),
                    _buildConfirmRow(
                      "Amount",
                      "${amount.toStringAsFixed(8)} BTC",
                    ),
                    const SizedBox(height: 12),
                    _buildConfirmRow(
                      "Network Fee",
                      "Free",
                      valueColor: const Color(0xFF00FF94),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _buildConfirmRow(
                      "Total",
                      "${total.toStringAsFixed(8)} BTC",
                      isBold: true,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              final satoshiFee = (fee * 100000000).toInt();
                              ref
                                  .read(sendTransactionProvider.notifier)
                                  .send(
                                    fromWalletId: fromWalletId,
                                    fromAddress: fromAddress,
                                    toAddress: toAddress,
                                    amount: amount,
                                    feeSatoshis: satoshiFee,
                                  );
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildConfirmRow(
    String label,
    String value, {
    bool isSmall = false,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isSmall ? 13 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontFamily: isSmall ? null : 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showWalletSelector(BuildContext context, WalletLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Select Wallet",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: state.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = state.wallets[index];
                    final isSelected = wallet.id == state.selectedWallet?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(walletProvider.notifier)
                              .selectWallet(wallet);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${wallet.balance.toStringAsFixed(8)} BTC",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
