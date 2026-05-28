import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/providers/currency_provider.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/utils/money_display.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/receive_flow_ui.dart';
import 'package:teste/core/l10n/l10n_extension.dart';
import 'deposit_method_screen.dart';

class DepositAmountScreen extends ConsumerStatefulWidget {
  final Wallet wallet;

  const DepositAmountScreen({super.key, required this.wallet});

  @override
  ConsumerState<DepositAmountScreen> createState() =>
      _DepositAmountScreenState();
}

class _DepositAmountScreenState extends ConsumerState<DepositAmountScreen> {
  String _amount = '0';
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencyProvider);
  }

  double get _parsedAmount {
    return MoneyDisplay.parseEditableInput(_amount);
  }

  String get _displayAmount {
    return MoneyDisplay.formatEditableInput(
      rawValue: _amount,
      currency: _selectedCurrency,
    );
  }

  String? _quoteHint({
    required double? btcUsd,
    required double? btcEur,
    required double? btcBrl,
  }) {
    if (_parsedAmount <= 0) {
      if (_selectedCurrency == Currency.btc) {
        return null;
      }
      return MoneyDisplay.formatQuote(
        currency: _selectedCurrency,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      );
    }

    if (_selectedCurrency == Currency.btc) {
      final brlValue = MoneyDisplay.convertFromBtcAmount(
        btcAmount: _parsedAmount,
        currency: Currency.brl,
        btcUsd: btcUsd,
        btcEur: btcEur,
        btcBrl: btcBrl,
      );
      return context.tr.depositFlowEquivalentTo(
        MoneyDisplay.formatCompact(amount: brlValue, currency: Currency.brl),
      );
    }

    final btcAmount = MoneyDisplay.convertToBtcAmount(
      amount: _parsedAmount,
      currency: _selectedCurrency,
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );
    return context.tr.depositFlowYouReceive(
      MoneyDisplay.formatCompact(amount: btcAmount, currency: Currency.btc),
    );
  }

  int get _maxRawLength {
    return _selectedCurrency == Currency.btc ? 16 : 12;
  }

  String get _currencyDescription {
    switch (_selectedCurrency) {
      case Currency.btc:
        return AppCopy.depositCurrencyDescription(
          context,
          isBtc: true,
          code: _selectedCurrency.code,
        );
      case Currency.usd:
      case Currency.eur:
      case Currency.brl:
        return AppCopy.depositCurrencyDescription(
          context,
          isBtc: false,
          code: _selectedCurrency.code,
        );
    }
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      _amount = MoneyDisplay.applyKeypadInput(
        currentValue: _amount,
        key: key,
        currency: _selectedCurrency,
        maxLength: _maxRawLength,
      );
    });
  }

  void _onContinue() {
    if (_parsedAmount <= 0) {
      SnackbarHelper.showError(AppCopy.depositAmountZero.resolve(context));
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositMethodScreen(
          wallet: widget.wallet,
          inputAmount: _parsedAmount,
          inputCurrency: _selectedCurrency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btcUsd = ref.watch(latestBtcPriceProvider);
    final btcEur = ref.watch(btcEurPriceProvider);
    final btcBrl = ref.watch(btcBrlPriceProvider);
    final quoteHint = _quoteHint(
      btcUsd: btcUsd,
      btcEur: btcEur,
      btcBrl: btcBrl,
    );

    return ReceiveFlowScaffold(
      title: context.tr.depositFlowDepositTitle,
      subtitle: context.tr.depositFlowAmountSubtitle,
      scrollable: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReceiveFlowPanel(
            backgroundColor: receiveFlowPanelAltColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReceiveFlowSectionLabel(
                  context.tr.depositFlowSelectedCurrency,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCurrency.code,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: receiveFlowTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currencyDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: receiveFlowMutedTextColor,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAmountDisplay(quoteHint),
          const SizedBox(height: AppSpacing.md),
          _buildKeypad(),
          const SizedBox(height: AppSpacing.md),
          ReceiveFlowPrimaryButton(
            label: context.tr.depositFlowContinue,
            onTap: _onContinue,
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAmountDisplay(String? quoteHint) {
    return ReceiveFlowPanel(
      child: Column(
        children: [
          Text(
            context.tr.depositFlowAmountLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: receiveFlowMutedTextColor),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _displayAmount,
              style: AppTypography.amountInput(
                isBtc: _selectedCurrency == Currency.btc,
                color: receiveFlowTextColor,
              ).copyWith(
                fontSize: _selectedCurrency == Currency.btc ? 42 : 46,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          if (quoteHint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              quoteHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: receiveFlowMutedTextColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '←'],
    ];

    return ReceiveFlowPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: keys
            .map(
              (row) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: row.map((key) => _buildKey(key)).toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) return const Expanded(child: SizedBox());

    final isBackspace = key == '←';

    return ReceiveFlowKeypadButton(
      onTap: () => _onKeyTap(key),
      child: isBackspace
          ? const Icon(
              LucideIcons.delete,
              color: receiveFlowTextColor,
              size: 18,
            )
          : Text(
              key,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: receiveFlowTextColor,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w400,
                  ),
            ),
    );
  }
}
