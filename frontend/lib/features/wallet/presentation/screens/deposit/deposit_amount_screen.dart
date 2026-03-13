import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/wallet.dart';
import 'deposit_method_screen.dart';
import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../shared/widgets/brushed_metal_container.dart';

class DepositAmountScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const DepositAmountScreen({super.key, required this.wallet});

  @override
  ConsumerState<DepositAmountScreen> createState() =>
      _DepositAmountScreenState();
}

class _DepositAmountScreenState extends ConsumerState<DepositAmountScreen> {
  String _amountRaw = '0'; // Stored as cents "250000" = R$ 2.500,00

  double get _parsedAmount {
    if (_amountRaw.isEmpty) return 0.0;
    final n = int.tryParse(_amountRaw) ?? 0;
    return n / 100.0;
  }

  String get _displayAmount {
    if (_amountRaw.isEmpty || _amountRaw == '0') return '0,00';
    final n = int.tryParse(_amountRaw) ?? 0;
    final value = n / 100.0;

    // Format to BRL manually to avoid external deps if not present
    // or use a simple regex approach:
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$integerPart,${parts[1]}';
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '←') {
        if (_amountRaw.length > 1) {
          _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1);
        } else {
          _amountRaw = '0';
        }
      } else if (key == '.') {
        // Ignored for fiat cents entry pattern
      } else {
        if (_amountRaw.length < 10) {
          // Limit to a reasonable amout
          _amountRaw = _amountRaw == '0' ? key : '$_amountRaw$key';
        }
      }
    });
  }

  void _onContinue() {
    if (_parsedAmount <= 0) {
      SnackbarHelper.showError("Please enter an amount greater than 0.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositMethodScreen(
          wallet: widget.wallet,
          amountFiat: _parsedAmount, // Passing Fiat amount
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BrushedMetalContainer(
        baseColor: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildEnterAmountLabel(),
                    const SizedBox(height: 16),
                    _buildAmountDisplay(),
                    const Spacer(flex: 3),
                    _buildKeypad(),
                    const SizedBox(height: 24),
                    _buildContinueButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Text(
            'Add Funds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildEnterAmountLabel() {
    return Text(
      'ENTER AMOUNT',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          const Text(
            'R\$ ',
            style: TextStyle(
              color: Color(0xFF0033FF), // Branded blue
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              _displayAmount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w300,
                fontFamily: 'Inter',
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '←'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) => _buildKey(key)).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) {
      return const Expanded(child: SizedBox());
    }
    
    final isBackspace = key == '←';

    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0033FF), // Branded blue
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: _onContinue,
          child: const Text(
            'CONTINUE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
