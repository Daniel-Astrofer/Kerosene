import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../../providers/signup_flow_provider.dart';
import 'signup_seed_verification_screen.dart';

class SignupSeedPhraseScreen extends ConsumerStatefulWidget {
  const SignupSeedPhraseScreen({super.key});

  @override
  ConsumerState<SignupSeedPhraseScreen> createState() =>
      _SignupSeedPhraseScreenState();
}

class _SignupSeedPhraseScreenState
    extends ConsumerState<SignupSeedPhraseScreen> {
  List<String>? _seedWords;
  bool _is24Words = false;

  @override
  void initState() {
    super.initState();
    _initMnemonic();
  }

  void _initMnemonic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedMnemonic = ref.read(signupFlowProvider).passphrase;
      if (savedMnemonic != null && savedMnemonic.isNotEmpty) {
        setState(() {
          _seedWords = savedMnemonic.split(' ');
          _is24Words = _seedWords!.length == 24;
        });
      } else {
        _generateMnemonic();
      }
    });
  }

  void _generateMnemonic() {
    final mnemonic = bip39.generateMnemonic(strength: _is24Words ? 256 : 128);
    setState(() {
      _seedWords = mnemonic.split(' ');
    });
    ref.read(signupFlowProvider.notifier).setPassphrase(mnemonic);
  }

  @override
  Widget build(BuildContext context) {
    if (_seedWords == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2962FF)),
        ),
      );
    }

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
                    const Color(0xFF7B61FF).withValues(alpha: 0.1),
                    const Color(0xFF7B61FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF2962FF), // Deep blue
                      ),
                    ),
                    Expanded(
                      flex: 2,
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        const Text(
                          'Sua Frase Secreta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Trate estas palavras como um papel físico.\nNunca as salve digitalmente.',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Word count toggle
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF101012),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1E1E24),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_is24Words) {
                                      setState(() {
                                        _is24Words = false;
                                        _generateMnemonic();
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_is24Words
                                          ? const Color(0xFF1E1E24)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: !_is24Words
                                          ? Border.all(
                                              color: const Color(0xFF3D7CFF),
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      '12',
                                      style: TextStyle(
                                        color: !_is24Words
                                            ? Colors.white
                                            : const Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (!_is24Words) {
                                      setState(() {
                                        _is24Words = true;
                                        _generateMnemonic();
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _is24Words
                                          ? const Color(0xFF1E1E24)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: _is24Words
                                          ? Border.all(
                                              color: const Color(0xFF3D7CFF),
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      '24',
                                      style: TextStyle(
                                        color: _is24Words
                                            ? Colors.white
                                            : const Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Seed Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _seedWords!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C0C0E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1E1E24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1 < 10 ? '0' : ''}${index + 1}. ',
                                    style: const TextStyle(
                                      color: Color(0xFF6E6E73),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _seedWords![index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF5252),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'NÃO DEIXE ESTA TELA ATÉ TER CERTEZA DA CÓPIA',
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
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
                                  const SignupSeedVerificationScreen(),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            'Já Anotei, Continuar',
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
        ],
      ),
    );
  }
}
