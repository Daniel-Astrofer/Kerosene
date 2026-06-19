import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/motion/app_motion.dart';
import 'package:slip39/slip39.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';

import '../../features/security/domain/entities/app_pin_status.dart';
import '../../features/security/domain/entities/account_security_profile.dart';
import '../../features/security/presentation/providers/security_provider.dart';
import '../../features/security/presentation/widgets/pin_entry_scaffold.dart';
import '../security/biometric_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class TransactionAuthResult {
  final bool isAuthenticated;
  final String? confirmationPassphrase;
  final String? totpCode;
  final String? passkeyAssertionJson;

  const TransactionAuthResult._({
    required this.isAuthenticated,
    this.confirmationPassphrase,
    this.totpCode,
    this.passkeyAssertionJson,
  });

  const TransactionAuthResult.cancelled() : this._(isAuthenticated: false);

  const TransactionAuthResult.success({
    String? confirmationPassphrase,
    String? totpCode,
    String? passkeyAssertionJson,
  }) : this._(
          isAuthenticated: true,
          confirmationPassphrase: confirmationPassphrase,
          totpCode: totpCode,
          passkeyAssertionJson: passkeyAssertionJson,
        );
}

class TransactionAuthGate {
  static Future<TransactionAuthResult> show(
    BuildContext context, {
    AccountSecurityProfile? profile,
    @Deprecated('Use profile') AccountSecurityProfile? security,
    bool forceTotp = false,
    bool allowDeviceAuthUnavailable = false,
    VoidCallback? onAuthenticated,
    VoidCallback? onCancelled,
  }) async {
    final resolvedProfile = profile ?? security;
    if (resolvedProfile == null) {
      throw ArgumentError('profile is required.');
    }

    final effectiveProfile = _effectiveProfile(
      resolvedProfile,
      forceTotp: forceTotp,
    );
    final needsManualFactors = _needsManualFactors(effectiveProfile);

    final appPinOutcome = await _showAppPinIfConfigured(
      context,
      effectiveProfile.appPin,
    );
    if (appPinOutcome == _DeviceAuthOutcome.rejected ||
        appPinOutcome == _DeviceAuthOutcome.unavailable ||
        !context.mounted) {
      onCancelled?.call();
      return const TransactionAuthResult.cancelled();
    }

    if (effectiveProfile.requiresPasskey && !needsManualFactors) {
      onAuthenticated?.call();
      return const TransactionAuthResult.success();
    }

    if (!effectiveProfile.requiresPasskey) {
      final deviceAuthOutcome =
          appPinOutcome == _DeviceAuthOutcome.authenticated
              ? _DeviceAuthOutcome.authenticated
              : await _showDevicePinFallback(
                  context,
                  BiometricService(),
                );

      if (deviceAuthOutcome == _DeviceAuthOutcome.rejected ||
          (deviceAuthOutcome == _DeviceAuthOutcome.unavailable &&
              !allowDeviceAuthUnavailable) ||
          !context.mounted) {
        onCancelled?.call();
        return const TransactionAuthResult.cancelled();
      }
    }

    final TransactionAuthResult result;
    if (!needsManualFactors) {
      result = const TransactionAuthResult.success();
    } else if (effectiveProfile.requiresShamirShares) {
      result = await showModalBottomSheet<TransactionAuthResult>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) =>
                _ShamirAuthorizationSheet(profile: effectiveProfile),
          ) ??
          const TransactionAuthResult.cancelled();
    } else {
      result = await showModalBottomSheet<TransactionAuthResult>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) =>
                _FactorAuthorizationSheet(profile: effectiveProfile),
          ) ??
          const TransactionAuthResult.cancelled();
    }

    if (result.isAuthenticated) {
      onAuthenticated?.call();
    } else {
      onCancelled?.call();
    }

    return result;
  }

  static AccountSecurityProfile securityFromString(String? raw) {
    final mode = accountSecurityModeFromApi(raw);
    switch (mode) {
      case AccountSecurityMode.shamir:
        return const AccountSecurityProfile(
          mode: AccountSecurityMode.shamir,
          requiredFactors: ['SLIP39_SHARES'],
        );
      case AccountSecurityMode.multisig2fa:
        return const AccountSecurityProfile(
          mode: AccountSecurityMode.multisig2fa,
          requiredFactors: ['PASSPHRASE', 'TOTP'],
        );
      case AccountSecurityMode.passkey:
        return const AccountSecurityProfile(
          mode: AccountSecurityMode.passkey,
          passkeyAvailable: true,
          passkeyEnabledForTransactions: true,
          requiredFactors: ['PASSKEY'],
        );
      case AccountSecurityMode.standard:
        return const AccountSecurityProfile(
          mode: AccountSecurityMode.standard,
          passkeyAvailable: true,
          passkeyEnabledForTransactions: true,
          requiredFactors: ['PASSKEY'],
        );
    }
  }

  static AccountSecurityProfile _effectiveProfile(
    AccountSecurityProfile profile, {
    required bool forceTotp,
  }) {
    if (!forceTotp || profile.requiresTotp) {
      return profile;
    }

    return profile.copyWith(
      requiredFactors: [...profile.requiredFactors, 'TOTP'],
    );
  }

  static bool _needsManualFactors(AccountSecurityProfile profile) {
    return profile.requiresPassphrase ||
        profile.requiresTotp ||
        profile.requiresShamirShares;
  }

  static Future<_DeviceAuthOutcome> _showDevicePinFallback(
    BuildContext context,
    BiometricService bio,
  ) async {
    try {
      final localizedReason = context.tr.authReasonTransactionConfirm;
      final canUseDeviceAuth = await bio.canAuthenticate();
      if (!context.mounted) {
        return _DeviceAuthOutcome.rejected;
      }
      if (!canUseDeviceAuth) {
        return _DeviceAuthOutcome.unavailable;
      }

      final didAuthenticate = await bio.authenticate(
        localizedReason: localizedReason,
      );
      return didAuthenticate
          ? _DeviceAuthOutcome.authenticated
          : _DeviceAuthOutcome.rejected;
    } catch (_) {
      return _DeviceAuthOutcome.unavailable;
    }
  }

  static Future<_DeviceAuthOutcome?> _showAppPinIfConfigured(
    BuildContext context,
    AppPinStatus status,
  ) async {
    if (!status.configured) {
      return null;
    }
    return _showAppPinAuthorization(context, status);
  }

  static Future<_DeviceAuthOutcome> _showAppPinAuthorization(
    BuildContext context,
    AppPinStatus status,
  ) async {
    final result = await showGeneralDialog<_DeviceAuthOutcome>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, __) {
        return _TransactionPinAuthorizationScreen(status: status);
      },
      transitionDuration: KeroseneMotion.short,
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    return result ?? _DeviceAuthOutcome.rejected;
  }
}

