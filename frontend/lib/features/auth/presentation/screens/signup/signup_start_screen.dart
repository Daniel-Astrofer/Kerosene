import 'package:flutter/material.dart';
import 'signup_username_screen.dart';

class SignupStartScreen extends StatelessWidget {
  const SignupStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Lighting Glow
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2962FF).withValues(alpha: 0.15),
                    const Color(0xFF2962FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B61FF).withValues(alpha: 0.08),
                    const Color(0xFF7B61FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF2962FF), // Deep blue
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF1E1E24), // Dark grey
                      ),
                    ),
                  ],
                ),

                // App Bar equivalent
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF2962FF).withValues(alpha: 0.1),
                                  const Color(0xFF2962FF).withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        const Text(
                          'Antes de Começar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0C0E),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF1E1E24)),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Para fazer parte de nosso serviço é necessário pagar uma ',
                                ),
                                TextSpan(
                                  text: 'taxa de inscrição ',
                                  style: TextStyle(color: Color(0xFF3D7CFF)),
                                ),
                                TextSpan(text: 'cobrada na criação da conta, '),
                                TextSpan(
                                  text: 'que vai diretamente para sua conta ',
                                  style: TextStyle(color: Color(0xFF3D7CFF)),
                                ),
                                TextSpan(
                                  text:
                                      'descontado as taxas de transação e de serviço.',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'Passos necessários',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Step 1
                        _buildStepItem(
                          icon: Icons.help_outline_rounded,
                          content: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'É aconselhável baixar um aplicativo autenticador de Two-Factor-Authentication ',
                                ),
                                TextSpan(
                                  text: 'para não perder acesso a sua conta.',
                                  style: TextStyle(color: Color(0xFFFF5252)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Step 2
                        _buildStepItem(
                          icon: Icons.help_outline_rounded,
                          content: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Salve suas senhas fisicamente',
                                  style: TextStyle(color: Color(0xFF00C853)),
                                ),
                                TextSpan(
                                  text:
                                      ', se caso perder suas senhas ou segredos, ',
                                ),
                                TextSpan(
                                  text:
                                      'a conta será perdida para sempre sem chance de recuperação',
                                  style: TextStyle(color: Color(0xFFFF5252)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SignupUsernameScreen(),
                                  ),
                                );
                              },
                              child: const Center(
                                child: Text(
                                  'Eu Entendo, Continuar',
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101012),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}

