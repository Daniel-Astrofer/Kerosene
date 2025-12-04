import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/colors.dart';
import 'package:teste/features/authentication/domain/entities/user_dto.dart';
import 'package:teste/features/authentication/domain/interactors/register_user.dart';
import 'package:teste/features/authentication/domain/usecases/mnemonic_bip39/bip39.dart';
import 'package:teste/features/authentication/presentation/pages/totp_verification.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  
  String? _generatedMnemonic;
  bool _isMnemonicRevealed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white, fontFamily: 'HubotSans'),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Cores.instance.cor1,
              Cores.instance.cor5,
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("1. Identity"),
              const SizedBox(height: 16),
              _buildGlassContainer(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passphraseController,
                        label: 'Passphrase',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!Bip39.validatePasspharse(passphrase: value)) {
                            return 'Invalid passphrase format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPassphraseController,
                        label: 'Confirm Passphrase',
                        icon: Icons.verified_user,
                        isPassword: true,
                        validator: (value) {
                          if (value != _passphraseController.text) {
                            return 'Passphrases do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle("2. Security Phrase"),
              const SizedBox(height: 16),
              _buildMnemonicSection(),
              
              const SizedBox(height: 48),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Cores.instance.cor3,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'HubotSansExpanded',
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withAlpha(50),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Cores.instance.cor3),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) return 'Required';
        return null;
      },
    );
  }

  Widget _buildMnemonicSection() {
    return _buildGlassContainer(
      child: Column(
        children: [
          if (!_isMnemonicRevealed)
            InkWell(
              onTap: () {
                setState(() {
                  _generatedMnemonic = Bip39.createPhrase(length: MnemonicLength.words18);
                  _isMnemonicRevealed = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Cores.instance.cor3, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Cores.instance.cor3.withAlpha(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.fingerprint, size: 48, color: Cores.instance.cor3),
                    const SizedBox(height: 16),
                    const Text(
                      "Tap to Generate Secure Phrase",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _generatedMnemonic!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Cores.instance.cor3,
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedMnemonic!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied to clipboard")),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      label: const Text("Copy", style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _generatedMnemonic = Bip39.createPhrase(length: MnemonicLength.words18);
                        });
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text("Regenerate", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Cores.instance.cor3, Cores.instance.cor4],
        ),
        boxShadow: [
          BoxShadow(
            color: Cores.instance.cor3.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleSignup,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Create Account & Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'HubotSans',
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (_generatedMnemonic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please generate a security phrase")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final response = await create(_usernameController.text, _passphraseController.text);
        
        // Update User DTO
        User.instance.username = _usernameController.text;
        User.instance.passphrase = _passphraseController.text;
        User.instance.totpSecret = response;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TotpScreen(totpsecret: response),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}