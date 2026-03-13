import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/signup_flow_provider.dart';
import '../../state/auth_state.dart';
import '../login_totp_screen.dart';

class SignupPaymentScreen extends ConsumerStatefulWidget {
  const SignupPaymentScreen({super.key});

  @override
  ConsumerState<SignupPaymentScreen> createState() => _SignupPaymentScreenState();
}

class _SignupPaymentScreenState extends ConsumerState<SignupPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flowState = ref.read(signupFlowProvider);
      if (flowState.paymentAddress == null || flowState.paymentAddress!.isEmpty) {
        if (flowState.sessionId != null) {
          ref.read(signupFlowProvider.notifier).fetchPaymentLink(
                ref.read(authRepositoryProvider),
              );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final flowState = ref.watch(signupFlowProvider);

    String depositAddress = flowState.paymentAddress ?? '';
    double amountBtc = flowState.paymentAmountBtc ?? 0.0;

    if (authState is AuthPaymentRequired) {
      depositAddress = authState.depositAddress;
      amountBtc = authState.amountBtc;
    }

    // Secondary fallback to sessionId if nothing else
    if (depositAddress.isEmpty && flowState.sessionId != null) {
       // We might be waiting for fetchPaymentLink to finish updating flowState
    }

    final isLoading = authState is AuthLoading;

    // Listener for state transitions
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthRequiresLoginTotp) {
        // Redirecionamento após ativação mock ou real que requer login
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => LoginTotpScreen(
                username: next.username,
                passphrase: next.passphrase,
                preAuthToken: next.preAuthToken,
              ),
            ),
            (route) => false,
          );
        }
      } else if (next is AuthAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (next is AuthInitial && previous is AuthLoading) {
        // Most likely mockConfirmOnboarding success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulação: Conta Ativada com Sucesso! ✅'),
            backgroundColor: Colors.amber,
          ),
        );
      } else if (next is AuthError) {
        String msg = next.message;
        if (msg.contains('401') || msg.contains('Credentials')) {
          msg = 'Conta ainda não ativada ou credenciais inválidas. Aguarde confirmações ou use o Simulador.';
        }
        showCustomErrorDialog(
          context,
          msg,
          onRetry: () {
            ref.read(authProvider.notifier).clearError();
          },
          onGoBack: () {
            ref.read(authProvider.notifier).clearError();
          },
        );
      }
    });

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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'PAGAMENTO DE\nONBOARDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 6.0,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Para ativar sua conta e garantir a segurança multisig, é necessário um depósito inicial.',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // BTC Amount
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'VALOR A DEPOSITAR',
                                style: TextStyle(
                                  color: Color(0xFF3D7CFF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${amountBtc.toStringAsFixed(8)} BTC',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // QR Code
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: depositAddress.isEmpty
                                ? const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : QrImageView(
                                    data:
                                        'bitcoin:$depositAddress?amount=$amountBtc',
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    gapless: false,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Address Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101012),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E1E24)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  depositAddress,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: Color(0xFF3D7CFF),
                                  size: 20,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: depositAddress),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Endereço copiado'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const Text(
                          'Aguardando confirmação na rede...',
                          style: TextStyle(
                            color: Color(0xFF3D7CFF),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        const SizedBox(height: 24),
                      ],
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF1E3A8A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: isLoading
                            ? null
                            : () {
                                final username = flowState.username;
                                final password = flowState.passphrase;
                                final sessionId = flowState.sessionId;

                                if (username != null && password != null && sessionId != null) {
                                  ref
                                      .read(authProvider.notifier)
                                      .mockConfirmOnboarding(
                                        sessionId: sessionId,
                                        username: username,
                                        password: password,
                                      );
                                } else {
                                  // Fallback: se não tiver credenciais, vai pra home (mas devia dar erro)
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                  );
                                }
                              },
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'CONCLUIR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
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
}
