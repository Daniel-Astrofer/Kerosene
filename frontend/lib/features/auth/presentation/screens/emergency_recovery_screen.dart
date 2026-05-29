import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kerosene/core/errors/exceptions.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_logo.dart';
import 'package:kerosene/core/theme/app_colors.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/features/auth/domain/emergency_recovery_models.dart';
import 'package:kerosene/features/auth/presentation/providers/emergency_recovery_provider.dart';

enum _RecoveryStep { start, verify, complete }

class EmergencyRecoveryScreen extends ConsumerStatefulWidget {
  const EmergencyRecoveryScreen({super.key});

  @override
  ConsumerState<EmergencyRecoveryScreen> createState() =>
      _EmergencyRecoveryScreenState();
}

class _EmergencyRecoveryScreenState
    extends ConsumerState<EmergencyRecoveryScreen> {
  final _usernameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  final _totpController = TextEditingController();
  final List<TextEditingController> _codeControllers =
      List.generate(3, (_) => TextEditingController());

  _RecoveryStep _step = _RecoveryStep.start;
  EmergencyRecoveryStartResult? _started;
  EmergencyRecoveryFinishResult? _finished;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    _totpController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _copy({
    required String pt,
    required String en,
    required String es,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'es' => es,
      _ => pt,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl2,
                      AppSpacing.base,
                      AppSpacing.xl2,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RecoveryTopBar(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          const Center(
                            child: KeroseneLogo(size: 46, showText: false),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          _RecoveryTitle(
                            eyebrow: _copy(
                              pt: 'RECUPERAÇÃO EMERGENCIAL',
                              en: 'EMERGENCY RECOVERY',
                              es: 'RECUPERACIÓN DE EMERGENCIA',
                            ),
                            title: _titleForStep(),
                            body: _bodyForStep(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.xl2),
                            _RecoveryNotice(
                              icon: LucideIcons.alertTriangle,
                              title: _copy(
                                pt: 'Não foi possível continuar',
                                en: 'Unable to continue',
                                es: 'No se pudo continuar',
                              ),
                              message: _error!,
                              tone: _RecoveryNoticeTone.error,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl2),
                          switch (_step) {
                            _RecoveryStep.start => _buildStartStep(),
                            _RecoveryStep.verify => _buildVerifyStep(),
                            _RecoveryStep.complete => _buildCompleteStep(),
                          },
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForStep() {
    return switch (_step) {
      _RecoveryStep.start => _copy(
          pt: 'Rotacione o acesso da conta',
          en: 'Rotate account access',
          es: 'Rota el acceso de la cuenta',
        ),
      _RecoveryStep.verify => _copy(
          pt: 'Configure o novo autenticador',
          en: 'Set up the new authenticator',
          es: 'Configura el nuevo autenticador',
        ),
      _RecoveryStep.complete => _copy(
          pt: 'Recovery concluído',
          en: 'Recovery complete',
          es: 'Recuperación completada',
        ),
    };
  }

  String _bodyForStep() {
    return switch (_step) {
      _RecoveryStep.start => _copy(
          pt: 'Use códigos de recuperação salvos offline para criar uma nova senha, novo TOTP e nova passkey neste dispositivo.',
          en: 'Use offline recovery codes to create a new password, new TOTP and new passkey on this device.',
          es: 'Usa códigos de recuperación guardados offline para crear nueva contraseña, TOTP y passkey en este dispositivo.',
        ),
      _RecoveryStep.verify => _copy(
          pt: 'Escaneie o QR no autenticador, digite o código de 6 dígitos e confirme a nova passkey local.',
          en: 'Scan the QR in your authenticator, enter the 6-digit code and confirm the new local passkey.',
          es: 'Escanea el QR en tu autenticador, ingresa el código de 6 dígitos y confirma la nueva passkey local.',
        ),
      _RecoveryStep.complete => _copy(
          pt: 'Guarde os novos códigos offline antes de entrar novamente. Eles não devem ficar no app de notas, email ou nuvem.',
          en: 'Store the new codes offline before signing in again. They should not live in notes, email or cloud storage.',
          es: 'Guarda los nuevos códigos offline antes de entrar de nuevo. No deben quedar en notas, email o nube.',
        ),
    };
  }

  Widget _buildStartStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecoveryTextField(
          controller: _usernameController,
          label: context.tr.username,
          icon: LucideIcons.user,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: AppSpacing.base),
        _RecoveryTextField(
          controller: _passphraseController,
          label: _copy(
            pt: 'Nova senha da conta',
            en: 'New account password',
            es: 'Nueva contraseña de cuenta',
          ),
          icon: LucideIcons.lock,
          enabled: !_busy,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: AppSpacing.base),
        _RecoveryTextField(
          controller: _confirmPassphraseController,
          label: _copy(
            pt: 'Confirmar nova senha',
            en: 'Confirm new password',
            es: 'Confirmar nueva contraseña',
          ),
          icon: LucideIcons.keyRound,
          enabled: !_busy,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          _copy(
            pt: 'Códigos de recuperação',
            en: 'Recovery codes',
            es: 'Códigos de recuperación',
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < _codeControllers.length; i++) ...[
          _RecoveryTextField(
            controller: _codeControllers[i],
            label: _copy(
              pt: 'Código ${i + 1}',
              en: 'Code ${i + 1}',
              es: 'Código ${i + 1}',
            ),
            icon: LucideIcons.binary,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            textInputAction: i == _codeControllers.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            onChanged: (_) => _clearError(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy || _codeControllers.length >= 10
                ? null
                : _addRecoveryCodeField,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              _copy(
                pt: 'Adicionar código',
                en: 'Add code',
                es: 'Agregar código',
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        _RecoveryActionButton(
          label: _copy(
            pt: 'Iniciar recovery',
            en: 'Start recovery',
            es: 'Iniciar recuperación',
          ),
          loading: _busy,
          onPressed: _busy ? null : _startRecovery,
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    final started = _started;
    if (started == null) {
      return const SizedBox.shrink();
    }

    final minutes = (started.expiresInSeconds / 60).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecoveryNotice(
          icon: LucideIcons.timer,
          title: _copy(
            pt: 'Sessão temporária',
            en: 'Temporary session',
            es: 'Sesión temporal',
          ),
          message: _copy(
            pt: 'Conclua em até $minutes minutos para evitar reiniciar o fluxo.',
            en: 'Finish within $minutes minutes to avoid restarting the flow.',
            es: 'Termina en hasta $minutes minutos para no reiniciar el flujo.',
          ),
          tone: _RecoveryNoticeTone.info,
        ),
        const SizedBox(height: AppSpacing.xl2),
        _TotpQrPanel(
          data: started.otpUri,
          onCopy: () => _copyToClipboard(started.otpUri),
        ),
        const SizedBox(height: AppSpacing.xl2),
        _RecoveryTextField(
          controller: _totpController,
          label: context.tr.totpCodeLabel,
          icon: LucideIcons.shieldCheck,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_busy) {
              _finishRecovery();
            }
          },
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: AppSpacing.xl2),
        _RecoveryActionButton(
          label: _copy(
            pt: 'Confirmar nova passkey',
            en: 'Confirm new passkey',
            es: 'Confirmar nueva passkey',
          ),
          loading: _busy,
          onPressed: _busy ? null : _finishRecovery,
        ),
        const SizedBox(height: AppSpacing.base),
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _step = _RecoveryStep.start;
                    _started = null;
                    _error = null;
                  });
                },
          child: Text(
            _copy(
              pt: 'Voltar e revisar dados',
              en: 'Go back and review data',
              es: 'Volver y revisar datos',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    final finished = _finished;
    final codes = finished?.newBackupCodes ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecoveryNotice(
          icon: LucideIcons.checkCircle2,
          title: _copy(
            pt: 'Credenciais rotacionadas',
            en: 'Credentials rotated',
            es: 'Credenciales rotadas',
          ),
          message: _copy(
            pt: 'A conta ${finished?.username ?? ''} agora usa a nova senha, novo TOTP e nova passkey deste dispositivo.',
            en: 'Account ${finished?.username ?? ''} now uses the new password, new TOTP and this device passkey.',
            es: 'La cuenta ${finished?.username ?? ''} ahora usa nueva contraseña, nuevo TOTP y la passkey de este dispositivo.',
          ),
          tone: _RecoveryNoticeTone.success,
        ),
        const SizedBox(height: AppSpacing.xl2),
        _BackupCodesGrid(codes: codes),
        const SizedBox(height: AppSpacing.xl2),
        _RecoveryActionButton(
          label: _copy(
            pt: 'Copiar novos códigos',
            en: 'Copy new codes',
            es: 'Copiar nuevos códigos',
          ),
          icon: LucideIcons.copy,
          loading: false,
          onPressed: codes.isEmpty
              ? null
              : () => _copyToClipboard(
                    codes.join('\n'),
                  ),
        ),
        const SizedBox(height: AppSpacing.base),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false),
          icon: const Icon(LucideIcons.logIn, size: 18),
          label: Text(
            _copy(
              pt: 'Entrar novamente',
              en: 'Sign in again',
              es: 'Entrar de nuevo',
            ),
          ),
        ),
      ],
    );
  }

  void _addRecoveryCodeField() {
    setState(() => _codeControllers.add(TextEditingController()));
  }

  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  Future<void> _startRecovery() async {
    final username = _usernameController.text.trim().toLowerCase();
    final passphrase = _passphraseController.text;
    final confirmPassphrase = _confirmPassphraseController.text;
    final codes = _codeControllers
        .map((controller) => controller.text.trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false);

    final validationError = _validateStart(
      username: username,
      passphrase: passphrase,
      confirmPassphrase: confirmPassphrase,
      codes: codes,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final started = await ref.read(emergencyRecoveryServiceProvider).start(
            EmergencyRecoveryStartDraft(
              username: username,
              newPassphrase: passphrase,
              recoveryCodes: codes,
            ),
          );
      if (!mounted) return;
      setState(() {
        _started = started;
        _step = _RecoveryStep.verify;
      });
    } catch (error) {
      _setTranslatedError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finishRecovery() async {
    final started = _started;
    if (started == null) return;

    final totp = _totpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(totp)) {
      setState(() {
        _error = _copy(
          pt: 'Digite o código TOTP de 6 dígitos do novo autenticador.',
          en: 'Enter the 6-digit TOTP from the new authenticator.',
          es: 'Ingresa el TOTP de 6 dígitos del nuevo autenticador.',
        );
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final finished = await ref.read(emergencyRecoveryServiceProvider).finish(
            username: _usernameController.text.trim().toLowerCase(),
            started: started,
            totpCode: totp,
          );
      if (!mounted) return;
      setState(() {
        _finished = finished;
        _step = _RecoveryStep.complete;
      });
    } catch (error) {
      _setTranslatedError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _validateStart({
    required String username,
    required String passphrase,
    required String confirmPassphrase,
    required List<String> codes,
  }) {
    if (username.length < 3) {
      return context.tr.authUsernameRequiredMessage;
    }
    if (passphrase.length < 12) {
      return _copy(
        pt: 'Use uma nova senha com pelo menos 12 caracteres.',
        en: 'Use a new password with at least 12 characters.',
        es: 'Usa una nueva contraseña con al menos 12 caracteres.',
      );
    }
    if (passphrase != confirmPassphrase) {
      return _copy(
        pt: 'A confirmação precisa ser igual à nova senha.',
        en: 'The confirmation must match the new password.',
        es: 'La confirmación debe coincidir con la nueva contraseña.',
      );
    }
    if (codes.length < 3) {
      return _copy(
        pt: 'Informe pelo menos 3 códigos de recuperação distintos.',
        en: 'Enter at least 3 distinct recovery codes.',
        es: 'Ingresa al menos 3 códigos de recuperación distintos.',
      );
    }
    if (codes.toSet().length != codes.length) {
      return _copy(
        pt: 'Os códigos de recuperação precisam ser distintos.',
        en: 'Recovery codes must be distinct.',
        es: 'Los códigos de recuperación deben ser distintos.',
      );
    }
    if (codes.any((code) => !RegExp(r'^\d{8}$').hasMatch(code))) {
      return _copy(
        pt: 'Cada código de recuperação deve ter 8 dígitos.',
        en: 'Each recovery code must have 8 digits.',
        es: 'Cada código de recuperación debe tener 8 dígitos.',
      );
    }
    return null;
  }

  void _setTranslatedError(Object error) {
    if (!mounted) return;
    final message = error is AppException
        ? ErrorTranslator.translate(context.tr, error.message)
        : ErrorTranslator.translate(context.tr, error.toString());
    setState(() => _error = message);
  }

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _copy(
            pt: 'Copiado.',
            en: 'Copied.',
            es: 'Copiado.',
          ),
        ),
      ),
    );
  }
}

class _RecoveryTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _RecoveryTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          color: Colors.white,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        const Spacer(),
      ],
    );
  }
}

class _RecoveryTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _RecoveryTitle({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(
            fontSize: 31,
            fontWeight: FontWeight.w500,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _RecoveryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _RecoveryTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

enum _RecoveryNoticeTone { info, success, error }

class _RecoveryNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final _RecoveryNoticeTone tone;

  const _RecoveryNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _RecoveryNoticeTone.info => AppColors.secondary,
      _RecoveryNoticeTone.success => AppColors.success,
      _RecoveryNoticeTone.error => AppColors.error,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotpQrPanel extends StatelessWidget {
  final String data;
  final VoidCallback onCopy;

  const _TotpQrPanel({
    required this.data,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 212,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            SelectableText(
              data,
              maxLines: 2,
              style: AppTypography.technicalMono(
                color: Colors.white60,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(LucideIcons.copy, size: 16),
              label: Text(MaterialLocalizations.of(context).copyButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCodesGrid extends StatelessWidget {
  final List<String> codes;

  const _BackupCodesGrid({required this.codes});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final code in codes)
          Container(
            width: 112,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              border: Border.all(color: AppColors.white10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: AppTypography.technicalMono(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _RecoveryActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  const _RecoveryActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? LucideIcons.arrowRight, size: 18),
        label: Text(label),
      ),
    );
  }
}
