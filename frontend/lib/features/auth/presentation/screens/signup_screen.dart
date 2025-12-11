import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';
import 'totp_setup_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String _mnemonic = '';

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  void _generateMnemonic() {
    try {
      setState(() {
        _mnemonic = bip39.generateMnemonic(strength: 192);
      });
    } catch (e) {
      setState(() {
        _mnemonic = "error generating mnemonic try again";
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthRequiresTotpSetup) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TotpSetupScreen(
              username: next.username,
              passphrase: next.passphrase,
              totpSecret: next.totpSecret,
            ),
          ),
        );
      } else if (next is AuthError) {
        showCustomErrorDialog(context, ErrorTranslator.translate(next.message));
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF050511), Color(0xFF1A1F3C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        const KeroseneLogo(size: 80),
                        const SizedBox(height: 32),

                        const Text(
                          'Create Wallet',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Setup your username and secure key.',
                          style: TextStyle(fontSize: 16, color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Username
                              TextFormField(
                                controller: _usernameController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-z0-9_]'),
                                  ),
                                ],
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'lower case letters, numbers and _',
                                  hintStyle: const TextStyle(
                                    color: Colors.white30,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white70,
                                  ),
                                  helperText: 'Only a-z, 0-9 and _',
                                  helperStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  if (value.length < 3) return 'Min 3 chars';
                                  if (!RegExp(
                                    r'^[a-z0-9_]+$',
                                  ).hasMatch(value)) {
                                    return 'Invalid characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              // Mnemonic Area
                              const Text(
                                'Your Secret Phrase (BIP39)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252A40),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _mnemonic,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF00D4FF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: _generateMnemonic,
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 18,
                                          ),
                                          label: const Text('Generate New'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF7B61FF,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFFFC371),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Save this phrase securely. It is the ONLY way to recover your account.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              // Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00D4FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Create Wallet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signup(username: _usernameController.text, password: _mnemonic);
    }
  }
}
