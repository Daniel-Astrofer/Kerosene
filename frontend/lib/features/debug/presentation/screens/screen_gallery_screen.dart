import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:teste/core/providers/price_provider.dart';
import 'package:teste/core/theme/app_colors.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';

// Wallet & Home Screens
import 'package:teste/features/home/presentation/screens/home_screen.dart';
import 'package:teste/features/wallet/presentation/screens/create_wallet_screen.dart';
import 'package:teste/features/wallet/presentation/screens/send_money_screen.dart';
import 'package:teste/features/wallet/presentation/screens/withdraw_screen.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'DEBUG GALLERY',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding:
            EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
        children: [
          _buildCategory(context, 'WALLET & TRANSACTIONS', [
            _buildScreenTile(
                context, 'Home Screen (Dashboard)', const HomeScreen()),
            _buildScreenTile(
                context, 'Create Wallet', const CreateWalletScreen()),
            _buildScreenTile(context, 'Send Money (Pix/Internal)',
                SendMoneyScreen(walletId: mockWallet.name)),
            _buildScreenTile(context, 'Withdrawal (Premium)',
                WithdrawScreen(walletId: mockWallet.name)),
            _buildScreenTile(context, 'Deposits List', const DepositsScreen()),
            _buildScreenTile(context, 'Deposit Amount',
                DepositAmountScreen(wallet: mockWallet)),
            _buildScreenTile(
                context,
                'Deposit Method',
                DepositMethodScreen(
                  wallet: mockWallet,
                  inputAmount: 1000.0,
                  inputCurrency: Currency.brl,
                )),
            _buildScreenTile(
                context,
                'Deposit Provider (Onramper)',
                DepositProviderScreen(
                    wallet: mockWallet,
                    inputAmount: 1000.0,
                    inputCurrency: Currency.brl,
                    method: 'Pix')),
            _buildScreenTile(
                context,
                'Onchain Invoice',
                DepositOnchainInvoiceScreen(
                    wallet: mockWallet,
                    inputAmount: 1000.0,
                    inputCurrency: Currency.brl,
                    providerName: 'Kerosene')),
            _buildScreenTile(
                context,
                'Lightning Invoice',
                DepositLightningInvoiceScreen(
                    wallet: mockWallet,
                    inputAmount: 1000.0,
                    inputCurrency: Currency.brl,
                    providerName: 'Kerosene')),
            _buildScreenTile(
                context,
                'Luxury QR Deposit',
                LuxuryQrDepositScreen(
                    address: mockWallet.address, amountBtc: 0.001)),
            _buildScreenTile(context, 'Receive Screen', const ReceiveScreen()),
            _buildScreenTile(
                context,
                'Receive QR',
                const ReceiveQrScreen(
                    amountDisplay: '0.002 BTC', paymentUri: 'bitcoin:bc1q...')),
            _buildScreenTile(context, 'Wallet Details',
                WalletDetailsScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Wallet Config',
                WalletConfigScreen(wallet: mockWallet)),
            _buildScreenTile(context, 'Unified Transaction (History)',
                const UnifiedTransactionScreen(isSend: false)),
          ]),
          _buildCategory(context, 'PROFILE & SETTINGS', [
            _buildScreenTile(context, 'Profile Main', const ProfileScreen()),
            _buildScreenTile(
                context, 'Personal Data', const PersonalDataScreen()),
            _buildScreenTile(context, 'Notification Settings',
                const NotificationSettingsScreen()),
            _buildScreenTile(
                context, 'Security Settings', const SecuritySettingsScreen()),
            _buildScreenTile(context, 'Support / Help', const SupportScreen()),
            _buildScreenTile(
                context, 'Global Settings', const SettingsScreen()),
          ]),
          _buildCategory(context, 'FEATURES', [
            _buildScreenTile(
                context, 'Sovereignty Status', const SovereigntyStatusScreen()),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategory(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.sm + AppSpacing.xs,
              left: AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.xl),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.05)),
          ),
          child: Column(
              children: children.asMap().entries.map((entry) {
            final idx = entry.key;
            final widget = entry.value;
            return Column(
              children: [
                widget,
                if (idx < children.length - 1)
                  Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.05)),
              ],
            );
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildScreenTile(BuildContext context, String title, Widget screen) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing:
          Icon(LucideIcons.chevronRight, color: AppColors.white20, size: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
