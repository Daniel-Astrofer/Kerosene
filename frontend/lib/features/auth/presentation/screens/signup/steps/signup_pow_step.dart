import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/l10n/l10n_extension.dart';

class SignupPowStep extends ConsumerStatefulWidget {
  final String username;
  final String mnemonic;
  final String accountSecurity;
  final int runId;

  const SignupPowStep({
    super.key,
    required this.username,
    required this.mnemonic,
    required this.accountSecurity,
    required this.runId,
  });

  @override
  ConsumerState<SignupPowStep> createState() => _SignupPowStepState();
}

class _SignupPowStepState extends ConsumerState<SignupPowStep>
    with TickerProviderStateMixin {
  static const List<_PowPhase> _phases = [
    _PowPhase(
      title: 'Solicitando desafio',
      body:
          'O shard está obtendo o desafio PoW único para esta criação de conta.',
      icon: LucideIcons.keyRound,
    ),
    _PowPhase(
      title: 'Dispositivo resolvendo PoW',
      body:
          'O aparelho testa nonces localmente até encontrar a resposta criptográfica válida.',
      icon: LucideIcons.cpu,
    ),
    _PowPhase(
      title: 'Provisionando credenciais',
      body:
          'A resposta foi aceita e o backend está preparando o segredo inicial do autenticador.',
      icon: LucideIcons.shieldCheck,
    ),
  ];

  late final AnimationController _pulseController;
  late final AnimationController _scanController;
  Timer? _phaseTimer;
  int _phaseIndex = 0;
  int _lastStartedRunId = 0;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _maybeStartRun(widget.runId);
  }

  @override
  void didUpdateWidget(covariant SignupPowStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runId != widget.runId) {
      _maybeStartRun(widget.runId);
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _maybeStartRun(int runId) {
    if (runId <= 0 || runId == _lastStartedRunId) {
      return;
    }

    _lastStartedRunId = runId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startSignup();
    });
  }

  void _startSignup() {
    _phaseTimer?.cancel();
    ref.read(authControllerProvider.notifier).clearError();
    setState(() {
      _phaseIndex = 0;
    });

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_phaseIndex >= _phases.length - 1) {
        timer.cancel();
        return;
      }

      setState(() {
        _phaseIndex += 1;
      });
    });

    ref.read(authControllerProvider.notifier).signup(
          username: widget.username,
          password: widget.mnemonic,
          accountSecurity: widget.accountSecurity,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthRequiresTotpSetup) {
        _phaseTimer?.cancel();
        if (mounted) {
          setState(() {
            _phaseIndex = _phases.length - 1;
          });
        }
        return;
      }

      if (next is! AuthError || _dialogOpen) {
        return;
      }

      _phaseTimer?.cancel();
      _dialogOpen = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _dialogOpen = false;
          return;
        }

        showCustomErrorDialog(
          context,
          next.message,
          title: 'Falha ao resolver o PoW',
          onRetry: () {
            _dialogOpen = false;
            _startSignup();
          },
          onGoBack: () {
            _dialogOpen = false;
            ref.read(authControllerProvider.notifier).clearError();
          },
        );
      });
    });

    final phase = _phases[_phaseIndex.clamp(0, _phases.length - 1)];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.usernameLoadingPow,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 26,
                  letterSpacing: -0.4,
                ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Este aparelho está executando a prova de trabalho exigida pelo backend. Quando a resposta for aceita, você segue automaticamente para configurar o autenticador.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnimatedPowDevice(
                  pulseController: _pulseController,
                  scanController: _scanController,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AnimatedGlyphIcon(
                            icon: phase.icon,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              phase.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                          _StatusChip(isLoading: isLoading),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        phase.body,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...List.generate(_phases.length, (index) {
                        final item = _phases[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == _phases.length - 1 ? 0 : AppSpacing.md,
                          ),
                          child: _PhaseRow(
                            title: item.title,
                            subtitle: item.body,
                            icon: item.icon,
                            isDone: index < _phaseIndex,
                            isCurrent: index == _phaseIndex,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            isLoading
                ? 'Mantenha o aplicativo aberto por alguns segundos enquanto o cálculo termina.'
                : 'Aguardando o backend concluir a transição para o próximo passo.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AnimatedPowDevice extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController scanController;

  const _AnimatedPowDevice({
    required this.pulseController,
    required this.scanController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 300,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseController, scanController]),
        builder: (context, _) {
          final pulse = pulseController.value;
          final scan = scanController.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.92 + (pulse * 0.14),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.22),
                        AppColors.primary.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.78 + (pulse * 0.18),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.18),
                    ),
                  ),
                ),
              ),
              Container(
                width: 180,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.surface.withOpacity(0.85),
                                const Color(0xFF070A12),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PowGridPainter(progress: scan),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        top: 36 + (scan * 130),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accent.withOpacity(0.85),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.25),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedGlyphIcon(
                              icon: LucideIcons.smartphone,
                              size: 42,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'POW',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    letterSpacing: 4,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'NONCE SEARCH',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    letterSpacing: 2.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PowGridPainter extends CustomPainter {
  final double progress;

  const _PowGridPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final activePaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.18)
      ..strokeWidth = 1.5;
    final activeY = 28 + (progress * (size.height - 56));

    canvas.drawLine(
      Offset(18, activeY),
      Offset(size.width - 18, activeY),
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PowGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PhaseRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;

  const _PhaseRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDone
        ? AppColors.success
        : isCurrent
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(isCurrent ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.22)),
          ),
          child: Center(
            child: AnimatedGlyphIcon(
              icon: isDone ? LucideIcons.check : icon,
              size: 16,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: isCurrent || isDone
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isCurrent || isDone
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _StatusChip extends StatelessWidget {
  final bool isLoading;

  const _StatusChip({
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLoading ? AppColors.warning : AppColors.success;
    final label = isLoading ? 'EM PROCESSO' : 'CONCLUÍDO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PowPhase {
  final String title;
  final String body;
  final IconData icon;

  const _PowPhase({
    required this.title,
    required this.body,
    required this.icon,
  });
}
