import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/custom_error_dialog.dart';
import '../../../../core/utils/error_translator.dart';
import '../providers/wallet_provider.dart';
import '../state/wallet_state.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? walletId;

  const SendMoneyScreen({super.key, this.walletId});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  String _amount = '0';
  final _receiverController = TextEditingController();

  @override
  void dispose() {
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SendMoneyState>(sendMoneyProvider, (previous, next) {
      if (next is SendMoneySuccess) {
        showCustomErrorDialog(
          context,
          "Transação realizada com sucesso!",
        ); // Reusing dialog for success for now or should I use SnackBar for success?
        // Better: SnackBar for success, Dialog for error. Or just Pop.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transação enviada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (next is SendMoneyError) {
        showCustomErrorDialog(context, ErrorTranslator.translate(next.message));
      }
    });

    final walletState = ref.watch(walletProvider);
    final sendMoneyState = ref.watch(sendMoneyProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050511), Color(0xFF1A1F3C), Color(0xFF2D2F4E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // AppBar custom
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Text(
                                  "Send Money",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48), // Balance for arrow
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Receiver Avatar & Name
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3B3E5B),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Input para nome disfarçado
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: TextField(
                                controller: _receiverController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Enter Receiver Name",
                                  hintStyle: TextStyle(color: Colors.white30),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Text(
                              "Wallet ID / Name",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Amount Display
                        Text(
                          "\$$_amount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Wallet Selector
                        if (walletState is WalletLoaded &&
                            walletState.selectedWallet != null)
                          InkWell(
                            onTap: () =>
                                _showWalletSelector(context, walletState),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.credit_card,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          walletState.selectedWallet!.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${(walletState.selectedWallet!.balanceSatoshis / 100000000).toStringAsFixed(8)} BTC",
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Continue Button
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: sendMoneyState is SendMoneySending
                                ? null
                                : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: sendMoneyState is SendMoneySending
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const Spacer(),

                        // Numeric Keypad
                        // Hide keypad if keyboard is open to avoid overflow
                        if (MediaQuery.of(context).viewInsets.bottom == 0)
                          _buildKeypad(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildKeyRow(["1", "2", "3"]),
          const SizedBox(height: 24),
          _buildKeyRow(["4", "5", "6"]),
          const SizedBox(height: 24),
          _buildKeyRow(["7", "8", "9"]),
          const SizedBox(height: 24),
          _buildKeyRow([".", "0", "DEL"]),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key == "DEL") {
          return InkWell(
            onTap: _handleBackspace,
            child: const SizedBox(
              width: 60,
              height: 60,
              child: Icon(Icons.backspace_outlined, color: Colors.white),
            ),
          );
        }
        return InkWell(
          onTap: () => _handleKeyInput(key),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Text(
                key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleKeyInput(String key) {
    setState(() {
      if (key == '.' && _amount.contains('.')) return;
      if (_amount == '0' && key != '.') _amount = '';
      if (_amount.isEmpty && key == '.') _amount = '0';
      _amount += key;
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
        if (_amount.isEmpty) _amount = '0';
      }
    });
  }

  void _handleContinue() {
    final walletState = ref.read(walletProvider);
    if (_receiverController.text.isEmpty ||
        _amount == '0' ||
        walletState is! WalletLoaded) {
      showCustomErrorDialog(context, "Por favor, preencha todos os campos.");
      return;
    }

    final usdAmount = double.tryParse(_amount) ?? 0.0;
    // Mock rate se nao tiver
    final rate = walletState.btcToUsdRate > 0
        ? walletState.btcToUsdRate
        : 96000.0;
    final btcAmount = usdAmount / rate;
    final satoshis = (btcAmount * 100000000).toInt();

    ref
        .read(sendMoneyProvider.notifier)
        .sendBitcoin(
          fromWalletId: walletState.selectedWallet!.name,
          toAddress: _receiverController.text,
          amountSatoshis: satoshis,
          feeSatoshis: 1000,
          description: "Send Money App Transfer",
        );
  }

  void _showWalletSelector(BuildContext context, WalletLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Select Wallet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: state.wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final wallet = state.wallets[index];
                    final balanceBtc = wallet.balanceSatoshis / 100000000;
                    final isSelected =
                        wallet.name == state.selectedWallet?.name;

                    return InkWell(
                      onTap: () {
                        ref.read(walletProvider.notifier).selectWallet(wallet);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7B61FF).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: const Color(0xFF7B61FF))
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7B61FF)
                                    : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF7B61FF)
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${balanceBtc.toStringAsFixed(8)} BTC",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF7B61FF),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
