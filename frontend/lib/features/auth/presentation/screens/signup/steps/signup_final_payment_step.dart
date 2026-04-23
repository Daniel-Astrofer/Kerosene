import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/constants/app_copy.dart';
import 'package:teste/core/presentation/widgets/animated_glyph_icon.dart';
import 'package:teste/core/presentation/widgets/app_notice.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/theme/app_typography.dart';
import 'package:teste/features/auth/controller/auth_controller.dart';
import 'package:teste/features/auth/presentation/screens/signup/widgets/signup_step_ui.dart';

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
      ref.read(authControllerProvider.notifier).getOnboardingLink(
            sessionId: widget.sessionId,
            username: widget.username,
            password: widget.password,
          );
    });
  }

  @override
  void dispose() {
    _txidController.dispose();
    super.dispose();
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    AppNotice.showSuccess(
      context,
      title: AppCopy.signupFinalPaymentAddressCopiedTitle.resolve(context),
      message: AppCopy.signupFinalPaymentAddressCopiedBody.resolve(context),
    );
  }

  void _copyAmount(double amount) {
    Clipboard.setData(
      ClipboardData(text: amount.toStringAsFixed(8)),
    );
    AppNotice.showSuccess(
      context,
      title: AppCopy.signupFinalPaymentAmountCopiedTitle.resolve(context),
      message: AppCopy.signupFinalPaymentAmountCopiedBody.resolve(context),
    );
  }

  Future<void> _pasteTxid() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.trim().isEmpty) {
      return;
    }

    setState(() {
      _txidController.text = data.text!.trim();
    });
  }

  String _bitcoinUri(AuthPaymentRequired state) {
    return 'bitcoin:${state.depositAddress}?amount=${state.amountBtc.toStringAsFixed(8)}';
  }

  String _titleForState(AuthPaymentRequired state) {
    return AppCopy.signupFinalPaymentTitle(
      context,
      paymentStatus: state.paymentStatus,
    );
  }

  String _subtitleForState(AuthPaymentRequired state) {
    return AppCopy.signupFinalPaymentSubtitle(
      context,
      paymentStatus: state.paymentStatus,
    );
  }

  String _highlightValue(AuthPaymentRequired state) {
    return AppCopy.signupFinalPaymentHighlightValue(
      context,
      paymentStatus: state.paymentStatus,
      amountBtc: state.amountBtc.toStringAsFixed(8),
    );
  }

  String _highlightHint(AuthPaymentRequired state) {
    if (state.statusMessage != null && state.statusMessage!.isNotEmpty) {
      return state.statusMessage!;
    }
    return AppCopy.signupFinalPaymentDefaultHint(context);
  }

  String _ctaLabel(AuthPaymentRequired state) {
    return AppCopy.signupFinalPaymentCta(
      context,
      paymentStatus: state.paymentStatus,
      isSubmitting: state.isSubmitting,
    );
  }

  bool _isActionLocked(AuthPaymentRequired state) {
    return state.isSubmitting ||
        state.paymentStatus == 'verifying_onboarding' ||
        state.paymentStatus == 'expired';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        showCustomErrorDialog(context, next.message);
      }
    });

    if (authState is AuthPaymentRequired) {
      return _buildPaymentUI(authState);
    }

    if (authState is AuthLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Text(
        AppCopy.signupFinalPaymentLoading.resolve(context),
      ),
    );
  }

  Widget _buildPaymentUI(AuthPaymentRequired state) {
    final bitcoinUri = _bitcoinUri(state);
    final isLocked = _isActionLocked(state);

    return SignupStepLayout(
      eyebrow: AppCopy.signupFinalPaymentEyebrow.resolve(context),
      title: _titleForState(state),
      subtitle: _subtitleForState(state),
      icon: signupStatusIconForPayment(state.paymentStatus),
      tone: signupToneForPayment(state.paymentStatus),
      highlightLabel: state.paymentStatus == 'pending'
          ? AppCopy.signupFinalPaymentHighlightExactAmount.resolve(context)
          : AppCopy.signupFinalPaymentHighlightStatus.resolve(context),
      highlightValue: _highlightValue(state),
      highlightHint: _highlightHint(state),
      chips: [
        AppCopy.signupFinalPaymentChipAddress.resolve(context),
        AppCopy.signupFinalPaymentChipTxid.resolve(context),
        AppCopy.signupFinalPaymentChipConfirmations.resolve(context),
      ],
      children: [
        _OnboardingPollingCard(state: state),
        const SizedBox(height: AppSpacing.md),
        SignupPanel(
          tone: SignupSurfaceTone.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppCopy.signupFinalPaymentSectionCopy.resolve(context),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _MetricTile(
                label: AppCopy.signupFinalPaymentExactAmountLabel.resolve(
                  context,
                ),
                value: '${state.amountBtc.toStringAsFixed(8)} BTC',
                onCopy: () => _copyAmount(state.amountBtc),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
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
                    data: bitcoinUri,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _MetricTile(
                label: AppCopy.signupFinalPaymentBtcAddressLabel.resolve(
                  context,
                ),
                value: state.depositAddress,
                isMonospace: true,
                onCopy: () => _copyAddress(state.depositAddress),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SignupPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppCopy.signupFinalPaymentSectionTxid.resolve(context),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pasteTxid,
                    icon: const Icon(
                      LucideIcons.clipboardPaste,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      AppCopy.signupFinalPaymentPaste.resolve(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppCopy.signupFinalPaymentTxidBody.resolve(context),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _txidController,
                enabled: !isLocked,
                style: AppTypography.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: AppCopy.signupFinalPaymentTxidHint.resolve(context),
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.done,
                minLines: 1,
                maxLines: 2,
              ),
              if (state.submittedTxid != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppCopy.signupFinalPaymentSubmittedTxid(
                    context,
                    txid: state.submittedTxid!,
                  ),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          SignupInlineNotice(
            icon: LucideIcons.alertTriangle,
            title: AppCopy.signupFinalPaymentValidationTitle.resolve(context),
            message: state.errorMessage!,
            tone: SignupSurfaceTone.warning,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SignupInlineNotice(
          icon: state.paymentStatus == 'completed'
              ? LucideIcons.badgeCheck
              : LucideIcons.receipt,
          title: AppCopy.signupFinalPaymentTrackTitle.resolve(context),
          message: _highlightHint(state),
          tone: signupToneForPayment(state.paymentStatus),
        ),
      ],
      footer: SignupPrimaryFooter(
        text: _ctaLabel(state),
        isLoading: state.isSubmitting,
        onPressed: isLocked
            ? null
            : state.paymentStatus == 'completed'
                ? () {
                    ref
                        .read(authControllerProvider.notifier)
                        .continueAfterOnboardingPayment(
                          username: widget.username,
                          password: widget.password,
                        );
                  }
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
        icon: state.paymentStatus == 'completed'
            ? LucideIcons.badgeCheck
            : LucideIcons.arrowRight,
        caption: AppCopy.signupFinalPaymentFooterCaption(
          context,
          paymentStatus: state.paymentStatus,
        ),
      ),
    );
  }
}

class _OnboardingPollingCard extends StatelessWidget {
  final AuthPaymentRequired state;

  const _OnboardingPollingCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPending = state.paymentStatus == 'pending';
    final isExpired = state.paymentStatus == 'expired';
    final isSuccess = state.paymentStatus == 'completed' ||
        state.paymentStatus == 'paid' ||
        state.paymentStatus == 'verifying_onboarding';
    final accent = isExpired
        ? const Color(0xFFEF4444)
        : isSuccess
            ? const Color(0xFF10B981)
            : const Color(0xFFFBBF24);

    return SignupPanel(
      tone: signupToneForPayment(state.paymentStatus),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: isPending
                ? SizedBox(
                    key: const ValueKey('pending'),
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: accent,
                    ),
                  )
                : AnimatedGlyphIcon(
                    key: ValueKey(state.paymentStatus),
                    icon: isExpired
                        ? LucideIcons.alertTriangle
                        : LucideIcons.badgeCheck,
                    size: 28,
                    color: accent,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? AppCopy.signupFinalPaymentPollingExpired.resolve(
                          context,
                        )
                      : isSuccess
                          ? AppCopy.signupFinalPaymentPollingDetected.resolve(
                              context,
                            )
                          : AppCopy.signupFinalPaymentPollingRunning.resolve(
                              context,
                            ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  state.statusMessage ??
                      AppCopy.signupFinalPaymentPollingBody.resolve(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.72),
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;
  final VoidCallback onCopy;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.onCopy,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: (isMonospace
                          ? AppTypography.bodySmall.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            )
                          : Theme.of(context).textTheme.displaySmall)
                      ?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: AnimatedGlyphIcon(
              icon: LucideIcons.copy,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
