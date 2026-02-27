import 'package:flutter/material.dart';
import 'animated_error_popup.dart';

String _getFriendlyMessage(String message) {
  final lower = message.toLowerCase();

  if (lower.contains("insufficient balance") ||
      lower.contains("saldo insuficiente")) {
    return "Insufficient balance to complete this transaction.";
  }
  if (lower.contains("user not found") ||
      lower.contains("usuário não existe") ||
      lower.contains("user does not exist")) {
    return "The recipient user could not be found. Please check the address or username.";
  }
  if (lower.contains("invalid address") ||
      lower.contains("endereço inválido")) {
    return "The Bitcoin address provided is invalid. Please verify and try again.";
  }
  if (lower.contains("timeout") || lower.contains("tempo esgotado")) {
    return "Connection timeout. Please check your internet and try again.";
  }
  if (lower.contains("401") ||
      lower.contains("unauthorized") ||
      lower.contains("não autorizado")) {
    return "Session expired. Please log in again.";
  }

  // Se tem json puro
  if (message.contains("{") && message.contains("}")) {
    return "An unexpected error occurred. Please try again later.";
  }

  return message;
}

void showCustomErrorDialog(BuildContext context, String message) {
  final friendlyMessage = _getFriendlyMessage(message);
  AnimatedErrorPopup.show(context, message: friendlyMessage);
}
