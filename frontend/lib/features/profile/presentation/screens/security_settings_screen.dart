import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/providers/biometric_provider.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/controller/auth_providers.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final _totpCodeController = TextEditingController();

  String _setupUri = '';
  String _setupSecret = '';
  List<String> _latestGeneratedCodes = const [];
  bool _busy = false;

  @override
  void dispose() {
    _totpCodeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    AppNotice.showSuccess(
      context,
      title: 'Copiado',
      message: '$label copiado para a área de transferência.',
    );
  }

  void _refreshSecurityProviders() {
    ref.invalidate(securityStatusProvider);
    ref.invalidate(backupCodesStatusProvider);
  }

  Future<void> _beginTotpSetup() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.setupTotp();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: 'Falha no TOTP',
            message: failure.message,
          );
        },
        (setup) {
          setState(() {
            _setupUri = setup.otpUri;
            _setupSecret = setup.secret;
            _totpCodeController.clear();
          });
        },
      );
    });
  }

  Future<void> _verifyTotpSetup() async {
    if (_totpCodeController.text.trim().length != 6) {
      AppNotice.showError(
        context,
        title: 'Código inválido',
        message: 'Digite os 6 dígitos do autenticador.',
      );
      return;
    }

    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyTotpSetup(
        totpCode: _totpCodeController.text.trim(),
      );
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: 'Falha no TOTP',
            message: failure.message,
          );
        },
        (status) {
          setState(() {
            _setupUri = '';
            _setupSecret = '';
            _latestGeneratedCodes = status.newlyGeneratedCodes;
          });
          _refreshSecurityProviders();
          AppNotice.showSuccess(
            context,
            title: 'TOTP ativado',
            message: 'A conta agora está protegida com autenticador.',
          );
          if (status.newlyGeneratedCodes.isNotEmpty) {
            _showBackupCodesSheet(status.newlyGeneratedCodes);
          }
        },
      );
    });
  }

  Future<void> _disableTotp() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.disableTotp();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: 'Falha ao desativar',
            message: failure.message,
          );
        },
        (_) {
          setState(() {
            _setupUri = '';
            _setupSecret = '';
            _latestGeneratedCodes = const [];
          });
          _refreshSecurityProviders();
          AppNotice.showSuccess(
            context,
            title: 'TOTP desativado',
            message: 'A conta voltou ao estado não protegido.',
          );
        },
      );
    });
  }

  Future<void> _regenerateBackupCodes() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.regenerateBackupCodes();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: 'Falha ao regenerar',
            message: failure.message,
          );
        },
        (status) {
          setState(() {
            _latestGeneratedCodes = status.newlyGeneratedCodes;
          });
          _refreshSecurityProviders();
          if (status.newlyGeneratedCodes.isNotEmpty) {
            _showBackupCodesSheet(status.newlyGeneratedCodes);
          }
        },
      );
    });
  }

  void _showBackupCodesSheet(List<String> codes) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: authenticatedSurfaceBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'BACKUP CODES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Guarde estes códigos fora do dispositivo. Eles ficam em Configurações > Segurança.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: codes
                    .map(
                      (code) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: Color(0xFF7DD3A0),
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => _copy(codes.join('\n'), 'Backup codes'),
                child: const Text('COPIAR'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioState = ref.watch(biometricProvider);
    final securityAsync = ref.watch(securityStatusProvider);
    final backupCodesAsync = ref.watch(backupCodesStatusProvider);

    return CyberBackground.authenticated(
      useScroll: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segurança',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Passkey, TOTP opcional, backup codes e estado de proteção da conta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white70,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            securityAsync.when(
              data: (security) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (security.unprotected)
                    _BannerCard(
                      color: const Color(0xFFF59E0B),
                      icon: Icons.warning_amber_rounded,
                      title: 'Conta não protegida',
                      body: security.warningMessage.isNotEmpty
                          ? security.warningMessage
                          : 'Ative TOTP para adicionar uma camada opcional de proteção.',
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _StatusCard(
                    security: security,
                    biometricEnabled: bioState.isEnabled,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Passkey',
                    subtitle: security.passkeyRegistered
                        ? 'A passkey está registrada para esta conta.'
                        : 'Registre uma passkey neste aparelho.',
                    actionLabel: 'REGISTRAR PASSKEY',
                    onAction: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .registerPasskey();
                      _refreshSecurityProviders();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_setupUri.isNotEmpty) ...[
                    _TotpSetupCard(
                      setupUri: _setupUri,
                      setupSecret: _setupSecret,
                      controller: _totpCodeController,
                      busy: _busy,
                      onCopySecret: () => _copy(_setupSecret, 'Segredo TOTP'),
                      onVerify: _verifyTotpSetup,
                    ),
                  ] else
                    _SectionCard(
                      title: 'TOTP opcional',
                      subtitle: security.totpEnabled
                          ? 'Autenticador ativo. O aviso de conta não protegida desaparece.'
                          : 'Sem TOTP. A conta fica marcada como não protegida.',
                      actionLabel:
                          security.totpEnabled ? 'DESATIVAR TOTP' : 'ATIVAR TOTP',
                      destructive: security.totpEnabled,
                      onAction:
                          security.totpEnabled ? _disableTotp : _beginTotpSetup,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  backupCodesAsync.when(
                    data: (backupStatus) => _SectionCard(
                      title: 'Backup codes',
                      subtitle: security.totpEnabled
                          ? '${backupStatus.remainingCodes} códigos restantes. Eles ficam em Configurações > Segurança.'
                          : 'Ative o TOTP para liberar backup codes.',
                      actionLabel: security.totpEnabled
                          ? 'REGERAR CÓDIGOS'
                          : 'AGUARDANDO TOTP',
                      disabled: !security.totpEnabled,
                      onAction:
                          security.totpEnabled ? _regenerateBackupCodes : null,
                      trailing: _latestGeneratedCodes.isNotEmpty
                          ? TextButton(
                              onPressed: () =>
                                  _showBackupCodesSheet(_latestGeneratedCodes),
                              child: const Text('VER ÚLTIMOS'),
                            )
                          : null,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => const _ErrorCard(
                      title: 'Backup codes',
                      body: 'Não foi possível consultar os códigos de backup.',
                    ),
                  ),
                ],
              ),
              loading: () => const _LoadingCard(),
              error: (_, __) => const _ErrorCard(
                title: 'Segurança',
                body: 'Não foi possível consultar o estado de segurança da conta.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  const _BannerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final dynamic security;
  final bool biometricEnabled;

  const _StatusCard({
    required this.security,
    required this.biometricEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado atual',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusPill('Senha forte', security.passwordConfigured),
              _StatusPill('Passkey', security.passkeyRegistered),
              _StatusPill('TOTP', security.totpEnabled),
              _StatusPill('Inbound', security.inboundEnabled),
              _StatusPill('Biometria local', biometricEnabled),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool enabled;

  const _StatusPill(this.label, this.enabled);

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF7DD3A0) : const Color(0xFFF87171);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool destructive;
  final bool disabled;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.destructive = false,
    this.disabled = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFF87171) : const Color(0xFF7AA2F7);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white70,
                  height: 1.45,
                ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerRight, child: trailing!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: disabled ? Colors.white24 : accent,
              foregroundColor: disabled ? Colors.white54 : Colors.black,
            ),
            onPressed: disabled ? null : onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _TotpSetupCard extends StatelessWidget {
  final String setupUri;
  final String setupSecret;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onCopySecret;
  final VoidCallback onVerify;

  const _TotpSetupCard({
    required this.setupUri,
    required this.setupSecret,
    required this.controller,
    required this.busy,
    required this.onCopySecret,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ativar TOTP',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: setupUri,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            setupSecret,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7DD3A0),
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onCopySecret,
            child: const Text('Copiar segredo'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Código do autenticador',
              hintText: '000000',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: busy ? null : onVerify,
            child: Text(busy ? 'VALIDANDO...' : 'VALIDAR TOTP'),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String body;

  const _ErrorCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      color: const Color(0xFFF87171),
      icon: Icons.error_outline_rounded,
      title: title,
      body: body,
    );
  }
}
