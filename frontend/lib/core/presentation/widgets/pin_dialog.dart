import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fingerprint_scanner.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85)),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App Logo - Using centered circular image for premium feel
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: const CyberFingerprintScanner(size: 120),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'HubotSansExpanded',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(),

              // PIN dots with subtle glow
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFF00F0FF)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  );
                }),
              ),

              // Error message
              SizedBox(
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _error != null
                      ? Padding(
                          key: ValueKey(_error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 20),

              // Keypad - Futuristic Grid
              _buildModernKeypad(),

              const SizedBox(height: 40),

              // Cancel Action
              if (!widget.isSetup)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'CANCEL AUTHENTICATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernKeypad() {
    final List<List<String>> keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            final isAction = key == '⌫' || key == 'C';
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (key == '⌫') {
                    _onDelete();
                  } else if (key == 'C') {
                    setState(() {
                      _entered = '';
                      _error = null;
                    });
                  } else {
                    _onDigit(key);
                  }
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    key,
                    style: TextStyle(
                      color: isAction
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.8)
                          : Colors.white,
                      fontSize: key == '⌫' ? 24 : 28,
                      fontWeight: FontWeight.w300,
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
