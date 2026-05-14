import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/core/utils/snackbar_helper.dart';
import 'package:teste/core/presentation/widgets/cyber_background.dart';
import 'package:teste/core/presentation/widgets/cyber_button.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../providers/wallet_provider.dart';
import '../state/create_wallet_state.dart';

/// Premium Create Wallet Screen - Refactored
class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final _nameController = TextEditingController();
  String _mnemonic = "";
  int _wordCount = 12;
  String _accountSecurity = 'STANDARD';
  bool _hasGenerated = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateMnemonic() {
    int strength = 128;
    if (_wordCount == 18) strength = 192;
    if (_wordCount == 24) strength = 256;
    setState(() {
      _mnemonic = bip39.generateMnemonic(strength: strength);
      _hasGenerated = true;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackbarHelper.showError("INSIRA UM NOME PARA A CARTEIRA");
      return;
    }

    if (!_hasGenerated) {
      _generateMnemonic();
      return;
    }

    await ref.read(createWalletProvider.notifier).createWallet(
          name: name,
          passphrase: _mnemonic,
          accountSecurity: _accountSecurity,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createWalletProvider, (previous, next) {
      if (next is CreateWalletSuccess) {
        HapticFeedback.vibrate();
        SnackbarHelper.showSuccess("CARTEIRA CRIADA COM SUCESSO");
        Navigator.pop(context);
      } else if (next is CreateWalletError) {
        SnackbarHelper.showError(next.message);
      }
    });

    return CyberBackground(
      useScroll: true,
      backgroundColor: const Color(0xFF050505),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon:
                      const Icon(LucideIcons.chevronLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "NOVA CARTEIRA",
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall!
                      .copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildHeader(),
            const SizedBox(height: AppSpacing.xxl),
            if (!_hasGenerated) ...[
              _buildSettingsForm().animate().fade().slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.xxl),
              _buildCreateButton("GERAR ESTRUTURA")
                  .animate(delay: 200.ms)
                  .fade()
                  .slideY(begin: 0.2, end: 0),
            ] else ...[
              _buildMnemonicDisplay()
                  .animate()
                  .fade()
                  .scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: AppSpacing.xxl),
              _buildCreateButton("FINALIZAR CRIAÇÃO")
                  .animate(delay: 200.ms)
                  .fade()
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _hasGenerated = false),
                  child: const Text("VOLTAR E ALTERAR",
                      style: TextStyle(color: Colors.white54)),
                ),
              ).animate(delay: 400.ms).fade(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _hasGenerated ? LucideIcons.shieldCheck : LucideIcons.wallet,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ).animate().scale(delay: 100.ms),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _hasGenerated ? "PROTEJA SUA SEED" : "DEFINA OS PARÂMETROS",
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ).animate().fade(delay: 200.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _hasGenerated
              ? "Anote estas palavras em ordem. Elas são a única chave para seus fundos."
              : "Escolha o nível de criptografia e o nome da sua nova conta no Vault.",
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ).animate().fade(delay: 300.ms),
      ],
    );
  }

  Widget _buildSettingsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("NOME DA CARTEIRA", style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Ex: Economias, Trading...",
            prefixIcon: const Icon(LucideIcons.pencil, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text("TAMANHO DA PASSPHRASE",
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _buildOptionButton(
                "12", _wordCount == 12, () => setState(() => _wordCount = 12)),
            const SizedBox(width: AppSpacing.md),
            _buildOptionButton(
                "18", _wordCount == 18, () => setState(() => _wordCount = 18)),
            const SizedBox(width: AppSpacing.md),
            _buildOptionButton(
                "24", _wordCount == 24, () => setState(() => _wordCount = 24)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text("SEGURANÇA DO PROTOCOLO",
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.md),
        _buildSecuritySelector(),
      ],
    );
  }

  Widget _buildOptionButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySelector() {
    return Column(
      children: [
        _buildSecurityCard(
          "STANDARD",
          "Criptografia AES-256 padrão. Recomendado para uso diário.",
          LucideIcons.checkCircle,
          _accountSecurity == 'STANDARD',
          () => setState(() => _accountSecurity = 'STANDARD'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSecurityCard(
          "SHAMIR",
          "Divisão criptográfica de segredo (SSS). Segurança de nível militar.",
          LucideIcons.lock,
          _accountSecurity == 'SHAMIR',
          () => setState(() => _accountSecurity = 'SHAMIR'),
        ),
      ],
    );
  }

  Widget _buildSecurityCard(String title, String desc, IconData icon,
      bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(desc,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMnemonicDisplay() {
    final words = _mnemonic.split(' ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words
                .asMap()
                .entries
                .map((e) => _buildWordBadge(e.key + 1, e.value))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.copy,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _mnemonic));
                  SnackbarHelper.showSuccess("COPIADO PARA O CLIPBOARD");
                },
                child: Text(
                  "COPIAR TUDO",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordBadge(int index, String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(index.toString().padLeft(2, '0'),
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Text(word,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreateButton(String label) {
    final state = ref.watch(createWalletProvider);
    return CyberButton(
      text: label,
      onTap: state is CreateWalletLoading ? null : _handleCreate,
      isLoading: state is CreateWalletLoading,
    );
  }
}
