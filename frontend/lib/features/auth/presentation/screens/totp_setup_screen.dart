import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

class TotpSetupScreen extends ConsumerStatefulWidget {
  final String username;
  final String passphrase;
  final String totpSecret; // URL otpauth ou secret raw

  const TotpSetupScreen({
    super.key,
    required this.username,
    required this.passphrase,
    required this.totpSecret,
  });

  @override
  ConsumerState<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends ConsumerState<TotpSetupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se recebeu apenas o secret, montar a URL otpauth
    String qrData = widget.totpSecret;
    if (!widget.totpSecret.startsWith('otpauth://')) {
      qrData =
          'otpauth://totp/Kerosene:${widget.username}?secret=${widget.totpSecret}&issuer=Kerosene';
    }

    // Listener para redirecionar após sucesso
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const KeroseneLogo(size: 60),
                const SizedBox(height: 32),
                const Text(
                  'Segurança em Duas Etapas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Escaneie o QR Code com seu app autenticador (Google Auth, Authy, etc).',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    foregroundColor: const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 32),

                // Secret em texto (caso não consiga ler QR)
                GestureDetector(
                  onTap: () {
                    // TODO: Copiar para clipboard
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      // Se for URL, tenta extrair o secret para mostrar clean
                      widget.totpSecret.startsWith('otpauth')
                          ? Uri.tryParse(
                                  widget.totpSecret,
                                )?.queryParameters['secret'] ??
                                widget.totpSecret
                          : widget.totpSecret,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Input para código
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Digite o código de 6 dígitos';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Botão Verificar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A3FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verificar e Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  void _verifyCode() {
    if (_formKey.currentState!.validate()) {
      // Extrair apenas o secret se for uma URL completa
      String secret = widget.totpSecret;
      if (widget.totpSecret.startsWith('otpauth://')) {
        secret = Uri.parse(widget.totpSecret).queryParameters['secret'] ?? '';
      }

      ref
          .read(authProvider.notifier)
          .verifyTotp(
            username: widget.username,
            passphrase: widget.passphrase,
            totpSecret: secret,
            totpCode: _codeController.text,
          );
    }
  }
}
