import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/error_translator.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/core/widgets/cyber_text_field.dart';
import 'package:teste/features/auth/controller/auth_providers.dart';
import 'package:teste/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:teste/features/auth/presentation/widgets/auth_action_illustration.dart';
import 'package:teste/l10n/l10n_extension.dart';

import '../../../../core/services/passkey_service.dart';

enum _RecoveryStage {
  collect,
  configure,
  success,
}

class _RecoveryIssueData {
  final AuthActionIllustrationMode illustrationMode;
  final String title;
  final String message;
  final bool requiresRestart;

  const _RecoveryIssueData({
    required this.illustrationMode,
    required this.title,
    required this.message,
    this.requiresRestart = false,
  });
}

class EmergencyRecoveryScreen extends ConsumerStatefulWidget {
  final String initialUsername;

  const EmergencyRecoveryScreen({
    super.key,
    this.initialUsername = '',
  });

  @override
  ConsumerState<EmergencyRecoveryScreen> createState() =>
      _EmergencyRecoveryScreenState();
}

class _EmergencyRecoveryScreenState
    extends ConsumerState<EmergencyRecoveryScreen> {
  final _usernameController = TextEditingController();
  final _newPassphraseController = TextEditingController();
  final _totpController = TextEditingController();
  late final List<TextEditingController> _recoveryCodeControllers;

  _RecoveryStage _stage = _RecoveryStage.collect;
  bool _isStarting = false;
  bool _isRegisteringPasskey = false;
  bool _isFinishing = false;
  EmergencyRecoveryStartResult? _startResult;
  EmergencyRecoveryFinishResult? _finishResult;
  Map<String, dynamic>? _newCredential;
  _RecoveryIssueData? _issue;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialUsername.trim();
    _recoveryCodeControllers = List.generate(3, (_) => TextEditingController());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPassphraseController.dispose();
    _totpController.dispose();
    for (final controller in _recoveryCodeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _normalizedUsername => _usernameController.text.trim();

  String get _normalizedPassphrase => _newPassphraseController.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .join(' ');

  List<String> get _normalizedRecoveryCodes => _recoveryCodeControllers
      .map((controller) => controller.text.replaceAll(RegExp(r'\D'), ''))
      .where((code) => code.isNotEmpty)
      .toList();

  String get _totpSecret {
    final uri = Uri.tryParse(_startResult?.otpUri ?? '');
    return uri?.queryParameters['secret'] ?? '';
  }

  String _t(LocalizedCopy copy) => copy.resolve(context);

  void _showSnack(String message) {
    AppNotice.showInfo(context, message: message);
  }

  void _resetRecoveryFlow() {
    setState(() {
      _stage = _RecoveryStage.collect;
      _isStarting = false;
      _isRegisteringPasskey = false;
      _isFinishing = false;
      _startResult = null;
      _finishResult = null;
      _newCredential = null;
      _issue = null;
      _totpController.clear();
    });
  }

  String? _validateStartInput() {
    if (_normalizedUsername.isEmpty) {
      return _t(_RecoveryCopy.usernameRequired);
    }

    if (!RegExp(r'^[a-z0-9_]{3,15}$').hasMatch(_normalizedUsername)) {
      return _t(_RecoveryCopy.usernameFormatInvalid);
    }

    if (_normalizedPassphrase.isEmpty) {
      return _t(_RecoveryCopy.passphraseRequired);
    }

    if (!bip39.validateMnemonic(_normalizedPassphrase)) {
      return _t(_RecoveryCopy.passphraseInvalid);
    }

    if (_normalizedRecoveryCodes.length < 3) {
      return _t(_RecoveryCopy.minimumRecoveryCodes);
    }

    final distinct = _normalizedRecoveryCodes.toSet();
    if (distinct.length < 3) {
      return _t(_RecoveryCopy.recoveryCodesMustBeDistinct);
    }

    if (_normalizedRecoveryCodes
        .any((code) => !RegExp(r'^\d{8}$').hasMatch(code))) {
      return _t(_RecoveryCopy.recoveryCodeFormatInvalid);
    }

    return null;
  }

  _RecoveryIssueData _mapIssue({
    required String message,
    String? errorCode,
  }) {
    final translated =
        ErrorTranslator.translate(context.l10n, errorCode ?? message);

    switch (errorCode) {
      case 'RECOVERY_BAD_REQUEST':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.warning,
          title: _t(_RecoveryCopy.invalidRecoveryPayload),
          message: translated,
        );
      case 'RECOVERY_REJECTED':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.keyRejected,
          title: _t(_RecoveryCopy.recoveryRejected),
          message: translated,
        );
      case 'RECOVERY_SESSION_EXPIRED':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.sessionExpired,
          title: _t(_RecoveryCopy.recoverySessionExpired),
          message: translated,
          requiresRestart: true,
        );
      case 'RECOVERY_RATE_LIMITED':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.warning,
          title: _t(_RecoveryCopy.recoveryTemporarilyBlocked),
          message: translated,
        );
      case 'ERR_AUTH_PASSKEY_AUTH_CANCELLED':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.warning,
          title: _t(_RecoveryCopy.passkeyRegistrationCancelled),
          message: translated,
        );
      case 'ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS':
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.keyRejected,
          title: _t(_RecoveryCopy.noLocalCredentialAvailable),
          message: translated,
        );
      default:
        return _RecoveryIssueData(
          illustrationMode: AuthActionIllustrationMode.warning,
          title: _t(_RecoveryCopy.recoveryFlowFailed),
          message: translated,
        );
    }
  }

  Future<void> _startEmergencyRecovery() async {
    final validationError = _validateStartInput();
    if (validationError != null) {
      setState(() {
        _issue = _mapIssue(message: validationError);
      });
      return;
    }

    setState(() {
      _isStarting = true;
      _issue = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.startEmergencyRecovery(
      username: _normalizedUsername,
      newPassphrase: _normalizedPassphrase,
      recoveryCodes: _normalizedRecoveryCodes,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isStarting = false;
          _issue = _mapIssue(
            message: failure.message,
            errorCode: failure.errorCode,
          );
        });
      },
      (startResult) {
        setState(() {
          _isStarting = false;
          _stage = _RecoveryStage.configure;
          _startResult = startResult;
          _issue = null;
          _newCredential = null;
          _finishResult = null;
          _totpController.clear();
        });
      },
    );
  }

  Future<void> _registerNewPasskey() async {
    final startResult = _startResult;
    if (startResult == null || _isRegisteringPasskey) {
      return;
    }

    setState(() {
      _isRegisteringPasskey = true;
      _issue = null;
    });

    try {
      final credential = await PasskeyService.instance.register(
        challengeHex: startResult.passkeyChallenge,
        username: _normalizedUsername,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isRegisteringPasskey = false;
        _newCredential = credential;
      });
      _showSnack(_t(_RecoveryCopy.newPasskeyRegistered));
    } catch (error) {
      if (!mounted) {
        return;
      }

      final raw = error.toString();
      final codeMatch = RegExp(
        r'(ERR_AUTH_PASSKEY_NO_LOCAL_CREDENTIALS|ERR_AUTH_PASSKEY_AUTH_CANCELLED)',
      ).firstMatch(raw);

      setState(() {
        _isRegisteringPasskey = false;
        _issue = _mapIssue(
          message: raw,
          errorCode: codeMatch?.group(1),
        );
      });
    }
  }

  Future<void> _finishEmergencyRecovery() async {
    if (_startResult == null) {
      return;
    }

    final totpCode = _totpController.text.replaceAll(RegExp(r'\D'), '');
    if (totpCode.length != 6) {
      setState(() {
        _issue = _mapIssue(
          message: _t(_RecoveryCopy.totpCodeRequired),
        );
      });
      return;
    }

    if (_newCredential == null) {
      setState(() {
        _issue = _mapIssue(
          message: _t(_RecoveryCopy.registerPasskeyBeforeFinishing),
        );
      });
      return;
    }

    setState(() {
      _isFinishing = true;
      _issue = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.finishEmergencyRecovery(
      recoverySessionId: _startResult!.recoverySessionId,
      totpCode: totpCode,
      credential: _newCredential!,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isFinishing = false;
          _issue = _mapIssue(
            message: failure.message,
            errorCode: failure.errorCode,
          );
        });
      },
      (finishResult) {
        setState(() {
          _isFinishing = false;
          _finishResult = finishResult;
          _stage = _RecoveryStage.success;
          _issue = null;
        });
      },
    );
  }

  AuthActionIllustrationMode _headerMode() {
    if (_issue != null) {
      return _issue!.illustrationMode;
    }

    switch (_stage) {
      case _RecoveryStage.collect:
        return AuthActionIllustrationMode.recoveryCodes;
      case _RecoveryStage.configure:
        return _newCredential == null
            ? AuthActionIllustrationMode.fingerprintScan
            : AuthActionIllustrationMode.keyTransfer;
      case _RecoveryStage.success:
        return AuthActionIllustrationMode.shieldSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _issue != null
        ? (_issue!.illustrationMode == AuthActionIllustrationMode.sessionExpired
            ? AppColors.warning
            : Theme.of(context).colorScheme.error)
        : (_stage == _RecoveryStage.success
            ? AppColors.success
            : Theme.of(context).colorScheme.secondary);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: AmbientSideGlowBackdrop(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      Text(
                        _t(_RecoveryCopy.screenTitle),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: AuthActionIllustration(
                                  mode: _headerMode(),
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                _issue?.title ??
                                    _RecoveryCopy.stageTitle(context, _stage),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _issue?.message ??
                                    _RecoveryCopy.stageMessage(context, _stage),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      height: 1.55,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              if (_stage == _RecoveryStage.collect)
                                _buildCollectStep(context),
                              if (_stage == _RecoveryStage.configure)
                                _buildConfigureStep(context),
                              if (_stage == _RecoveryStage.success)
                                _buildSuccessStep(context),
                              if (_issue != null) ...[
                                const SizedBox(height: AppSpacing.lg),
                                if (_issue!.requiresRestart)
                                  BouncingButton(
                                    text: _t(_RecoveryCopy.restartRecovery),
                                    onPressed: _resetRecoveryFlow,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CyberTextField(
          controller: _usernameController,
          label: _t(_RecoveryCopy.usernameLabel),
          hint: '@astroferas',
          onChanged: (_) {
            if (_issue != null) {
              setState(() => _issue = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _TextAreaCard(
          label: _t(_RecoveryCopy.newPassphraseLabel),
          hint: _t(_RecoveryCopy.newPassphraseHint),
          controller: _newPassphraseController,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _t(_RecoveryCopy.recoveryCodesLabel),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_recoveryCodeControllers.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _recoveryCodeControllers.length - 1
                  ? 0
                  : AppSpacing.md,
            ),
            child: CyberTextField(
              controller: _recoveryCodeControllers[index],
              label: _RecoveryCopy.recoveryCodeLabel(context, index + 1),
              hint: '12345678',
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_issue != null) {
                  setState(() => _issue = null);
                }
              },
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        BouncingButton(
          text: _t(_RecoveryCopy.startRecovery),
          isLoading: _isStarting,
          onPressed: _isStarting ? null : _startEmergencyRecovery,
        ),
      ],
    );
  }

  Widget _buildConfigureStep(BuildContext context) {
    final startResult = _startResult;
    if (startResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: _t(_RecoveryCopy.temporarySessionTitle),
          lines: [
            'sessionId: ${startResult.recoverySessionId}',
            _RecoveryCopy.sessionExpiresIn(
              context,
              startResult.expiresInSeconds ~/ 60,
            ),
            _RecoveryCopy.minimumCodesSent(
              context,
              startResult.requiredRecoveryCodes,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t(_RecoveryCopy.newTotpLabel),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: startResult.otpUri,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_totpSecret.isNotEmpty)
                _InfoCard(
                  title: _t(_RecoveryCopy.authenticatorSecretTitle),
                  lines: [_totpSecret],
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BouncingButton(
          text: _newCredential == null
              ? _t(_RecoveryCopy.registerNewPasskey)
              : _t(_RecoveryCopy.passkeyRegisteredOnDevice),
          isLoading: _isRegisteringPasskey,
          onPressed: _isRegisteringPasskey ? null : _registerNewPasskey,
        ),
        const SizedBox(height: AppSpacing.lg),
        CyberTextField(
          controller: _totpController,
          label: _t(_RecoveryCopy.totpCodeLabel),
          hint: '123456',
          keyboardType: TextInputType.number,
          onChanged: (_) {
            if (_issue != null) {
              setState(() => _issue = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        BouncingButton(
          text: _t(_RecoveryCopy.completeRecovery),
          isLoading: _isFinishing,
          onPressed: _isFinishing ? null : _finishEmergencyRecovery,
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    final finishResult = _finishResult;
    if (finishResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: _t(_RecoveryCopy.accountRotatedTitle),
          lines: [
            '@${finishResult.username}',
            _t(_RecoveryCopy.accountRotatedBody),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t(_RecoveryCopy.newRecoveryCodesLabel),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...finishResult.newBackupCodes.map(
                (code) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      code,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BouncingButton(
          text: _t(_RecoveryCopy.backToLogin),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoCard({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAreaCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _TextAreaCard({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 1.45,
                ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCopy {
  static const usernameRequired = LocalizedCopy(
    en: 'Enter the username before starting recovery.',
    pt: 'Informe o username antes de iniciar a recuperacao.',
    es: 'Ingresa el usuario antes de iniciar la recuperacion.',
  );
  static const usernameFormatInvalid = LocalizedCopy(
    en: 'Use a valid username with 3 to 15 characters, only a-z, 0-9 and _.',
    pt: 'Use um username valido com 3 a 15 caracteres, apenas a-z, 0-9 e _.',
    es: 'Usa un usuario valido de 3 a 15 caracteres, solo a-z, 0-9 y _.',
  );
  static const passphraseRequired = LocalizedCopy(
    en: 'Define the new passphrase before continuing.',
    pt: 'Defina a nova frase secreta antes de continuar.',
    es: 'Define la nueva frase secreta antes de continuar.',
  );
  static const passphraseInvalid = LocalizedCopy(
    en: 'The new passphrase must be a valid BIP39 seed.',
    pt: 'A nova frase secreta precisa ser uma seed BIP39 valida.',
    es: 'La nueva frase secreta debe ser una seed BIP39 valida.',
  );
  static const minimumRecoveryCodes = LocalizedCopy(
    en: 'Send at least 3 distinct recovery codes.',
    pt: 'Envie pelo menos 3 recovery codes distintos.',
    es: 'Envia al menos 3 recovery codes distintos.',
  );
  static const recoveryCodesMustBeDistinct = LocalizedCopy(
    en: 'Recovery codes must be distinct.',
    pt: 'Os recovery codes precisam ser distintos.',
    es: 'Los recovery codes deben ser distintos.',
  );
  static const recoveryCodeFormatInvalid = LocalizedCopy(
    en: 'Each recovery code must have exactly 8 digits.',
    pt: 'Cada recovery code deve ter exatamente 8 digitos.',
    es: 'Cada recovery code debe tener exactamente 8 digitos.',
  );
  static const invalidRecoveryPayload = LocalizedCopy(
    en: 'Invalid recovery information',
    pt: 'Dados invalidos para recuperacao',
    es: 'Datos invalidos para recuperacion',
  );
  static const recoveryRejected = LocalizedCopy(
    en: 'Recovery rejected',
    pt: 'Recuperacao rejeitada',
    es: 'Recuperacion rechazada',
  );
  static const recoverySessionExpired = LocalizedCopy(
    en: 'Recovery session expired',
    pt: 'Sessao de recuperacao expirada',
    es: 'Sesion de recuperacion expirada',
  );
  static const recoveryTemporarilyBlocked = LocalizedCopy(
    en: 'Recovery temporarily blocked',
    pt: 'Recuperacao temporariamente bloqueada',
    es: 'Recuperacion temporalmente bloqueada',
  );
  static const passkeyRegistrationCancelled = LocalizedCopy(
    en: 'Passkey registration cancelled',
    pt: 'Registro de passkey cancelado',
    es: 'Registro de passkey cancelado',
  );
  static const noLocalCredentialAvailable = LocalizedCopy(
    en: 'No local credential available',
    pt: 'Sem credencial local disponivel',
    es: 'Sin credencial local disponible',
  );
  static const recoveryFlowFailed = LocalizedCopy(
    en: 'Recovery flow failed',
    pt: 'Falha no fluxo de recuperacao',
    es: 'Fallo el flujo de recuperacion',
  );
  static const newPasskeyRegistered = LocalizedCopy(
    en: 'New passkey registered on this device.',
    pt: 'Nova passkey registrada neste aparelho.',
    es: 'Nueva passkey registrada en este dispositivo.',
  );
  static const totpCodeRequired = LocalizedCopy(
    en: 'Enter the 6-digit TOTP code from the new authenticator.',
    pt: 'Informe o codigo TOTP de 6 digitos do novo autenticador.',
    es: 'Ingresa el codigo TOTP de 6 digitos del nuevo autenticador.',
  );
  static const registerPasskeyBeforeFinishing = LocalizedCopy(
    en: 'Register the new passkey on this device before completing recovery.',
    pt: 'Registre a nova passkey neste aparelho antes de concluir a recuperacao.',
    es: 'Registra la nueva passkey en este dispositivo antes de completar la recuperacion.',
  );
  static const restartRecovery = LocalizedCopy(
    en: 'Restart recovery',
    pt: 'Reiniciar recuperacao',
    es: 'Reiniciar recuperacion',
  );
  static const screenTitle = LocalizedCopy(
    en: 'Emergency recovery',
    pt: 'Recuperacao emergencial',
    es: 'Recuperacion de emergencia',
  );
  static const usernameLabel = LocalizedCopy(
    en: 'USERNAME',
    pt: 'USERNAME',
    es: 'USUARIO',
  );
  static const newPassphraseLabel = LocalizedCopy(
    en: 'NEW PASSPHRASE',
    pt: 'NOVA FRASE SECRETA',
    es: 'NUEVA FRASE SECRETA',
  );
  static const newPassphraseHint = LocalizedCopy(
    en: 'Paste or type the full new BIP39 seed.',
    pt: 'Cole ou digite a nova seed BIP39 completa.',
    es: 'Pega o escribe la nueva seed BIP39 completa.',
  );
  static const recoveryCodesLabel = LocalizedCopy(
    en: 'RECOVERY CODES',
    pt: 'RECOVERY CODES',
    es: 'RECOVERY CODES',
  );
  static const startRecovery = LocalizedCopy(
    en: 'Start recovery',
    pt: 'Iniciar recuperacao',
    es: 'Iniciar recuperacion',
  );
  static const temporarySessionTitle = LocalizedCopy(
    en: 'Temporary session',
    pt: 'Sessao temporaria',
    es: 'Sesion temporal',
  );
  static const newTotpLabel = LocalizedCopy(
    en: 'NEW TOTP',
    pt: 'NOVO TOTP',
    es: 'NUEVO TOTP',
  );
  static const authenticatorSecretTitle = LocalizedCopy(
    en: 'Authenticator secret',
    pt: 'Segredo do autenticador',
    es: 'Secreto del autenticador',
  );
  static const registerNewPasskey = LocalizedCopy(
    en: 'Register new passkey',
    pt: 'Registrar nova passkey',
    es: 'Registrar nueva passkey',
  );
  static const passkeyRegisteredOnDevice = LocalizedCopy(
    en: 'Passkey registered on this device',
    pt: 'Passkey registrada neste aparelho',
    es: 'Passkey registrada en este dispositivo',
  );
  static const totpCodeLabel = LocalizedCopy(
    en: 'TOTP CODE',
    pt: 'CODIGO TOTP',
    es: 'CODIGO TOTP',
  );
  static const completeRecovery = LocalizedCopy(
    en: 'Complete recovery',
    pt: 'Concluir recuperacao',
    es: 'Completar recuperacion',
  );
  static const accountRotatedTitle = LocalizedCopy(
    en: 'Account rotated',
    pt: 'Conta rotacionada',
    es: 'Cuenta rotada',
  );
  static const accountRotatedBody = LocalizedCopy(
    en: 'Store the new recovery codes offline. The old ones are no longer valid.',
    pt: 'Guarde os novos recovery codes offline. Os anteriores deixaram de valer imediatamente.',
    es: 'Guarda los nuevos recovery codes offline. Los anteriores dejaron de ser validos.',
  );
  static const newRecoveryCodesLabel = LocalizedCopy(
    en: 'NEW RECOVERY CODES',
    pt: 'NOVOS RECOVERY CODES',
    es: 'NUEVOS RECOVERY CODES',
  );
  static const backToLogin = LocalizedCopy(
    en: 'Back to login',
    pt: 'Voltar ao login',
    es: 'Volver al login',
  );

  static String recoveryCodeLabel(BuildContext context, int index) {
    return LocalizedCopy(
      en: 'Code $index',
      pt: 'Codigo $index',
      es: 'Codigo $index',
    ).resolve(context);
  }

  static String stageTitle(BuildContext context, _RecoveryStage stage) {
    switch (stage) {
      case _RecoveryStage.collect:
        return const LocalizedCopy(
          en: 'Send the recovery codes',
          pt: 'Envie os recovery codes',
          es: 'Envia los recovery codes',
        ).resolve(context);
      case _RecoveryStage.configure:
        return const LocalizedCopy(
          en: 'Configure the new credentials',
          pt: 'Configure as novas credenciais',
          es: 'Configura las nuevas credenciales',
        ).resolve(context);
      case _RecoveryStage.success:
        return const LocalizedCopy(
          en: 'Credentials rotated',
          pt: 'Credenciais rotacionadas',
          es: 'Credenciales rotadas',
        ).resolve(context);
    }
  }

  static String stageMessage(BuildContext context, _RecoveryStage stage) {
    switch (stage) {
      case _RecoveryStage.collect:
        return const LocalizedCopy(
          en: 'Use at least 3 different recovery codes and a valid new recovery phrase. For your privacy, we do not confirm whether an account exists until the recovery is validated.',
          pt: 'Use pelo menos 3 codigos de recuperacao diferentes e uma nova frase valida. Pela sua privacidade, nao confirmamos se a conta existe ate a recuperacao ser validada.',
          es: 'Usa al menos 3 codigos de recuperacion distintos y una nueva frase valida. Por tu privacidad, no confirmamos si la cuenta existe hasta validar la recuperacion.',
        ).resolve(context);
      case _RecoveryStage.configure:
        return const LocalizedCopy(
          en: 'Now register a new TOTP authenticator, bind a new passkey, and submit the final verification before the session expires.',
          pt: 'Agora registre um novo autenticador TOTP, vincule uma nova passkey e envie a verificacao final antes da sessao expirar.',
          es: 'Ahora registra un nuevo autenticador TOTP, vincula una nueva passkey y envia la verificacion final antes de que expire la sesion.',
        ).resolve(context);
      case _RecoveryStage.success:
        return const LocalizedCopy(
          en: 'Your old passphrase, TOTP, passkey, and recovery codes were replaced. Store the new set offline immediately.',
          pt: 'Sua passphrase, TOTP, passkey e recovery codes antigos foram substituidos. Guarde o novo conjunto offline imediatamente.',
          es: 'Tu passphrase, TOTP, passkey y recovery codes anteriores fueron sustituidos. Guarda el nuevo conjunto offline inmediatamente.',
        ).resolve(context);
    }
  }

  static String sessionExpiresIn(BuildContext context, int minutes) {
    return LocalizedCopy(
      en: 'Expires in $minutes minutes',
      pt: 'Expira em $minutes minutos',
      es: 'Expira en $minutes minutos',
    ).resolve(context);
  }

  static String minimumCodesSent(BuildContext context, int count) {
    return LocalizedCopy(
      en: 'Minimum of $count recovery codes already sent',
      pt: 'Minimo de $count recovery codes ja enviado',
      es: 'Minimo de $count recovery codes ya enviado',
    ).resolve(context);
  }
}
