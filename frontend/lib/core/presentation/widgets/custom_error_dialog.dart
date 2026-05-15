import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';

void showCustomErrorDialog(
  BuildContext context,
  String message, {
  String title = 'ERRO',
  VoidCallback? onRetry,
  VoidCallback? onGoBack,
}) {
  showDialog(
    context: context,
    builder: (context) => CustomErrorDialog(
      title: title,
      message: message,
      onRetry: onRetry,
      onGoBack: onGoBack,
    ),
  );
}

class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const CustomErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CyberTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CyberTheme.neonRed.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: CyberTheme.neonRed.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: CyberTheme.neonRed,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              title.toUpperCase(),
              style: CyberTheme.heading(size: 20, color: CyberTheme.neonRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onRetry != null || onGoBack != null)
              Row(
                children: [
                  if (onGoBack != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onGoBack!();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.7),
                          side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.24)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('VOLTAR'),
                      ),
                    ),
                  if (onGoBack != null && onRetry != null)
                    const SizedBox(width: 12),
                  if (onRetry != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry!();
                        },
                        style: CyberTheme.neonButton(CyberTheme.neonRed),
                        child: const Text('TENTAR NOVAMENTE'),
                      ),
                    ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: CyberTheme.neonButton(CyberTheme.neonRed),
                  child: const Text('ENTENDIDO'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
