import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

class P2PScreen extends ConsumerStatefulWidget {
  const P2PScreen({super.key});

  @override
  ConsumerState<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends ConsumerState<P2PScreen>
    with SingleTickerProviderStateMixin {
  bool _isBuy = true;
  String _selectedAsset = "BTC";
  final List<String> _assets = ["BTC", "USDT", "ETH", "DAI"];
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassContainer(
                    opacity: 0.1,
                    blur: 15,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(5),
                    child: _buildBuySellToggle(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAssetFilter(),
                const SizedBox(height: 10),
                _buildActionRow(),
                const SizedBox(height: 10),
                Expanded(child: _buildAdsList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "P2P Trading",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Fast & Secure Marketplace",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(Icons.history_rounded),
              const SizedBox(width: 12),
              _buildHeaderIcon(Icons.more_horiz_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return GlassContainer(
      opacity: 0.1,
      blur: 10,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }

  Widget _buildBuySellToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isBuy = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isBuy
                    ? const Color(0xFF00FF94).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isBuy
                      ? const Color(0xFF00FF94).withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                "Comprar",
                style: TextStyle(
                  color: _isBuy ? const Color(0xFF00FF94) : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isBuy = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isBuy
                    ? const Color(0xFFFF0055).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: !_isBuy
                      ? const Color(0xFFFF0055).withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                "Vender",
                style: TextStyle(
                  color: !_isBuy ? const Color(0xFFFF0055) : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _assets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final asset = _assets[index];
          final isSelected = _selectedAsset == asset;
          return GestureDetector(
            onTap: () => setState(() => _selectedAsset = asset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                asset,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionButton(Icons.keyboard_arrow_down_rounded, "BRL"),
              const SizedBox(width: 12),
              _buildActionButton(Icons.filter_list_rounded, "Filtro"),
            ],
          ),
          _buildActionButton(Icons.credit_card_rounded, "Pagamento"),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GlassContainer(
      opacity: 0.05,
      blur: 5,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _buildAdsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        100,
      ), // Bottom padding for dock
      itemCount: 8,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildAdCard(index);
      },
    );
  }

  Widget _buildAdCard(int index) {
    final names = [
      "Cryptooo",
      "FastTrade",
      "KingBTC",
      "ExpressPay",
      "GlobalP2P",
    ];
    final prices = [
      "342,034.50",
      "342,110.20",
      "342,080.00",
      "342,150.00",
      "342,000.00",
    ];

    final name = names[index % names.length];
    final price = prices[index % prices.length];
    final isOnline = index % 2 == 0;

    return GlassContainer(
      opacity: 0.05,
      blur: 10,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      name[0],
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF94),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              const Spacer(),
              Text(
                "98.5% concluído",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preço",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "BRL",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBuy
                      ? const Color(0xFF00FF94)
                      : const Color(0xFFFF0055),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 0,
                  ),
                  minimumSize: const Size(80, 40),
                  elevation: 5,
                  shadowColor:
                      (_isBuy
                              ? const Color(0xFF00FF94)
                              : const Color(0xFFFF0055))
                          .withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isBuy ? "Comprar" : "Vender",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow("Limite", "R\$ 100,00 - R\$ 5.000,00"),
                  const SizedBox(height: 4),
                  _buildStatRow("Disponível", "0.05432 BTC"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPaymentTag("Pix", const Color(0xFF32BCAD)),
              const SizedBox(width: 8),
              _buildPaymentTag("Transf. Bancária", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label ",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
