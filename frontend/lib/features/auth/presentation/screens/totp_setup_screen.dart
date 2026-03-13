import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/features/auth/presentation/providers/auth_provider.dart';
import 'package:teste/features/auth/presentation/providers/signup_flow_provider.dart';
import 'package:teste/features/auth/presentation/state/auth_state.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import 'signup/signup_passkey_screen.dart';

class TotpSetupScreen extends ConsumerStatefulWidget {
  final String? username;
  final String? passphrase;
  final String? totpSecret;
  final String? qrCodeUri;

  const TotpSetupScreen({
    super.key,
    this.username,
    this.passphrase,
    this.totpSecret,
    this.qrCodeUri,
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
    final flowState = ref.watch(signupFlowProvider);

    final username = widget.username ?? flowState.username ?? '';
    final passphrase = widget.passphrase ?? flowState.passphrase ?? '';
    final totpSecret = widget.totpSecret ?? flowState.totpSecret ?? '';
    final qrCodeUri = widget.qrCodeUri ?? flowState.qrCodeUri ?? totpSecret;

    debugPrint('🛠️ [TOTP Screen] username: $username, secret: ${totpSecret.isNotEmpty}, qr: ${qrCodeUri.isNotEmpty}');

    String qrData = qrCodeUri;
    if (qrData.isNotEmpty && !qrData.startsWith('otpauth://')) {
      qrData =
          'otpauth://totp/Kerosene:$username?secret=$qrData&issuer=Kerosene';
    }

    // Listener para redirecionar após sucesso
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthTotpVerified) {
        // Save sessionId to flow provider
        ref.read(signupFlowProvider.notifier).setSessionId(next.sessionId);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignupPasskeyScreen()),
          (route) => false,
        );
      } else if (next is AuthAuthenticated) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (next is AuthError) {
        showCustomErrorDialog(
          context,
          next.message,
          onRetry: () {
            ref.read(authProvider.notifier).clearError();
            if (_codeController.text.length == 6) {
              _verifyCode(username, passphrase, totpSecret);
            } else {
              _codeController.clear();
            }
          },
          onGoBack: () {
            ref.read(authProvider.notifier).clearError();
            Navigator.pop(context);
          },
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    String cleanSecret = totpSecret.replaceAll('"', '');
    if (cleanSecret.contains('otpauth://')) {
      final uri = Uri.tryParse(cleanSecret);
      cleanSecret = uri?.queryParameters['secret'] ?? cleanSecret;
    } else if (cleanSecret.contains('secret=')) {
      try {
        final uri = Uri.parse(cleanSecret);
        cleanSecret = uri.queryParameters['secret'] ?? cleanSecret;
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: CyberTheme.bgDeep,
      body: Container(
        decoration: BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: Column(
              children: [
                // Top Progress Bar
                Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF2962FF), // Deep blue
                      ),
                    ),
                  ],
                ),

                // App Bar equivalent
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                      left: 8.0,
                      bottom: 8.0,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Conecte seu\nAuthenticator',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Abra o Google Authenticator ou Authy e escaneie o código QR abaixo.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 48),

                          // QR Code Container
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: qrData.isEmpty
                                  ? const SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      gapless: false,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Colors.black,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Secret Display (Manual insertion)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                // Copy to clipboard logic could go here
                              },
                              child: Column(
                                children: [
                                  const Text(
                                    'OU INSIRA O CÓDIGO MANUALMENTE',
                                    style: TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cleanSecret,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3D7CFF),
                                      fontSize: 16,
                                      letterSpacing: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Verification Input boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              String text = '';
                              if (_codeController.text.length > index) {
                                text = _codeController.text[index];
                              }
                              return Container(
                                width:
                                    (MediaQuery.of(context).size.width -
                                        64 -
                                        50) /
                                    6,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF101012),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _codeController.text.length == index
                                        ? const Color(0xFF3D7CFF)
                                        : const Color(0xFF1E1E24),
                                    width: _codeController.text.length == index
                                        ? 1.5
                                        : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Hidden TextFormField for input
                          Opacity(
                            opacity: 0,
                            child: TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              maxLength: 6,
                              onChanged: (val) {
                                setState(
                                  () {},
                                ); // Rebuild to show characters in boxes
                                if (val.length == 6 && !isLoading) {
                                  _verifyCode(username, passphrase, totpSecret);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Continuous Button at bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7), // Off-white
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: (isLoading || _codeController.text.length < 6)
                            ? null
                            : () =>
                                  _verifyCode(username, passphrase, totpSecret),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ativar 2FA e Continuar',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _verifyCode(String username, String passphrase, String secret) {
    if (_codeController.text.length == 6) {
      // Extrair apenas o secret se for uma URL completa
      String cleanSecret = secret;
      if (secret.startsWith('otpauth://')) {
        cleanSecret = Uri.parse(secret).queryParameters['secret'] ?? '';
      }

      ref
          .read(authProvider.notifier)
          .verifyTotp(
            username: username,
            passphrase: passphrase,
            totpSecret: cleanSecret,
            totpCode: _codeController.text,
          );
    }
  }
}
