import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/signup_flow_provider.dart';
import '../../state/auth_state.dart';
import 'package:teste/core/presentation/widgets/custom_error_dialog.dart';
import 'package:teste/features/auth/presentation/screens/totp_setup_screen.dart';

class SignupSeedVerificationScreen extends ConsumerStatefulWidget {
  const SignupSeedVerificationScreen({super.key});

  @override
  ConsumerState<SignupSeedVerificationScreen> createState() =>
      _SignupSeedVerificationScreenState();
}

class _SignupSeedVerificationScreenState
    extends ConsumerState<SignupSeedVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  List<String>? _words;
  List<int>? _verificationIndexes; // 0-based indexing for logic
  Map<int, TextEditingController>? _controllers;

  @override
  void initState() {
    super.initState();
    _initVerification();
  }

  void _initVerification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seedPhrase = ref.read(signupFlowProvider).passphrase;
      if (seedPhrase == null || seedPhrase.isEmpty) {
        Navigator.pop(context); // Safety
        return;
      }

      final words = seedPhrase.split(' ');
      final random = Random();
      final Set<int> indexes = {};
      while (indexes.length < 3) {
        indexes.add(random.nextInt(words.length));
      }
      final sortedIndexes = indexes.toList()..sort();

      final controllers = <int, TextEditingController>{};
      for (int index in sortedIndexes) {
        controllers[index] = TextEditingController();
      }

      setState(() {
        _words = words;
        _verificationIndexes = sortedIndexes;
        _controllers = controllers;
      });
    });
  }

  @override
  void dispose() {
    if (_controllers != null) {
      for (var controller in _controllers!.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_words == null ||
        _verificationIndexes == null ||
        _controllers == null) {
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          const Text(
                            'Verificar Frase',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Complete com as palavras ausentes para garantir a segurança dos seus fundos.',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 48),

                          // Seed Grid with inline inputs
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
                            itemCount: _words!.length,
                            itemBuilder: (context, index) {
                              bool isInput = _verificationIndexes!.contains(
                                index,
                              );

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isInput
                                      ? const Color(0xFF151518)
                                      : const Color(0xFF0C0C0E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isInput
                                        ? const Color(0xFF3D7CFF)
                                        : const Color(0xFF1E1E24),
                                    width: isInput ? 1.5 : 1.0,
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
                                    Expanded(
                                      child: isInput
                                          ? TextFormField(
                                              controller: _controllers![index],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim() !=
                                                        _words![index]) {
                                                  return 'Errado';
                                                }
                                                return null;
                                              },
                                            )
                                          : Text(
                                              _words![index],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),

                // Continuous Button at bottom
                Consumer(
                  builder: (context, ref, child) {
                    ref.listen<AuthState>(authProvider, (_, next) {
                      if (next is AuthRequiresTotpSetup) {
                        ref
                            .read(signupFlowProvider.notifier)
                            .setTotpSecret(next.totpSecret);
                        ref
                            .read(signupFlowProvider.notifier)
                            .setQrCodeUri(next.qrCodeUri);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TotpSetupScreen(
                              username: next.username,
                              passphrase: next.passphrase,
                              totpSecret: next.totpSecret,
                              qrCodeUri: next.qrCodeUri,
                            ),
                          ),
                          (route) => false,
                        );
                      } else if (next is AuthError) {
                        showCustomErrorDialog(
                          context,
                          next.message,
                          onRetry: () {
                            ref.read(authProvider.notifier).clearError();
                          },
                          onGoBack: () {
                            ref.read(authProvider.notifier).clearError();
                          },
                        );
                      }
                    });

                    final isLoading = ref.watch(authProvider) is AuthLoading;

                    return Padding(
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
                            onTap: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      final flow = ref.read(signupFlowProvider);

                                      String securityParam = 'STANDARD';
                                      if (flow.seedSecurityOption ==
                                          SeedSecurityOption.slip39) {
                                        securityParam = 'SHAMIR';
                                      }
                                      if (flow.seedSecurityOption ==
                                          SeedSecurityOption.multisig2fa) {
                                        securityParam = 'MULTISIG';
                                      }

                                      ref
                                          .read(authProvider.notifier)
                                          .signup(
                                            username: flow.username ?? '',
                                            password: flow.passphrase ?? '',
                                            accountSecurity: securityParam,
                                          );
                                    }
                                  },
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Verificar e Continuar',
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
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
