import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../security/app_pin_service.dart';

enum _PinMode { setup, confirm, enter }

/// A full-screen PIN dialog.
///
/// - [isSetup]: true → shows setup flow (enter + confirm), false → shows entry flow.
/// - Returns `true` if authentication/setup succeeded, `false` if cancelled.
class PinDialog extends StatefulWidget {
  final bool isSetup;

  const PinDialog({super.key, required this.isSetup});

  static Future<bool> show(
    BuildContext context, {
    required bool isSetup,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => PinDialog(isSetup: isSetup),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  late _PinMode _mode;
  final _pinService = AppPinService();

  String _entered = '';
  String _firstPin = '';
  String? _error;

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _mode = widget.isSetup ? _PinMode.setup : _PinMode.enter;
  }

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });

    if (_entered.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), _handleComplete);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _error = null;
    });
  }

  Future<void> _handleComplete() async {
    switch (_mode) {
      case _PinMode.setup:
        setState(() {
          _firstPin = _entered;
          _entered = '';
          _mode = _PinMode.confirm;
        });
        break;

      case _PinMode.confirm:
        if (_entered == _firstPin) {
          await _pinService.setPin(_entered);
          if (mounted) Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = 'PINs do not match. Try again.';
            _entered = '';
            _mode = _PinMode.setup;
            _firstPin = '';
          });
        }
        break;

      case _PinMode.enter:
        final ok = await _pinService.verifyPin(_entered);
        if (ok) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _error = 'Incorrect PIN. Try again.';
            _entered = '';
          });
        }
        break;
    }
  }

  String get _title {
    switch (_mode) {
      case _PinMode.setup:
        return 'Create your PIN';
      case _PinMode.confirm:
        return 'Confirm your PIN';
      case _PinMode.enter:
        return 'Enter your PIN';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _PinMode.setup:
        return 'Choose a 6-digit PIN to secure the app';
      case _PinMode.confirm:
        return 'Enter the same PIN to confirm';
      case _PinMode.enter:
        return 'Enter your 6-digit PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: double.infinity,
          color: Colors.black,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSetup
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    color: const Color(0xFFF7931A),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 36),

                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _entered.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFFF7931A)
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    );
                  }),
                ),

                // Error message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _error != null
                      ? Padding(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox(height: 32),
                ),

                const SizedBox(height: 28),

                // Keypad
                _buildKeypad(),

                const SizedBox(height: 20),

                // Cancel
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
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

  Widget _buildKeypad() {
    final digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: digits.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((label) {
            if (label.isEmpty) return const SizedBox(width: 80, height: 64);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (label == '⌫') {
                    _onDelete();
                  } else {
                    _onDigit(label);
                  }
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: label == '⌫'
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white,
                      fontSize: label == '⌫' ? 24 : 32,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
