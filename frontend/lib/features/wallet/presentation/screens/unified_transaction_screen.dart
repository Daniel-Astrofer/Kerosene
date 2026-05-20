import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/l10n/l10n_extension.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:teste/core/services/audio_service.dart';
import 'nfc_interaction_screen.dart';

/// Unified Transaction Screen for Send/Receive flows
class UnifiedTransactionScreen extends StatefulWidget {
  final bool isSend;
  final String? initialAddress;

  const UnifiedTransactionScreen({
    super.key,
    required this.isSend,
    this.initialAddress,
  });

  @override
  State<UnifiedTransactionScreen> createState() =>
      _UnifiedTransactionScreenState();
}

class _UnifiedTransactionScreenState extends State<UnifiedTransactionScreen> {
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authenticatedSurfaceBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: authenticatedSurfaceBackgroundColor),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTypeSelector(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildAmountDisplay(),
                        const SizedBox(height: AppSpacing.xxl),
                        if (widget.isSend) _buildAddressInput(),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildActionGrid(),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
            ),
          ),
          Text(
            widget.isSend
                ? context.tr.sendBitcoin.toUpperCase()
                : context.tr.receiveBitcoin.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            context.tr.onChain.toUpperCase(),
            !widget.isSend,
            LucideIcons.link,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildTypeButton(
            context.tr.lightning.toUpperCase(),
            widget.isSend,
            LucideIcons.zap,
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0.0);
  }

  Widget _buildTypeButton(String label, bool isSelected, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.3),
              size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.3),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          context.tr.transactionAmount.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.3),
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₿',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary, fontSize: 32),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _amountController.text.isEmpty ? '0.00' : _amountController.text,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge!
                  .copyWith(fontSize: 48, fontFamily: 'JetBrainsMono'),
            ),
          ],
        ),
      ],
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildAddressInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _addressController,
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          hintText: context.tr.destinationAddressHint,
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.2)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(LucideIcons.qrCode,
                color: Theme.of(context).colorScheme.primary),
            onPressed: _handleScanQr,
          ),
        ),
      ).animate().fade().slideY(begin: 0.1, end: 0.0),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
            context.tr.scanQR.toUpperCase(), LucideIcons.qrCode, _handleScanQr),
        _buildActionCard(context.tr.approximateNfc.toUpperCase(),
            LucideIcons.wifi, _handleNfc),
        if (!widget.isSend)
          _buildActionCard(
              context.tr.createLink.toUpperCase(), LucideIcons.share2, () {}),
        _buildActionCard(
            context.tr.history.toUpperCase(), LucideIcons.history, () {}),
      ],
    ).animate().fade(delay: 400.ms);
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: CyberButton(
        text: _isProcessing
            ? context.tr.processing.toUpperCase()
            : (widget.isSend
                ? context.tr.confirmSend.toUpperCase()
                : context.tr.generatePaymentRequest.toUpperCase()),
        onTap: _handleProcess,
        isLoading: _isProcessing,
      ),
    ).animate().slideY(begin: 0.2, end: 0.0);
  }

  void _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) {
      _addressController.text = result;
    }
  }

  void _handleNfc() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NfcInteractionScreen(
          amountDisplay: _amountController.text,
          paymentUri: widget.isSend
              ? null
              : 'bitcoin:${_addressController.text}?amount=${_amountController.text}',
        ),
      ),
    );
  }

  void _handleProcess() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        AudioService.instance.playTransaction();
        HapticFeedback.vibrate();
        Navigator.pop(context);
      }
    });
  }
}
