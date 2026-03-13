import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../shared/widgets/brushed_metal_container.dart';
import '../../../../../core/presentation/widgets/glass_container.dart';

import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../core/providers/price_provider.dart';
import '../../../domain/entities/wallet.dart';

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
    Clipboard.setData(ClipboardData(text: address));
    SnackbarHelper.showSuccess(
      'Endereço copiado para a área de transferência!',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(btcPriceProvider);

    // Simulate fees
    final networkFeeFiat = 15.00;
    final providerFeeFiat = amountFiat * 0.0099;
    final totalFiat = amountFiat + networkFeeFiat + providerFeeFiat;
    final btcAddress =
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'; // Placeholder

    return Scaffold(
      backgroundColor: Colors.black,
      body: BrushedMetalContainer(
        baseColor: const Color(0xFF0A0A0A),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: btcPriceAsync.when(
                  data: (price) {
                    final fiatPrice = price;
                    final receiveBtc = amountFiat / fiatPrice;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildMainCard(totalFiat),
                        const SizedBox(height: 24),
                        _buildQrCodeSection(btcAddress),
                        const SizedBox(height: 16),
                        _buildAddressPill(btcAddress),
                        const SizedBox(height: 8),
                        Text(
                          'Tempo estimado: ~30-60 min (3 confirmações)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildDetailsBlock(
                          fiatPrice,
                          networkFeeFiat,
                          providerFeeFiat,
                          receiveBtc,
                        ),
                        const SizedBox(height: 32),
                        _buildSecurityFooter(),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A5CFF)),
                  ),
                  error: (e, s) => Center(
                    child: Text(
                      'Erro: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            'Endereço On-chain',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMainCard(double totalFiat) {
    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1.0,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'VALOR DO DEPÓSITO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${totalFiat.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              fontFamily: 'Inter',
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A5CFF).withOpacity(0.15), // Blue pill
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VIA ${providerName.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF1A5CFF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String address) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32), // smooth squircle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ENDEREÇO BTC PARA DEPÓSITO',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: 'bitcoin:$address',
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black87,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPill(String address) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(100), // pill shape
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              address,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'SF Mono',
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _copyAddress(address),
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
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

  Widget _buildDetailsBlock(
    double btcPrice,
    double networkFee,
    double providerFee,
    double receiveBtc,
  ) {
    return Column(
      children: [
        _buildDetailRow(
          'Cotação BTC',
          '1 BTC = R\$ ${btcPrice.toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Taxa de Rede',
          'R\$ ${networkFee.toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Taxa de Serviço',
          'R\$ ${providerFee.toStringAsFixed(2).replaceAll('.', ',')} (0.99%)',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Colors.white10, height: 1),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total a Receber',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${receiveBtc.toStringAsFixed(8)} BTC',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFA3).withOpacity(0.05), // green tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FFA3).withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00FFA3).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00FFA3),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRANSAÇÃO PROTEGIDA',
                  style: TextStyle(
                    color: Color(0xFF00FFA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este endereço foi gerado exclusivamente para você e é monitorado 24/7. Os fundos serão creditados automaticamente após as confirmações da rede.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
