import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';

class DepositOnchainInvoiceScreen extends ConsumerWidget {
  final Wallet wallet;
  final double amountFiat;
  final String providerName;

  const DepositOnchainInvoiceScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
    required this.providerName,
  });

  void _copyAddress(String address) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: address));
    SnackbarHelper.showSuccess('Endereço copiado!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(btcPriceProvider);
    final networkFeeFiat = 15.00;
    final providerFeeFiat = amountFiat * 0.0099;
    final totalFiat = amountFiat + networkFeeFiat + providerFeeFiat;
    const btcAddress = 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: btcPriceAsync.when(
                data: (price) {
                  final receiveBtc = amountFiat / price;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildMainCard(totalFiat).animate().fade().scale(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildQrCodeSection(btcAddress).animate(delay: 100.ms).fade().scale(curve: Curves.easeOutBack),
                        const SizedBox(height: AppSpacing.lg),
                        _buildAddressPill(btcAddress).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '~30-60 min (3 confirmações)',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3), fontWeight: FontWeight.bold),
                        ).animate(delay: 300.ms).fade(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildDetailsBlock(price, networkFeeFiat, providerFeeFiat, receiveBtc).animate(delay: 400.ms).fade().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSecurityFooter().animate(delay: 500.ms).fade().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  );
                },
                loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                error: (e, _) => Center(child: Text('Erro: $e', style: TextStyle(color: Theme.of(context).colorScheme.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'ENDEREÇO ON-CHAIN',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildMainCard(double totalFiat) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'VALOR DO DEPÓSITO',
            style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'R\$ ${totalFiat.toStringAsFixed(2).replaceAll('.', ',')}',
            style: AppTypography.h1.copyWith(fontSize: 32, fontFamily: 'JetBrainsMono'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              'VIA ${providerName.toUpperCase()}',
              style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String address) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            'ENDEREÇO BTC',
            style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.lg)),
            child: QrImageView(
              data: 'bitcoin:$address',
              version: QrVersions.auto,
              size: 180,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPill(String address) {
    return GlassContainer(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs, top: AppSpacing.xs, bottom: AppSpacing.xs),
      borderRadius: BorderRadius.circular(100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              address,
              style: AppTypography.caption.copyWith(fontFamily: 'JetBrainsMono', fontSize: 10, color: Colors.white60),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _copyAddress(address),
            icon: Icon(LucideIcons.copy, color: Colors.white, size: 14),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBlock(double btcPrice, double networkFee, double providerFee, double receiveBtc) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Column(
        children: [
          _buildDetailRow('Cotação BTC', 'R\$ ${btcPrice.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow('Taxa de Rede', 'R\$ ${networkFee.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow('Taxa de Serviço', 'R\$ ${providerFee.toStringAsFixed(2).replaceAll('.', ',')} (0.99%)'),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: Colors.white, height: 1, thickness: 0.05),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a Receber', style: AppTypography.bodySmall.copyWith(color: Colors.white60)),
              Text(
                '${receiveBtc.toStringAsFixed(8)} BTC',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.5))),
        Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
      ],
    );
  }

  Widget _buildSecurityFooter() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      border: Border.all(color: AppColors.success.withOpacity(0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSAÇÃO PROTEGIDA',
                  style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este endereço foi gerado exclusivamente para você e é monitorado 24/7. Os fundos serão creditados automaticamente após confirmações.',
                  style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.5), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
