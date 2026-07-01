// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/security/domain/entities/app_pin_status.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';

enum AppPinSheetMode { enable, change, disable }

class AppPinManagementSheet extends ConsumerStatefulWidget {
  final AppPinStatus initialStatus;
  final AppPinSheetMode mode;

  const AppPinManagementSheet({
    required this.initialStatus,
    required this.mode,
  });

  @override
  ConsumerState<AppPinManagementSheet> createState() =>
      AppPinManagementSheetState();
}

class AppPinManagementSheetState extends ConsumerState<AppPinManagementSheet> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _totpController = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _requiresNewPin => widget.mode != AppPinSheetMode.disable;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_requiresNewPin &&
        _newPinController.text.trim() != _confirmPinController.text.trim()) {
      setState(
        () => _error = context.tr.securityPinMismatchError,
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await ref.read(securityRepositoryProvider).configureAppPin(
          enabled: widget.mode != AppPinSheetMode.disable,
          pin: _requiresNewPin ? _newPinController.text.trim() : null,
          currentPin: _currentPinController.text.trim().isNotEmpty
              ? _currentPinController.text.trim()
              : null,
          totpCode: _totpController.text.trim().isNotEmpty
              ? _totpController.text.trim()
              : null,
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
        ref.invalidate(accountSecurityProfileProvider);
        ref.invalidate(appPinStatusProvider);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      AppPinSheetMode.enable => context.tr.securityPinEnableTitle,
      AppPinSheetMode.change => context.tr.securityPinChangeTitle,
      AppPinSheetMode.disable => context.tr.securityPinDisableTitle,
    };

    final body = switch (widget.mode) {
      AppPinSheetMode.enable => context.tr.securityPinEnableBody,
      AppPinSheetMode.change => context.tr.securityPinChangeBody,
      AppPinSheetMode.disable => context.tr.securityPinDisableBody,
    };

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
              width: 52,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              color: monoBorderStrongColor,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: monoTextColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.initialStatus.enabled) ...[
              TextField(
                controller: _currentPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.tr.securityCurrentPinLabel,
                  counterText: '',
                ),
              ),
              if (widget.initialStatus.resettableWithTotp)
                TextField(
                  controller: _totpController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  style: const TextStyle(color: monoTextColor),
                  decoration: monochromeInputDecoration(
                    label: context.tr.securityTotpCodeLabel,
                    counterText: '',
                  ),
                ),
            ],
            if (_requiresNewPin) ...[
              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.tr.securityNewPinLabel(
                    widget.initialStatus.minPinLength,
                    widget.initialStatus.maxPinLength,
                  ),
                  counterText: '',
                ),
              ),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: widget.initialStatus.maxPinLength,
                style: const TextStyle(color: monoTextColor),
                decoration: monochromeInputDecoration(
                  label: context.tr.securityConfirmNewPinLabel,
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: monoMutedTextColor,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: monochromeFilledButtonStyle(
                emphasis: widget.mode != AppPinSheetMode.disable,
                destructive: widget.mode == AppPinSheetMode.disable,
              ),
              child: _busy
                  ? SizedBox(
                      height: 18,
                      child: TorLoadingDots(
                        dotSize: 6,
                        spacing: 8,
                        travel: 10,
                        color: widget.mode == AppPinSheetMode.disable
                            ? monoTextColor
                            : Colors.black,
                      ),
                    )
                  : Text(
                      widget.mode == AppPinSheetMode.disable
                          ? context.tr.securityDisablePinAction.toUpperCase()
                          : context.tr.securitySavePinAction.toUpperCase(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
