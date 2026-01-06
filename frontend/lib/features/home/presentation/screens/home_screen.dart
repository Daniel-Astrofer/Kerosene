import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/state/wallet_state.dart';
import '../../../wallet/presentation/widgets/wallet_card.dart';
import '../../../wallet/presentation/screens/wallet_details_screen.dart';
import '../../../wallet/presentation/screens/create_wallet_screen.dart';
// O usuário pediu para remover botões antigos, mas talvez queira acessar detalhes da wallet clicada.

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // Iniciar carregamento das wallets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refresh(); // Garante load
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    final walletState = ref.read(walletProvider);
    if (walletState is WalletLoaded && walletState.wallets.isNotEmpty) {
      final selectedWallet = walletState.wallets[index];
      // Selecionar wallet no state global
      ref.read(walletProvider.notifier).selectWallet(selectedWallet);
      // Atualizar saldo da wallet focada
      ref.read(walletProvider.notifier).updateWalletBalance(selectedWallet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pushReplacementNamed(context, '/welcome');
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050511),
                  Color(0xFF1A1F3C),
                  Color(0xFF2D2F4E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: SafeArea(
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Area
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                user?.name ?? "User",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Wallet Area (No Expanded, just content)
                        _buildWalletContent(walletState),
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

  Widget _buildWalletContent(WalletState state) {
    if (state is WalletLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
      );
    }

    if (state is WalletError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Erro ao carregar carteiras",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            TextButton(
              onPressed: () => ref.read(walletProvider.notifier).refresh(),
              child: const Text("Tentar Novamente"),
            ),
          ],
        ),
      );
    }

    if (state is WalletLoaded) {
      if (state.wallets.isEmpty) {
        return _buildEmptyState();
      }

      // Se mudar o estado e o index for invalido, reseta
      if (_currentIndex >= state.wallets.length) {
        _currentIndex = 0;
      }

      final currentWallet = state.wallets[_currentIndex];
      /**/
      return Column(
        children: [
          // Carousel
          SizedBox(
            height: 220, // Increased height for better card visibility
            child: PageView.builder(
              controller: _pageController,
              itemCount: state.wallets.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final wallet = state.wallets[index];
                return GestureDetector(
                  onTap: () {
                    ref.read(walletProvider.notifier).selectWallet(wallet);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WalletDetailsScreen(wallet: wallet),
                      ),
                    );
                  },
                  child: WalletCard(
                    wallet: wallet,
                    isSelected: index == _currentIndex,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Balance Display (Linked to focused wallet)
          Text(
            "CURRENT BALANCE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "\$",
                style: TextStyle(
                  color: const Color(0xFF00D4FF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 4),
              // Calculando USD baseado em rate e balance
              Text(
                _formatUsdBalance(
                  currentWallet.balanceSatoshis,
                  state.btcToUsdRate,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF252A40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${(currentWallet.balanceSatoshis / 100000000).toStringAsFixed(8)} BTC",
              style: const TextStyle(
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Push buttons to bottom if space allows in IntrinsicHeight, else just spacing
          const SizedBox(height: 48),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navegar para Detalhes da Wallet atual
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WalletDetailsScreen(wallet: currentWallet),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text("History"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateWalletScreen(),
                        ), // Ou send money se tiver saldo
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("New Wallet"), // Botão secundário de add
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Wallets Found",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first Bitcoin wallet to get started.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),

          // Big Create Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateWalletScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0054FF)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0054FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "Create Wallet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUsdBalance(int satoshis, double rate) {
    if (rate <= 0) return "0.00";
    final btc = satoshis / 100000000.0;
    final usd = btc * rate;
    return usd.toStringAsFixed(2);
  }
}