enum _DeviceAuthOutcome { authenticated, unavailable, rejected }

class _TransactionPinAuthorizationScreen extends ConsumerStatefulWidget {
  final AppPinStatus status;

  const _TransactionPinAuthorizationScreen({required this.status});

  @override
  ConsumerState<_TransactionPinAuthorizationScreen> createState() =>
      _TransactionPinAuthorizationScreenState();
}

class _TransactionPinAuthorizationScreenState
    extends ConsumerState<_TransactionPinAuthorizationScreen> {
  bool _busy = false;
  String _pin = '';
  String? _error;

  int get _pinLength => widget.status.minPinLength.clamp(4, 8);

  void _appendDigit(String digit) {
    if (_busy || widget.status.locked || _pin.length >= _pinLength) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _deleteDigit() {
    if (_busy || _pin.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || widget.status.locked) {
      return;
    }
    if (_pin.length != _pinLength) {
      setState(() {
        _error = context.tr.appEntryPinLengthError(_pinLength, _pinLength);
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result =
        await ref.read(securityRepositoryProvider).verifyAppPin(pin: _pin);

    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        HapticFeedback.heavyImpact();
        setState(() {
          _busy = false;
          _pin = '';
          _error = ErrorTranslator.translate(context.tr, failure.message);
        });
        ref.invalidate(appPinStatusProvider);
      },
      (_) {
        ref.invalidate(appPinStatusProvider);
        Navigator.of(context).pop(_DeviceAuthOutcome.authenticated);
      },
    );

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  void _cancel() {
    Navigator.of(context).pop(_DeviceAuthOutcome.rejected);
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      instruction: _transactionPinInstruction(context),
      valueLength: _pin.length,
      maxLength: _pinLength,
      error: _error,
      busy: _busy,
      enabled: !widget.status.locked,
      confirmLabel: context.tr.appEntryConfirm,
      onDigit: _appendDigit,
      onDelete: _deleteDigit,
      onConfirm: _busy || widget.status.locked ? null : _submit,
      footer: TextButton(
        onPressed: _busy ? null : _cancel,
        style: TextButton.styleFrom(foregroundColor: Colors.white70),
        child: Text(_transactionPinCancel(context)),
      ),
    );
  }
}

String _transactionPinInstruction(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Enter this device PIN to authorize the transaction.',
    'es' => 'Ingresa el PIN de este dispositivo para autorizar la transacción.',
    _ => 'Digite o PIN deste dispositivo para autorizar a transação.',
  };
}

String _transactionPinCancel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'en' => 'Cancel',
    'es' => 'Cancelar',
    _ => 'Cancelar',
  };
}

