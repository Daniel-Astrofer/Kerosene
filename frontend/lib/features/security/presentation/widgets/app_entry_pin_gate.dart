import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_screen_background.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'pin_entry_scaffold.dart';

class AppEntryPinGate extends ConsumerWidget {
  final Widget child;

  const AppEntryPinGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(appEntryPinUnlockedProvider);
    final statusAsync = ref.watch(appPinStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (unlocked) {
          return child;
        }
        if (status.requiresSetup) {
          return _AppEntryPinSetupScreen(status: status);
        }
        if (!status.requiresVerification) {
          return child;
        }
        return _AppEntryPinLockScreen(status: status);
      },
      loading: () => const _PinGateLoadingState(),
      error: (_, __) => const _PinGateLoadingState(),
    );
  }
}

class _PinGateLoadingState extends StatelessWidget {
  const _PinGateLoadingState();

  @override
  Widget build(BuildContext context) {
    return const KeroseneScreenBackground(
      useScroll: false,
      child: Center(
        child: TorLoadingDots(),
      ),
    );
  }
}

class _AppEntryPinSetupScreen extends ConsumerStatefulWidget {
  final AppPinStatus status;

  const _AppEntryPinSetupScreen({required this.status});

  @override
  ConsumerState<_AppEntryPinSetupScreen> createState() =>
      _AppEntryPinSetupScreenState();
}

class _AppEntryPinSetupScreenState
    extends ConsumerState<_AppEntryPinSetupScreen> {
  bool _busy = false;
  bool _confirming = false;
  String _pin = '';
  String _confirmation = '';
  String? _error;

  int get _pinLength => widget.status.minPinLength.clamp(4, 8);

  String get _currentInput => _confirming ? _confirmation : _pin;

  set _currentInput(String value) {
    if (_confirming) {
      _confirmation = value;
    } else {
      _pin = value;
    }
  }

  void _appendDigit(String digit) {
    if (_busy || _currentInput.length >= _pinLength) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _currentInput = _currentInput + digit;
      _error = null;
    });
    if (_currentInput.length == _pinLength) {
      unawaited(_submit());
    }
  }

  void _deleteDigit() {
    if (_busy || _currentInput.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    final input = _currentInput;
    if (input.length != _pinLength) {
      setState(() {
        _error = context.tr.appEntryPinLengthError(
          _pinLength,
          _pinLength,
        );
      });
      return;
    }

    if (!_confirming) {
      setState(() {
        _confirming = true;
        _confirmation = '';
        _error = null;
      });
      return;
    }

    if (_pin != _confirmation) {
      setState(() {
        _error = context.tr.securityPinMismatchError;
        _pin = '';
        _confirmation = '';
        _confirming = false;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref.read(securityRepositoryProvider).configureAppPin(
          enabled: true,
          pin: _pin,
        );

    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _error = ErrorTranslator.translate(context.tr, failure.message);
        });
      },
      (_) {
        ref.read(appEntryPinUnlockedProvider.notifier).unlock();
        ref.invalidate(appPinStatusProvider);
      },
    );

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      instruction: _confirming
          ? _appEntryPinConfirmInstruction(context)
          : _appEntryPinCreateInstruction(context),
      valueLength: _currentInput.length,
      maxLength: _pinLength,
      error: _error,
      busy: _busy,
      onDigit: _appendDigit,
      onDelete: _deleteDigit,
      onConfirm: _busy ? null : _submit,
    );
  }
}

class _AppEntryPinLockScreen extends ConsumerStatefulWidget {
  final AppPinStatus status;

  const _AppEntryPinLockScreen({required this.status});

  @override
  ConsumerState<_AppEntryPinLockScreen> createState() =>
      _AppEntryPinLockScreenState();
}

