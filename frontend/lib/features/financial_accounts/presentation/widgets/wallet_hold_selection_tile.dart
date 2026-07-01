import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/theme/app_animations.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/financial_accounts/domain/entities/wallet.dart';

const Duration kWalletHoldSelectionDuration = Duration(seconds: 2);

String walletSelectionBalanceLabel(Wallet wallet) {
  final amount = MoneyDisplay.format(
    amount: wallet.balance,
    currency: Currency.btc,
    withSymbol: false,
    decimalPlaces: 8,
  );
  return '$amount BTC';
}

class WalletHoldSelectionTile extends StatefulWidget {
  final Wallet wallet;
  final bool selected;
  final bool compact;
  final ValueChanged<Wallet> onSelect;
  final ValueChanged<Wallet> onConfirmed;

  const WalletHoldSelectionTile({
    super.key,
    required this.wallet,
    required this.selected,
    required this.compact,
    required this.onSelect,
    required this.onConfirmed,
  });

  @override
  State<WalletHoldSelectionTile> createState() =>
      _WalletHoldSelectionTileState();
}

class _WalletHoldSelectionTileState extends State<WalletHoldSelectionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  Timer? _holdTimer;
  bool _holding = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: kWalletHoldSelectionDuration,
    );
  }

  @override
  void didUpdateWidget(covariant WalletHoldSelectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selected && oldWidget.selected) {
      _resetHold();
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _completeHold() {
    if (!mounted || !_holding || _completed) return;
    _completed = true;
    _holding = false;
    _holdController.value = 1;
    HapticFeedback.mediumImpact();
    widget.onConfirmed(widget.wallet);
  }

  void _startHold() {
    widget.onSelect(widget.wallet);
    _holdTimer?.cancel();
    _completed = false;
    _holding = true;
    _holdController.forward(from: 0);
    _holdTimer = Timer(kWalletHoldSelectionDuration, _completeHold);
  }

  void _cancelHold() {
    if (_completed) return;
    _holding = false;
    _holdTimer?.cancel();
    _holdController.animateBack(
      0,
      duration: KeroseneMotion.fast,
      curve: KeroseneMotion.exit,
    );
  }

  void _resetHold() {
    _holding = false;
    _completed = false;
    _holdTimer?.cancel();
    _holdController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final foreground = selected ? AppColors.hexFF000000 : AppColors.hexFFFFFFFF;
    final muted = selected
        ? AppColors.hexFF000000.withValues(alpha: 0.58)
        : AppColors.hexFFA1A1A1;
    final surface = selected ? AppColors.hexFFFFFFFF : AppColors.hexFF151515;
    final border = selected ? AppColors.hexFFFFFFFF : AppColors.hexFF2A2A2A;
    final compact = widget.compact;
    final nameSize = compact ? 20.0 : 23.0;
    final verticalPadding = compact ? 18.0 : 24.0;
    final iconOuterSize = compact ? 68.0 : 76.0;
    final iconInnerSize = compact ? 52.0 : 58.0;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.wallet.name,
      hint: 'Toque para selecionar. Segure para confirmar.',
      onTap: () => widget.onSelect(widget.wallet),
      onLongPress: () {
        widget.onSelect(widget.wallet);
        widget.onConfirmed(widget.wallet);
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _startHold(),
        onPointerUp: (_) => _cancelHold(),
        onPointerCancel: (_) => _cancelHold(),
        child: AnimatedScale(
          scale: selected ? 1 : 0.965,
          duration: AppAnimations.standard,
          curve: AppAnimations.emphasizedCurve,
          child: AnimatedContainer(
            duration: AppAnimations.emphasized,
            curve: AppAnimations.emphasizedCurve,
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 20,
              verticalPadding,
              compact ? 16 : 20,
              verticalPadding,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: selected ? 1.2 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.14),
                        blurRadius: 30,
                        spreadRadius: -14,
                        offset: const Offset(0, 18),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: iconOuterSize,
                  child: AnimatedBuilder(
                    animation: _holdController,
                    builder: (context, child) {
                      final showProgress =
                          selected && (_holding || _holdController.value > 0);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (selected)
                            SizedBox.square(
                              dimension: iconOuterSize,
                              child: CircularProgressIndicator(
                                value: showProgress
                                    ? _holdController.value.clamp(0.0, 1.0)
                                    : 0,
                                strokeWidth: 2.4,
                                strokeCap: StrokeCap.round,
                                color: foreground,
                                backgroundColor:
                                    foreground.withValues(alpha: 0.13),
                              ),
                            ),
                          child!,
                        ],
                      );
                    },
                    child: AnimatedContainer(
                      duration: AppAnimations.emphasized,
                      curve: AppAnimations.standardCurve,
                      width: iconInnerSize,
                      height: iconInnerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.hexFF000000.withValues(alpha: 0.08)
                            : AppColors.hexFF242424,
                        border: Border.all(
                          color: selected
                              ? AppColors.hexFF000000.withValues(alpha: 0.12)
                              : AppColors.hexFF333333,
                        ),
                      ),
                      child: Icon(
                        _walletIcon(widget.wallet),
                        color: foreground,
                        size: compact ? 23 : 26,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _displayName(widget.wallet.name),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.inter(
                      color: foreground,
                      fontSize: nameSize,
                      fontWeight: FontWeight.w700,
                      height: 1.06,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    walletSelectionBalanceLabel(widget.wallet),
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.inter(
                      color: muted,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _walletIcon(Wallet wallet) {
    if (wallet.isColdWallet || wallet.isCustodialOnchain) {
      return KeroseneIcons.coldWallet;
    }
    return KeroseneIcons.wallet;
  }

  static String _displayName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Wallet' : trimmed;
  }
}
