import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../../../../core/theme/cyber_theme.dart';
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
      final newMnemonic = Mnemonic.generate(
        Language.portuguese,
        length: MnemonicLength.words18,
      ).sentence;
      if (mounted) {
        setState(() {
          _mnemonic = newMnemonic;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mnemonic = "erro ao gerar frase tente novamente";
        });
      }
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
        // ref.read(signupFlowProvider.notifier).setError(next.message); // This line is commented out as signupFlowProvider is not defined in this context.
        showCustomErrorDialog(context, ErrorTranslator.translate(next.message));
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CyberTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ─── Logo ─────────────────────────────
                const KeroseneLogo(size: 72),
                const SizedBox(height: 32),

                // ─── Title ────────────────────────────
                Text(
                  'Create Wallet',
                  style: CyberTheme.heading(size: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Setup your username and secure key.',
                  style: CyberTheme.label(
                    size: 14,
                    color: CyberTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 44),

                // ─── Form ─────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-z0-9_]'),
                          ),
                        ],
                        style: const TextStyle(
                          color: CyberTheme.textPrimary,
                          fontSize: 15,
                        ),
                        decoration:
                            CyberTheme.cyberInput(
                              label: 'Username',
                              hint: 'lower case letters, numbers and _',
                              icon: Icons.person_outline_rounded,
                            ).copyWith(
                              helperText: 'Only a-z, 0-9 and _',
                              helperStyle: const TextStyle(
                                color: CyberTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 3) return 'Min 3 chars';
                          if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                            return 'Invalid characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ─── Mnemonic Section ────────────
                      Text(
                        'YOUR SECRET PHRASE (BIP39)',
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
                              'Save this phrase securely. It is the ONLY way to recover your account.',
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

// ═══════════════════════════════════════════════
// Extracted: Mnemonic Display Card
// ═══════════════════════════════════════════════
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
              // Copy button
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
                label: const Text('Copiar'),
                style: TextButton.styleFrom(
                  foregroundColor: CyberTheme.neonCyan,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Generate new button
              TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Generate New'),
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

// ═══════════════════════════════════════════════
// Extracted: Create Wallet Button
// ═══════════════════════════════════════════════
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
            : const Text(
                'Create Wallet',
                style: TextStyle(
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
