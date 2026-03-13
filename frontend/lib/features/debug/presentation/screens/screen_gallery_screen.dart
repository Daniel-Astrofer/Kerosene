import 'package:flutter/material.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';

// Auth Screens
import 'package:teste/features/auth/presentation/screens/welcome_screen.dart';
import 'package:teste/features/auth/presentation/screens/login_screen.dart';
import 'package:teste/features/auth/presentation/screens/presentation_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_start_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_username_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_security_selection_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_seed_phrase_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_seed_verification_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_passkey_screen.dart';
import 'package:teste/features/auth/presentation/screens/signup/signup_payment_screen.dart';
import 'package:teste/features/auth/presentation/screens/totp_setup_screen.dart';

// Wallet & Home Screens
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/wallet/presentation/screens/create_wallet_screen.dart';
import 'package:teste/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:teste/features/wallet/presentation/screens/withdraw_screen.dart' as wallet_withdraw;
import 'package:teste/features/transactions/presentation/screens/withdraw_screen.dart' as tx_withdraw;
import 'package:teste/features/transactions/presentation/screens/deposits_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_amount_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_method_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_provider_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_onchain_invoice_screen.dart';
import 'package:teste/features/wallet/presentation/screens/deposit/deposit_lightning_invoice_screen.dart';
import 'package:teste/features/wallet/presentation/screens/luxury_qr_deposit_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_screen.dart';
import 'package:teste/features/wallet/presentation/screens/receive_qr_screen.dart';
import 'package:teste/features/wallet/presentation/screens/wallet_details_screen.dart';
import 'package:teste/features/wallet/presentation/screens/wallet_config_screen.dart';
import 'package:teste/features/wallet/presentation/screens/unified_transaction_screen.dart';

// Profile Screens
import 'package:teste/features/profile/presentation/screens/profile_screen.dart';
import 'package:teste/features/profile/presentation/screens/personal_data_screen.dart';
import 'package:teste/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:teste/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:teste/features/profile/presentation/screens/support_screen.dart';

// Others
import 'package:teste/features/security/presentation/screens/sovereignty_status_screen.dart';
import 'package:teste/features/market/presentation/screens/market_screen.dart';
import 'package:teste/features/nft/presentation/screens/nft_marketplace_screen.dart';
import 'package:teste/features/p2p/presentation/screens/p2p_screen.dart';
import 'package:teste/features/settings/presentation/screens/settings_screen.dart';

final Wallet mockWallet = Wallet(
  id: 'mock_id_777',
  name: 'Black Card',
  address: 'bc1qkerosene0mock0address0sovereign0key0',
  balance: 0.042,
  derivationPath: "m/84'/0'/0'/0/0",
  type: WalletType.nativeSegwit,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

class ScreenGalleryScreen extends StatelessWidget {
  const ScreenGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        title: const Text(
          'DEBUG GALLERY',
          style: TextStyle(fontFamily: 'HubotSansExpanded', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _buildCategory(context, 'AUTHENTICATION', [
            _buildScreenTile(context, 'Welcome Screen', const WelcomeScreen()),
            _buildScreenTile(context, 'Login Screen', const LoginScreen()),
            _buildScreenTile(context, 'Presentation Slides', const PresentationScreen()),
            _buildScreenTile(context, 'Signup Start', const SignupStartScreen()),
            _buildScreenTile(context, 'Signup Username', const SignupUsernameScreen()),
            _buildScreenTile(context, 'Signup Security Selection', const SignupSecuritySelectionScreen()),
            _buildScreenTile(context, 'Signup Seed Phrase', const SignupSeedPhraseScreen()),
            _buildScreenTile(context, 'Signup Seed Verification', const SignupSeedVerificationScreen()),
            _buildScreenTile(context, 'Signup Sovereign Key', const SignupPasskeyScreen()),
            _buildScreenTile(context, 'Signup Payment', const SignupPaymentScreen()),
            _buildScreenTile(context, 'TOTP Setup', const TotpSetupScreen()),
          ]),
          _buildCategory(context, 'WALLET & TRANSACTIONS', [
            _buildScreenTile(context, 'Home Screen (Dashboard)', const HomeScreen()),
            _buildScreenTile(context, 'Create Wallet', const CreateWalletScreen()),
            _buildScreenTile(context, 'Send Money (Pix/Internal)', SendMoneyScreen(walletId: mockWallet.name)),
            _buildScreenTile(context, 'Withdraw (Internal)', wallet_withdraw.WithdrawScreen(walletId: mockWallet.name)),
            _buildScreenTile(context, 'Withdraw (External BTC)', tx_withdraw.WithdrawScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Deposits List', const DepositsScreen()),
            _buildScreenTile(context, 'Deposit Amount', DepositAmountScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Deposit Method', DepositMethodScreen(wallet: mockWallet, amountFiat: 1000.0)),
            _buildScreenTile(context, 'Deposit Provider (Onramper)', DepositProviderScreen(wallet: mockWallet, amountFiat: 1000.0, method: 'Pix')),
            _buildScreenTile(context, 'Onchain Invoice', DepositOnchainInvoiceScreen(wallet: mockWallet, amountFiat: 1000.0, providerName: 'Kerosene')),
            _buildScreenTile(context, 'Lightning Invoice', DepositLightningInvoiceScreen(wallet: mockWallet, amountFiat: 1000.0, providerName: 'Kerosene')),
            _buildScreenTile(context, 'Luxury QR Deposit', LuxuryQrDepositScreen(address: mockWallet.address, amountBtc: 0.001)),
            _buildScreenTile(context, 'Receive Screen', const ReceiveScreen()),
            _buildScreenTile(context, 'Receive QR', const ReceiveQrScreen(amountDisplay: '0.002 BTC', paymentUri: 'bitcoin:bc1q...')),
            _buildScreenTile(context, 'Wallet Details', WalletDetailsScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Wallet Config', WalletConfigScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Unified Transaction (History)', const UnifiedTransactionScreen()),
          ]),
          _buildCategory(context, 'PROFILE & SETTINGS', [
            _buildScreenTile(context, 'Profile Main', const ProfileScreen()),
            _buildScreenTile(context, 'Personal Data', const PersonalDataScreen()),
            _buildScreenTile(context, 'Notification Settings', const NotificationSettingsScreen()),
            _buildScreenTile(context, 'Security Settings', const SecuritySettingsScreen()),
            _buildScreenTile(context, 'Support / Help', const SupportScreen()),
            _buildScreenTile(context, 'Global Settings', const SettingsScreen()),
          ]),
          _buildCategory(context, 'FEATURES', [
            _buildScreenTile(context, 'Market / Trading', const MarketScreen()),
            _buildScreenTile(context, 'NFT Marketplace', const NftMarketplaceScreen()),
            _buildScreenTile(context, 'P2P Trading', const P2PScreen()),
            _buildScreenTile(context, 'Sovereignty Status', const SovereigntyStatusScreen()),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategory(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFF7B61FF).withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children.asMap().entries.map((entry) {
            final idx = entry.key;
            final widget = entry.value;
            return Column(
              children: [
                widget,
                if (idx < children.length - 1)
                  Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white.withValues(alpha: 0.05)),
              ],
            );
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildScreenTile(BuildContext context, String title, Widget screen) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title, 
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 14, 
          fontWeight: FontWeight.w500
        )
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
