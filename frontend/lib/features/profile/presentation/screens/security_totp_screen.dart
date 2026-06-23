import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/core/presentation/widgets/app_notice.dart';
import 'package:kerosene/core/presentation/widgets/kerosene_screen_background.dart';
import 'package:kerosene/core/presentation/widgets/tor_loading_dots.dart';
import 'package:kerosene/core/theme/app_spacing.dart';
import 'package:kerosene/core/theme/app_typography.dart';
import 'package:kerosene/core/theme/monochrome_theme.dart';
import 'package:kerosene/core/utils/error_translator.dart';
import 'package:kerosene/design_system/icons.dart';
import 'package:kerosene/features/auth/controller/auth_providers.dart';
import 'package:kerosene/features/security/presentation/providers/security_provider.dart';

import 'security_settings_components.dart';

class SecurityTotpScreen extends ConsumerStatefulWidget {
  const SecurityTotpScreen({super.key});

  @override
  ConsumerState<SecurityTotpScreen> createState() => _SecurityTotpScreenState();
}

class _SecurityTotpScreenState extends ConsumerState<SecurityTotpScreen> {
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

  void _refreshSecurityProviders() {
    ref.invalidate(securityStatusProvider);
    ref.invalidate(backupCodesStatusProvider);
    ref.invalidate(accountSecurityProfileProvider);
  }

  Future<void> _beginTotpSetup() async {
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.setupTotp();
      result.fold(
        (failure) {
          AppNotice.showError(
            context,
            title: context.tr.securityTotpFailureTitle,
            message: ErrorTranslator.translate(
              context.tr,
              failure.toString(),
            ),
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
        title: context.tr.securityInvalidCodeTitle,
        message: context.tr.securityTotpCodeRequiredMessage,
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
            title: context.tr.securityTotpFailureTitle,
            message: ErrorTranslator.translate(
              context.tr,
              failure.toString(),
            ),
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
            title: context.tr.securityTotpEnabledTitle,
            message: context.tr.securityTotpEnabledMessage,
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
            title: context.tr.securityTotpDisableFailedTitle,
            message: ErrorTranslator.translate(
              context.tr,
              failure.toString(),
            ),
          );
        },
        (_) {
          setState(() {
            _setupUri = '';
            _setupSecret = '';
            _latestGeneratedCodes = const [];
            _totpCodeController.clear();
          });
          _refreshSecurityProviders();
          AppNotice.showSuccess(
            context,
            title: context.tr.securityTotpDisabledTitle,
            message: context.tr.securityTotpDisabledMessage,
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
            title: context.tr.securityBackupRegenerateFailedTitle,
            message: ErrorTranslator.translate(
              context.tr,
              failure.toString(),
            ),
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
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
                  context.tr.securityBackupCodesTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: monoMutedTextColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr.securityBackupCodesBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: monoMutedTextColor,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                          decoration: monochromePanelDecoration(
                            color: monoSurfaceAltColor,
                            borderColor: monoBorderStrongColor,
                            showShadow: false,
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: monoTextColor,
                              fontFamily: AppTypography.financialFontFamily,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityAsync = ref.watch(securityStatusProvider);
    final backupCodesAsync = ref.watch(backupCodesStatusProvider);

    return KeroseneScreenBackground(
      useScroll: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotpScreenHeader(onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: AppSpacing.xl),
            securityAsync.when(
              data: (security) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotpOverviewCard(totpEnabled: security.totpEnabled),
                  const SizedBox(height: AppSpacing.md),
                  if (_setupUri.isNotEmpty)
                    TotpSetupCard(
                      setupUri: _setupUri,
                      setupSecret: _setupSecret,
                      controller: _totpCodeController,
                      busy: _busy,
                      onVerify: _verifyTotpSetup,
                    )
                  else
                    SecuritySectionCard(
                      title: context.tr.securityTotpOptionalTitle,
                      subtitle: security.totpEnabled
                          ? context.tr.securityTotpEnabledSubtitle
                          : context.tr.securityTotpDisabledSubtitle,
                      actionLabel: security.totpEnabled
                          ? context.tr.securityDisableTotpAction.toUpperCase()
                          : context.tr.securityEnableTotpAction.toUpperCase(),
                      destructive: security.totpEnabled,
                      onAction: _busy
                          ? null
                          : security.totpEnabled
                              ? _disableTotp
                              : _beginTotpSetup,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  backupCodesAsync.when(
                    data: (backupStatus) => SecuritySectionCard(
                      title: context.tr.securityBackupCodesTitle,
                      subtitle: security.totpEnabled
                          ? context.tr.securityBackupCodesRemaining(
                              backupStatus.remainingCodes,
                            )
                          : context.tr.securityBackupCodesLockedSubtitle,
                      actionLabel: security.totpEnabled
                          ? context.tr.securityRegenerateCodesAction
                              .toUpperCase()
                          : context.tr.securityWaitingTotpAction.toUpperCase(),
                      disabled: !security.totpEnabled || _busy,
                      onAction:
                          security.totpEnabled ? _regenerateBackupCodes : null,
                      trailing: _latestGeneratedCodes.isNotEmpty
                          ? TextButton(
                              onPressed: () =>
                                  _showBackupCodesSheet(_latestGeneratedCodes),
                              style: monochromeTextButtonStyle(),
                              child: Text(
                                context.tr.securityViewLatestAction
                                    .toUpperCase(),
                              ),
                            )
                          : null,
                    ),
                    loading: () => const SecurityLoadingCard(),
                    error: (_, __) => SecurityErrorCard(
                      title: context.tr.securityBackupCodesTitle,
                      body: context.tr.securityBackupCodesLoadError,
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _TotpBusyCard(),
                  ],
                ],
              ),
              loading: () => const SecurityLoadingCard(),
              error: (_, __) => SecurityErrorCard(
                title: context.tr.twoFactorAuth,
                body: context.tr.securityStatusLoadError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotpScreenHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _TotpScreenHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(KeroseneIcons.back),
          style: IconButton.styleFrom(
            backgroundColor: monoSurfaceAltColor,
            foregroundColor: monoTextColor,
            minimumSize: const Size(42, 42),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            side: const BorderSide(color: monoBorderStrongColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.twoFactorAuth,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: monoTextColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure e valide o código TOTP usado para proteger acessos e transações sensíveis.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: monoMutedTextColor,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotpOverviewCard extends StatelessWidget {
  final bool totpEnabled;

  const _TotpOverviewCard({required this.totpEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: monochromePanelDecoration(
        color: monoSurfaceColor,
        borderColor: monoBorderStrongColor,
      ),
      child: Row(
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
            child: const Icon(KeroseneIcons.verified, color: monoTextColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totpEnabled ? 'TOTP ativo' : 'TOTP pendente',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: monoTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  totpEnabled
                      ? 'Sua conta exige um código temporário do aplicativo autenticador.'
                      : 'Ative o autenticador e valide o primeiro código de 6 dígitos para concluir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: monoMutedTextColor,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SecurityStatusPill(totpEnabled ? 'ATIVO' : 'INATIVO', totpEnabled),
        ],
      ),
    );
  }
}

class _TotpBusyCard extends StatelessWidget {
  const _TotpBusyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: monochromePanelDecoration(
        color: monoSurfaceAltColor,
        borderColor: monoBorderColor,
        showShadow: false,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            height: 24,
            child: Center(
              child: TorLoadingDots(
                dotSize: 4,
                spacing: 5,
                travel: 7,
                color: monoMutedTextColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Validando segurança da conta',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: monoMutedTextColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