class _AppEntryPinLockScreenState
    extends ConsumerState<_AppEntryPinLockScreen> {
  Timer? _ticker;
  final ValueNotifier<String> _pinNotifier = ValueNotifier('');
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);
  String get _pin => _pinNotifier.value;
  set _pin(String val) => _pinNotifier.value = val;
  String? get _errorMessage => _errorNotifier.value;
  set _errorMessage(String? val) => _errorNotifier.value = val;
  bool _busy = false;

  AppPinStatus get _status => ref.watch(appPinStatusProvider).maybeWhen(
        data: (status) => status,
        orElse: () => widget.status,
      );

  int get _pinTargetLength => _status.minPinLength.clamp(4, 8);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _status.locked) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pinNotifier.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_busy || _pin.length >= _pinTargetLength) {
      return;
    }
    HapticFeedback.selectionClick();
    _pin += digit;
    _errorMessage = null;
    if (_pin.length == _pinTargetLength) {
      unawaited(_submit());
    }
  }

  void _deleteDigit() {
    if (_busy || _pin.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    _pin = _pin.substring(0, _pin.length - 1);
    _errorMessage = null;
  }

  Future<void> _submit() async {
    if (_busy || _status.locked) {
      return;
    }
    if (_pin.length != _pinTargetLength) {
      _errorMessage = context.tr.appEntryPinLengthError(
        _pinTargetLength,
        _pinTargetLength,
      );
      return;
    }

    setState(() => _busy = true);
    final result =
        await ref.read(securityRepositoryProvider).verifyAppPin(pin: _pin);

    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        setState(() {
          _pin = '';
          _errorMessage =
              ErrorTranslator.translate(context.tr, failure.message);
        });
        ref.invalidate(appPinStatusProvider);
      },
      (_) {
        ref.read(appEntryPinUnlockedProvider.notifier).unlock();
        ref.invalidate(appPinStatusProvider);
      },
    );

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _status.remainingLockDuration;
    final instruction = _status.locked
        ? context.tr.appEntryRetryIn(_formatDuration(remaining))
        : _appEntryPinUnlockInstruction(context);

    return ListenableBuilder(
      listenable: Listenable.merge([_pinNotifier, _errorNotifier]),
      builder: (context, _) {
        return PinEntryScaffold(
          instruction: instruction,
          valueLength: _pin.length,
          maxLength: _pinTargetLength,
          error: _errorMessage,
          busy: _busy,
          enabled: !_status.locked,
          onDigit: _appendDigit,
          onDelete: _deleteDigit,
          onConfirm: _busy || _status.locked ? null : _submit,
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

String _appEntryPinCreateInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Create a PIN to access your account',
    'es' => 'Crea un PIN para acceder a tu cuenta',
    _ => 'Crie um PIN para acessar a conta',
  };
}

String _appEntryPinConfirmInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Confirm the PIN',
    'es' => 'Confirma el PIN',
    _ => 'Confirme o PIN',
  };
}

String _appEntryPinUnlockInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter your PIN to access your account',
    'es' => 'Ingresa el PIN para acceder a tu cuenta',
    _ => 'Digite o PIN para acessar sua conta',
  };
}

class _TotpResetSheet extends ConsumerStatefulWidget {
  const _TotpResetSheet();

  @override
  ConsumerState<_TotpResetSheet> createState() => _TotpResetSheetState();
}

class _TotpResetSheetState extends ConsumerState<_TotpResetSheet> {
  final _totpController = TextEditingController();
  final _newPinController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _totpController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(securityRepositoryProvider).configureAppPin(
          enabled: true,
          pin: _newPinController.text.trim(),
          totpCode: _totpController.text.trim(),
        );
    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _error = ErrorTranslator.translate(context.tr, failure.message);
        });
      },
      (_) {
        ref.invalidate(appPinStatusProvider);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: monochromePanelDecoration(
          color: monoSurfaceColor,
          borderColor: monoBorderStrongColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 1,
              width: 48,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              color: monoBorderStrongColor,
            ),
            Text(
              context.tr.appEntryResetTitle.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: monoMutedTextColor,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr.appEntryResetMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _totpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(color: monoTextColor),
              decoration: monochromeInputDecoration(
                label: context.tr.appEntryTotpLabel,
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              style: const TextStyle(color: monoTextColor),
              decoration: monochromeInputDecoration(
                label: context.tr.appEntryNewPinLabel,
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: monoMutedTextColor,
                      letterSpacing: 0.8,
                      height: 1.35,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: monochromeFilledButtonStyle(),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      child: TorLoadingDots(
                        dotSize: 6,
                        spacing: 8,
                        travel: 10,
                        color: Colors.black,
                      ),
                    )
                  : Text(context.tr.appEntrySavePin),
            ),
          ],
        ),
      ),
    );
  }
}
