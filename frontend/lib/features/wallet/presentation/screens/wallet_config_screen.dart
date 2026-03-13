import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/wallet.dart';
import '../../../../core/theme/cyber_theme.dart';

class WalletConfigScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletConfigScreen({super.key, required this.wallet});

  @override
  State<WalletConfigScreen> createState() => _WalletConfigScreenState();
}

class _WalletConfigScreenState extends State<WalletConfigScreen> {
  bool _isBlocked = false;
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.bgDeep,
      appBar: AppBar(
        title: Text(
          widget.wallet.name,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CyberTheme.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CyberTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ─── Status Card ─────────────────────
              _CyberStatusCard(isBlocked: _isBlocked),

              const SizedBox(height: 28),

              // ─── Action Tiles ────────────────────
              _CyberActionTile(
                title: 'Block Card',
                subtitle: 'Temporarily disable this wallet',
                icon: Icons.block_flipped,
                isDestructive: true,
                trailing: Switch(
                  value: _isBlocked,
                  onChanged: (val) => setState(() => _isBlocked = val),
                  activeThumbColor: CyberTheme.neonRed,
                  activeTrackColor: CyberTheme.neonRed.withValues(alpha: 0.3),
                  inactiveThumbColor: CyberTheme.textMuted,
                  inactiveTrackColor: CyberTheme.border,
                ),
              ),
              const SizedBox(height: 14),
              _CyberActionTile(
                title: 'Hide Balance',
                subtitle: 'Hide balance on home screen',
                icon: Icons.visibility_off_outlined,
                trailing: Switch(
                  value: _hideBalance,
                  onChanged: (val) => setState(() => _hideBalance = val),
                  activeThumbColor: CyberTheme.neonCyan,
                  activeTrackColor: CyberTheme.neonCyan.withValues(alpha: 0.3),
                  inactiveThumbColor: CyberTheme.textMuted,
                  inactiveTrackColor: CyberTheme.border,
                ),
              ),
              const SizedBox(height: 14),
              _CyberActionTile(
                title: 'View Transactions',
                subtitle: 'See full history',
                icon: Icons.history_rounded,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
                },
              ),
              const SizedBox(height: 14),
              _CyberActionTile(
                title: 'Export Private Key',
                subtitle: 'View mnemonic/key',
                icon: Icons.vpn_key_outlined,
                isDestructive: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Requires Authentication')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Status Card — Cybercore Industrial Panel
// ═══════════════════════════════════════════════
class _CyberStatusCard extends StatelessWidget {
  final bool isBlocked;

  const _CyberStatusCard({required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    final statusColor = isBlocked ? CyberTheme.neonRed : CyberTheme.neonCyan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: CyberTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        boxShadow: CyberTheme.subtleGlow(statusColor),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.shield_outlined, size: 28, color: statusColor),
          ),
          const SizedBox(height: 16),
          Text(
            isBlocked ? 'LOCKED' : 'ACTIVE',
            style: GoogleFonts.jetBrainsMono(
              color: statusColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'WALLET STATUS',
            style: CyberTheme.label(size: 11, color: CyberTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Action Tile — Extracted Stateless Widget
// ═══════════════════════════════════════════════
class _CyberActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _CyberActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDestructive
        ? CyberTheme.neonRed
        : CyberTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: CyberTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CyberTheme.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive
                            ? CyberTheme.neonRed
                            : CyberTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: CyberTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CyberTheme.textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
