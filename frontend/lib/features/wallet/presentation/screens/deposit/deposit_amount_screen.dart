import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'deposit_method_screen.dart';

class DepositAmountScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const DepositAmountScreen({super.key, required this.wallet});

  @override
  ConsumerState<DepositAmountScreen> createState() =>
      _DepositAmountScreenState();
}

class _DepositAmountScreenState extends ConsumerState<DepositAmountScreen> {
  String _amountRaw = '0';

  double get _parsedAmount {
    if (_amountRaw.isEmpty) return 0.0;
    final n = int.tryParse(_amountRaw) ?? 0;
    return n / 100.0;
  }

  String get _displayAmount {
    if (_amountRaw.isEmpty || _amountRaw == '0') return '0,00';
    final n = int.tryParse(_amountRaw) ?? 0;
    final value = n / 100.0;

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
      } else {
        if (_amountRaw.length < 10) {
          _amountRaw = _amountRaw == '0' ? key : '$_amountRaw$key';
        }
      }
    });
  }

  void _onContinue() {
    if (_parsedAmount <= 0) {
      SnackbarHelper.showError("Por favor, insira um valor maior que zero.");
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositMethodScreen(
          wallet: widget.wallet,
          amountFiat: _parsedAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CyberBackground(
        useScroll: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildEnterAmountLabel().animate().fade(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAmountDisplay()
                      .animate()
                      .fade()
                      .scale(begin: const Offset(0.9, 0.9)),
                  const Spacer(flex: 3),
                  _buildKeypad()
                      .animate(delay: 100.ms)
                      .fade()
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: CyberButton(
                      text: 'CONTINUAR',
                      onTap: _onContinue,
                    ),
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft,
                color: Theme.of(context).colorScheme.onPrimary, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.05),
              padding: const EdgeInsets.all(AppSpacing.sm),
            ),
          ),
          Text(
            'ADICIONAR SALDO',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(letterSpacing: 2),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildEnterAmountLabel() {
    return Text(
      'VALOR DO DEPÓSITO',
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 10,
          ),
    );
  }

  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'R\$ ',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              _displayAmount,
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 64, fontFamily: 'JetBrainsMono', letterSpacing: -2),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    if (key.isEmpty) return const Expanded(child: SizedBox());

    final isBackspace = key == '←';

    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyTap(key),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
          child: Center(
            child: isBackspace
                ? Icon(LucideIcons.delete,
                    color: Theme.of(context).colorScheme.onPrimary, size: 20)
                : Text(
                    key,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontFamily: 'JetBrainsMono'),
                  ),
          ),
        ),
      ),
    );
  }
}
