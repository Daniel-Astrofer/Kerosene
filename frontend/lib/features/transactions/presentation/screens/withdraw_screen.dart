import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/cyber_background.dart';

import '../../../wallet/domain/entities/wallet.dart';
import '../providers/transaction_provider.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';
import '../../../wallet/domain/entities/transaction.dart';

enum SendMode { nfc, manual, qr }

/// Tela de envio (Withdraw) redesenhada para match o Figma "RECEIVE / ENTER AMOUNT"
class WithdrawScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;
  final bool showBackButton;

  const WithdrawScreen({
    super.key,
    this.wallet,
    this.showBackButton = true,
  });

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totpController = TextEditingController();

  String _amountRaw = ''; // raw digit string e.g. "100015887"
  final SendMode _sendMode = SendMode.manual;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    if (_amountRaw.isEmpty) return 0.0;
    final n = int.tryParse(_amountRaw) ?? 0;
    return n / 100000000.0;
  }

  String get _displayAmount {
    if (_amountRaw.isEmpty) return '0.00000000';
    final n = int.tryParse(_amountRaw) ?? 0;
    final btc = n / 100000000.0;
    return btc.toStringAsFixed(8);
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '←') {
        if (_amountRaw.isNotEmpty) {
          _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
        }
      } else if (key == '.') {
        // Handle decimal point if needed, or stick to satoshi-style entry
      } else {
        if (_amountRaw.length < 12) {
          _amountRaw = '$_amountRaw$key';
        }
      }
      // Trim leading zeros
      while (_amountRaw.length > 1 && _amountRaw.startsWith('0')) {
        _amountRaw = _amountRaw.substring(1);
      }
    });
  }

  void _onContinue() {
    if (_parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorAmountRequired),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_sendMode == SendMode.manual) {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, digite o endereço ou username.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _showFinalConfirmation();
    } else {
      // fallback for QR / NFC not fully implemented yet
      _showAddressModal();
    }
  }

  void _showAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressInputModal(
        controller: _addressController,
        descriptionController: _descriptionController,
        onDone: () {
          Navigator.pop(context);
          _showFinalConfirmation();
        },
      ),
    );
  }

  void _showFinalConfirmation() {
    final walletState = ref.read(walletProvider);
    final Wallet? effectiveWallet = widget.wallet ??
        (walletState is WalletLoaded ? walletState.selectedWallet : null);
    if (effectiveWallet == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawConfirmationModal(
        wallet: effectiveWallet,
        amount: _parsedAmount,
        address: _addressController.text,
        description: _descriptionController.text,
        totpController: _totpController,
        onConfirm: () => _handleWithdraw(effectiveWallet),
      ),
    );
  }

  Future<void> _handleWithdraw(Wallet wallet) async {
    final result = await ref.read(withdrawProvider.notifier).withdraw(
          fromWalletName: wallet.name,
          toAddress: _addressController.text.trim(),
          amount: _parsedAmount,
          totpCode: _totpController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context); // Close modal
      showDialog(
        context: context,
        barrierColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        builder: (_) => TransactionSuccessDialog(
          type: TransactionType.send,
          amount: result.amountReceived,
          counterparty: result.receiver,
        ),
      );

      ref.invalidate(transactionHistoryProvider);
      ref.read(walletProvider.notifier).refresh();

      setState(() {
        _amountRaw = '';
        _addressController.clear();
        _descriptionController.clear();
        _totpController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final Wallet? effectiveWallet = widget.wallet ??
        (walletState is WalletLoaded ? walletState.selectedWallet : null);

    if (effectiveWallet == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: true,
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  _buildAmountDisplay(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildAddressSection(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildNetworkSelection(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFeeBreakdown(),
            ),
            const SizedBox(height: 24),
            _buildKeypad(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    elevation: 0,
                    shadowColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    context.l10n.withdrawConfirmButton.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.onPrimary, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05),
                padding: const EdgeInsets.all(8),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(
            context.l10n.withdrawConfirmButton.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onPrimary),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          context.l10n.amountToSend.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "₿ ",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900),
            ),
            Text(
              _displayAmount,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2.0,
                    fontFamily: 'JetBrainsMono',
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _addressController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrainsMono',
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Endereço BTC ou Invoice Lightning',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.3),
                  fontFamily: 'HubotSans',
                  fontSize: 13,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                prefixIcon: Icon(Icons.account_balance_wallet_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8),
                    size: 20),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 0),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lightning',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.4),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'On-chain',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 2.0,
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

  Widget _buildFeeBreakdown() {
    // Simulated values for display
    final withdrawalAmount = _parsedAmount;
    final networkFee = 0.0001;
    final serviceFee = 0.00005;
    final total = withdrawalAmount - networkFee - serviceFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildFeeRow('NETWORK FEE', '${networkFee.toStringAsFixed(5)} BTC'),
          const SizedBox(height: 12),
          _buildFeeRow('SERVICE FEE', '${serviceFee.toStringAsFixed(5)} BTC'),
          const SizedBox(height: 16),
          Divider(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${(total > 0 ? total : 0.0).toStringAsFixed(5)} BTC',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrainsMono',
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(Icons.backspace_outlined,
                  color: Theme.of(context).colorScheme.onPrimary, size: 22)
              : Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFamily: 'JetBrainsMono',
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
        ),
      ),
    );
  }
}

class _AddressInputModal extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController descriptionController;
  final VoidCallback onDone;

  const _AddressInputModal({
    required this.controller,
    required this.descriptionController,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0xFF292929))),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETALHES DO ENVIO',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            controller: controller,
            label: 'ENDEREÇO BTC',
            hint: 'bc1q...',
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: descriptionController,
            label: 'DESCRIÇÃO (OPCIONAL)',
            hint: 'Ex: Pagamento almoço',
            icon: Icons.description_rounded,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Confirmar Destino'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF292929)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF292929)),
            ),
          ),
        ),
      ],
    );
  }
}

class _WithdrawConfirmationModal extends StatelessWidget {
  final Wallet wallet;
  final double amount;
  final String address;
  final String description;
  final TextEditingController totpController;
  final VoidCallback onConfirm;

  const _WithdrawConfirmationModal({
    required this.wallet,
    required this.amount,
    required this.address,
    required this.description,
    required this.totpController,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0xFF292929))),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CONFIRMAR TRANSAÇÃO',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '${amount.toStringAsFixed(8)} BTC',
            style: const TextStyle(
              color: Color(0xFF00FFA3),
              fontSize: 32,
              fontWeight: FontWeight.w200,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Para:', address),
          if (description.isNotEmpty) _buildInfoRow('Nota:', description),
          const SizedBox(height: 32),
          TextField(
            controller: totpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.1),
                letterSpacing: 8,
              ),
              counterText: '',
              labelText: 'CÓDIGO TOTP',
              labelStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFA3),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'ENVIAR AGORA',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
