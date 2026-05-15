import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/core/widgets/bouncing_button.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';

class SignupFinalPaymentStep extends ConsumerStatefulWidget {
  final String sessionId;
  final String username;
  final String password;

  const SignupFinalPaymentStep({
    super.key,
    required this.sessionId,
    required this.username,
    required this.password,
  });

  @override
  ConsumerState<SignupFinalPaymentStep> createState() =>
      _SignupFinalPaymentStepState();
}

class _SignupFinalPaymentStepState
    extends ConsumerState<SignupFinalPaymentStep> {
  late final TextEditingController _txidController;

  @override
  void initState() {
    super.initState();
    _txidController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(authControllerProvider.notifier)
          .getOnboardingLink(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _txidController.dispose();
    super.dispose();
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço copiado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        showCustomErrorDialog(context, next.message);
      }
    });

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: authState is AuthPaymentRequired
                ? _buildPaymentUI(authState)
                : authState is AuthLoading
                    ? const Center(
                        child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator(),
                      ))
                    : const Center(
                        child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text('Aguardando dados de pagamento...'),
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentUI(AuthPaymentRequired state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(
          'ATIVAR CONTA',
          style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontSize: 28,
                letterSpacing: 0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Para finalizar a criação da sua carteira soberana, é necessário um depósito inicial para cobrir as taxas de abertura de canal e registro na mainnet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Amount Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'VALOR A DEPOSITAR',
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${state.amountBtc.toStringAsFixed(8)} BTC',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // QR Code
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: QrImageView(
              data: state.depositAddress,
              version: QrVersions.auto,
              size: 180.0,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Address Field
        Text(
          'ENDEREÇO BTC (ON-CHAIN)',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.depositAddress,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyAddress(state.depositAddress),
                child: Icon(LucideIcons.copy,
                    size: 18, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        Text(
          'TXID DA TRANSAÇÃO',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _txidController,
          enabled: !state.isSubmitting &&
              state.paymentStatus != 'verifying_onboarding' &&
              state.paymentStatus != 'completed',
          style: AppTypography.bodySmall.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: 'Cole aqui o TXID on-chain',
            hintStyle: AppTypography.bodySmall.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
          minLines: 1,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.lg),

        if (state.statusMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                if (state.isSubmitting ||
                    state.paymentStatus == 'verifying_onboarding') ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    state.statusMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        BouncingButton(
          text: state.paymentStatus == 'completed'
              ? 'PAGAMENTO CONFIRMADO'
              : state.paymentStatus == 'verifying_onboarding'
                  ? 'AGUARDANDO CONFIRMAÇÕES'
                  : state.isSubmitting
                      ? 'VALIDANDO TXID...'
                      : 'CONFIRMAR TRANSAÇÃO',
          onPressed: state.isSubmitting ||
                  state.paymentStatus == 'verifying_onboarding' ||
                  state.paymentStatus == 'completed'
              ? null
              : () {
                  ref
                      .read(authControllerProvider.notifier)
                      .submitOnboardingPayment(
                        linkId: state.paymentLinkId,
                        txid: _txidController.text,
                        username: widget.username,
                        password: widget.password,
                      );
                },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'A conta será ativada automaticamente após 3 confirmações na rede.',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.6),
                fontSize: 10,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
