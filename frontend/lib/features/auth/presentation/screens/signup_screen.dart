import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:teste/core/theme/cyber_theme.dart';
import 'package:teste/l10n/l10n_extension.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  late String _mnemonic;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  void _generateMnemonic() {
    setState(() {
      _mnemonic = bip39.generateMnemonic();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: CyberTheme.bgDeep,
      body: Container(
        decoration: BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        context.l10n.signupScreenTitle,
                        style: CyberTheme.heading(size: 24),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ESCOLHA SEU HANDLE",
                          style: CyberTheme.label(
                            size: 11,
                            color: CyberTheme.textSecondary,
                          ).copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: CyberTheme.cyberInput(
                            label: 'Username',
                            hint: 'ex: Satoshi_99',
                            icon: Icons.alternate_email_rounded,
                            suffix: Text(
                              '@kerosene',
                              style: TextStyle(
                                color: CyberTheme.neonCyan.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.l10n.required;
                            }
                            if (value.length < 3) {
                              return context.l10n.signupUsernameMinChars;
                            }
                            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                              return context.l10n.signupUsernameInvalid;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // ─── Mnemonic Section ────────────
                        Text(
                          context.l10n.signupMnemonicLabel.toUpperCase(),
                          style: CyberTheme.label(
                            size: 11,
                            color: CyberTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MnemonicCard(
                          mnemonic: _mnemonic,
                          onRegenerate: _generateMnemonic,
                        ),

                        const SizedBox(height: 14),

                        // Warning
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: CyberTheme.neonAmber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.signupMnemonicWarning,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CyberTheme.textSecondary.withValues(
                                    alpha: 0.8,
                                  ),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 44),

                        // ─── Create Button ───────────────
                        _CyberCreateButton(
                          isLoading: isLoading,
                          onPressed: _handleSignup,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signup(
            username: _usernameController.text,
            password: _mnemonic,
            accountSecurity: 'STANDARD',
          );
    }
  }
}

class _MnemonicCard extends StatelessWidget {
  final String mnemonic;
  final VoidCallback onRegenerate;

  const _MnemonicCard({required this.mnemonic, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CyberTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.border, width: 1),
        boxShadow: CyberTheme.subtleGlow(CyberTheme.neonCyan),
      ),
      child: Column(
        children: [
          Text(
            mnemonic,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              height: 1.8,
              color: CyberTheme.neonCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mnemonic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text('Frase copiada com segurança!'),
                        ],
                      ),
                      backgroundColor: CyberTheme.neonCyan.withValues(
                        alpha: 0.85,
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(context.l10n.signupMnemonicCopy),
                style: TextButton.styleFrom(
                  foregroundColor: CyberTheme.neonCyan,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.l10n.signupMnemonicGenerateNew),
                style: TextButton.styleFrom(
                  foregroundColor: CyberTheme.neonPurple,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CyberCreateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _CyberCreateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading
            ? []
            : CyberTheme.glow(CyberTheme.neonCyan, blur: 16),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: CyberTheme.neonButton(CyberTheme.neonCyan),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: CyberTheme.bgDeep,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                context.l10n.signupScreenTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CyberTheme.bgDeep,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
