import 'package:flutter/material.dart';
import 'glass_container.dart';

class AnimatedErrorPopup extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;

  const AnimatedErrorPopup({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = false,
  });

  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
  }) {
    // Basic translation matching for titles
    String title = isSuccess ? 'Sucesso' : 'Erro na Transação';
    if (message.toLowerCase().contains('saldo') ||
        message.toLowerCase().contains('fundos') ||
        message.toLowerCase().contains('insuficiente')) {
      title = 'Saldo Insuficiente';
    } else if (message.toLowerCase().contains('conexão') ||
        message.toLowerCase().contains('servidor')) {
      title = 'Erro de Rede';
    } else if (message.toLowerCase().contains('autenticação') ||
        message.toLowerCase().contains('senha') ||
        message.toLowerCase().contains('código')) {
      title = 'Falha de Acesso';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Error',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedErrorPopup(
              title: title,
              message: message,
              isSuccess: isSuccess,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<AnimatedErrorPopup> createState() => _AnimatedErrorPopupState();
}

class _AnimatedErrorPopupState extends State<AnimatedErrorPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isSuccess
        ? const Color(0xFF00FF94)
        : const Color(0xFFFF0055);

    // Split message logic: "Description. Faltam X BTC"
    String mainMessage = widget.message;
    String? extraData;

    if (widget.message.contains('. Faltam ')) {
      final parts = widget.message.split('. Faltam ');
      mainMessage = parts[0];
      extraData = 'Faltam ${parts[1]}';
    } else if (widget.message.contains('\nFaltam ')) {
      final parts = widget.message.split('\nFaltam ');
      mainMessage = parts[0];
      extraData = 'Faltam ${parts[1]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GlassContainer(
        width: double.infinity,
        borderRadius: BorderRadius.circular(32),
        blur: 20,
        opacity: 0.1,
        border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Centered Animated Icon
            RepaintBoundary(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: baseColor,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Main Message
            Text(
              mainMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // Extra Data Section (Structured)
            if (extraData != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: baseColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: baseColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        extraData,
                        style: TextStyle(
                          color: baseColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
