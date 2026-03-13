import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/signup_flow_provider.dart';
import 'signup_security_selection_screen.dart';

class SignupUsernameScreen extends ConsumerStatefulWidget {
  const SignupUsernameScreen({super.key});

  @override
  ConsumerState<SignupUsernameScreen> createState() =>
      _SignupUsernameScreenState();
}

class _SignupUsernameScreenState extends ConsumerState<SignupUsernameScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill if already set in flow state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedUsername = ref.read(signupFlowProvider).username;
      if (savedUsername != null && savedUsername.isNotEmpty) {
        _usernameController.text = savedUsername;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Lighting Glows
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Progress Bar
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF2962FF), // Deep blue
                      ),
                    ),
                    Expanded(
                      flex: 5,
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
                        const SizedBox(height: 24),

                        const Text(
                          'Escolha seu\nUsername',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Este será o seu handle único na rede Kerosene. Use-o para receber transferências de outros usuários.',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0C0E),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF1E1E24)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "HANDLE (VISÍVEL NO APP)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8E8E93),
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'ex: satoshi_99',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF333333),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                      color: Color(0xFF8E8E93),
                                    ),
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.all(14.0),
                                      child: Text(
                                        '@kerosene',
                                        style: TextStyle(
                                          color: Color(0xFF3D7CFF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF151518),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3D7CFF),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, insira um username';
                                    }
                                    if (value.length < 3) {
                                      return 'Mínimo de 3 caracteres';
                                    }
                                    if (!RegExp(
                                      r'^[a-z0-9_]+$',
                                    ).hasMatch(value)) {
                                      return 'Apenas letras minúsculas, números e underline (_)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

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
                                if (_formKey.currentState!.validate()) {
                                  ref
                                      .read(signupFlowProvider.notifier)
                                      .setUsername(_usernameController.text);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupSecuritySelectionScreen(),
                                    ),
                                  );
                                }
                              },
                              child: const Center(
                                child: Text(
                                  'Continuar',
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

                        const SizedBox(height: 40),
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
}
