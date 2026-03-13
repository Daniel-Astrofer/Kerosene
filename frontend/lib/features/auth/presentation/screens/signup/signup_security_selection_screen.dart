import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/signup_flow_provider.dart';
import 'package:teste/core/presentation/widgets/glass_container.dart';
import 'signup_seed_phrase_screen.dart';

class SignupSecuritySelectionScreen extends ConsumerStatefulWidget {
  const SignupSecuritySelectionScreen({super.key});

  @override
  ConsumerState<SignupSecuritySelectionScreen> createState() =>
      _SignupSecuritySelectionScreenState();
}

class _SignupSecuritySelectionScreenState
    extends ConsumerState<SignupSecuritySelectionScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _tabs = ['Padrão', 'Shamir', 'Multisig'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedOption = ref.read(signupFlowProvider).seedSecurityOption;
      setState(() {
        _selectedIndex = savedOption.index;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Lighting Glows
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2962FF).withValues(alpha: 0.15),
                    const Color(0xFF2962FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B61FF).withValues(alpha: 0.12),
                    const Color(0xFF7B61FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar
                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF2962FF),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                  ],
                ),

                // App Bar equivalent
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_tabs.length, (index) {
                                final isSelected = _selectedIndex == index;
                                return GestureDetector(
                                  onTap: () => _onTabTapped(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _tabs[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF8E8E93),
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Segurança da Conta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Escolha o nível de proteção para seus ativos.',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          children: [
                            _buildSecurityPage(
                              option: SeedSecurityOption.standard,
                              title: 'Padrão (BIP39)',
                              description:
                                  'Frase de 12 ou 24 palavras. O método mais comum e compatível.',
                              features: [
                                _buildFeatureItem(
                                  Icons.security_rounded,
                                  'Simplicidade',
                                  'Fácil de gerenciar e restaurar.',
                                ),
                                _buildFeatureItem(
                                  Icons.wallet_outlined,
                                  'Amplo Suporte',
                                  'Compatível com todas as carteiras.',
                                ),
                              ],
                              glowColor: const Color(0xFF3D7CFF),
                            ),
                            _buildSecurityPage(
                              option: SeedSecurityOption.slip39,
                              title: 'Shamir SLIP-39',
                              description:
                                  'Divida sua frase em partes. Ideal para grandes quantias.',
                              features: [
                                _buildFeatureItem(
                                  Icons.share_outlined,
                                  'Resistência',
                                  'Perca um fragmento e não comprometa fundos.',
                                ),
                                _buildFeatureItem(
                                  Icons.group_work_outlined,
                                  'Distribuído',
                                  'Distribua a confiança entre locais seguros.',
                                ),
                              ],
                              glowColor: const Color(0xFFFFB800),
                            ),
                            _buildSecurityPage(
                              option: SeedSecurityOption.multisig2fa,
                              title: 'Cofre Multisig',
                              description:
                                  'Requer aprovação de múltiplos dispositivos para transações.',
                              features: [
                                _buildFeatureItem(
                                  Icons.lock_person_outlined,
                                  'Máxima Proteção',
                                  'Imune a hacks no celular.',
                                ),
                                _buildFeatureItem(
                                  Icons.account_balance_outlined,
                                  'Assistido',
                                  'Recuperação segura e institucional.',
                                ),
                              ],
                              glowColor: const Color(0xFFB026FF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          final selectedOption =
                              SeedSecurityOption.values[_selectedIndex];
                          ref
                              .read(signupFlowProvider.notifier)
                              .setSeedSecurityOption(selectedOption);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SignupSeedPhraseScreen(),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            'Selecionar e Continuar',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPage({
    required SeedSecurityOption option,
    required String title,
    required String description,
    required List<Widget> features,
    required Color glowColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF1E1E24), width: 1.5),
        color: const Color(0xFF0C0C0E).withValues(alpha: 0.6),
        blur: 10,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    option == SeedSecurityOption.standard
                        ? Icons.shield_outlined
                        : option == SeedSecurityOption.slip39
                        ? Icons.account_tree_outlined
                        : Icons.phonelink_lock_outlined,
                    color: glowColor,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ...features,
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
