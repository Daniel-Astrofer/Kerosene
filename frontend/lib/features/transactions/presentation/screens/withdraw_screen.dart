import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/domain/entities/wallet.dart';
import '../providers/transaction_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../transactions/presentation/widgets/transaction_success_dialog.dart';
import '../../../wallet/domain/entities/transaction.dart';

enum SendMode { nfc, manual, qr }

/// Tela de envio (Withdraw) redesenhada para match o Figma "RECEIVE / ENTER AMOUNT"
class WithdrawScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final bool showBackButton;

  const WithdrawScreen({
    super.key,
    required this.wallet,
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
          content: Text(AppLocalizations.of(context)!.errorAmountRequired),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawConfirmationModal(
        wallet: widget.wallet,
        amount: _parsedAmount,
        address: _addressController.text,
        description: _descriptionController.text,
        totpController: _totpController,
        onConfirm: _handleWithdraw,
      ),
    );
  }

  Future<void> _handleWithdraw() async {
    final result = await ref
        .read(withdrawProvider.notifier)
        .withdraw(
          fromWalletName: widget.wallet.name,
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
        barrierColor: Colors.black.withValues(alpha: 0.8),
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
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // AMOUNT TO SEND label
                    Text(
                      'AMOUNT TO SEND',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Large BTC amount display
                    _buildAmountDisplay(),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PROCESSING: ~15 MINS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Destination Address
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildAddressSection(),
                    ),

                    const SizedBox(height: 24),

                    // Network Selection
                    Text(
                      'RECEBER VIA:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildNetworkSelection(),
                    ),

                    const SizedBox(height: 24),

                    // Fee Breakdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildFeeBreakdown(),
                    ),

                    const SizedBox(height: 32),

                    // Confirm Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00FFA3,
                            ), // Neon Green
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shadowColor: const Color(
                              0xFF00FFA3,
                            ).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'CONFIRMAR E ENVIAR',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Keypad fixed at bottom
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (widget.showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          const Expanded(
            child: Text(
              'SECURE WITHDRAWAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                _displayAmount,
                key: ValueKey(_displayAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'Inter',
                  letterSpacing: -1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'BTC',
            style: TextStyle(
              color: Color(0xFF00FFA3), // neon green
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₿',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 24,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DESTINATION ADDRESS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00D4FF),
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _addressController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Endereço BTC, Username ou Paynym...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF042B2B), // Dark greenish bg
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
              ), // Cyan border
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF00D4FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lightning',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'On-chain',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeBreakdown() {
    // Simulated values for display
    final withdrawalAmount = _parsedAmount;
    final networkFee = 0.0001;
    final serviceFee = 0.00005;
    final total =
        withdrawalAmount -
        networkFee -
        serviceFee; // Basic subtraction logic for mock

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildFeeRow(
            'WITHDRAWAL',
            '${withdrawalAmount.toStringAsFixed(5)} BTC',
          ),
          const SizedBox(height: 12),
          _buildFeeRow('NETWORK FEE', '${networkFee.toStringAsFixed(5)} BTC'),
          const SizedBox(height: 12),
          _buildFeeRow('SERVICE FEE', '${serviceFee.toStringAsFixed(5)} BTC'),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL TO RECEIVE',
                style: TextStyle(
                  color: Color(0xFF00D4FF), // Cyan
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${(total > 0 ? total : 0.0).toStringAsFixed(5)} BTC',
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
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
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['00', '0', '←'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) => _buildKey(key)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isBackspace = key == '←';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onKeyTap(key),
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: isBackspace
                  ? Icon(
                      Icons.backspace_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    )
                  : Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Inter',
                      ),
                    ),
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
          const Text(
            'DETALHES DO ENVIO',
            style: TextStyle(
              color: Colors.white,
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
          style: const TextStyle(color: Colors.white),
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
          const Text(
            'CONFIRMAR TRANSAÇÃO',
            style: TextStyle(
              color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                letterSpacing: 8,
              ),
              counterText: '',
              labelText: 'CÓDIGO TOTP',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                foregroundColor: Colors.black,
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
              style: const TextStyle(
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
