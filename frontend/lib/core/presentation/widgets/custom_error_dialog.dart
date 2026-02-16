import 'package:flutter/material.dart';
import 'dart:ui';

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

  // If it's a raw JSON response or technical error, try to extract a msg or return generic
  if (message.contains("{") && message.contains("}")) {
    return "An unexpected error occurred. Please try again later.";
  }

  return message;
}

void showCustomErrorDialog(BuildContext context, String message) {
  final friendlyMessage = _getFriendlyMessage(message);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.8),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: anim1,
          child: _buildDialogContent(ctx, friendlyMessage),
        ),
      );
    },
  );
}

Widget _buildDialogContent(BuildContext context, String message) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Pulsing Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                    ),
                  );
                },
                onEnd:
                    () {}, // Handled by repeating if needed, but here simple pulse on entry
              ),
              const SizedBox(height: 24),

              const Text(
                "Attention",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2F4E), Color(0xFF1A1F3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Center(
                    child: Text(
                      "UNDERSTOOD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
