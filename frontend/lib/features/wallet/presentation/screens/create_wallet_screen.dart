import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../../../../core/presentation/widgets/kerosene_logo.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../providers/wallet_provider.dart';
import '../state/create_wallet_state.dart';

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
    int strength = _mnemonicLength == 18 ? 192 : 256;
    setState(() {
      _generatedMnemonic = bip39.generateMnemonic(strength: strength);
    });
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate() && _generatedMnemonic.isNotEmpty) {
      ref
          .read(createWalletProvider.notifier)
          .createWallet(
            name: _nameController.text,
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
        title: const Text('New Wallet', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              padding: const EdgeInsets.all(24),
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      const KeroseneLogo(size: 60),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Wallet Name',
                                hintText: 'e.g. Savings',
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
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white70,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              'Passphrase Strength',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<int>(
                                      title: const Text(
                                        '18 Words',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      value: 18,
                                      groupValue: _mnemonicLength,
                                      onChanged: (val) => setState(
                                        () => _mnemonicLength = val!,
                                      ),
                                      activeColor: const Color(0xFF7B61FF),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<int>(
                                      title: const Text(
                                        '24 Words',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      value: 24,
                                      groupValue: _mnemonicLength,
                                      onChanged: (val) => setState(
                                        () => _mnemonicLength = val!,
                                      ),
                                      activeColor: const Color(0xFF7B61FF),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (_generatedMnemonic.isEmpty)
                              OutlinedButton.icon(
                                onPressed: _generatePassphrase,
                                icon: const Icon(Icons.vpn_key),
                                label: const Text('Generate Secure Passphrase'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00D4FF),
                                  side: const BorderSide(
                                    color: Color(0xFF00D4FF),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF252A40),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: SelectableText(
                                      _generatedMnemonic,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'monospace',
                                        height: 1.5,
                                        color: Color(0xFF00D4FF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: _generatedMnemonic,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Copied!'),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: const Text('Copy'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: _generatePassphrase,
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text('Regenerate'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF7B61FF,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: Color(0xFFFFC371),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Save this phrase now! Without it you lose access forever.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                            const SizedBox(height: 48),

                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleCreate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00D4FF),
                                  foregroundColor: Colors.white,
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
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