class _FactorAuthorizationSheet extends StatefulWidget {
  final AccountSecurityProfile profile;

  const _FactorAuthorizationSheet({required this.profile});

  @override
  State<_FactorAuthorizationSheet> createState() =>
      _FactorAuthorizationSheetState();
}

class _FactorAuthorizationSheetState extends State<_FactorAuthorizationSheet> {
  final _passphraseController = TextEditingController();
  final _totpController = TextEditingController();
  bool _passphraseError = false;
  bool _totpError = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  void _confirm() {
    final needsPassphrase = widget.profile.requiresPassphrase;
    final needsTotp = widget.profile.requiresTotp;

    setState(() {
      _passphraseError =
          needsPassphrase && _passphraseController.text.trim().isEmpty;
      _totpError = needsTotp && _totpController.text.trim().length != 6;
    });

    if (_passphraseError || _totpError) {
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      TransactionAuthResult.success(
        confirmationPassphrase:
            needsPassphrase ? _passphraseController.text.trim() : null,
        totpCode: needsTotp ? _totpController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AuthorizationSheetBase(
      icon: widget.profile.mode == AccountSecurityMode.multisig2fa
          ? KeroseneIcons.totp
          : KeroseneIcons.passkey,
      title: widget.profile.mode == AccountSecurityMode.multisig2fa
          ? context.tr.transactionAuthVaultTitle
          : context.tr.transactionAuthOperationTitle,
      subtitle: _subtitle(context, widget.profile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.profile.requiresPassphrase)
                _FactorChip(
                  label: context.tr.transactionAuthPassphraseLabel,
                  icon: KeroseneIcons.passkey,
                  color: theme.colorScheme.primary,
                ),
              if (widget.profile.requiresTotp)
                _FactorChip(
                  label: 'TOTP',
                  icon: KeroseneIcons.totp,
                  color: theme.colorScheme.secondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.profile.requiresPassphrase)
            _LabeledField(
              controller: _passphraseController,
              label: context.tr.transactionAuthConfirmationPassphraseLabel,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              hasError: _passphraseError,
              errorText: context.tr.transactionAuthEnterPassphrase,
              onChanged: (_) => setState(() => _passphraseError = false),
            ),
          if (widget.profile.requiresPassphrase) const SizedBox(height: 12),
          if (widget.profile.requiresTotp)
            _LabeledField(
              controller: _totpController,
              label: context.tr.transactionAuthTotpCodeLabel,
              keyboardType: TextInputType.number,
              maxLength: 6,
              hasError: _totpError,
              errorText: context.tr.transactionAuthEnterAuthenticatorDigits,
              onChanged: (_) => setState(() => _totpError = false),
            ),
          const SizedBox(height: AppSpacing.xl),
          _ConfirmButton(
            onTap: _confirm,
            text: context.tr.transactionAuthContinue,
          ),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context, AccountSecurityProfile profile) {
    if (profile.mode == AccountSecurityMode.multisig2fa) {
      return profile.multisigThreshold >= 3
          ? context.tr.transactionAuthProfileSubtitleMultisigFull
          : context.tr.transactionAuthProfileSubtitleMultisigStandard;
    }
    if (profile.mode == AccountSecurityMode.passkey) {
      return context.tr.transactionAuthProfileSubtitlePasskeyOnly;
    }
    return context.tr.transactionAuthProfileSubtitleDefault;
  }
}

class _ShamirAuthorizationSheet extends StatefulWidget {
  final AccountSecurityProfile profile;

  const _ShamirAuthorizationSheet({required this.profile});

  @override
  State<_ShamirAuthorizationSheet> createState() =>
      _ShamirAuthorizationSheetState();
}

class _ShamirAuthorizationSheetState extends State<_ShamirAuthorizationSheet> {
  late final List<TextEditingController> _shareControllers;
  final _totpController = TextEditingController();
  bool _totpError = false;
  String? _recoveryError;

  int get _threshold => widget.profile.shamirThreshold ?? 3;
  int get _totalShares => widget.profile.shamirTotalShares ?? _threshold;

  @override
  void initState() {
    super.initState();
    _shareControllers =
        List.generate(_threshold, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final controller in _shareControllers) {
      controller.dispose();
    }
    _totpController.dispose();
    super.dispose();
  }

  void _confirm() {
    final shares = _shareControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (shares.length != _threshold) {
      setState(() {
        _recoveryError =
            context.tr.transactionAuthShamirRecoveryError(_threshold);
      });
      return;
    }

    if (widget.profile.requiresTotp &&
        _totpController.text.trim().length != 6) {
      setState(() {
        _totpError = true;
        _recoveryError = null;
      });
      return;
    }

    try {
      final recoveredSecret = Slip39.recoverSecret(shares);
      final recoveredMnemonic = Mnemonic(
        Uint8List.fromList(recoveredSecret),
        Language.portuguese,
      ).sentence;

      HapticFeedback.mediumImpact();
      Navigator.pop(
        context,
        TransactionAuthResult.success(
          confirmationPassphrase: recoveredMnemonic,
          totpCode:
              widget.profile.requiresTotp ? _totpController.text.trim() : null,
        ),
      );
    } catch (_) {
      setState(() {
        _recoveryError = context.tr.transactionAuthShamirReconstructFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthorizationSheetBase(
      icon: KeroseneIcons.shares,
      title: context.tr.transactionAuthShamirTitle,
      subtitle: context.tr.transactionAuthShamirSubtitle(
        _threshold,
        _totalShares,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FactorChip(
                label: '$_threshold/$_totalShares SLIP-39',
                icon: KeroseneIcons.shares,
                color: KeroseneBrandTokens.warning,
              ),
              if (widget.profile.requiresTotp)
                _FactorChip(
                  label: 'TOTP',
                  icon: KeroseneIcons.totp,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(_shareControllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    index == _shareControllers.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: _ShareField(
                controller: _shareControllers[index],
                label: context.tr.transactionAuthShareLabel(index + 1),
              ),
            );
          }),
          if (widget.profile.requiresTotp) ...[
            const SizedBox(height: 12),
            _LabeledField(
              controller: _totpController,
              label: 'TOTP',
              keyboardType: TextInputType.number,
              maxLength: 6,
              hasError: _totpError,
              errorText: context.tr.transactionAuthEnterAuthenticatorDigits,
              onChanged: (_) => setState(() => _totpError = false),
            ),
          ],
          if (_recoveryError != null) ...[
            const SizedBox(height: 12),
            Text(
              _recoveryError!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.redAccent,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ConfirmButton(
            onTap: _confirm,
            text: context.tr.transactionAuthReconstructAndContinue,
          ),
        ],
      ),
    );
  }
}

class _AuthorizationSheetBase extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthorizationSheetBase({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.24),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.56),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FactorChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int? maxLength;
  final bool obscureText;
  final bool hasError;
  final String errorText;
  final ValueChanged<String>? onChanged;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.maxLength,
    this.obscureText = false,
    required this.hasError,
    required this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      maxLines: 1,
      textAlign: keyboardType == TextInputType.number
          ? TextAlign.center
          : TextAlign.start,
      style: theme.textTheme.titleMedium!.copyWith(
        fontFamily: keyboardType == TextInputType.number
            ? AppTypography.financialFontFamily
            : null,
        letterSpacing: keyboardType == TextInputType.number ? 6 : 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        errorText: hasError ? errorText : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _ShareField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _ShareField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.45),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        hintText: context.tr.transactionAuthShareHint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const _ConfirmButton({
    required this.onTap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.74),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: theme.textTheme.labelLarge!.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
