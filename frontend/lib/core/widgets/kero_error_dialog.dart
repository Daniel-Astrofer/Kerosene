import 'package:flutter/material.dart';
import 'package:teste/core/presentation/widgets/app_notification_surface.dart';
import 'package:teste/l10n/l10n_extension.dart';

/// Kerosene Error Types — matches Figma error variants
enum KeroErrorType {
  ledgerInsufficientBalance,
  authUserAlreadyExists,
  authInvalidCredentials,
  authTotpTimeout,
  ledgerPaymentRequestError,
  walletNotFound,
  internalServer,
  ledgerPaymentReceived,
}

extension KeroErrorTypeExt on KeroErrorType {
  String get code {
    switch (this) {
      case KeroErrorType.ledgerInsufficientBalance:
        return 'ERR_LEDGER_INSUFFICIENT_BALANCE';
      case KeroErrorType.authUserAlreadyExists:
        return 'ERR_AUTH_USER_ALREADY_EXISTS';
      case KeroErrorType.authInvalidCredentials:
        return 'ERR_AUTH_INVALID_CREDENTIALS';
      case KeroErrorType.authTotpTimeout:
        return 'ERR_AUTH_TOTP_TIMEOUT';
      case KeroErrorType.ledgerPaymentRequestError:
        return 'ERR_LEDGER_PAYMENT_REQUEST';
      case KeroErrorType.walletNotFound:
        return 'ERR_WALLET_NOT_FOUND';
      case KeroErrorType.internalServer:
        return 'ERR_INTERNAL_SERVER';
      case KeroErrorType.ledgerPaymentReceived:
        return 'ERR_LEDGER_PAYMENT_RECEIVED';
    }
  }

  String get title {
    switch (this) {
      case KeroErrorType.ledgerInsufficientBalance:
        return 'Saldo Insuficiente';
      case KeroErrorType.authUserAlreadyExists:
        return 'Usuário Já Existe';
      case KeroErrorType.authInvalidCredentials:
        return 'Credenciais Inválidas';
      case KeroErrorType.authTotpTimeout:
        return 'Código Expirado';
      case KeroErrorType.ledgerPaymentRequestError:
        return 'Erro no Pagamento';
      case KeroErrorType.walletNotFound:
        return 'Carteira Não Encontrada';
      case KeroErrorType.internalServer:
        return 'Erro Interno';
      case KeroErrorType.ledgerPaymentReceived:
        return 'Pagamento Recebido';
    }
  }

  String get description {
    switch (this) {
      case KeroErrorType.ledgerInsufficientBalance:
        return 'Você não tem saldo suficiente para completar esta transação. Verifique seu saldo ou faça um depósito.';
      case KeroErrorType.authUserAlreadyExists:
        return 'Já existe uma conta registrada com este nome de usuário. Tente fazer login ou use outro nome.';
      case KeroErrorType.authInvalidCredentials:
        return 'Usuário ou senha inválidos. Por favor, verifique suas credenciais e tente novamente.';
      case KeroErrorType.authTotpTimeout:
        return 'O código de autenticação de dois fatores expirou. Aguarde e use o próximo código gerado.';
      case KeroErrorType.ledgerPaymentRequestError:
        return 'Não foi possível processar o pagamento. Verifique os dados inseridos e tente novamente.';
      case KeroErrorType.walletNotFound:
        return 'A carteira especificada não foi encontrada. Verifique se ela ainda está ativa.';
      case KeroErrorType.internalServer:
        return 'Não conseguimos concluir agora. Por favor, tente novamente mais tarde.';
      case KeroErrorType.ledgerPaymentReceived:
        return 'O pagamento foi processado com sucesso.';
    }
  }

  Color get accentColor {
    switch (this) {
      case KeroErrorType.ledgerPaymentReceived:
        return const Color(0xFF00C896);
      default:
        return const Color(0xFFFF3B5C);
    }
  }

  IconData get icon {
    switch (this) {
      case KeroErrorType.ledgerInsufficientBalance:
        return Icons.account_balance_wallet_outlined;
      case KeroErrorType.authUserAlreadyExists:
        return Icons.person_outline_rounded;
      case KeroErrorType.authInvalidCredentials:
        return Icons.lock_outline_rounded;
      case KeroErrorType.authTotpTimeout:
        return Icons.timer_off_outlined;
      case KeroErrorType.ledgerPaymentRequestError:
        return Icons.receipt_long_outlined;
      case KeroErrorType.walletNotFound:
        return Icons.search_off_rounded;
      case KeroErrorType.internalServer:
        return Icons.cloud_off_rounded;
      case KeroErrorType.ledgerPaymentReceived:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Parses a backend error code string into a [KeroErrorType]
KeroErrorType keroErrorFromCode(String code) {
  for (final type in KeroErrorType.values) {
    if (type.code == code) return type;
  }
  return KeroErrorType.internalServer;
}

/// Shows a styled Kerosene error/status overlay matching the Figma designs.
///
/// Usage:
/// ```dart
/// showKeroErrorDialog(context, KeroErrorType.ledgerInsufficientBalance,
///   onSecondaryAction: () { /* go to deposit */ });
/// ```
Future<void> showKeroErrorDialog(
  BuildContext context,
  KeroErrorType errorType, {
  VoidCallback? onSecondaryAction,
  String? secondaryLabel,
  String? customDescription,
}) {
  return showDialog(
    context: context,
    barrierColor:
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
    builder: (_) => KeroErrorDialog(
      errorType: errorType,
      onSecondaryAction: onSecondaryAction,
      secondaryLabel: secondaryLabel,
      customDescription: customDescription,
    ),
  );
}

/// Full-screen error dialog matching Figma Variant error screens
class KeroErrorDialog extends StatelessWidget {
  final KeroErrorType errorType;
  final VoidCallback? onSecondaryAction;
  final String? secondaryLabel;
  final String? customDescription;

  const KeroErrorDialog({
    super.key,
    required this.errorType,
    this.onSecondaryAction,
    this.secondaryLabel,
    this.customDescription,
  });

  @override
  Widget build(BuildContext context) {
    final description = customDescription ?? errorType.description;
    final tone = errorType == KeroErrorType.ledgerPaymentReceived
        ? AppNotificationTone.success
        : AppNotificationTone.error;
    final actions = <AppNotificationAction>[
      AppNotificationAction(
        label: context.l10n.goBack,
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (onSecondaryAction != null)
        AppNotificationAction(
          label: secondaryLabel ?? context.l10n.deposit,
          icon: Icons.add_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            onSecondaryAction!();
          },
        ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: AppNotificationSurface(
        title: errorType.title,
        message: description,
        footerLabel: errorType.code,
        tone: tone,
        leadingIcon: errorType.icon,
        maxMessageLines: 4,
        onClose: () => Navigator.of(context).pop(),
        actions: actions,
      ),
    );
  }
}
