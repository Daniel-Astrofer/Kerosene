import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';

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
  ConsumerState<DepositLightningInvoiceScreen> createState() => _DepositLightningInvoiceScreenState();
}

class _DepositLightningInvoiceScreenState extends ConsumerState<DepositLightningInvoiceScreen> {
  Timer? _timer;
  int _secondsRemaining = 15 * 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
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

  void _copyInvoice() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(const ClipboardData(text: 'lnbc10u1p3x0d...'));
    SnackbarHelper.showSuccess('Fatura copiada!');
  }

  @override
  Widget build(BuildContext context) {
    final btcPriceAsync = ref.watch(btcPriceProvider);
    final networkFeeFiat = 1.50;
    final providerFeeFiat = widget.amountFiat * 0.0099;
    final totalFiat = widget.amountFiat + networkFeeFiat + providerFeeFiat;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: btcPriceAsync.when(
                data: (price) {
                  final receiveBtc = widget.amountFiat / price;
                  final sats = (receiveBtc * 100000000).toInt();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildMainCard(totalFiat).animate().fade().scale(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildTimerWidget().animate(delay: 100.ms).fade(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildDetailsBlock(networkFeeFiat, providerFeeFiat, receiveBtc, sats).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xl),
                        _buildInvoiceField().animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xxl),
                        CyberButton(
                          text: 'COPIAR FATURA',
                          onTap: _copyInvoice,
                        ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Mantenha esta tela aberta até confirmar o pagamento.',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
                        ).animate(delay: 500.ms).fade(),
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
            'FATURA LIGHTNING',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(letterSpacing: 2, color: Theme.of(context).colorScheme.secondary),
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
      border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), width: 1.5),
      child: Column(
        children: [
          Text(
            'TOTAL A PAGAR',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'R\$ ${totalFiat.toStringAsFixed(2).replaceAll('.', ',')}',
            style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 40, fontFamily: 'JetBrainsMono'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VIA ${widget.providerName.toUpperCase()}',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
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
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3), fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimerBlock(_formattedMinutes),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(':', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2))),
            ),
            _buildTimerBlock(_formattedSeconds),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerBlock(String value) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailsBlock(double networkFee, double providerFee, double receiveBtc, int sats) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Column(
        children: [
          _buildDetailRow('Taxa de Rede (Lightning)', 'R\$ ${networkFee.toStringAsFixed(2).replaceAll('.', ',')}'),
          const SizedBox(height: AppSpacing.sm),
          _buildDetailRow('Taxa do Provedor', 'R\$ ${providerFee.toStringAsFixed(2).replaceAll('.', ',')}'),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: Theme.of(context).colorScheme.onPrimary, height: 1, thickness: 0.05),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOCÊ RECEBERÁ',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${receiveBtc.toStringAsFixed(8)} BTC',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.success, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '$sats SATS',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.success, fontWeight: FontWeight.w900),
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
        Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5))),
        Text(value, style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
      ],
    );
  }

  Widget _buildInvoiceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVOICE HASH',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassContainer(
          padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs, top: AppSpacing.xs, bottom: AppSpacing.xs),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'lightning:lnbc10u1p3x0d...',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(fontFamily: 'JetBrainsMono', color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _copyInvoice,
                icon: Icon(LucideIcons.copy, color: Theme.of(context).colorScheme.onPrimary, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
