import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:teste/l10n/l10n_extension.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/presentation/widgets/pin_dialog.dart';
import '../../../../core/security/app_pin_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../widgets/amount_input_pad.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  final String walletId;

  const WithdrawScreen({super.key, required this.walletId});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _totpController = TextEditingController();

  // Timer for debouncing amount input
  Timer? _debounce;
  double _currentAmount = 0.0;

  // Fee selection (0=fast, 1=standard, 2=slow)
  int _selectedFeeSpeed = 0;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _totpController.dispose();
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
    final totpCode = _totpController.text.trim();
    if (address.isEmpty || _currentAmount <= 0) {
      SnackbarHelper.showError(context.l10n.withdrawInvalidFields);
      return;
    }
    if (totpCode.length != 6) {
      SnackbarHelper.showError('Código TOTP inválido. Insira os 6 dígitos.');
      return;
    }

    // Authenticate
    final biometricService = BiometricService();
    final canAuth = await biometricService.canAuthenticate();
    final iEnrolled = await biometricService.isBiometricEnrolled();

    bool authenticated = false;
    if (canAuth && iEnrolled) {
      if (!context.mounted) return;
      authenticated = await biometricService.authenticate(
        localizedReason: context.l10n.withdrawAuthReason,
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
      SnackbarHelper.showError(context.l10n.withdrawAuthCancelled);
      return;
    }

    // Send transaction (Withdrawal On-chain)
    final result = await ref
        .read(withdrawProvider.notifier)
        .withdraw(
          toAddress: address,
          amount: _currentAmount,
          fromWalletName: widget.walletId,
          totpCode: totpCode,
        );

    if (!context.mounted) return;
    if (result != null) {
      SnackbarHelper.showSuccess(context.l10n.withdrawSuccess);
      if (context.mounted) {
        ref.read(walletProvider.notifier).refresh();
        Navigator.pop(context);
      }
    } else {
      final errorState = ref.read(withdrawProvider);
      if (errorState.error != null && context.mounted) {
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, errorState.error!),
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
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            title: Text(
              context.l10n.saqueAction,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address Input
                  Text(
                    context.l10n.withdrawAddressLabel,
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
                    hint: context.l10n.withdrawAddressLabel,
                    icon: Icons.qr_code_scanner_rounded,
                  ),

                  const SizedBox(height: 32),

                  // Amount Input
                  Text(
                    context.l10n.withdrawAmountLabel,
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
                    readOnly: true,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AmountInputPad(
                          onNumberPressed: (val) {
                            final current = _amountController.text;
                            _amountController.text = current + val;
                            _onAmountChanged(_amountController.text);
                          },
                          onBackspace: () {
                            final current = _amountController.text;
                            if (current.isNotEmpty) {
                              _amountController.text = current.substring(0, current.length - 1);
                              _onAmountChanged(_amountController.text);
                            }
                          },
                          onDecimal: () {
                            final current = _amountController.text;
                            if (!current.contains('.')) {
                              _amountController.text = current.isEmpty ? '0.' : '$current.';
                            }
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // TOTP code
                  Text(
                    'Código TOTP (6 dígitos)',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInputBox(
                    controller: _totpController,
                    hint: '000000',
                    icon: Icons.lock_clock_rounded,
                    isNumeric: true,
                  ),

                  const SizedBox(height: 32),

                  // Network Fee section
                  if (_currentAmount > 0)
                    feeAsyncValue.when(
                      data: (feeData) => _buildFeeSection(feeData),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Color(0xFFD0F288)),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          context.l10n.withdrawErrorFee,
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
                        backgroundColor: const Color(0xFF0033FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: const Color(0xFF0033FF).withOpacity(0.2),
                      ),
                          : const Text(
                              "CONTINUE",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
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
        ),
      );
    }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumeric = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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
        Text(
          context.l10n.withdrawFeeSection,
          style: const TextStyle(
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
                context.l10n.withdrawFeeFast,
                feeData.estimatedFastBtc,
                Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFeeOption(
                1,
                context.l10n.withdrawFeeMedium,
                feeData.estimatedStandardBtc,
                Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFeeOption(
                2,
                context.l10n.withdrawFeeSlow,
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
              ? color.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.05),
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
```
