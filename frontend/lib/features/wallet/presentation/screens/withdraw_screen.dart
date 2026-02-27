import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  final String walletId;

  const WithdrawScreen({super.key, required this.walletId});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  // Timer for debouncing amount input
  Timer? _debounce;
  double _currentAmount = 0.0;

  // Fee selection (0=fast, 1=standard, 2=slow)
  int _selectedFeeSpeed = 0;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      final amt = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
      if (amt > 0) {
        setState(() {
          _currentAmount = amt;
        });
      }
    });
  }

  Future<void> _handleWithdraw(BuildContext context, dynamic feeData) async {
    final address = _addressController.text.trim();
    if (address.isEmpty || _currentAmount <= 0) {
      SnackbarHelper.showError('Preencha um endereço e um valor válido.');
      return;
    }

    // Authenticate
    final biometricService = BiometricService();
    final canAuth = await biometricService.canAuthenticate();
    final iEnrolled = await biometricService.isBiometricEnrolled();

    bool authenticated = false;
    if (canAuth && iEnrolled) {
      authenticated = await biometricService.authenticate(
        localizedReason: 'Autentique para confirmar o saque.',
      );
    } else {
      if (!context.mounted) return;
      final pinService = AppPinService();
      final hasPinSet = await pinService.hasPinSet();
      if (!context.mounted) return;
      authenticated = await PinDialog.show(context, isSetup: !hasPinSet);
    }

    if (!context.mounted) return;
    if (!authenticated) {
      SnackbarHelper.showError("Autenticação cancelada.");
      return;
    }

    // Send transaction (Withdrawal On-chain)
    final result = await ref
        .read(withdrawProvider.notifier)
        .withdraw(
          toAddress: address,
          amount: _currentAmount,
          fromWalletName: widget.walletId,
        );

    if (result != null) {
      SnackbarHelper.showSuccess(
        "Saque enviado com sucesso para a rede Bitcoin!",
      );
      if (context.mounted) {
        ref.read(walletProvider.notifier).refresh();
        Navigator.pop(context);
      }
    } else {
      final errorState = ref.read(withdrawProvider);
      if (errorState.error != null && context.mounted) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(errorState.error!),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeAsyncValue = ref.watch(feeEstimateProvider(_currentAmount));
    final sendState = ref.watch(withdrawProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text(
          'Saque On-chain',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF0A0A15)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address Input
                  const Text(
                    "ENDEREÇO BITCOIN DE DESTINO",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputBox(
                    controller: _addressController,
                    hint: 'Colar endereço bc1...',
                    icon: Icons.qr_code_scanner_rounded,
                  ),

                  const SizedBox(height: 32),

                  // Amount Input
                  const Text(
                    "VALOR (BTC)",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputBox(
                    controller: _amountController,
                    hint: '0.00',
                    icon: Icons.currency_bitcoin_rounded,
                    isNumeric: true,
                    onChanged: _onAmountChanged,
                  ),

                  const SizedBox(height: 32),

                  // Network Fee section
                  if (_currentAmount > 0)
                    feeAsyncValue.when(
                      data: (feeData) => _buildFeeSection(feeData),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD0F288),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          "Erro ao estimar taxas da rede.",
                          style: TextStyle(color: Colors.red[300]),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // Send Action
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_currentAmount > 0 &&
                              sendState.isLoading == false &&
                              feeAsyncValue.value != null)
                          ? () => _handleWithdraw(context, feeAsyncValue.value)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD0F288),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: sendState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "CONFIRMAR SAQUE",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
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

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumeric = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildFeeSection(dynamic feeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "DIFICULDADE DA REDE (TAXA)",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildFeeOption(
                0,
                "Rápido",
                feeData.estimatedFastBtc,
                Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFeeOption(
                1,
                "Médio",
                feeData.estimatedStandardBtc,
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFeeOption(
                2,
                "Demorado",
                feeData.estimatedSlowBtc,
                Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeOption(
    int index,
    String label,
    double amountBtc,
    Color color,
  ) {
    final isSelected = _selectedFeeSpeed == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeeSpeed = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amountBtc.toStringAsFixed(6),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
