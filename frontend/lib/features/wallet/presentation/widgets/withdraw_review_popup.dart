import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/constants/app_copy.dart';
import 'package:kerosene/core/presentation/widgets/cyber_button.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/utils/snackbar_helper.dart';
import 'package:kerosene/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';

class WithdrawReviewPopup extends ConsumerStatefulWidget {
  final double amount;
  final bool isLightning;
  final String walletName;
  final Function(String address, String totp, bool shamirVerified) onConfirm;

  const WithdrawReviewPopup({
    super.key,
    required this.amount,
    required this.isLightning,
    required this.walletName,
    required this.onConfirm,
  });

  @override
  ConsumerState<WithdrawReviewPopup> createState() =>
      _WithdrawReviewPopupState();
}

class _WithdrawReviewPopupState extends ConsumerState<WithdrawReviewPopup> {
  final _addressController = TextEditingController();
  final _totpController = TextEditingController();
  bool _shamirVerified = false;
  int _currentStep = 0; // 0: Address, 1: Security (Shamir/TOTP)
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_addressController.text.trim().isEmpty) {
        SnackbarHelper.showError(
          AppCopy.withdrawReviewEmptyError(
            context,
            isLightning: widget.isLightning,
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _handleSecurity() async {
    // Local validation only. The real passkey challenge is triggered later by
    // the backend response and signed in the provider.
    setState(() => _isLoading = true);
    await Future.delayed(800.ms);
    if (!mounted) {
      return;
    }
    setState(() => _shamirVerified = true);

    // TOTP Check
    if (_totpController.text.length != 6) {
      setState(() {
        _isLoading = false;
        _shamirVerified = false;
      });
      SnackbarHelper.showError(
        AppCopy.withdrawReviewInvalidTotp.resolve(context),
      );
      return;
    }

    widget.onConfirm(
        _addressController.text.trim(), _totpController.text.trim(), true);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.xxl)),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AnimatedSwitcher(
          duration: 300.ms,
          child: _currentStep == 0 ? _buildAddressStep() : _buildSecurityStep(),
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      key: const ValueKey('address'),
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
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppCopy.withdrawReviewTitle(
            context,
            isLightning: widget.isLightning,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(
                widget.isLightning ? LucideIcons.zap : LucideIcons.link,
                color: widget.isLightning ? Colors.yellow : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  autofocus: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: 'IBMPlexSansHebrew', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppCopy.withdrawReviewAddressPrompt(
                      context,
                      isLightning: widget.isLightning,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.qrCode, size: 20),
                onPressed: _scanQr,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CyberButton(
          text: AppCopy.withdrawReviewContinue.resolve(context),
          onTap: _nextStep,
        ),
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      key: const ValueKey('security'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppCopy.withdrawReviewSecurityTitle.resolve(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildSecurityItem(
          icon: LucideIcons.key,
          label: AppCopy.withdrawReviewShamirLabel.resolve(context),
          status: _shamirVerified
              ? AppCopy.withdrawReviewVerified.resolve(context)
              : AppCopy.withdrawReviewPending.resolve(context),
          color: _shamirVerified ? AppColors.success : Colors.orange,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppCopy.withdrawReviewEnterTotp.resolve(context),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: _totpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontFamily: 'IBMPlexSansHebrew',
                  letterSpacing: 10,
                  fontSize: 24,
                ),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: "",
              hintText: context.tr.totpEnterCodeHint,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CyberButton(
          text: AppCopy.withdrawReviewConfirm.resolve(context),
          isLoading: _isLoading,
          onTap: _handleSecurity,
        ),
      ],
    );
  }

  Widget _buildSecurityItem(
      {required IconData icon,
      required String label,
      required String status,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
          const Spacer(),
          Text(status,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: color, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      _addressController.text = result;
    }
  }
}
