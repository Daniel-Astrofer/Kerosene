import 'package:flutter/material.dart';

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
        return 'Ocorreu um erro inesperado em nossos servidores. Por favor, tente novamente mais tarde.';
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
    barrierColor: Colors.black.withValues(alpha: 0.85),
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
    final color = errorType.accentColor;
    final description = customDescription ?? errorType.description;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(errorType.icon, color: color, size: 38),
            ),

            const SizedBox(height: 20),

            // Error code
            Text(
              errorType.code,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              errorType.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            // Description
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Primary action: Back / Close
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  elevation: 0,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Secondary action (optional)
            if (onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSecondaryAction!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryLabel ?? 'Depositar',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
