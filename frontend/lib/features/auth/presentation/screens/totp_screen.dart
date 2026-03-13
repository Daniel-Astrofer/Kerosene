import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/neon_button.dart';
import '../widgets/totp_input_container.dart';

class TotpScreen extends StatefulWidget {
  final bool isSetup; // true = Signup/Ativação, false = Login
  final String? secret;
  final String? provisionUri;
  final Function(String code) onVerify;

  const TotpScreen({
    super.key,
    required this.isSetup,
    this.secret,
    this.provisionUri,
    required this.onVerify,
  });

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen> {
  String _currentCode = '';

  void _copySecret() {
    if (widget.secret != null) {
      Clipboard.setData(ClipboardData(text: widget.secret!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Segredo copiado para a área de transferência!'),
          backgroundColor: Color(0xFF00FFA3),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Autenticação 2FA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (widget.isSetup) ...[
                // QR Code Container
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: widget.provisionUri != null
                        ? QrImageView(
                            data: widget.provisionUri!,
                            version: QrVersions.auto,
                            size: 168.0,
                          )
                        : const Icon(
                            Icons.qr_code_2_rounded,
                            size: 100,
                            color: Colors.black,
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Escaneie o código QR no seu aplicativo de\nautenticação.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Secret Key
                Text(
                  'TOTP SECRET',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.secret ?? 'XXXX - XXXX - XXXX - XXXX',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          letterSpacing: 2.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: _copySecret,
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF00FFA3),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ] else ...[
                // Login Mode (Just code input)
                const SizedBox(height: 60),
                Text(
                  'Digite o código do seu aplicativo\nde autenticação.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
              ],

              // Verification Code Input
              Text(
                'CÓDIGO DE VERIFICAÇÃO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              TotpInputContainer(
                onCompleted: (code) {
                  setState(() {
                    _currentCode = code;
                  });
                },
              ),

              const SizedBox(height: 48),

              // Action Button
              NeonButton(
                text: widget.isSetup ? 'Ativar 2FA' : 'Verificar e Entrar',
                onPressed: () {
                  if (_currentCode.length == 6) {
                    widget.onVerify(_currentCode);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, insira o código de 6 dígitos.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                baseColor: const Color(0xFF00FFA3),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
