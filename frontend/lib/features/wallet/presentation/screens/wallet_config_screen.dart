import 'package:flutter/material.dart';
import '../../domain/entities/wallet.dart';
import '../../../../core/presentation/widgets/glass_container.dart';

class WalletConfigScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletConfigScreen({super.key, required this.wallet});

  @override
  State<WalletConfigScreen> createState() => _WalletConfigScreenState();
}

class _WalletConfigScreenState extends State<WalletConfigScreen> {
  bool _isBlocked = false; // Mock state
  bool _hideBalance = false; // Mock state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.wallet.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              opacity: 0.1,
              child: Column(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 48,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isBlocked ? "Locked" : "Active",
                    style: TextStyle(
                      color: _isBlocked ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Wallet Status",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            _buildActionTile(
              title: "Block Card",
              subtitle: "Temporarily disable this wallet",
              icon: Icons.block_flipped,
              isDestructive: true,
              trailing: Switch(
                value: _isBlocked,
                onChanged: (val) {
                  setState(() => _isBlocked = val);
                },
                activeThumbColor: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              title: "Hide Balance",
              subtitle: "Hide balance on home screen",
              icon: Icons.visibility_off_outlined,
              trailing: Switch(
                value: _hideBalance,
                onChanged: (val) {
                  setState(() => _hideBalance = val);
                },
                activeThumbColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              title: "View Transactions",
              subtitle: "See full history",
              icon: Icons.history_rounded,
              onTap: () {
                // Navigate to full history (future impl)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
              },
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              title: "Export Private Key",
              subtitle: "View mnemonic/key",
              icon: Icons.vpn_key_outlined,
              isDestructive: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Requires Authentication")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      opacity: 0.05,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : Colors.white70,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }
}
