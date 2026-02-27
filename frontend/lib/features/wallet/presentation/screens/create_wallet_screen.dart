import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../providers/wallet_provider.dart';
import '../state/create_wallet_state.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _generatedMnemonic = '';
  int _mnemonicLength = 18;

  void _generatePassphrase() {
    final length = _mnemonicLength == 18
        ? MnemonicLength.words18
        : MnemonicLength.words24;
    setState(() {
      _generatedMnemonic = Mnemonic.generate(
        Language.portuguese,
        length: length,
      ).sentence;
    });
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate() && _generatedMnemonic.isNotEmpty) {
      ref
          .read(createWalletProvider.notifier)
          .createWallet(
            name: _nameController.text.trim(),
            passphrase: _generatedMnemonic,
          );
    } else if (_generatedMnemonic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a passphrase first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreateWalletState>(createWalletProvider, (previous, next) {
      if (next is CreateWalletSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        ref.read(walletProvider.notifier).refresh();
      } else if (next is CreateWalletError) {
        showCustomErrorDialog(context, ErrorTranslator.translate(next.message));
      }
    });

    final state = ref.watch(createWalletProvider);
    final isLoading = state is CreateWalletLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'New Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF0A0A15)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Progress Indicator or Icon
                  _buildAnimatedSection(
                    delay: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 48,
                        color: Color(0xFF7B61FF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildAnimatedSection(
                    delay: 100,
                    child: GlassContainer(
                      blur: 40,
                      opacity: 0.05,
                      borderRadius: BorderRadius.circular(32),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "WALLET IDENTITY",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Savings, Daily, etc.',
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome obrigatório';
                                }
                                if (!RegExp(
                                  r'^[a-zA-Z0-9\s]+$',
                                ).hasMatch(value)) {
                                  return 'Apenas letras e números são permitidos';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            const Text(
                              "PASSPHRASE SECURITY",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(child: _buildStrengthOption(18)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStrengthOption(24)),
                              ],
                            ),

                            const SizedBox(height: 32),

                            if (_generatedMnemonic.isEmpty)
                              ElevatedButton(
                                onPressed: _generatePassphrase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF7B61FF,
                                  ).withValues(alpha: 0.2),
                                  foregroundColor: const Color(0xFF7B61FF),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      "Gerar Chave de Segurança",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              _buildMnemonicContent(),

                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleCreate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shadowColor: Colors.white24,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        "CRIAR CARTEIRA",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildStrengthOption(int value) {
    bool isSelected = _mnemonicLength == value;
    return GestureDetector(
      onTap: () => setState(() => _mnemonicLength = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7B61FF).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            "$value Palavras",
            style: TextStyle(
              color: isSelected ? const Color(0xFF7B61FF) : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMnemonicContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              SelectableText(
                _generatedMnemonic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTinyButton(Icons.copy_rounded, "Copiar", () {
                    Clipboard.setData(ClipboardData(text: _generatedMnemonic));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Copiado!")));
                  }),
                  const SizedBox(width: 16),
                  _buildTinyButton(
                    Icons.refresh_rounded,
                    "Novo",
                    _generatePassphrase,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9D00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9D00),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Guarde bem estas palavras. Sem elas, seus fundos serão perdidos.",
                  style: TextStyle(color: Color(0xFFFF9D00), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTinyButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
