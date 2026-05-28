import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/tor_loading_dots.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/theme/monochrome_theme.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/security/domain/entities/app_pin_status.dart';
import 'package:teste/features/security/presentation/providers/security_provider.dart';
import 'package:teste/core/l10n/l10n_extension.dart';

class AppEntryPinGate extends ConsumerWidget {
  final Widget child;

  const AppEntryPinGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(appEntryPinUnlockedProvider);
    final statusAsync = ref.watch(appPinStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (!status.enabled || unlocked) {
          return child;
        }
        return _AppEntryPinLockScreen(status: status);
      },
      loading: () => const _PinGateLoadingState(),
      error: (_, __) => _PinGateErrorState(
        onRetry: () => ref.invalidate(appPinStatusProvider),
      ),
    );
  }
}

class _PinGateLoadingState extends StatelessWidget {
  const _PinGateLoadingState();

  @override
  Widget build(BuildContext context) {
    return const CyberBackground.authenticated(
      useScroll: false,
      child: Center(
        child: TorLoadingDots(),
      ),
    );
  }
}

class _PinGateErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _PinGateErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CyberBackground.authenticated(
      useScroll: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                    width: 44,
                    height: 44,
                    decoration: monochromePanelDecoration(
                      color: monoSurfaceAltColor,
                      borderColor: monoBorderStrongColor,
                      showShadow: false,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.lock,
                      color: monoTextColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr.appEntryPinUnavailableTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: monoTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr.appEntryPinUnavailableMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: monoMutedTextColor,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: onRetry,
                    style: monochromeFilledButtonStyle(),
                    child: Text(context.tr.appEntryRefresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
  String _pin = '';
  bool _busy = false;
  String? _errorMessage;

  AppPinStatus get _status => ref.watch(appPinStatusProvider).maybeWhen(
        data: (status) => status,
        orElse: () => widget.status,
      );

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
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_busy || _pin.length >= _status.maxPinLength) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
  }

  void _deleteDigit() {
    if (_busy || _pin.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || _status.locked) {
      return;
    }
    if (_pin.length < _status.minPinLength ||
        _pin.length > _status.maxPinLength) {
      setState(() {
        _errorMessage = context.tr.appEntryPinLengthError(
          _status.minPinLength,
          _status.maxPinLength,
        );
      });
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

  Future<void> _resetWithTotp() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TotpResetSheet(),
    );

    if (result == true && mounted) {
      ref.read(appEntryPinUnlockedProvider.notifier).unlock();
      ref.invalidate(appPinStatusProvider);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _status.remainingLockDuration;
    final subtitle = _status.locked
        ? context.tr.appEntryRetryIn(_formatDuration(remaining))
        : context.tr.appEntryUnlockPrompt;
    final helper = _status.locked
        ? context.tr.appEntryLockedHelper
        : _status.resettableWithTotp
            ? context.tr.appEntryAttemptsHelper(
                _status.remainingAttempts,
              )
            : context.tr.appEntryLocalPinHelper;

    return CyberBackground.authenticated(
      useScroll: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: monochromePanelDecoration(
                          color: monoSurfaceAltColor,
                          borderColor: monoBorderStrongColor,
                          showShadow: false,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          LucideIcons.lock,
                          color: monoTextColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.appEntryEyebrow.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: monoMutedTextColor,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: monoTextColor,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              helper,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: monoMutedTextColor,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: monochromePanelDecoration(
                      color: monoSurfaceColor,
                      borderColor: monoBorderStrongColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PinDots(
                          length: _pin.length,
                          maxLength: _status.maxPinLength,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 36,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _errorMessage == null
                                ? const SizedBox.shrink()
                                : Text(
                                    _errorMessage!.toUpperCase(),
                                    key: ValueKey(_errorMessage),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: monoMutedTextColor,
                                          letterSpacing: 0.8,
                                          height: 1.35,
                                        ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: monochromePanelDecoration(
                      color: monoSurfaceColor,
                      borderColor: monoBorderColor,
                    ),
                    child: _NumericPad(
                      enabled: !_busy && !_status.locked,
                      onDigit: _appendDigit,
                      onDelete: _deleteDigit,
                      onClear: () => setState(() {
                        _pin = '';
                        _errorMessage = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _busy || _status.locked ? null : _submit,
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
                        : Text(context.tr.appEntryConfirm),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_status.resettableWithTotp)
                        TextButton(
                          onPressed: _busy ? null : _resetWithTotp,
                          style: monochromeTextButtonStyle(),
                          child: Text(context.tr.appEntryReset),
                        ),
                      if (_status.resettableWithTotp)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '•',
                            style: AppTypography.caption.copyWith(
                              color: monoFaintTextColor,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: _busy ? null : _logout,
                        style: monochromeTextButtonStyle(),
                        child: Text(context.tr.appEntryExit),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
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

class _PinDots extends StatelessWidget {
  final int length;
  final int maxLength;

  const _PinDots({
    required this.length,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final total = maxLength.clamp(4, 8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final filled = index < length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: filled ? monoTextColor : monoSurfaceAltColor,
            border: Border.all(
              color: filled ? monoTextColor : monoBorderStrongColor,
            ),
          ),
        );
      }),
    );
  }
}

class _NumericPad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const _NumericPad({
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '←'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: row.map((key) {
              final isSpecial = key == '←' || key == 'C';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: !enabled
                          ? null
                          : () {
                              if (key == '←') {
                                onDelete();
                                return;
                              }
                              if (key == 'C') {
                                onClear();
                                return;
                              }
                              onDigit(key);
                            },
                      child: Ink(
                        height: 62,
                        decoration: monochromePanelDecoration(
                          color:
                              enabled ? monoSurfaceAltColor : monoSurfaceColor,
                          borderColor:
                              enabled ? monoBorderStrongColor : monoBorderColor,
                          showShadow: false,
                        ),
                        child: Center(
                          child: isSpecial
                              ? Icon(
                                  key == '←'
                                      ? LucideIcons.delete
                                      : LucideIcons.rotateCcw,
                                  size: 18,
                                  color: enabled
                                      ? monoMutedTextColor
                                      : monoFaintTextColor,
                                )
                              : Text(
                                  key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontFamily: 'IBMPlexSansHebrew',
                                        color: enabled
                                            ? monoTextColor
                                            : monoFaintTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 24,
                                      ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
