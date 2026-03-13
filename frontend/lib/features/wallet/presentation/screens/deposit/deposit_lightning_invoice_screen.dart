import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/snackbar_helper.dart';
import '../../../../../shared/widgets/brushed_metal_container.dart';
import '../../../../../core/presentation/widgets/glass_container.dart';
import '../../../../../core/providers/price_provider.dart';
import '../../../domain/entities/wallet.dart';

class DepositLightningInvoiceScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  final double amountFiat;
  final String providerName;

  const DepositLightningInvoiceScreen({
    super.key,
    required this.wallet,
    required this.amountFiat,
    required this.providerName,
  });

  @override
  ConsumerState<DepositLightningInvoiceScreen> createState() =>
      _DepositLightningInvoiceScreenState();
}

class _DepositLightningInvoiceScreenState
    extends ConsumerState<DepositLightningInvoiceScreen> {
  Timer? _timer;
  int _secondsRemaining = 15 * 60; // 15 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedMinutes => (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
  String get _formattedSeconds => (_secondsRemaining % 60).toString().padLeft(2, '0');
  String get _formattedCentiseconds => '00'; // Mocking smooth ms locally is expensive, static for now

  void _copyInvoice() {
    Clipboard.setData(
      const ClipboardData(
        text: 'lnbc10u1p3x0d...', // placeholder
      ),
    );
    SnackbarHelper.showSuccess('Fatura copiada para a área de transferência!');
  }

  @override
  Widget build(BuildContext context) {
    // Assuming BRL for mockup
    final btcPriceAsync = ref.watch(btcPriceProvider);

    // Fake fee simulation
    final networkFeeFiat = 1.50; // R$ 1,50
    final providerFeeFiat = widget.amountFiat * 0.0099; // 0.99%
    final totalFiat = widget.amountFiat + networkFeeFiat + providerFeeFiat;

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
                    final fiatPrice = price; // simplistic
                    final receiveBtc = widget.amountFiat / fiatPrice;
                    final sats = (receiveBtc * 100000000).toInt();

                    return Column(
                      children: [
                        _buildMainCard(totalFiat),
                        const SizedBox(height: 24),
                        _buildTimerWidget(),
                        const SizedBox(height: 24),
                        _buildDetailsBlock(
                          networkFeeFiat,
                          providerFeeFiat,
                          receiveBtc,
                          sats,
                        ),
                        const SizedBox(height: 24),
                        _buildInvoiceField(),
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
            _buildFooterButton(),
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
            'INVOICE LIGHTNING',
            style: TextStyle(
              color: Color(0xFF00D4FF), // Lightning color indication
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
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
        color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
        width: 1.5,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'TOTAL A PAGAR',
            style: TextStyle(
              color: Color(0xFF00D4FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${totalFiat.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w200,
              fontFamily: 'Inter',
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'VIA ${widget.providerName.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    return Column(
      children: [
        Text(
          'EXPIRA EM',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimerBlock(_formattedMinutes),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(color: Colors.white54, fontSize: 24)),
            ),
            _buildTimerBlock(_formattedSeconds),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(color: Colors.white54, fontSize: 24)),
            ),
            _buildTimerBlock(_formattedCentiseconds),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerBlock(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w300,
          fontFamily: 'SF Mono',
        ),
      ),
    );
  }

  Widget _buildDetailsBlock(
    double networkFee,
    double providerFee,
    double receiveBtc,
    int sats,
  ) {
    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1.0,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDetailRow(
            'Taxa de Rede (Lightning)',
            'R\$ ${networkFee.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Taxa do Provedor',
            'R\$ ${providerFee.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOCÊ RECEBERÁ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${receiveBtc.toStringAsFixed(8)} BTC',
                      style: const TextStyle(
                        color: Color(0xFF00FFA3), // green
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFA3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SATS: $sats',
                  style: const TextStyle(
                    color: Color(0xFF00FFA3),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVOICE HASH',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'lightning:lnbc10u1p3x0d...', // truncated
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'SF Mono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _copyInvoice,
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF1A5CFF),
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5CFF).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32, top: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _copyInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0033FF), // Branded blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'COPIAR FATURA LIGHTNING',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Não feche esta tela até confirmar o pagamento.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
