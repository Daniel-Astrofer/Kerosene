import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../security/biometric_service.dart';
import '../theme/app_spacing.dart';

/// Security tier as stored in the wallet/account.
enum AccountSecurity { standard, advanced, totp, shamir }

class TransactionAuthResult {
  final bool isAuthenticated;
  final String? confirmationPassphrase;
  final String? totpCode;

  const TransactionAuthResult._({
    required this.isAuthenticated,
    this.confirmationPassphrase,
    this.totpCode,
  });

  const TransactionAuthResult.cancelled() : this._(isAuthenticated: false);

  const TransactionAuthResult.success({
    String? confirmationPassphrase,
    String? totpCode,
  }) : this._(
         isAuthenticated: true,
         confirmationPassphrase: confirmationPassphrase,
         totpCode: totpCode,
       );
}

/// Shows the right auth challenge for a transaction, then calls [onAuthenticated].
/// If auth fails or is cancelled, calls [onCancelled].
///
/// Usage:
/// ```dart
/// TransactionAuthGate.show(
///   context,
///   security: AccountSecurity.shamir,
///   onAuthenticated: () => _sendBitcoin(),
/// );
/// ```
class TransactionAuthGate {
  /// Resolves the security level from the raw string saved on the account.
  static AccountSecurity securityFromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'SHAMIR':
        return AccountSecurity.shamir;
      case 'TOTP':
        return AccountSecurity.totp;
      case 'MULTISIG_2FA':
      case 'ADVANCED':
        return AccountSecurity.advanced;
      default:
        return AccountSecurity.standard;
    }
  }

  /// Shows the appropriate auth challenge and waits for the result.
  static Future<TransactionAuthResult> show(
    BuildContext context, {
    required AccountSecurity security,
    VoidCallback? onAuthenticated,
    VoidCallback? onCancelled,
  }) async {
    final biometricService = BiometricService();
    final result = await _resolve(
      context,
      security: security,
      biometricService: biometricService,
    );

    if (result.isAuthenticated) {
      onAuthenticated?.call();
    } else {
      onCancelled?.call();
    }

    return result;
  }

  static Future<TransactionAuthResult> _resolve(
    BuildContext context, {
    required AccountSecurity security,
    required BiometricService biometricService,
  }) async {
    final didAuthenticate = await _showDevicePinFallback(
      context,
      biometricService,
    );
    if (!didAuthenticate || !context.mounted) {
      return const TransactionAuthResult.cancelled();
    }

    switch (security) {
      case AccountSecurity.standard:
        return const TransactionAuthResult.success();

      case AccountSecurity.advanced:
        final passphrase = await _showPassphraseDialog(
          context,
          title: 'Confirmação da Passphrase',
          subtitle: 'Digite sua passphrase para autorizar esta transação',
        );
        if (passphrase == null || passphrase.isEmpty) {
          return const TransactionAuthResult.cancelled();
        }
        return TransactionAuthResult.success(
          confirmationPassphrase: passphrase,
        );

      case AccountSecurity.totp:
        final totpCode = await _showTotpDialog(context);
        if (totpCode == null || totpCode.isEmpty) {
          return const TransactionAuthResult.cancelled();
        }
        return TransactionAuthResult.success(totpCode: totpCode);

      case AccountSecurity.shamir:
        final passphrase = await _showPassphraseDialog(
          context,
          title: 'Confirmação do Cofre',
          subtitle: 'Digite sua passphrase para liberar esta transação',
        );
        if (passphrase == null || passphrase.isEmpty) {
          return const TransactionAuthResult.cancelled();
        }
        return TransactionAuthResult.success(
          confirmationPassphrase: passphrase,
        );
    }
  }

  static Future<bool> _showDevicePinFallback(
    BuildContext context,
    BiometricService bio,
  ) async {
    try {
      return await bio.authenticate(
        localizedReason: 'Use seu PIN ou padrão do dispositivo para confirmar',
      );
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _showTotpDialog(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _TotpEntrySheet(),
    );
    return result;
  }

  static Future<String?> _showPassphraseDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PassphraseEntrySheet(title: title, subtitle: subtitle),
    );
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOTP Entry sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TotpEntrySheet extends StatefulWidget {
  const _TotpEntrySheet();

  @override
  State<_TotpEntrySheet> createState() => _TotpEntrySheetState();
}

class _TotpEntrySheetState extends State<_TotpEntrySheet> {
  final _controller = TextEditingController();
  bool _error = false;

  void _verify() {
    final code = _controller.text.trim();
    if (code.length != 6) return;
    HapticFeedback.vibrate();
    Navigator.pop(context, code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSheetBase(
      icon: LucideIcons.shield,
      title: 'Autenticador (TOTP)',
      subtitle: 'Digite o código de 6 dígitos do seu app autenticador',
      child: Column(
        children: [
          _CodeTextField(
            controller: _controller,
            label: 'Código de 6 dígitos',
            hasError: _error,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (_) => setState(() => _error = false),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ConfirmButton(onTap: _verify, text: 'VERIFICAR'),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passphrase confirmation sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PassphraseEntrySheet extends StatefulWidget {
  final String title;
  final String subtitle;

  const _PassphraseEntrySheet({
    required this.title,
    required this.subtitle,
  });

  @override
  State<_PassphraseEntrySheet> createState() => _PassphraseEntrySheetState();
}

class _PassphraseEntrySheetState extends State<_PassphraseEntrySheet> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _isVerifying = false;

  Future<void> _verify() async {
    if (_isVerifying) return;
    final passphrase = _controller.text.trim();
    if (passphrase.isEmpty) {
      setState(() => _error = true);
      return;
    }

    setState(() => _isVerifying = true);

    if (!mounted) return;
    HapticFeedback.vibrate();
    Navigator.pop(context, passphrase);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthSheetBase(
      icon: LucideIcons.key,
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        children: [
          _CodeTextField(
            controller: _controller,
            label: 'Passphrase',
            hasError: _error,
            keyboardType: TextInputType.text,
            maxLength: 128,
            onChanged: (_) => setState(() => _error = false),
            onSubmitted: (_) => _verify(),
            obscureText: true,
            textAlign: TextAlign.start,
            letterSpacing: 0,
            errorText: 'Passphrase obrigatória.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _ConfirmButton(
            onTap: _verify,
            text: 'VERIFICAR',
            isLoading: _isVerifying,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Sub-Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AuthSheetBase extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthSheetBase({
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
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ).animate().scale(curve: Curves.easeOutBack),

          const SizedBox(height: AppSpacing.lg),

          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          child,
        ],
      ),
    );
  }
}

class _CodeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool hasError;
  final TextInputType keyboardType;
  final int maxLength;
  final bool obscureText;
  final TextAlign textAlign;
  final double letterSpacing;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _CodeTextField({
    required this.controller,
    required this.label,
    required this.hasError,
    required this.keyboardType,
    required this.maxLength,
    this.obscureText = false,
    this.textAlign = TextAlign.center,
    this.letterSpacing = 6,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: 1,
      textAlign: textAlign,
      autofocus: true,
      obscureText: obscureText,
      style: theme.textTheme.titleLarge!.copyWith(
        letterSpacing: letterSpacing,
        fontFamily: 'JetBrainsMono',
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        errorText:
            hasError ? (errorText ?? 'Código incorreto. Tente novamente.') : null,
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
      onSubmitted: onSubmitted,
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final bool isLoading;

  const _ConfirmButton({
    required this.onTap,
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  text,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}
