import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import 'package:teste/l10n/l10n_extension.dart';
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
      // The original code already had 'if (mounted)'.
      // The user's edit seems to be trying to add checks and then has a misplaced brace.
      // Assuming the intent was to ensure the widget is mounted before setState,
      // and to fix any potential lint issues with curly braces.
      // The provided snippet `}{` is syntactically incorrect.
      // I will interpret the request as ensuring `setState` is only called if mounted,
      // and correcting the structure around the `setState` call.
      // Since `if (mounted)` is already present, I will ensure it's correctly structured.
      // The snippet `if (_isDisposed) { return; }` requires `_isDisposed` to be defined,
      // which it is not. I will omit this part to maintain syntactic correctness and
      // avoid introducing undeclared variables, focusing on the brace issue.
      // The `if (!mounted) { return; }` is redundant if `if (mounted)` wraps `setState`.
      // I will keep the existing `if (mounted)` structure as it's correct.
      // The provided edit `}{` is a syntax error. I will correct the structure.
      if (mounted) {
        setState(() {
          _mnemonic = newMnemonic;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mnemonic = context.l10n.signupMnemonicError;
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
        showCustomErrorDialog(
          context,
          ErrorTranslator.translate(context.l10n, next.message),
          onRetry: () {
            ref.read(authProvider.notifier).clearError();
            if (_usernameController.text.isNotEmpty && _mnemonic.isNotEmpty) {
              _handleSignup();
            }
          },
          onGoBack: () {
            ref.read(authProvider.notifier).clearError();
            Navigator.pop(context); // Go back to Welcome screen
          },
        );
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
                  context.l10n.signupScreenTitle,
                  style: CyberTheme.heading(size: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.signupScreenSubtitle,
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
                              label: context.l10n.username,
                              hint: context.l10n.signupUsernameHint,
                              icon: Icons.person_outline_rounded,
                            ).copyWith(
                              helperText: context.l10n.signupUsernameHelper,
                              helperStyle: const TextStyle(
                                color: CyberTheme.textMuted,
                                fontSize: 11,
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
              // Generate new button
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
